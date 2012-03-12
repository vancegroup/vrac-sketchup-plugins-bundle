=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed November 2008 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   Lib6Algo.rb
# Original Date	:   15 Dec 2008 - version 3.0
# Type			:   Script library part of the LibFredo6 shared libraries
# Description	:   Implement some geometrical algorithms
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

#--------------------------------------------------------------------------------------------------------------
# Class ScaleBox: compute a bounding box for a given list of entities
#--------------------------------------------------------------------------------------------------------------			 				   

class ScaleBox

def initialize(lst_entities, normaldef=nil, vecdir=nil)
	#Initialization
	@lst_entities = []
	lst_entities.each { |e| @lst_entities.push e }
	@tr_identity = Geom::Transformation.new
	@precision = 0.000001
	@vec_dir = nil
	@hsh_vertices = {}	
	@hsh_edges = {}	
	@hsh_entities = {}	
	@hsh_entID = {}	
	
	#Computing the initial best-fitting box
	bbox = compute_initial_bbox normaldef, vecdir
end

#Methods to get information about the scaling box
def get_bbox ; @bbox ; end
def get_hsh_entities ; @hsh_entities ; end
def get_hsh_entID ; @hsh_entID ; end
def get_hsh_vertices ; @hsh_vertices ; end
def get_hsh_edges ;	@hsh_edges ; end
def get_wireframe ;	@lst_wireframe ; end
def get_entities ; @lst_entities ; end
def get_ini_normal ; @normal_ini ; end
def get_ini_vecdir ; @vecdir_ini ; end

#Compute the initial (best-fitting) bounding box for the given selection
#Return the Bounding box as a set of 3D points 
# in 1D: just 2 points
# in 2D: 4 points defining a rectangle anti-clockwise order
# in 3D: 8 points defining the lower rectangle (0..3) and upper rectangle (4..7), anti-clockwise order
def compute_initial_bbox(normaldef=nil, vecdir=nil)

	#Check if the bounding box is a Line, a Plane or a 3D Box
	@bbox = nil
	@dim = 0
	@line0 = nil
	@plane0 = nil
	@lst_wireframe = []
	@hsh_wf_edges = {}
	check_fit_dimension @lst_entities, @tr_identity
	
	return nil if @dim == 0
	
	#Collect all vertex points from the selection
	@pt_collection = collect_all_points @lst_entities, @tr_identity, [], nil
	
	#Compute the right box according to the dimension
	case @dim
	when 1
		@bbox = compute_box_1
	when 2
		@normal_ini = @plane0[1]
		@vecdir_ini = vecdir
		@bbox = recompute_box @normal_ini, @vecdir_ini
	when 3
		@normal_ini = ((normaldef) ? normaldef : Z_AXIS)
		@vecdir_ini = vecdir
		@bbox = recompute_box @normal_ini, @vecdir_ini
	end	
	
	return @bbox
end
	
