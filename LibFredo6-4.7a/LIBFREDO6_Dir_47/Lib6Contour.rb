=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Sep. 2012 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Contour.rb
# Original Date	:  11 Sep 12
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  Contains some standalone generic methods for handling contours and curves
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module G6

#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
# Sketchup Curve Management
#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------

#MAKE_CURVE: Adjust the curve vertices when in loop so that they start at a junction - This limits the collateral broken curves
def G6.loop_adjust_vertices(lvx)
	return lvx unless lvx.first == lvx.last
	vxbreak = lvx[1..-2].find { |vx| (vx.edges.find_all { |e| !e.soft? }).length > 2 } 
	ibreak = lvx.rindex vxbreak
	lvx = lvx[ibreak..-1] + lvx[1..ibreak] if ibreak && ibreak > 0
	lvx
end
	
#MAKE_CURVE: Create the Curve geometry out of a sequence of vertices in the context <entities>
# Return the list of curves created (usually only one)
def G6.contour_make_curve(lvx, entities)
	#In case of loop, shifting vertex so that the curve starts at a crossing. 
	lvx = G6.loop_adjust_vertices lvx
	
	#Storing current information on edges and setting edges as soft
	hold_curves = {}
	hsh_info = {}
	lvx.each do |vx| 
		next unless vx.valid?
		vx.edges.each do |e| 
			hsh_info[e.entityID] = [e.start, e.end, e.soft?, e.material] unless hsh_info[e.entityID]
			curve = e.curve
			hold_curves[curve.entityID] = curve if curve && !hold_curves[curve.entityID]
			e.soft = true
		end
	end	
	
	#Exploding the old curves
	hold_vertices = {}
	hold_curves.each do |key, curve|
		hold_vertices[key] = G6.loop_adjust_vertices curve.vertices
		curve.edges[0].explode_curve
	end
	
	#Creating the curves in a separate group
	topgroup = entities.add_group
	topgroup.entities.add_curve lvx.collect { |vx| vx.position }
	topgroup.explode	
	
	#Restoring the edges
	hsh_info.each do |id, a| 
		vx0, vx1, soft, mat = a
		next unless vx0.valid? && vx1.valid?
		edge = vx0.common_edge(vx1)
		next unless edge
		edge.soft = soft
		edge.material = mat
	end	
	
	#Restoring the collateral broken curves
	hold_vertices.each do |key, llvx|
		lspt = [llvx.first.position]
		n = llvx.length-2
		for i in 0..n
			vx0 = llvx[i]
			vx1 = llvx[i+1]
			lspt.push vx1.position if vx0.common_edge(vx1)
			next if i < n 
			entities.add_curve lspt
			lspt = []
		end	
	end
	
	#Returning the list of curves
	lcurves = []
	for i in 0..lvx.length-2
		next unless lvx[i].valid? && lvx[i+1].valid?
		e = lvx[i].common_edge lvx[i+1]
		next unless e
		curve = e.curve
		lcurves.push curve unless curve == nil || lcurves.include?(curve)
	end
	lcurves
end
	
#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
# Contour Information
#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------

#Compute the curvilinear abscisses of points in a curve	
def G6.curvilinear_ratio (pts)
	dtot = 0
	dist = [0]
	for i in 1..pts.length-1
		dtot += pts[i-1].distance pts[i]
		dist[i] = dtot
	end
	dist = dist.collect { |d| d / dtot } if dtot > 0
	dist
end

#Compute the curvilinear distance of points in a curve from its origin
def G6.curvilinear_distance(pts)
	dtot = 0
	dist = [0]
	for i in 1..pts.length-1
		dtot += pts[i-1].distance pts[i]
		dist[i] = dtot
	end
	dist
end

