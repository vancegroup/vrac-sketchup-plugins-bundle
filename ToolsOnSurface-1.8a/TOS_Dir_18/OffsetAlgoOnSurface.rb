=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed April / July 2008 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   OffsetOnSurface.rb
# Original Date	:   10 April 2008 - version 1.0
# Revisions		:	14 May 2008 - version 1.1
#						- added tool for generating Construction lines
#						- handle overlap of contours
#						- revisit simplification of contour
#						- default setting in separate file
#						- options added : simplify, marks as Cpoint
#						- Programming API
#						- bug fixing
#					04 Jun 2008 - version 1.2
#					11 Jul 2008 - version 1.3
# Type			:   Sketchup Tool
# Description	:   Offset a contour on a surface (inside and outside)
-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module SUToolsOnSurface

#Strings (do not translate here)			 
T6[:ERROR_InvalidSelection] = "NO Contour for the selection"
T6[:ERROR_ComplexSelection] = "Selection too complex for offset operation"

#--------------------------------------------------------------------------------------------------------------
# Class OffsetAlgo: Offset algorithm 
#--------------------------------------------------------------------------------------------------------------			 
class OffsetAlgo

attr_reader :noselection, :hsh_faces, :lst_edges, :hsh_edges

def initialize(linemode)
    @model = Sketchup.active_model
    @view = @model.active_view
	@entities = @model.active_entities
	@selection = @model.selection
	@linemode = linemode
	@dsnap = OFSG.dsnap
	@lst_impfaces = []
	@ofsstore = SelectionStore.create
	
	@msg_invalid_selection = T6[:ERROR_InvalidSelection]
	@msg_complex_selection = T6[:ERROR_ComplexSelection]
	
	reset	
end

#Reset all variables for the class OFS
def reset
	@hsh_faces = {}
	@hsh_edges = {}
	@lst_edges = []
	@lst_all_edges = []
	@lst_main_edges = []
	@hsh_selected_edges = {}
	@hsh_selected_faces = {}
	@hsh_vertices = {}
	@too_complex = false
	@all_loops = []
	@lst_main_edges = []
	@lst_inner_edges = []
	@lst_outer_edges = []
	@main_loops = []
	@inner_loops = []
	@outer_loops = []
end

def api_call(selection, distance, group, alone, genfaces, gencurve, simplify, cpoint)
	#Transfering options
	@group = (group) ? @entities_add_group : nil
	@option_alone = alone
	@option_cpoint = cpoint
	@option_nofaces = !genfaces
	@option_nocurves = !gencurve
	@option_nosimplify = !simplify
	
	#Generating the offset contour
	execute distance
	return 0
end

def set_option_linemode(linemode)
	@linemode = linemode
end

def set_group(group)
	@group = group
end

def set_option_alone(alone)
	@option_alone = alone
end

def set_option_cpoint(cpoint)
	@option_cpoint = cpoint
end

def set_option_nofaces(nofaces)
	@option_nofaces = nofaces
end

def set_option_nocurves(nocurves)
	@option_nocurves = nocurves
end
	
def set_option_nosimplify(nosimplify)
	@option_nosimplify = nosimplify
end
	
def set_option_contours(contours)
	@option_contours = contours
	compute_active_loops if @all_loops.length > 0
end
		
#Check the selection at entry of the tool if any	
def check_initial_selection(flgmsg, selection=nil)
	#checking if the selection contains faces
	reset
	selection = @selection unless selection
	selection.each do |e|
		if e.class == Sketchup::Face
			@hsh_selected_faces[e.to_s] = e 
		elsif e.class == Sketchup::Edge
			@hsh_selected_edges[e.to_s] = e if e.faces.length > 0
		end
	end	
	
	#Evaluating the selection for edges and faces
	unless inspect_selected_edges
		reset
		if (flgmsg)
			UI.messagebox @msg_complex_selection
		end	
		return OFS_ERROR_COMPLEX_SELECTION	
	end
	
	return OFS_ERROR_NO_SELECTION if (@hsh_faces.length == 0) 	#no face selected
	
	#calculating the contour
	if (@hsh_edges.length == 0)
		reset
		if (flgmsg)
			UI.messagebox @msg_invalid_selection
		end	
		return OFS_ERROR_INVALID_SELECTION
	end	
	construct_contour_loops

	#Selection is OK
	return 0
end

#Inspect the edges that are selected to check if they define a proper selection
def inspect_selected_edges
	unless @hsh_selected_edges.length > 0
		@hsh_selected_faces.each { |key, f| @hsh_faces[f.to_s] = f }
		return calculate_edges
	end
	
	lstedges = []
	@hsh_selected_edges.each do |key, e|
		lfaces = e.faces
		if (lfaces.length == 1)
			@hsh_faces[lfaces[0].to_s] = lfaces[0]
			lstedges.push e
			next
		end	
		n = 0
		face = nil
		lfaces.each do |f|
			if @hsh_selected_faces[f.to_s]
				n += 1
				face = f
			end
		end
		if n == 1	
			@hsh_faces[face.to_s] = face
			lstedges.push e
		end	
	end
	
	#rechecking edges for complex topology
	lstedges.each do |e|
		face = nil
		n = 0
		e.faces.each do |f|
			if @hsh_faces[f.to_s]
				n += 1
				face = f
			end
		end		
		store_edge_data(e, face) if n == 1	
	end
	
	#Calculating extra properties at vertices - Reject operation if too complex
	return false if @too_complex
	@hsh_vertices.each { |key, vd| properties_at_vertex vd }
	true