#Check if the list of entities fit in dimension 1 (line), 2 (plane) or 3 (volume)
def check_fit_dimension(lst_entities, t)
	lst_cpoint = []
	lst_entities.each do |e|
		
		# Construction Point
		if e.class == Sketchup::ConstructionPoint
			if @plane0
				@dim = 3 unless e.position.on_plane? @plane0
			elsif @line0
				unless e.position.on_line? @line0
					@dim = 2
					@plane0 = [e.position, @line0[1] * e.position.vector_to(@line0[0])]
				end	
			elsif lst_cpoint.length == 0
				lst_cpoint.push e.position
			elsif lst_cpoint.length > 0 && e.position == lst_cpoint[0]
				next
			else
				@dim = 1
				@line0 = [lst_cpoint[0], lst_cpoint[0].vector_to(e.position)]
			end
			
		# Edge
		elsif e.class == Sketchup::Edge
			pt1 = t * e.start.position
			pt2 = t * e.end.position
			if @dim <= 1
				@dim = 1
				vec = pt1.vector_to pt2
				eline = [pt1, pt2]
				if @line0
					unless pt1.on_line?(@line0) && pt2.on_line?(@line0)
						@dim = 2
						if @line0[1].parallel?(vec)
							@plane0 = [@line0[0], @line0[0].vector_to(pt1) * @line0[1]]
						else
							@plane0 = [@line0[0], vec * @line0[1]]
						end
					end	
				else
					@line0 = [pt1, vec]
				end	
			elsif @dim == 2	
				@dim = 3 unless pt1.on_plane?(@plane0) && pt2.on_plane?(@plane0)
			end	
			
		# Face
		elsif e.class == Sketchup::Face
			@dim = 2
			eplane = [t * e.vertices[0].position, t * e.normal]
			if @plane0
				@dim = 3 unless eplane[0].on_plane?(@plane0) && eplane[1].parallel?(@plane0[1])
			else
				@plane0 = eplane
			end	
			
		#Group and Component Instance	
		elsif e.class == Sketchup::Group || e.class == Sketchup::ComponentInstance
			eg = (e.class == Sketchup::Group) ? e : e.definition
			check_fit_dimension eg.entities, t * e.transformation	
		end
		
		#Exit if 3D
		return @dim if @dim >= 3
	end	
	return @dim
end

#Compute the oriented distance from a point <origin> along a vector <vec>
def oriented_distance(origin, vec, pt)
	return 0 if origin == pt
	origin.distance(pt) * ((origin.vector_to(pt) % vec < 0) ? -1 : +1)
end

#Compute a box of dimension 1 (actually only 2 points)
def compute_box_1
	origin = @line0[0]
	vec = @line0[1]
	lstpt = @pt_collection.collect { |pt| [pt, oriented_distance(origin, vec, pt)] }
	lstpt.sort! { |lp1, lp2| lp1[1] <=> lp2[1] }
	return [lstpt.first[0], lstpt.last[0]]
end

#Recompute the box when either the plane or the vector has changed
def recompute_box(normal, vecdir=nil)
	#Setting the plane if not already done
	set_plane normal if normal
	bbox = nil
	
	#Forcing a particular direction for the rectangle
	@vec_dir = vecdir if vecdir
	if @vec_dir && @vec_dir.valid?
		vecproj = nil
		vecproj = @tr_direct * @vec_dir
		if vecproj
			vecproj.z = 0
			bbox = brect_along_vector(@hull, vecproj)[1] if vecproj.valid?
		end
	end	
	
	#Calculating the best bounding rectangle for the convex hull
	unless bbox
		bbox = brect_compute @hull
	end
	
	#Giving height to the box in 3D
	if @dim > 2
		bbox = bbox.collect { |pt| Geom::Point3d.new(pt.x, pt.y, @zmin) } + 
			   bbox.collect { |pt| Geom::Point3d.new(pt.x, pt.y, @zmax) }
	else
		bbox = bbox.collect { |pt| Geom::Point3d.new(pt.x, pt.y, @zmin) } 
	end	
		
	#Restoring in original coordinates
	@bbox = bbox.collect { |pt| @tr_back * pt }
	
	return @bbox
end

#Set a Plane for computing the fitting box - Compute the convex hull of the projections of the point collection
def set_plane(normal)
	@plane_normal = normal
	
	#Changing axes to have the Plane become the XY plane
	angle = X_AXIS.angle_between(normal).modulo(Math::PI)
	if angle > 45.degrees
		pt0 = Geom::Point3d.new 1, 0, 0
		pt0 = pt0.project_to_plane [ORIGIN, normal]
		xvec = ORIGIN.vector_to pt0
		yvec = normal * xvec
	else
		pt0 = Geom::Point3d.new 0, 1, 0
		pt0 = pt0.project_to_plane [ORIGIN, normal]
		yvec = ORIGIN.vector_to pt0
		xvec = normal * yvec
	end	
	@tr_back = Geom::Transformation.axes ORIGIN, xvec, yvec, normal
	@tr_direct = @tr_back.inverse
	lstpt = @pt_collection.collect { |pt| @tr_direct * pt }
	
	#Calculate the projections on the plane XY
	lstproj = lstpt.collect { |pt| Geom::Point3d.new(pt.x, pt.y, 0.0) }
	
	#Calculating the Convex Hull
	@hull = convex_hull_2D_compute lstproj
	
	#Calculate the lowest and highest Z coordinates
	if (@dim > 2)
		@zmin = @zmax = nil
		lstpt.each do |pt|
			z = pt.z
			@zmin = z unless @zmin && z > @zmin
			@zmax = z unless @zmax && z < @zmax
		end	
	else
		@zmin = @zmax = lstpt[0].z
	end