#Compute the curvilinear distance of points in a curve from its origin
def G6.stats_segment_length(pts)
	n = pts.length-1
	davg = dmin = dmax = pts[0].distance(pts[1])
	for i in 2..n
		d = pts[i-1].distance pts[i]
		davg += d
		dmin = d if d < dmin
		dmax = d if d > dmax
	end
	[dmin, dmax, davg / n]
end

#Compute the curvilinear distance of points in a curve from its origin
def G6.contour_stats(pts)
	n = pts.length-1
	loop = (pts.first == pts.last)
	hinfo = {}
	davg = dmin = dmax = pts[0].distance(pts[1])
	dist = [dmin]
	for i in 1..n
		d = dist[i] = pts[i-1].distance(pts[i])
		davg += d
		dmin = d if d < dmin
		dmax = d if d > dmax
	end
	davg /= n
	
	#Computing angles
	nb_angle_avg = 0
	if loop
		angle0 = pts[-2].vector_to(pts[0]).angle_between pts[0].vector_to(pts[1])
		angles = [angle0]
		#angle0 = 0.15 if angle0 < 0.15
		#unless angle0 < 0.0001
		angle_min = angle_max = angle_avg = angle0
		nb_angle_avg += 1
		#end	
	else
		angle0 = 0
		angles = []
		angle_avg = angle_max = 0
		angle_min = nil
	end	
	for i in 1..n-1
		vec1 = pts[i-1].vector_to pts[i]
		vec2 = pts[i].vector_to pts[i+1]
		angles[i] = angle = vec1.angle_between(vec2)
		#puts "angle = #{angle.radians}"
		#angle = 0.15 if angle < 0.15
		if angle && angle > 0.0001
			nb_angle_avg += 1
			angle_avg += angle
			angle_min = angle if !angle_min || angle < angle_min
			angle_max = angle if angle > angle_max
		end	
	end
	angles.push angle0 if loop
	
	#Returning the statistics
	hinfo[:dist] = dist
	hinfo[:dmin] = dmin
	hinfo[:dmax] = dmax
	hinfo[:davg] = davg
	hinfo[:angle_sum] = angle_avg
	hinfo[:angle_avg] = (nb_angle_avg == 0) ? 0 : angle_avg / nb_angle_avg
	hinfo[:angle_min] = angle_min
	hinfo[:angle_max] = angle_max
	hinfo[:angles] = angles
	hinfo
end

#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
# Contour Mapping
#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------

#CURVE_MAPPING: Build the map info between two curves based on curvilinear abscisse
def G6.contour_mapping_by_curvilinear(pts1, pts2)
	dist1 = G6.curvilinear_ratio(pts1)
	dist2 = G6.curvilinear_ratio(pts2)

	map = []
	i1 = i2 = 0
	while true
		d1 = dist1[i1]
		d2 = dist2[i2]
		break unless d1 && d2
		if (d1 - d2).abs < 0.01
			map.push [pts1[i1], pts2[i2], 0]
			i1 += 1
			i2 += 1
		elsif d1 < d2
			map.push [nil, pts1[i1], -1]
			i1 += 1
		else
			map.push [nil, pts2[i2], +1]
			i2 += 1
		end
	end
	map
end