end

#Define a selection starting from a face with all connected faces that share a Soft edge
def virtual_selection(face, add=false)
	return true if @hsh_faces && @hsh_faces[face.to_s]
	reset
	if (add)
		@lst_impfaces.push face unless @lst_impfaces.include?(face)
	else
		@lst_impfaces = [face]
	end	
	@lst_impfaces.each { |f| face_neighbours f }
	unless calculate_edges
		reset
		return false
	end	
	construct_contour_loops
	(@hsh_faces.length > 0) && (@hsh_edges.length > 0)
end

#Determine all connected faces to the face (i.e. if bording edge is soft or hidden)
#note: the recursive version seems to bugsplat on big number of faces. So I use an iterative version
def face_neighbours(face)
	lface = [face]
	
	while true
		break if lface.length == 0
		f = lface[0]
		if @hsh_faces[f.to_s]
			lface[0..0] = []
			next
		end	
		lface[0..0] = []
		@hsh_faces[f.to_s] = f
		f.edges.each do |e|
			if e.hidden? || e.soft?
				e.faces.each do |ff| 
					lface.push ff unless ff == f || @hsh_faces[ff.to_s]
				end	
			end	
		end
	end	
end

#Calculate the contour of the surface (i.e. edges with only one face)
def calculate_edges
	@hsh_faces.each do |key, face|
		face.edges.each do |e|
			n = 0
			e.faces.each { |f| n += 1 if @hsh_faces[f.to_s] }
			next unless (n == 1)		#edge shares more than one selected face
			
			#Storing the edges
			store_edge_data(e, face)
			return false if @too_complex
		end
	end	
	@hsh_vertices.each { |key, vd| properties_at_vertex vd }
	return true
end

def store_edge_data(e, face)
	@lst_all_edges.push e
	ed = OFS_EdgeData.new
	@hsh_edges[e.to_s] = ed
	ed.edge = e
	ed.face_in = face
	ed.face_out = nil
	ed.normal_in = OFSG.normal_ex_to_edge(e, face)
	ed.normal_out = ed.normal_in.reverse
	ed.normal_out = ed.normal_in.reverse
	e.faces.each do |f|
		if f != face
			ed.face_out = f
			ed.normal_out = OFSG.normal_ex_to_edge e, f
			break
		end
	end	
	ed.pt1 = e.start.position
	ed.pt2 = e.end.position
	ed.curved = false
	ed.looped = false
	
	#Storing the vertex data
	rev = (ed.edge.reversed_in? ed.face_in) ? true : false
	rev = false
	if rev
		ed.pt1 = e.end.position
		ed.pt2 = e.start.position
		ed.vd_start = store_vertex_data(e.end, ed)
		ed.vd_end = store_vertex_data(e.start, ed)		
	else
		ed.pt1 = e.start.position
		ed.pt2 = e.end.position
		ed.vd_start = store_vertex_data(e.start, ed)
		ed.vd_end = store_vertex_data(e.end, ed)
	end	
end

def store_vertex_data(v, ed)
	vd = @hsh_vertices[v.to_s]
	unless vd
		vd = OFS_VertexData.new
		vd.vxs_in = OFS_VexSubData.new
		vd.vxs_out = OFS_VexSubData.new
		vd.vertex = v
		vd.origin = v.position
		vd.lstedges = []
		vd.newpt = nil
		vd.mark = nil
		vd.next_in_loop = nil
		vd.reversed = false
		vd.validity = true
		vd.touched = false
		@hsh_vertices[v.to_s] = vd
	end	
	vd.lstedges.push ed
	@too_complex = true if vd.lstedges.length > 2		#complex vertex
	vd
end