end

#Collect all vertices from the selection
def collect_all_points(lst_entities, t, lstpt, entid)
	lst_entities.each do |e|
		if e.class == Sketchup::Edge
			push_unique_vertex lstpt, t, e.start, entid
			push_unique_vertex lstpt, t, e.end, entid			
			@hsh_entities[e.entityID] = true unless entid
			@hsh_entID[e.entityID] = true
			@hsh_entID[e.start.entityID] = true
			@hsh_entID[e.end.entityID] = true
			collect_wireframe_edge e, t
		elsif e.class == Sketchup::Face
			e.outer_loop.vertices.each { |v| push_unique_vertex lstpt, t, v, entid }
			@hsh_entID[e.entityID] = true
			e.edges.each { |edge| collect_wireframe_edge edge, t }
		elsif e.class == Sketchup::ConstructionPoint
			push_unique_vertex lstpt, t, e, entid
		elsif e.class == Sketchup::Group || e.class == Sketchup::ComponentInstance
			eg = (e.class == Sketchup::Group) ? e : e.definition
			id = e.entityID
			@hsh_entities[id] = true unless entid
			collect_all_points eg.entities, t * e.transformation, lstpt, id
		end
	end	
	lstpt
end

#Collect the absolutae coordinates of an edge for building a wireframe
def collect_wireframe_edge(edge, t)
	@hsh_wf_edges[edge.to_s] = true
	@lst_wireframe.push t * edge.start.position, t * edge.end.position
end

#Push a vertex to the list of points if not already stored
def push_unique_vertex(lpt, t, v, entid)
	ptpos = t * v.position
	id = v.entityID
	p = @hsh_vertices[id]
	return if p && p == ptpos
	@hsh_vertices[id] = ptpos
	@hsh_entities[id] = true unless entid
	lpt.push ptpos
end

#Compute a fitting rectangle for the given hull
def brect_compute(hull)
	#Degenerated case with less than 3 points
	n = hull.length - 2
	return hull unless n > 0
	
	#Loop of each segment and calculate the rectangle, and check if it has the minimum area
	normal = Z_AXIS
	lst_vec = []
	lst_area = []
	for i in 0..n
		origin = hull[i]
		vec1 = origin.vector_to(hull[i+1]).normalize
		
		#Avoid treating the same directions several times - This is a simple optimization
		next unless vec1.valid? && !vector_colinear?(vec1, lst_vec)
		lst_vec.push vec1
		
		#Computing the rectangle along the direction
		lst_area.push brect_along_vector(hull, vec1)
	end
	
	#Sorting the results by area
	lst_area.sort! { |la1, la2| la1[0] <=> la2[0] }
	
	#Looking for the list of smallest areas
	lst_smallest = []
	areamin = lst_area[0][0]
	lst_area.each do |la|
		break unless close_to(la[0], areamin)
		lst_smallest.push la
	end
	nbsmall = lst_smallest.length
		
	#Only one smallest area - We just return the bounding rectangle
	return lst_smallest[0][1] if nbsmall == 1
		
	#Check for symetry
	if nbsmall == 2
		return lst_smallest[0][1] if is_square(lst_smallest[0][1])
		vsum = lst_smallest[0][2] + lst_smallest[1][2]
		vsum = lst_smallest[0][2] unless vsum.valid?
		return brect_along_vector(hull, vsum)[1]
	end	
	
	#Check if one of the vector is parallel to an Axis
	lst_angleX = lst_smallest.collect { |la| [la, la[2].angle_between(X_AXIS)] }
	lst_angleX.sort! { |a, b| a[1] <=> b[1] }
	if lst_angleX[0][1] <= 1.degrees
		return brect_along_vector(hull, X_AXIS)[1]
	end
	lst_angleY = lst_smallest.collect { |la| [la, la[2].angle_between(Y_AXIS)] }
	lst_angleY.sort! { |a, b| a[1] <=> b[1] }
	if lst_angleY[0][1] <= 1.degrees
		return brect_along_vector(hull, Y_AXIS)[1]
	end

	#Return the Bounding box
	return (lst_angleY[0][1] > lst_angleX[0][1]) ? lst_angleX[0][0][1] : lst_angleY[0][0][1]