#CURVE_MAPPING: Build the map info between two curves based on proximity of points of <pts1> and <pts2>
#The two curves must have their first and last points matching respectively
def G6.contour_mapping_by_proximity(pts1, pts2)
	map = [[pts1[0], pts2[0], 0]]
	i1 = i2 = 1
	while true
		pt1 = pts1[i1]
		pt2 = pts2[i2]
		pt1n = pts1[i1+1]
		pt2n = pts2[i2+1]
		break unless pt1 && pt2
		
		#Points are the same
		if pt1 == pt2
 			map.push [pt1, pt2, 0]
			i1 += 1
			i2 += 1
			next
		end	
		
		#Reaching End for Curve 2
		if !pt2n
			for i in i1..pts1.length-2
				pt1 = pts1[i]
				d, pt, pti = G6.proximity_point_segment(pt1, pts2[-2], pts2[-1])
				map.push [pt1, pti, -1]
			end
			break
		end

		#reaching End for Curve 1
		if !pt1n
			for i in i2..pts2.length-2
				map.push [nil, pts2[i], 1]
			end
			break
		end
		
		#Curve 2 is more detailed than curve1 locally
		da, pta, ptia = G6.proximity_point_segment(pt1, pt2, pt2n)
		pt2m = pts2[i2-1]
		db, ptb, ptib = G6.proximity_point_segment(pt1, pt2m, pt2)
		if (da == db && ptia == ptib)
			state = 0
		elsif da <= db
			state = (pt2.distance(ptia) < 0.2 * pt2.distance(pt2n)) ? 0 : 2
		else	
			state = (pt2.distance(ptib) < 0.2 * pt2.distance(pt2m)) ? 0 : 1
		end	
		
		#Contribution to map and next step
		case state
		when 0
			map.push [pt1, pt2, 0]
			i1 += 1
			i2 += 1
		when 1
			map.push [pt1, ptib, -1]
			i1 += 1
		when 2
			map.push [nil, pt2, +1]
			i2 += 1
		end
	end
	map.push [pts1[-1], pts2[-1], 0]

	#Complementing the intermediate points
	n = map.length - 1
	pts1 = map.collect { |a| a[0] }
	pts2 = map.collect { |a| a[1] }
	
	map
end
	
#Execute a mapping transformation from the original curve indicated by lvx	
def G6.contour_mapping_transform(map, lvx, entities)
	n = map.length - 1
	pts1 = map.collect { |a| a[0] }
	pts2 = map.collect { |a| a[1] }
	laction = map.collect { |a| a[2] }
	
	#Inserting the points to add into the first curve
	ibeg = 0
	for i in 0..n
		if laction[i] <= 0
			pts1[ibeg..i] = G6.contour_mapping_interpolate pts1[ibeg], pts1[i], pts2[ibeg..i] if i > ibeg+1
			ibeg = i			
		end
	end
	
	#Inserting the point to delete into the second curve
	ls = []
	if laction[0] == -1
		for i in 2..n-1
			j = n - i
			ls.unshift j
			break if laction[j] >= 0
		end	
	end
	for i in 0..n
		ls.push i
		if laction[i] >= 0 && ls.length > 1
			if ls.length > 2
				lpt1 = ls.collect { |k| pts1[k] }
				pts = G6.contour_mapping_interpolate pts2[ls[0]], pts2[i], lpt1 if ls.length > 2
				ls.each_with_index { |k, j| pts2[k] = pts[j] }
			end	
			ls = [i]
		end
	end
	
	#Creating the vertices to add on first curve	
	edges = entities.add_edges pts1
	vx0 = lvx[0]
	new_lvx = [vx0]
	edges.each do |e|
		vx0 = e.other_vertex vx0
		new_lvx.push vx0
	end
	
	#Calculating the translation vectors
	hfaces_del = {}
	lvec = []
	n -= 1 if pts1.first == pts1.last
	for i in 0..n
		vec = pts1[i].vector_to(pts2[i])
		lvec.push vec
		vx = new_lvx[i]
		if laction[i] == 1
			vx.faces.each do |face|
				face_id = face.entityID
				next if hfaces_del[face_id]
				hfaces_del[face_id] = face unless (face.normal % vec).abs < 0.0001
			end
		end	
	end	
	
	#Erasing the faces if needed
	hfaces_del.each { |face_id, face| face.erase! if face.valid? }
	
	#Merging vertices	
	
	#Moving the vertices
	entities.transform_by_vectors new_lvx[0..n], lvec
	
	[new_lvx]
end