#Compute and store extra properties at vertex linking 2 edges
def properties_at_vertex(vd)		
	vxs_in = vd.vxs_in
	vxs_out = vd.vxs_out
	v = vd.vertex
	origin = vd.origin

	ed1 = vd.lstedges[0]
	face1 = ed1.face_in
	
	#termination vertex
	if (vd.lstedges.length == 1)
		ed1 = vd.lstedges[0]
		vxs_in.vec = ed1.normal_in
		vxs_out.vec = ed1.normal_out
		vnorm = ed1.face_in.normal
		vxs_in.vplane = [origin, vxs_in.vec * vnorm]
		vnorm = ed1.face_out.normal if ed1.face_out
		vd.trueborder = (ed1.face_out) ? false : true
		vxs_out.vplane = [origin, vxs_out.vec * vnorm]
		vd.colinear = false
		vd.cos_angle = 0.0
		vxs_in.dfactor = 1.0
		vxs_out.dfactor = 1.0
		vxs_in.same_plane = true
		vxs_out.same_plane = true
		edge1 = ed1.edge
		mark = OFSG.mark(origin, face1, vd.vertex, edge1, vd)
		vxs_in.camino = Camino.new(vxs_in.vplane, mark, vxs_in.vec.reverse)
		mark = OFSG.mark(origin, face1, vd.vertex, edge1, vd)
		vxs_out.camino = Camino.new(vxs_out.vplane, mark, vxs_in.vec)
		return
	end	
	
	#vertex with 2 edges
	ed1 = vd.lstedges[0]
	ed2 = vd.lstedges[1]

	#Computing parameters for Inside
	vec1 = ed1.normal_in
	vec2 = ed2.normal_in	
	vxs_in.vec = Geom.linear_combination 0.5, vec1, 0.5, vec2
	face1 = ed1.face_in
	face2 = ed2.face_in
	vxs_in.same_plane = face1.normal.parallel?(face2.normal)
	vnorm = OFSG.average_normal(face1, face2)
	vxs_in.vplane = [origin, vxs_in.vec * vnorm]
	angle = vxs_in.vec.angle_between vec1
	angle1 = vxs_in.vec.angle_between vec1
	angle2 = vxs_in.vec.angle_between vec2
	cosinus = (Math::cos(angle1) + Math::cos(angle2)) * 0.5
	vxs_in.dfactor = (cosinus.abs < 0.05) ? 1.0 : 1.0 / cosinus

	#Computing parameters for outside
	vec1 = ed1.normal_out
	vec2 = ed2.normal_out	
	vxs_out.vec = OFSG.average_vector(vec1, vec2)
	vd.trueborder = (ed1.face_out || ed2.face_out) ? false : true
	f1 = (ed1.face_out) ? ed1.face_out : face1
	f2 = (ed2.face_out) ? ed2.face_out : face2	
	vxs_out.same_plane = f1.normal.parallel?(f2.normal)
	vnorm = OFSG.average_normal(f1, f2)
	vxs_out.vplane = [origin, vxs_out.vec * vnorm]
	angle1 = vxs_out.vec.angle_between vec1
	angle2 = vxs_out.vec.angle_between vec2
	cosinus = (Math::cos(angle1) + Math::cos(angle2)) * 0.5
	vxs_out.dfactor = (cosinus.abs < 0.05) ? 1.0 : 1.0 / cosinus
	
	edge1 = ed1.edge
	edge2 = ed2.edge
	v1 = edge1.start.position.vector_to edge1.end.position
	v2 = edge2.start.position.vector_to edge2.end.position
	vd.colinear = v1.parallel? v2
	vd.cos_angle = (Math::cos v1.angle_between(v2)).abs
	vd.angle_in = convex_concave_angle origin, vxs_in.vec, edge1
	
	#creating the caminos for the vertex
	mark = OFSG.mark(origin, face1, vd.vertex, edge1, vd)
	vxs_in.camino = Camino.new(vxs_in.vplane, mark, vxs_in.vec.reverse)
	mark = OFSG.mark(origin, face1, vd.vertex, edge1, vd)
	vxs_out.camino = Camino.new(vxs_out.vplane, mark, vxs_out.vec.reverse)
end

def convex_concave_angle(pt, vec_in, edge)
	ptend = edge.start.position
	ptend = edge.end.position if ptend == pt
	vec = pt.vector_to ptend
	vec.angle_between(vec_in.reverse)	
end

def compute_all_vertices(distance)
	@hsh_vertices.each do |key, vd| 
		compute_vertex vd, distance 
	end	
end

def compute_vertex(vd, distance)	
	if (distance > 0)
		vd.vxs = vxs = vd.vxs_out
		if (vxs.vec.valid?)
			if @option_alone || vd.trueborder
				pt = vd.origin.offset vd.vxs_in.vec, vd.vxs_in.dfactor * distance
				vd.mark = OFSG.create_mark(pt, nil)
			elsif vd.colinear		#skip vertex that are on edges, as they usually mess up the contour
				vd.mark = OFSG.create_mark(nil, vd.edloop.face_in)
			else	
				vd.mark = vxs.camino.extend_chemin(vxs.dfactor * distance, @dsnap)
			end	
		else
			vd.mark = OFSG.create_mark(vd.vertex.position, nil)
		end
	else
		vd.vxs = vxs = vd.vxs_in
		if vd.colinear		#skip vertex that are on edges, as they usually mess up the contour
			vd.mark = OFSG.create_mark(nil, nil)
		elsif @option_alone
			pt = vd.origin.offset vxs.vec.reverse, -vxs.dfactor * distance
			vd.mark = OFSG.create_mark(pt, nil)
		else
			vd.mark = vxs.camino.extend_chemin(-vxs.dfactor * distance, @dsnap)
		end	
	end	
	vd.newpt = vd.mark.pt.clone if vd.mark.pt
	vd.mark.signature = vd
end