end

#Check if the 4 points define a square
def is_square(lpt)
	lpt[0].distance(lpt[1]) == lpt[1].distance(lpt[2])
end

#Compute the fitting rectangle with one side being colinear to <vec1>
def brect_along_vector(hull, vec1)
	#Computing the projections along the vector and its perpendicular in the plane
	origin = ORIGIN
	normal = Z_AXIS
	vec2 = normal * vec1
	lst1, lst2 = [], []
	hull.each do |pt|
		ptproj1 = pt.project_to_line [origin, vec1]
		lst1.push [ptproj1, oriented_distance(origin, vec1, ptproj1)]
		ptproj2 = pt.project_to_line [origin, vec2]
		lst2.push [ptproj2, oriented_distance(origin, vec2, ptproj2)]
	end
	
	#Sort the projections by oriented distance and keep only first and last
	lst1.sort! { |lp1, lp2| lp1[1] <=> lp2[1] } 
	lst2.sort! { |lp1, lp2| lp1[1] <=> lp2[1] } 
	bb = [lst1.first[0], lst1.last[0], lst2.first[0], lst2.last[0]]

	#Compute the Bounding box
	bb1 = Geom.intersect_line_line [bb[0], vec2], [bb[2], vec1]
	bb2 = Geom.intersect_line_line [bb[0], vec2], [bb[3], vec1]
	bb3 = Geom.intersect_line_line [bb[1], vec2], [bb[3], vec1]
	bb4 = Geom.intersect_line_line [bb[1], vec2], [bb[2], vec1]
		
	#Compute the area
	area = bb1.distance(bb2) * bb3.distance(bb4)
	return [area, [bb1, bb2, bb3, bb4], vec1]
end

#Compute the Convex Hull of a given set of points located on a plane
#Method based on Graham Scan with Akl-Toussaint Heuristics
def convex_hull_2D_compute(lsptxy)
	return lstpxy if lsptxy.length < 3
	lsptxy = convex_hull_2D_heuristic lsptxy
	return convex_hull_2d_graham_scan(lsptxy[0], lsptxy[1..-1])
end

#Implement the Akl-Toussint heuristics to eliminate points outside a computed octogonal convex hull
def convex_hull_2D_heuristic(lsptxy)
	#Finding the outer octogon
	pt_xmin = pt_xmax = pt_ymin = pt_ymax = lsptxy[0]
	pt_xysmin = pt_xysmax = pt_xydmin = pt_xydmax = lsptxy[0]
	xmin = xmax = pt_xmin.x
	ymin = ymax = pt_xmin.y
	xysmin = xysmax = pt_xmin.x + pt_xmin.y
	xydmin = xydmax = pt_xmin.x - pt_xmin.y
	lsptxy.each do |pt|
		x = pt.x
		y = pt.y
		sum = x + y	
		dif = x - y		
		if x < xmin || (x == xmin && y < pt_xmin.y)
			pt_xmin = pt
			xmin = x
		end	
		if x > xmax || (x == xmax && y > pt_xmax.y)
			pt_xmax = pt
			xmax = x
		end	
		if y < ymin || (y == ymin && x < pt_ymin.x)
			pt_ymin = pt
			ymin = y
		end	
		if y > ymax || (y == ymax && x > pt_ymax.x)
			pt_ymax = pt
			ymax = y
		end
		if sum < xysmin
			pt_xysmin = pt
			xysmin = sum
		end	
		if sum > xysmax
			pt_xysmax = pt
			xysmax = sum
		end	
		if dif < xydmin
			pt_xydmin = pt
			xydmin = dif
		end	
		if dif > xydmax
			pt_xydmax = pt
			xydmax = dif
		end	
	end
	poly2d = [pt_ymin, pt_ymax, pt_xmin, pt_xmax, pt_xysmin, pt_xysmax, pt_xydmin, pt_xydmax].uniq
	
	#Filtering all points which are stricly inside the polygon
	if poly2d.length > 2
		polygon = convex_hull_2d_graham_scan pt_ymin, poly2d[1..-1]
		lsptxy.delete_if { |pt| Geom.point_in_polygon_2D pt, polygon, false } if polygon.length > 2
	end	
	
	#Computing the total convex hull
	return [pt_ymin] + lsptxy