#CURVE_MAPPING: Calculate new points position by curvilinear interpolation
def G6.contour_mapping_interpolate(pt1beg, pt1end, pts2)
	nls = pts2.length - 1	
	dsum = []
	dtot = 0
	for i in 1..nls
		dtot += pts2[i-1].distance pts2[i]
		dsum[i] = dtot
	end
	
	pts = [pt1beg]
	for i in 1..nls
		r = dsum[i] / dtot
		pts.push Geom.linear_combination(1-r, pt1beg, r, pt1end)
	end	
	pts
end

#----------------------------------------------------------------------------------------
# CONTOUR SHAPING: top methods
#----------------------------------------------------------------------------------------

#Toplevel method to transform a contour into a new one via a compution proc and options
def G6.contour_reshaping(lst_info_contours, calculation_proc, hgen_options, hcalc_options, local_options, ctrl_points=nil)
	results_info = []
	contour_gen_mode = hgen_options[:contour_gen_mode]
	contour_gen_mode = :erase unless contour_gen_mode
	
	#Exploding the curves if any, when in Deformation mode
	if contour_gen_mode == :keep
		hsh_prev_curves = {}
		lst_explode = []
		lst_info_contours.each do |info|
			lvx, ledges, tr, parent = info
			ledges.each do |edge|
				curve = edge.curve
				if curve && !hsh_prev_curves[curve.entityID]
					hsh_prev_curves[curve.entityID] = [curve.vertices, parent]
					lst_explode.push curve
				end	
			end	
		end
		lst_explode.each { |curve| curve.edges[0].explode_curve } unless hsh_prev_curves.empty?
	end
	
	#Transforming the contours into calculated contours
	hgroups = {}
	lst_info_contours.each do |info|
		lvx, ledges, tr, parent = info
		entities = G6.grouponent_entities(parent)
		pts_vx = lvx.collect { |vx| vx.position }
		
		#Assigning the original contour
		pts = pts_vx unless ctrl_points
		
		#Preprocessing the original contour if required (Removing Spike, collinear, etc...)
		bz = G6.contour_processing pts, calculation_proc, hcalc_options, local_options
				
		#Generation by deformation
		if contour_gen_mode == :keep
			map = G6.contour_mapping_by_proximity pts_vx, bz
			llvx = G6.contour_mapping_transform(map, lvx, entities)
			results_info.push [llvx, parent, tr, entities]
			
		#generation in a group	
		elsif contour_gen_mode == :group
			grp = hgroups[parent.entityID]
			grp = hgroups[parent.entityID] = entities.add_group unless grp
			tpg = grp.entities.add_group
			ledges = tpg.entities.add_edges bz
			tpg.explode
			new_lvx = G6.vertices_from_edges_in_sequence ledges, bz[0]
			results_info.push [[new_lvx], grp, tr * grp.transformation, grp.entities]
			
		#Generation by creation and erasing original contour	
		else
			ledges.each { |e| e.erase! if e.valid? }
			tpg = entities.add_group
			ledges = tpg.entities.add_edges bz
			tpg.explode
			new_lvx = G6.vertices_from_edges_in_sequence ledges, bz[0]
			results_info.push [[new_lvx], parent, tr, entities]
		end
	end
	
	#Cleaning the results (lonely vertices and collinear edges)
	if contour_gen_mode == :keep
		results_info.each do |info| 
			llvx, parent, tr, entities = info
			info[0] = llvx.collect { |lvx| G6.contour_cleanup lvx, entities }
		end
	end
	
	#Generating as SU Curve
	if hgen_options[:make_curve]
		results_info.each do |info| 
			llvx, parent, tr, entities = info
			entities = G6.grouponent_entities(parent)
			llvx.collect { |lvx| G6.contour_make_curve lvx, entities }
		end
	end	
	
	#Restoring the previous curves if applicable
	#restore_remembered_curves
	
	results_info
end
	