def loop_from_edge(ed, fstart)
	loop = []
	vdbeg = (fstart) ? ed.vd_start : ed.vd_end
	ed.looped = true unless fstart
	return loop unless vdbeg
	ednext = ed
	vdnext = vdbeg
	loop.push vdbeg
	vdbeg.edloop = ed
	
	while true
		break if (vdnext.lstedges.length == 1)
		ednext = (ednext == vdnext.lstedges[0]) ? vdnext.lstedges[1] : vdnext.lstedges[0]
		vdnext = (vdnext == ednext.vd_start) ? ednext.vd_end : ednext.vd_start
		ednext.looped = true
		break unless vdnext
		loop.last.next_in_loop = vdnext
		loop.push vdnext
		vdnext.edloop = ednext
		break if (vdnext == vdbeg)
	end	
	loop
end

#Organize the contours of the selection into loops
def construct_contour_loops
	@hsh_edges.each do |key, ed|
		next if ed.looped
		lp1 = loop_from_edge(ed, true)
		if (ed.looped)
			loop = lp1
		else	
			lp2 = loop_from_edge(ed, false)
			loop = lp1.reverse + lp2
		end	
		@all_loops.push loop
	end	

	@all_loops.each_with_index do |loop, iloop|
		loop.each do |vd|
			vd.iloop = iloop
			vd.edloop.iloop = iloop
		end	
	end	

	check_loops_type
	@hsh_edges.each do |key, ed|
		case @lst_loop_type[ed.iloop]
		when -1	
			@lst_inner_edges.push ed.edge
		when 1	
			@lst_outer_edges.push ed.edge
		else
			@lst_main_edges.push ed.edge
		end	
	end		
	compute_active_loops
end

def loop_status(loop)
	return 0 if loop.first != loop.last		#not a true loop
	sum = 0.0
	loop.each { |vd| sum += vd.angle_in }
	valcrit = Math::PI * loop.length.to_f
	d = sum * 2.0 - valcrit
	return 0 if d.abs < 1.0e-08
	(d < 0) ? 1 : -1
end

#check whether the type of all loops ( Inner or Outer) and build list of loops accordingly
def check_loops_type
	nb = @all_loops.length - 1
	@lst_loop_type = []
	for i in 0..nb
		@lst_loop_type.push 0
	end	
		
	@all_loops.each_with_index do |loop, iloop|
		case status = loop_status(loop)
		when 1
			@outer_loops.push loop
		when -1
			@inner_loops.push loop
		else
			@main_loops.push loop
		end
		@lst_loop_type[iloop] = status
	end	
end

#Compute the active list of loops
def compute_active_loops
	@loops = @main_loops
	@lst_edges = @lst_main_edges
	opt = @option_contours
	opt = 'A' if @all_loops.length == 1
	case opt
	when 'O'
		@loops += @outer_loops
		@lst_edges += @lst_outer_edges
	when 'I'
		@loops += @inner_loops
		@lst_edges += @lst_inner_edges
	else
		@loops += @outer_loops + @inner_loops
		@lst_edges += @lst_outer_edges + @lst_inner_edges
	end	
end

#Execution Post Operation
def try_execute_after(distance)
	return false unless @ofsstore.same_entities?
	
	Sketchup.undo
	selection = @ofsstore.retrieve_selection
	return false unless selection.length > 0
	
	status = check_initial_selection false, selection
	return true if status != 0
	
	execute distance
	true
end

#-------------------------------------------------------------
#Top function to execute the Offset on Surface
#-------------------------------------------------------------
def execute(distance, title)
	#Computing the transformed position of the contour vertices
	@distance = distance
	compute_all_vertices distance

	#Saving geometry for potential Undo / change after operation
	@lst_faces = []
	@hsh_faces.each { |key, f| @lst_faces.push f }
	@ofsstore.store_selection @lst_faces, @lst_edges
	
	#performing drawing of edge
	@model.start_operation title
	
		#identifying the Group if needed
		if @group
			grp = @group
			unless grp
				@model.abort_operation
				return
			end	
			entities = grp.entities
		else
			entities = @entities
		end

		list_coseg = []
		attr = "Offset " + ((@linemode) ? 'L' : 'C') + " ---" + Time.now.to_i.to_s
		@loops.each do |loop|
			lspt = calculate_contour(loop, @dsnap, list_coseg)
			
			#Sketchup bug when contour reuse existing edges
			unless @group || @linemode == false
				OFSG.supersede_coseg entities, list_coseg, attr
			end
			
			#Generating first the faces
			generate_all_faces entities, loop, attr unless distance < 0 || @option_nofaces || @linemode == false
			
			#Generating the edges and curves
			lspt = make_boucle lspt unless @option_nocurves || @linemode == false
			lspt.each do |ls|
				next if ls.length == 0
				g = entities.add_group
				if @linemode
					if (@option_nocurves)
						g.entities.add_edges ls
					else	
						g.entities.add_curve ls
					end	
					group_remove_faces(g)
				else
					nb = ls.length - 2
					for i in 0..nb
						g.entities.add_cline ls[i], ls[i+1]
					end	
				end
				#g.explode
				assign_attributes g, attr
				if @option_cpoint
					ls.each do |pt| 
						cpoint = entities.add_cpoint pt
						OFSG.set_polyline_attribute_entity cpoint, attr
					end	
				end	
			end	
		end
		
	@model.commit_operation  
	
	#Storing the current context for possible re-entering of distance
	@ofsstore.save_entities
	
	#Resetting all class variables
	reset
	@lst_impfaces = []