end

#Construct the convex hull using the Graham Scan method
def convex_hull_2d_graham_scan(pivot, lstpt)
	#Remove duplicates and Sort points by the angle formed by the line [Pivot, pt] with the X axis
	lpt = []
	lstpt.each { |pt| lpt.push pt unless pt == pivot }
	lpt.collect! { |pt| [pt, pivot.vector_to(pt).angle_between(X_AXIS)] }
	lpt.sort! { |a1, a2| a1[1] <=> a2[1] }
	
	#Construct the path progressively
	lpt.collect! { |a| a[0] }
	hull = [pivot, lpt[0]]
	n = lpt.length - 1
	for i in 1..n
		####while hull.length >= 2 && (hull[-2].vector_to(hull[-1]) * hull[-1].vector_to(lpt[i])) % Z_AXIS <= 0
		while hull.length >= 2 && (hull[-2].vector_to(hull[-1]) * hull[-1].vector_to(lpt[i])) % Z_AXIS < 0
			hull[-1..-1] = []
		end	
		hull.push lpt[i] unless hull.last == lpt[i]
	end
	hull.push pivot unless hull.last == hull.first	
	return hull
end		

#Check if a vector is in a remarkable direction, to be privilegded in case min areas are equal
def vector_colinear?(vec, lst_vec)
	lst_vec.each { |v| return true if vec.parallel? v }
	false
end

def close_to(a, b)
	((a - b).abs - a.abs * @precision) <= 0
end

end	#class ScaleBox

#--------------------------------------------------------------------------------------------------------------
# 2D Best fit bounding Box (in the horizontal plane)
#--------------------------------------------------------------------------------------------------------------			 				   

class BestFit2d

def BestFit2d.best_fitting_box(normal, pts, vec_align=nil)
	#Getting the list of boxes
	smallest = BestFit2d.best_fitting_boxes normal, pts
	
	#Pickng the aligned box to vec_align if there are several smallest bounding boxes
	if smallest.length > 1 && vec_align
		vec_align = vec_align.normalize
		vnorm = vec_align * Z_AXIS
		smallest.sort! { |boxA, boxB| compare_box_alignment vec_align, vnorm, boxA, boxB }
	end
	
	smallest[0]
end