#Preprocess original contour for some cleanup	
def G6.contour_processing(pts, calculation_proc, hcalc_options, local_options)
	return pts unless hcalc_options

	#Creating the map for local options
	map_pts = []
	for i in 0..pts.length-1
		map_pts[i] = i
	end
	
	#Cleaning up the curve by removing the small spikes
	n = hcalc_options[:remove_spikes]
	if n.class == Fixnum && n > 0
		tolerance = 0.15 * n
		pts, map_pts = G6.contour_adjust_small_spikes pts, tolerance, map_pts
	end

	#Removing collinear Edges
	if hcalc_options[:remove_collinear]
		pts, map_pts = G6.contour_adjust_collinear pts, map_pts
		lopt = []
		map_pts.each { |i| lopt.push local_options[i] }
		bz = calculation_proc.call pts, hcalc_options, lopt
		
	#Or handling the sections	
	elsif hcalc_options[:by_section]
		lsections = contour_collinear_sections(pts)
		bz = []
		for i in 0..lsections.length-1
			ibeg, iend = lsections[i]
			if ibeg == iend
				bz.push pts[ibeg]
			else	
				lopt = []
				map_pts[ibeg..iend].each { |i| lopt.push local_options[i] }
				bz += calculation_proc.call pts[ibeg..iend], hcalc_options, lopt
			end	
		end
		unless pts.first == pts.last
			bz.unshift pts.first unless bz.first == pts.first
			bz.push pts.last unless bz.last == pts.last
		end	
		
	#Or keeping all vertices
	else
		lopt = []
		map_pts.each { |i| lopt.push local_options[i] }
		bz = calculation_proc.call pts, hcalc_options, lopt
	end
	
	#Returning the computed contour
	bz
end
	
#Detremine the collinear and non collinear sections of the contour	
def G6.contour_collinear_sections(pts)
	n = pts.length-1
	return [[0, 1]] if n < 2
	loop = (pts.first == pts.last)

	#Computing angles
	if loop
		anglen = angle0 = (pts[-2].vector_to(pts[0]).angle_between(pts[0].vector_to(pts[1])) > 0.001) ? true : false
	else
		angle0 = (pts[0].vector_to(pts[1]).angle_between(pts[1].vector_to(pts[2])) > 0.001) ? true : false
		anglen = (pts[-3].vector_to(pts[-2]).angle_between(pts[-2].vector_to(pts[-1])) > 0.001) ? true : false
	end	
	angles = [angle0]
	for i in 1..n-1
		vec1 = pts[i-1].vector_to pts[i]
		vec2 = pts[i].vector_to pts[i+1]
		angles[i] = (vec1.angle_between(vec2) > 0.001) ? true : false
	end
	angles.push anglen
	
	#Identifying sections of collinear vertices
	lsections = []
	ibeg = nil
	flat = !angles[0]
	for i in 0..n
		if flat && angles[i]
			lsections.push [0, 0] unless ibeg
			ibeg = i-1
			flat = !flat
		elsif !flat && (!angles[i] || i == n)
			ibeg = 0 unless ibeg
			if angles[i-1] && !angles[i-2] && i != n
				lsections.push [i-1, i-1]
			else	
				lsections.push [ibeg, i]
			end	
			flat = !flat
		elsif flat && i == n
			lsections.push [n, n]
		end	
	end	
	lsections.push [n, n] unless lsections.last.last == n

	lsections
end

#Clean up a contour for colinear edges
def G6.contour_adjust_collinear(pts, map_pts=nil)
	n = pts.length-1
	return [pts, map_pts] if n < 2
	map_pts = [] unless map_pts
	
	new_pts = [pts[0]]
	new_map_pts = [map_pts[0]]
	for i in 1..n-1
		pt = pts[i]
		vec1 = pts[i-1].vector_to pt
		vec2 = pt.vector_to pts[i+1]
		if (vec1 * vec2).length > 0
			new_pts.push pt
			new_map_pts.push map_pts[i]
		end	
	end
	new_pts.push pts.last
	new_map_pts.push map_pts.last
	
	[new_pts, new_map_pts]
end