end

#Assign attributes to edges	
def assign_attributes(g, attr)
	ls = g.explode
	return unless ls
	ls.each do |ent|
		if (ent.class == Sketchup::ConstructionLine)
			OFSG.set_polyline_attribute_entity ent, attr
		elsif (ent.class == Sketchup::Edge)
			OFSG.set_polyline_attribute_entity ent, attr
			assign_anchor ent
		elsif ent.class == Sketchup::Curve
			ent.each_edge do |ee|
				OFSG.set_polyline_attribute_entity ee, attr
				assign_anchor ee
			end
		end
	end	
end
	
def assign_anchor(edge)
	pt = edge.start.position
	if @list_anchors.include? pt
		OFSG.set_polyline_anchor(edge.start, 'S')
	end
	pt = edge.end.position
	if @list_anchors.include? pt
		OFSG.set_polyline_anchor(edge.end, 'S')
	end
end
	
#Concatenate the different portions of contours to make true loops if any
def make_boucle(lspt)
	return lspt if lspt.length < 2
	lstout = []
	while lspt.length >= 1
		l0 = lspt.pop
		nb = lspt.length - 1
		if (nb < 0)
			lstout.push l0
			break
		end
		lnew = nil
		for i in 0..nb
			l1 = lspt[i]
			if l0.last == l1.first
				lnew = l0 + l1[1..-1]
			elsif l0.first == l1.first
				lnew = l0.reverse + l1[1..-1]
			elsif l0.first == l1.last
				lnew = l1 + l0[1..-1]
			elsif l0.last == l1.last
				lnew = l0[0..-1] + l1.reverse
			end			
			if lnew
				lspt[i..i] = []
				lspt.push lnew
				break
			end
		end	
		lstout.push l0 unless lnew
	end	
	return lstout
end
	
def group_remove_faces(g)
	lst = []
	g.entities.each do |e|
		lst.push e if e.class == Sketchup::Face
	end
	g.entities.erase_entities lst if lst.length > 0
end
	
def get_new_contour(distance)
	#computing the new position of vertices
	@distance = distance
	compute_all_vertices distance

	#Simplifying the contour and joining the new position of vertices
	lpt = []
	@loops.each do |loop|		
		lspt = calculate_contour(loop, @dsnap)
		lpt.concat lspt
	end	
	lpt
end

def calculate_contour(loop, dsnap, list_coseg=nil)

	#Simplifying the contour by removing overlapping points
	remove_spikes loop
	
	#joining the remaining points
	lp = []
	loop.each { |vd| lp.push vd if vd.mark.pt }
	parcours = []
	nv = lp.length - 2
	for i in 0..nv
		vd1 = lp[i]
		vd2 = lp[i+1]
		pk = junction vd1, vd2
		pk.each { |mk| parcours.push mk }
	end	
	if (loop.first == loop.last) && (lp.first != lp.last)
		pk = junction lp.last, lp.first
		pk.each { |mk| parcours.push mk }
	end
	
	#Cleaning up the resulting contour
	parcours = remove_dups_in_parcours(parcours, 0)
	llmk2 = simplify_parcours loop, parcours
	
	llmk = []
	llmk2.each do |l|
		####lmk = snap_in_parcours(l, dsnap)
		lmk = smooth_parcours(l)
		####lmk = smooth_parcours(lmk)
		llmk.push lmk
	end	
		
	
	#Calculating the list of segments that are on the same edges
	llmk.each { |lmk| OFSG.compute_coseg lmk, list_coseg } if list_coseg
	
	#returning the list of points
	@list_anchors = []
	llpt= []
	llmk.each do |lmk|
		lpt = []
		lmk.each do |mk| 
			lpt.push mk.pt
			@list_anchors.push mk.pt if mk.signature
		end	
		llpt.push lpt
	end
	llpt	
end

#-----------------------------------------------------------------------
# Section to simplify contour