#Compute the best-fitting bounding box for a 2D curve
def BestFit2d.best_fitting_boxes(normal, pts, keep_all=false)
	lst_vec = []
	lst_areas = []
	normal = normal.normalize
	pts = pts + [pts.first] unless pts.last == pts.first
	n = pts.length
	for i in 0..n-2
		origin = pts[i]
		vec1 = origin.vector_to(pts[i+1]).normalize
		next unless vec1.valid?
		vec2 = normal * vec1
		puts "vec1 not valid" unless vec1.valid?
		puts "vec2 not valid" unless vec2.valid?
		
		#Avoid treating the same directions several times - This is a simple optimization
		next if vector_colinear?(vec1, lst_vec)
		lst_vec.push vec1
		unless keep_all
			next if vector_colinear?(vec2, lst_vec)
			lst_vec.push vec2
		end
		
		#Compute the projection of all face vertices on the edge vector and its perpendicular in the face plane
		lst1, lst2 = [], []
		pts.each do |pt|
			lst1.push projection(origin, vec1, pt) if pt && vec1.valid?
			lst2.push projection(origin, vec2, pt) if pt && vec2.valid?
		end
		#next if lst1.length < 2 || lst2.empty?
		
		#Sort the projections by oriented distance and keep only first and last
		lst1.sort! { |lp1, lp2| lp1[1] <=> lp2[1] } 
		lst2.sort! { |lp1, lp2| lp1[1] <=> lp2[1] } 
		bb = [lst1.first[0], lst1.last[0], lst2.first[0], lst2.last[0]]
		area = bb[0].distance(bb[1]) * bb[2].distance(bb[3])

		#Compute the Bounding box
		bb1 = Geom.intersect_line_line [bb[0], vec2], [bb[2], vec1]
		bb2 = Geom.intersect_line_line [bb[0], vec2], [bb[3], vec1]
		bb3 = Geom.intersect_line_line [bb[1], vec2], [bb[3], vec1]
		bb4 = Geom.intersect_line_line [bb[1], vec2], [bb[2], vec1]
		
		#Only keep the minimum area
		lst_areas.push [area, [bb1, bb2, bb3, bb4]]
	end
	
	#Computing the minimum area
	lst_areas.sort! { |a, b| a[0] <=> b[0] }
	
	#Identifying the smallest area
	smallest = []
	area = lst_areas[0][0]
	lst_areas.each do |ls|
		break if ((ls[0] - area) / area).abs > 0.001
		smallest.push ls[1]
	end
	
	#Return the Bounding box
	return smallest
end

# Compute the projection of a point on a line and the oriented distance - Return [ptproj, oriented_distance]
def self.projection(origin, vec, pt)
	begin
		ptproj = pt.project_to_line [origin, vec]
		return [ptproj, origin.distance(ptproj) * (((origin.vector_to(ptproj) % vec) < 0) ? -1 : 1)]
	rescue
		puts "Rescue PROJ origin = #{origin} vec = #{vec.valid?} pt = #{pt}"
	end	
end

#Check if a vector is in a remarkable direction, to be privilegded in case min areas are equal
def self.vector_colinear?(vec, lst_vec)
	lst_vec.each { |v| return true if vec.parallel? v }
	false
end

def self.compare_box_alignment(vec_align, vnorm, box1, box2)
	lvec = []
	lvec[0] = [0, box1[0].vector_to(box1[1]).normalize]
	lvec[1] = [0, box1[0].vector_to(box1[3]).normalize]
	lvec[2] = [1, box2[0].vector_to(box2[1]).normalize]
	lvec[3] = [1, box2[0].vector_to(box2[3]).normalize]
	lvec.sort! do |a, b| 
		psa = a[1] % vnorm
		psb = b[1] % vnorm
		((psa.abs - psb.abs).abs < 0.001) ? (a[1] % vec_align) * psa <=> (b[1] % vec_align) * psb : psa.abs <=> psb.abs
	end	
	(lvec.first[0] == 0) ? -1 : 1
end

end	#class BestFit2d

#========================================================================================
#========================================================================================
# Class SelectionProcessor
#========================================================================================
#========================================================================================

class SelectionProcessor

PseudoElt = Struct.new :key, :su_obj, :tr, :data, :pelt_parent, :name, :childrens, :layers

def initialize(selection, *hoptions)
	@model = Sketchup.active_model
	selection = @model.selection unless selection
	entities = (selection == nil || selection.empty?) ? @model.active_entities : selection
	t = Geom::Transformation.new
	
	hoptions.each { |hoption| parse_options(hoption) }
	
	@hsh_pelt = {}
	@nb_groups = 0

	top = @model
	@top_name = Traductor.text_model_or_selection
	if entities.length == 1
		ss0 = entities[0]
		if ss0.instance_of?(Sketchup::ComponentInstance) || ss0.instance_of?(Sketchup::Group)
			top = ss0
			entities = (ss0.instance_of?(Sketchup::ComponentInstance)) ? ss0.definition.entities : ss0.entities
			t = ss0.transformation
			@top_name = container_name ss0
		end	
	end	
	process_selection nil, entities, top, t, [top.layer]