#Clean up a contour for small segments with size < tolerance in % of average length
def G6.contour_adjust_small_spikes(pts, tolerance=0.25, map_pts=nil)
	n = pts.length-1
	return [pts, map_pts] if n < 2
	map_pts = [] unless map_pts
	
	#Computing average length and angle
	hinfo = G6.contour_stats(pts)
	davg = hinfo[:davg]
	dist = hinfo[:dist]
	angles = hinfo[:angles]
	
	#Removing small spikes
	tolerance = 0.25 unless tolerance
	
	i = 1
	new_pts = [pts[0]]
	new_map_pts = [map_pts[0]]
	while true
		break if i >= n
		if dist[i] / davg < tolerance && dist[i+1] / davg < tolerance && angles[i] > 70.degrees
			if i > 1
				new_pts.pop
				new_map_pts.pop
			end	
			i += 1
		else
			new_pts.push pts[i]
			new_map_pts.push map_pts[i]
		end
		i += 1
	end	
	unless new_pts.last == pts.last
		new_pts.push pts.last
		new_map_pts.push map_pts.last
	end
	
	[new_pts, new_map_pts]
end
	
#----------------------------------------------------------------------------------------
# CONTOUR MAKING: Switch methods
#----------------------------------------------------------------------------------------

#MAKER: computation method for new contour
def G6.contour_maker(pts, hcalc_options, local_options)
	hcalc_options = {} unless hcalc_options

	case hcalc_options[:method]
	when :fspline
		bz = G6::NurbsFSpline.compute(pts, hcalc_options, local_options)
	when :bspline	
		bz = G6::NurbsSpline.compute(pts, hcalc_options, local_options)
	else
		bz = pts.clone
	end
	bz
end
	
#----------------------------------------------------------------------------------------
# CLEANUP: methods to clean up contours
#----------------------------------------------------------------------------------------
	
#GENERIC: Clean up lonely vertices and possible collinear edges
def G6.contour_cleanup(lvx, entities)
	#Removing the lonely vertices
	loop = (lvx.first == lvx.last)
	lvx_res = []
	for i in 0..lvx.length-1
		vx = lvx[i]
		next unless vx.valid?
		lvx_res.push vx if !G6.remove_lonely_vertex(vx, entities)		
	end	
	lvx_res = lvx_res.find_all { |vx| vx.valid? }
	
	#Removing the possible collinear edges
	ledges = G6.edges_from_vertices_in_sequence(lvx_res)
	hedges = {}
	ledges.each { |e| hedges[e.entityID] = e if e.valid? }
	lvx_res.each do |vx|
		next if !vx.valid? || vx.edges.length < 3
		status = false
		vx.edges.each do |e|
			next if !e.valid? || hedges[e.entityID]
			status |= G6.remove_collinear_edge e
		end
		G6.remove_lonely_vertex(vx, entities) if status
	end
	
	#Returning the new list of vertices
	lvx_res = lvx_res.find_all { |vx| vx.valid? }
	lvx_res.push lvx_res.first if loop && lvx_res.first != lvx_res.last
	lvx_res
end

#Remove a lonely vertex
#returns True if removed, False otherwise
def G6.remove_lonely_vertex(vx, entities)
	return true unless vx.valid?
	edges = vx.edges
	if edges.length == 2 || edges.find { |e| e.length == 0 }
		ptx = vx.position
		vx0 = edges[0].other_vertex vx
		vx1 = edges[1].other_vertex vx
		vec0 = vx0.position.vector_to ptx
		vec1 = vx1.position.vector_to ptx
		return false unless vec0.valid? && vec1.valid? && vec0.parallel?(vec1)
		#return false unless vec0.valid? && vec1.valid? && (vec0 * vec1).valid?
		axes = vec0.axes
		ptend = ptx.offset axes[0], 0.01
		edge = entities.add_line ptx, ptend  
		edge.erase!
		return true
	end	
	false
end