#Simplify the contour by removing portions that are intersecting
def simplify_parcours(loop, parcours)

	#checking whether to apply the simplification
	if (@distance > 0 && @outer_loops.include?(loop)) ||
	   (@distance < 0 && @inner_loops.include?(loop)) || @option_nosimplify
	   return [parcours]
	end 
		
	#Creating the list of segments
	lstseg = []
	nb = parcours.length - 2
	hface = {}
	for i in 0..nb
		lstseg.push segment_create(parcours[i], parcours[i+1], hface)
	end	

	#Chaining the segments
	isloop = (parcours.first.pt == parcours.last.pt)
	nb = lstseg.length - 2
	for i in 1..nb
		seg = lstseg[i]
		seg.segprev = lstseg[i-1]
		seg.segnext = lstseg[i+1]
	end
	sfirst = lstseg.first
	slast = lstseg.last
	sfirst.segnext = lstseg[1]
	slast.segprev = lstseg[nb]
	if isloop
		sfirst.segprev = slast
		slast.segnext = sfirst
	end	
	
	#Loop on segments to check if they intersect
	listA = [[]]
	listB = [[]]
	validity = true
	lstseg.each do |seg|
		validity = segment_intersect(seg, hface, validity, listA, listB)
	end

	#Deciding which group of segments to choose
	return listA if listB.length == 1 && listB[0].length == 0
	
	nbA = count_reversed listA
	nbB = count_reversed listB
	
	#Algorithm is to find a vertex <vd> which is not reversed and which path to its origin does not cross the 
	# generated contour. If so, it is in the valid part of the contour
	lvdA = []
	lvdB = []
	loop.each do |vd|
		next if vd == nil || vd.touched == false || vd.mark.pt == nil || vd.reversed
		unless vertex_camino_cross_contour(vd, lstseg)
			if (vd.validity)
				lvdA.push vd
			else
				lvdB.push vd
			end	
		end	
	end
	return [[]] if lvdA.length == 0 && lvdB.length == 0
	return listA + listB if lvdA.length == lvdB.length
	(lvdA.length > lvdB.length) ? listA : listB
end

def count_reversed(list)
	nb = 0
	list.each do |ll|
		ll.each do |mark|
			vd = mark.signature
			nb += 1 if vd && vd.reversed 
		end
	end
	return nb	
end

#Determine if the camino of a vertex crosses or not the contour <lstseg> 
def vertex_camino_cross_contour(vd, lstseg)
	chemin = vd.vxs.camino.chemin
	nb = chemin.length - 2
	ptmark = vd.mark.pt
	iend = (vd.mark.face) ? nb : nb+1
	for i in 0..iend
		pt1 = chemin[i].pt
		pt2 = (i == iend) ? ptmark : chemin[i+1].pt
		lstseg.each do |seg|
			pt = OFSG.segment_intersection(pt1, pt2, seg.mk1.pt, seg.mk2.pt, false)
			return true if pt && pt != ptmark
		end
	end	
	return false
end

#Create a segment and pre-compute some list
def segment_create(mk1, mk2, hface)
	seg = OFS_Segment.new
	seg.mk1 = mk1
	seg.mk2 = mk2
	seg.segprev = nil
	seg.segnext = nil
	
	#Computing the common faces to each mark
	lf1 = []
	if mk1.vertex
		mk1.vertex.faces.each { |f| lf1.push f }
	elsif mk1.edge
		mk1.edge.faces.each { |f| lf1.push f }
	elsif mk1.face
		lf1.push mk1.face
	end
	
	lf2 = []
	if mk2.vertex
		mk2.vertex.faces.each { |f| lf2.push f }
	elsif mk2.edge
		mk2.edge.faces.each { |f| lf2.push f }
	elsif mk2.face
		lf2.push mk2.face
	end
	
	lf = seg.lstfaces = lf1 + lf2
	lf.uniq!
	
	#Creating a hash table linking segments and faces
	hnil = hface["nill"] = [] unless hnil = hface["nill"]
	if lf.length == 0
		hnil.push seg
	else	
		lf.each do |f| 
			l = hface[f.to_s] 
			l = hface[f.to_s] = [] unless l
			l.push seg unless l.include?(seg)
		end
	end	
	seg
end

#processing the intersection of <seg> with all other segments and building the 2 lists of points
def segment_intersect(seg, hface, validity, listA, listB)
	#computing the list of segments that can intersect <seg>
	if (seg.lstfaces.length == 0)
		listseg = hface["nill"]
	else
		listseg = []
		seg.lstfaces.each { |f| hface[f.to_s].each { |s| listseg.push s unless listseg.include?(s) } }
	end	
	
	#Computing the intersection
	segprev = seg.segprev
	segnext = seg.segnext
	pt1 = seg.mk1.pt
	pt2 = seg.mk2.pt
	vd1 = seg.mk1.signature
	vd2 = seg.mk2.signature
	lstptord = []
	listseg.each do |s|
		next if (s == seg || s == segprev || s == segnext)
		pt = OFSG.segment_intersection(pt1, pt2, s.mk1.pt, s.mk2.pt, true)
		next unless pt
		pord = OFS_PtOrd.new
		pord.pt = pt
		pord.distance = pt1.distance pt
		lstptord.push pord
	end
	
	#Sorting the intersections
	lstptord.sort! { |x, y| x.distance <=> y.distance } if lstptord.length > 1
	
	#Constructing the 2 lists
	listZ = (validity) ? listA : listB
	ll = listZ.last
	ll.push seg.mk1 unless ll.length > 0 && ll.last.pt == pt1
	vd1.validity = validity if vd1
	vd1.touched = true if vd1
	face = seg.mk1.face
	lstptord.each do |ptord|
		mk = OFSG.mark ptord.pt, face, nil, nil
		ll.push mk
		validity = ! validity
		listZ = (validity) ? listA : listB
		ll = []
		listZ.push ll
		ll.push mk
	end
	ll.push seg.mk2 unless ll.length > 0 && ll.last.pt == pt2
	vd2.validity = validity if vd2
	vd2.touched = true if vd2
	
	return validity