end

#Parse the options for the instance
def parse_options(hoption)
	hoption.each do |key, value|
		skey = key.to_s
		case skey
		when /entity_proc/i
			@entity_proc = value
		when /pelt_init_proc/i
			@pelt_init_proc = value
		end	
	end		
end

#Return the top element of the hierarchy
def top_pelt
	@top_pelt
end
	
#Recursive processing of the selection	
def process_selection(pelt_parent, entities, comp, t, layers)	
	#progress_status_bar
	pelt = create_pseudo_element pelt_parent, comp, t, layers
	entities.each do |e|
		@entity_proc.call false, pelt, e if @entity_proc
		if e.instance_of?(Sketchup::Group)
			process_selection(pelt, e.entities, e, t * e.transformation, layers + [e.layer])
		elsif e.instance_of?(Sketchup::ComponentInstance)
			process_selection(pelt, e.definition.entities, e, t * e.transformation, layers + [e.layer])
		end			
		@entity_proc.call true, pelt, e if @entity_proc
	end
end

#Create a Pseudo element
def create_pseudo_element(pelt_parent, su_obj, t, layers)
	su_obj = @model unless su_obj
	key = su_obj.entityID.to_s
	pelt = PseudoElt.new
	@top_pelt = pelt unless pelt_parent
	@hsh_pelt[key] = pelt
	
	pelt.key = key
	pelt.su_obj = su_obj
	pelt.tr = t
	pelt.childrens = []
	pelt.layers = layers.uniq
	pelt.pelt_parent = pelt_parent
	pelt_parent.childrens.push pelt if pelt_parent
	
	#Assigning a name to the instance or group
	if pelt_parent == nil
		pelt.name = @top_name
	else
		pelt.name = container_name(su_obj)
	end	
	
	@pelt_init_proc.call pelt if @pelt_init_proc
	
	pelt
end

#Find the name of a component instance or group
def container_name(su_obj)
	name = ""
	if su_obj.class == Sketchup::ComponentInstance
		cdef = su_obj.definition
		if (su_obj.name.empty?)
			imax = cdef.instances.length.to_s.length
			i = cdef.instances.rindex(su_obj)+1
			inst_name = '#' + sprintf("%0#{imax}d", i+1)
		else
			inst_name = su_obj.name
		end
		name = su_obj.definition.name + " [#{inst_name}]"
	elsif su_obj.class == Sketchup::Group
		@nb_groups += 1
		name = (su_obj.name.empty?) ? "Group ##{@nb_groups}" : su_obj.name
	else
		name = su_obj.name if defined?(su_obj.name)
	end
	name
end

#Get the Component Instances
def get_component_instances
	lst = @hsh_pelt.values.find_all { |pelt| pelt.su_obj.instance_of?(Sketchup::ComponentInstance) } 
end

#Return the list of groups
def get_groups
	lst = @hsh_pelt.values.find_all { |pelt| pelt.su_obj.instance_of?(Sketchup::Group) } 
end
	
#Apply a proc by traversing the hierarchy Bottom-up
def apply_bottom_up(proc, pelt=nil)
	pelt = @top_pelt unless pelt
	pelt.childrens.each { |pp| apply_bottom_up proc, pp }
	proc.call pelt
end
	
#Apply a proc by traversing the hierarchy Top Down
def apply_top_down(proc, pelt=nil)
	pelt = @top_pelt unless pelt
	proc.call pelt
	pelt.childrens.each { |pp| apply_top_down proc, pp }
end
	
#Apply a proc by traversing the hierarchy Top Down
def apply(proc, pelt=nil)
	pelt = @top_pelt unless pelt
	proc.call false, pelt
	pelt.childrens.each { |pp| apply proc, pp }
	proc.call true, pelt
end
	
end	#SelectionProcessor

end	#End Module Traductor