#Remove a colinear edge
#returns True if removed, False otherwise
def G6.remove_collinear_edge(edge)
	return true unless edge.valid?
	return false unless edge.faces.length == 2
	face0, face1 = edge.faces
	if face0.normal.parallel?(face1.normal)
		edge.erase!
		return true
	end	
	false
end

#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
# Contour Error detection
#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------

#Error management for Edges
def G6.detect_error_in_edges(ledges, parent, ask=true)
	return ledges unless ledges && ledges.length > 0
	
	bad_edges = []
	hsh_vertices = {}
	ledges.each do |e|
		[e.start, e.end].each do |vx|
			unless hsh_vertices[vx.entityID]
				hsh_vertices[vx.entityID] = true
				G6.check_bad_edges_at_vertex(vx, bad_edges)
			end	
		end	
	end	
	
	#No bad edges found
	return ledges if bad_edges.empty?
	
	#Highlighting the areas
	Traductor::SUOperation.embedded_start_operation "fixing"
	
	entities = G6.grouponent_entities parent
	hsh_bad_edges = {}
	lcpoints = []
	bad_edges.each do |a|
		e1, e2, vx = a
		hsh_bad_edges[e1.entityID] = hsh_bad_edges[e2.entityID] = true
		lcpoints.push entities.add_cpoint(vx.position)
	end	
	
	#Asking for confirmation
	if ask
		msg = "#{T6[:T_ERROR_BadNeedleSpine1, bad_edges.length.to_s]}\n#{T6[:T_ERROR_BadNeedleSpine2]}"
		status = UI.messagebox(msg, MB_OKCANCEL)
	else
		status = 1
	end	
	lcpoints.each { |cpoint| cpoint.erase! }

	#Cancelling operation and return empty ledges
	if status != 1
		Traductor::SUOperation.embedded_forget_operation
		return []
	end	
	
	#Analyzing the bad edges
	removed_edges = []
	bad_edges.each do |a|
		e1, e2, vx = a
		next if removed_edges.include?(e1) || removed_edges.include?(e2)
		reason1, le1 = G6.prolong_bad_edge(e1, vx, hsh_bad_edges)
		reason2, le2 = G6.prolong_bad_edge(e2, vx, hsh_bad_edges)
		removed_edges += ((reason1 < reason2) || (reason1 == reason2 && le1.length < le2.length)) ? le1 : le2
	end

	#Removing the bad edges
	removed_edges.each do |e|
		next unless e.valid?
		e.erase!
	end	
	
	#Commiting the change
	Traductor::SUOperation.embedded_commit_operation
	
	#Returning the valid edges
	(ledges - removed_edges).find_all { |e| e.valid? }
end

#Check bad edges for needle eyes and spines
def G6.check_bad_edges_at_vertex(vx, bad_edges)
	ledges = vx.edges
	n = ledges.length - 1
	return [] if n < 1
	
	for i in 0..n
		e1 = ledges[i]
		for j in i+1..n
			e2 = ledges[j]
			vec1 = vx.position.vector_to e1.other_vertex(vx).position
			vec2 = vx.position.vector_to e2.other_vertex(vx).position
			angle = vec1.angle_between(vec2)
			if angle < 4.degrees
				bad_edges.push [e1, e2, vx]
			end	
		end
	end	
	bad_edges
end

def G6.prolong_bad_edge(edge, vx, hsh_bad_edges)
	n = 0
	ledges = [edge]
	reason = 10
	while n < 5
		vx_next = edge.other_vertex(vx)
		if vx_next.edges.length == 1
			reason = 0
			break
		elsif n >= 1 && hsh_bad_edges[edge.entityID]
			reason = 1
			break
		elsif vx_next.edges.length > 2
			reason = 5
			break
		end
		n += 1
		vx = vx_next
		edge = vx.edges.find { |e| e != edge }
		ledges.push edge
	end
	[reason, ledges]
end

end #Module G6