end

#Simplify the contour by removing transformed vertices that are outside the contour
def remove_spikes(loop)
	angle_limit = 10.degrees
	angle_max = 45.degrees
	remove_dups_in_contour(loop, @dsnap)
	loop.each { |vd| vd.reversed = false }
	
	#Eliminating redundant vertices
	correction = true
	vdprev = loop.last
	while correction
		correction = false
		loop.each do |vd|
			next unless vd.mark.pt
			unless vdprev.mark.pt
				vdprev = vd
				next
			end
			if OFSG.same_side_of_plane?(vdprev.vxs_in.vplane, vd.origin, vd.mark.pt)
				vdprev = vd
				next
			end	
			
			#The 2 paths are crossing. We note it and also elimiates almost colinear vertices to avoid spikes
			vd.reversed = true
			vdprev.reversed = true
			
			next if @option_nosimplify
			
			if vd.colinear || ((Math::PI / 2 - vd.angle_in).abs < angle_limit) 
				vd.mark.pt = nil
				correction = true
			elsif vdprev.colinear || ((Math::PI / 2 - vdprev.angle_in).abs < angle_limit)
				vdprev.mark.pt = nil
				vdprev = vd
				correction = true
			elsif (vdprev.angle_in - vd.angle_in).abs > angle_max
				if (vdprev.angle_in > vd.angle_in)
					vdprev.mark.pt = nil
					vdprev = vd
				else
					vd.mark.pt = nil
				end
				correction = true
			end
		end	
	end	
	
	#Eliminating dups
	remove_dups_in_contour(loop, 0)
end

#remove points which are very close in a contour
def remove_dups_in_contour(loop, dsnap)
	lp = []
	loop.each { |vd| lp.push vd if vd.mark.pt }

	vdprev = lp[0]
	nb = lp.length - 1
	for i in 1..nb
		vd1 = vdprev
		vd2 = lp[i]
		next unless vd2.mark.pt && vd1.mark.pt
		if vd1.mark.pt.distance(vd2.mark.pt) <= dsnap
			if vd1.cos_angle <= vd2.cos_angle
				vd2.mark.pt = nil
			else
				vd1.mark.pt = nil
				vdprev = vd2
			end
			next
		end
		vdprev = vd2
	end			
end

def snap_in_parcours(parcours, dsnap)
	return [] unless parcours.length > 0
	dsnap_v = dsnap
	dsnap_e = dsnap
	dsnap_ev = 5 * dsnap
	parcours.each_with_index do |mk, i|
		parcours[i] = OFSG.snap_to_vertex(mk.pt, mk.face, mk.edge, dsnap_v) unless mk.vertex || (mk.face == nil)
		parcours[i].signature = mk.signature
	end	
	parcours.each_with_index do |mk, i|
		parcours[i] = OFSG.snap_in_face(mk.pt, mk.face, mk.edge, dsnap_e) unless mk.vertex || (mk.face == nil)
		parcours[i].signature = mk.signature
	end	

	#Eliminating dups
	parcours = remove_dups_in_parcours(parcours, 0)

	#smoothing edge points close to vertex
	n = parcours.length - 2
	for i in 0..n
		mk1 = parcours[i]
		mk2 = parcours[i+1]
		d = mk1.pt.distance(mk2.pt)
		if mk1.edge && mk2.vertex && d <= dsnap_ev
			parcours[i] = mk2
		elsif mk2.edge && mk1.vertex && d <= dsnap_ev	
			parcours[i+1] = mk1
		end
	end	
	
	#Eliminating dups
	remove_dups_in_parcours(parcours, 0)	
end


def remove_dups_in_parcours(parcours, dsnap)
	return [] unless parcours.length > 0
	lp = []
	n = parcours.length - 2
	for i in 0..n
		mk1 = parcours[i]
		mk2 = parcours[i+1]
		next unless mk1.pt && mk2.pt
		lp.push mk1 if mk1.pt.distance(mk2.pt) > dsnap || mk1.vertex || mk1.edge
	end	
	lp.push parcours.last unless parcours.last.pt && lp.last.pt.distance(parcours.last.pt) <= dsnap
	lp
end

#remove 'free' marks corresponding to original vertices, when angle is not meaningful
def smooth_parcours(parcours)
	return parcours if @option_nosimplify
	hlsup = {}
	n = parcours.length-2
	for i in 1..n
		mk = parcours[i]
		vd = mk.signature
		next unless vd
		next if mk.vertex || mk.edge || (mk.face == nil)
		next if OFSG.which_edge(mk.face, mk.pt)
		unless vd.vxs.same_plane || vd.vxs.dfactor > 1.01 || vd.cos_angle < 0.5
			hlsup[i] = true
		end
	end	
	
	lp = []
	parcours.each_with_index { |mk, i| lp.push mk unless hlsup[i] }
	lp
end

def generate_all_faces(entities, loop, attr)
	@hsh_keep_edges = {}
	g = entities.add_group
	nb = loop.length - 1	
	k = 0
	lstfaces = []
	ptlast = nil
	while (k < nb)
		vd1 = loop[k]
		k += 1
		next if vd1.mark.face
		ptlast = vd1.mark.pt if vd1.mark.pt
		next unless ptlast
		camino1 = vd1.vxs.camino
		next if camino1 && camino1.chemin.length > 2
		for j in k..nb
			k = j
			vd2 = loop[j]
			camino2 = vd2.vxs.camino
			if vd2.mark.face || (camino2 && camino2.chemin.length > 2)
				ptlast = nil
				break
			end	
			lstfaces += generate_single_face g.entities, vd1, vd2, ptlast, attr
			break
		end	
	end
	cleanup_colinear(g.entities, lstfaces)
	g.explode
end

def generate_single_face(entities, vd1, vd2, ptlast, attr)
	newpt1 = (vd1.mark.pt) ? vd1.mark.pt : ptlast
	newpt2 = (vd2.mark.pt) ? vd2.mark.pt : ptlast
	pt1 = vd1.origin
	pt2 = vd2.origin
	face = vd2.edloop.face_in
	
	edge1 = entities.add_edges [pt1, newpt1]
	edge2 = entities.add_edges [pt2, newpt2]
	@hsh_keep_edges[edge1[0].entityID] = true
	@hsh_keep_edges[edge2[0].entityID] = true
	
	begin
		if (newpt1 == newpt2)
			newface = entities.add_face [pt1, pt2, newpt1]
		else
			newface = entities.add_face [pt1, pt2, newpt2, newpt1]
		end	
		OFSG.transfer_face face, newface
		OFSG.set_polyline_attribute_entity newface, attr
		return [newface]
	rescue
		newface1 = entities.add_face [pt1, pt2, newpt2]
		newface2 = entities.add_face [newpt2, newpt1, pt1]
		OFSG.transfer_face face, newface1
		OFSG.transfer_face face, newface2
		OFSG.set_polyline_attribute_entity newface1, attr
		OFSG.set_polyline_attribute_entity newface2, attr
		return [newface1, newface2]
	end	
end		

#Erase all coplanar edges on the generated faces
def cleanup_colinear(entities, lstfaces)
	ldel = []
	hedge = {}
	lstfaces.each do |face|
		face.edges.each do |e|
			next if hedge[e.to_s]
			hedge[e.to_s] = true
			if (e.faces.length == 2) 
				face1 = e.faces[0]
				face2 = e.faces[1]
				if (face1.normal.parallel? face2.normal) &&
				   (face1.material == face2.material) && (face1.back_material == face2.back_material)
					ldel.push e unless @hsh_keep_edges[e.entityID]
				else
					e.soft = true
					e.smooth = true
				end	
			end
		end	
	end
	entities.erase_entities ldel
end

#Precompute the parameters and Camino for the Red point
def set_red_point(origin, face, edge)

	#determining if the red point is a vertex
	at_vertex = nil
	dmin = edge.length / 100.0
	edge.vertices.each do |v|
		if v.position.distance(origin) < dmin
			at_vertex = v
			break
		end
	end
	
	#Computing the faces in and out
	if (at_vertex)
		vd = @hsh_vertices[at_vertex.to_s]
		ed1 = vd.lstedges[0]
		ed2 = vd.lstedges[1]
		edge1 = ed1.edge
		edge2 = ed2.edge
		face1 = ed1.face_in
		face2 = ed2.face_in
		origin = at_vertex.position
	else
		lstfaces_in = [face]
		faceout = nil
		edge.faces.each { |f| faceout = f if face != f }
	end
	
	#Creating the Camino for the red point for the INSIDE direction
	vec = edge.start.position.vector_to edge.end.position 
	vplane = [origin, vec]
	normal = OFSG.normal_ex_to_edge edge, face
	mark = OFSG.mark(origin, face, at_vertex, edge, nil)
	@red_camino_in = Camino.new vplane, mark, normal.reverse

	#Creating the Camino for the red point for the OUTSIDE direction
	if faceout == nil || @option_alone
		normalout = normal.reverse
		ffout = face
	else	
		normalout = OFSG.normal_ex_to_edge edge, faceout
		ffout = faceout
	end	
	mark = OFSG.mark(origin, ffout, at_vertex, edge, nil)
	@red_camino_out = Camino.new vplane, mark, normalout.reverse
end

#Calculate the transformation of the Red Point at a distance
def path_from_red_point(distance)
	camino = (distance > 0) ? @red_camino_out : @red_camino_in
	return unless camino
	d = distance.abs
	mark = camino.extend_chemin d, 0
	pt = mark.pt
	chemin = camino.chemin	
	path = []
	chemin.each do |node| 
		break if (node.distance >= d)
		path.push node.pt 
	end	
	path.push pt
	path
end

def junction(vd1, vd2)
	mark1 = vd1.mark
	mark2 = vd2.mark
	lstmark = Junction.calculate(mark1, mark2, @distance)
	unless lstmark.length < 2
		lstmark.first.signature = vd1
		lstmark.last.signature = vd2
	end
	lstmark
end

end #Class OffsetAlgo

end #module SUToolsOnSurface
