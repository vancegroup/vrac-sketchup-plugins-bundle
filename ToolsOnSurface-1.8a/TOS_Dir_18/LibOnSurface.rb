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
# Name			:   LibOnSurface.rb
# Original Date	:   10 April 2008 - version 1.0
# Revisions		:	14 May 2008 - version 1.1
#					04 Jun 2008 - version 1.2
#					12 Jul 2008 - version 1.3
#					31 Jul 2009 - version 1.5
# Type			:   Sketchup Ruby Script
# Description	:   Utility library for Tools on Surface
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module SUToolsOnSurface

#-------------------------------------------------------------------
# Common strings (do NOT translate here)
#-------------------------------------------------------------------
T6[:TIT_OnSurface] = "on Surface"

#Operations strings
T6[:OPS_EditVertex] = "Edit Vertex on Surface"
T6[:OPS_EraseVertex] = "Erase Vertex on Surface"
T6[:OPS_InsertVertex] = "Insert Vertex on Surface"
T6[:OPS_VoidTriangle] = "Repair small empty triangles"
T6[:OPS_MakeFace] = "Generate Faces"					
				  
#Inference tooltips
T6[:TIP_INF_Red_Axis] = "Red axis"
T6[:TIP_INF_Green_Axis] = "Green axis"
T6[:TIP_INF_Blue_Axis] = "Blue axis"
T6[:TIP_INF_Blue_Plane] = "Horiz. plane Red/Green"
T6[:TIP_INF_Red_Plane] = "Vert. plane Blue/Green"
T6[:TIP_INF_Green_Plane] = "Vert. plane Blue/Red"
T6[:TIP_INF_Colinear_Last] = "Collinear to previous"
T6[:TIP_INF_Colinear] = "Collinear at vertex"
T6[:TIP_INF_Perpendicular] = "Perpendicular"
T6[:TIP_INF_Perpendicular_Last] = "Perpendicular to previous"
T6[:TIP_INF_45] = "45 degrees"
T6[:TIP_INF_45_Last] = "45 degrees to previous"
T6[:TIP_Exit] = "Click to Exit"
			   	
#General Constants for All Surface Tools	
STATE_ORIGIN = 0
STATE_END = 1
STATE_EXECUTION = 2
OFS_INFERENCE_PROXIMITY = 0.997	
DEUX_PI = 2 * Math::PI

OFS_ERROR_NO_SELECTION = 1
OFS_ERROR_INVALID_SELECTION = 2
OFS_ERROR_COMPLEX_SELECTION = 3
OFS_ERROR_DISTANCE_ZERO = 4

#Common Data structures to hold some useful records
OFS_EdgeData = Struct.new("OFS_EdgeData", :edge, :face_in, :normal_in, :face_out, :normal_out,
                                          :pt1, :pt2, :curved, :looped, :vd_start, :vd_end, :iloop) 
										  
OFS_VertexData = Struct.new("OFS_VertexData", :origin, :vertex, :lstedges, :newpt, :colinear, :cos_angle, 
											  :trueborder, :vxs_in, :vxs_out, :vxs, :mark, :next_in_loop,
											  :edloop, :iloop, :angle_in, :reversed, :validity, :touched) 
											  
OFS_VexSubData = Struct.new("OFS_VexSubData", :vec, :distance, :vnorm, :same_plane,
                                              :vplane, :dfactor, :camino) 
											  
OFS_Node = Struct.new("OFS_Node", :pt, :edge, :distance, :face, :vec, :vertex) 

OFS_Mark = Struct.new("OFS_Mark", :pt, :face, :vertex, :edge, :signature) 

OFS_Segment = Struct.new("OFS_Segment", :mk1, :mk2, :lstfaces, :segprev, :segnext) 

OFS_PtOrd = Struct.new("OFS_PtOrd", :pt, :distance) 

OFS_EditVx = Struct.new("OFS_EditVx", :vxpivot, :edpivot, :ledges, :mark, :pts, 
                                      :parcours, :attr, :anchor, :list_coseg) #for polyline edition

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Class holding the saing of current selection before applying an Operation
# Shared by all tools on surface
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class SelectionStore
private_class_method :new
@@ofsstore = nil

def SelectionStore.create
	unless @@ofsstore
		@@ofsstore = new 
	end	
	@@ofsstore
end

def initialize
	@lstfaces = nil
	@lestedges = nil
end

#Store a selection of faces and edges
def store_selection(lstfaces, lstedges)
	@lstfaces = []
	@lstedges = []
	@lstfacecenters = []
	@lstedgecenters = []
	lstfaces.each do |f|
		@lstfaces.push f
		@lstfacecenters.push f.bounds.center
	end
	lstedges.each do |e|
		@lstedges.push e
		@lstedgecenters.push e.bounds.center
	end
end

#Saving the model entities
def save_entities	
	@saved_entities = []
	entities = Sketchup.active_model.active_entities
	entities.each do |e|
		@saved_entities.push e
	end	
end

#retrieve the previous selection - Algorithm is not very performing when model is complex
def retrieve_selection
	lstnewfaces = []
	lstnewedges = []
	entities = Sketchup.active_model.active_entities
	pbar = Traductor::ProgressionBar.new entities.length, "Elts"
	entities.each do |e|
		pbar.countage
		if (e.class == Sketchup::Face) && ((! @saved_entities.include? e) || (@lstfaces.include? e))
			lstnewfaces.push e
		end
		if (e.class == Sketchup::Edge) && ((! @saved_entities.include? e) || (@lstedges.include? e))
			lstnewedges.push e
		end
	end	
	if (lstnewfaces.length > 0)	
		if (lstnewfaces.length != @lstfaces.length)	#A non selected face was incidentally created by undo
			facestokeep = []
			lstnewfaces.each { |f| facestokeep.push f if (@lstfacecenters.include? f.bounds.center) }
			lstnewfaces = facestokeep
		end
	else	
		lstnewfaces = @lstfaces
	end	

	if (lstnewedges.length > 0)	
		if (lstnewedges.length != @lstedges.length)	#A non selected face was incidentally created by undo
			edgestokeep = []
			lstnewedges.each { |e| edgestokeep.push e if (@lstedgecenters.include? e.bounds.center) }
			lstnewedges = edgestokeep
		end
	else	
		lstnewedges = @lstedges
	end	
	
	#returning the selection
	lstnewfaces + lstnewedges
end

def same_entities?
	lst = Sketchup.active_model.active_entities
	return false unless (@saved_entities && lst.length == @saved_entities.length)
	lst.each_with_index do |e, i|
		return false if e != @saved_entities[i]
	end
	true
end

end #class SelectionStore

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Utility Class Junction to calculate Junctions on a surface
#There is no instance methods, just class methods
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class Junction

#Calculate the path up to a distance
def Junction.to_distance(mark, vecdir, len)
	return [mark] if len == 0 || vecdir.valid? == false
	face = mark.face
	origin = mark.pt
	vecdir = vecdir.reverse if len < 0
	@snap = OFSG.dsnap unless @snap
	
	#No initial face - We simply return the segment
	unless face
		pt = origin.offset vecdir, len.abs
		mark2 = OFSG.create_mark pt, nil
		return [mark, mark2]
	end	
		
	#building the Camino up to the distance	
	vplane = [origin, face.normal * vecdir]
	camino = Camino.new vplane, mark, vecdir
	mark2 = camino.extend_chemin len.abs, @snap
	lstmk = camino.chemin_to_parcours
	return lstmk + [mark2] if camino.end && lstmk[-1].pt != mark2.pt
	return lstmk[0..-2] + [mark2] if lstmk[-1].pt != mark2.pt
	return lstmk
end

#Calculate the junction between 2 marks on the surface
def Junction.calculate(mark1, mark2, distance=0, parcours_prev=nil)
	OFSG.correction_mark(mark1)
	OFSG.correction_mark(mark2)
	face1 = mark1.face
	face2 = mark2.face
	
	#ignore duplicate points, if any
	return [] if mark1.pt == mark2.pt
	
	#Direct path
	@snap = OFSG.dsnap unless @snap
	if (mark1.pt.distance(mark2.pt) <= @snap)
		return [mark1, mark2]
	end
	
	#Very close points
	if (face1 == nil && face2 == nil)
		return [mark1, mark2]
	end
	
	#One of the mark is outside surface
	if face2 == nil
		camino = Junction.join_marks(mark1, mark2, distance)
		return camino.chemin_to_parcours + [mark2]
	elsif face1 == nil
		camino = Junction.join_marks(mark2, mark1, distance)
		return [mark1] + camino.chemin_to_parcours.reverse
	end
	
	#Both marks are on surface
	camino1 = Junction.join_marks(mark1, mark2, distance, parcours_prev)
	if camino1.end
		camino2 = Junction.join_marks(mark2, mark1, distance)
		return camino1.chemin_to_parcours + camino2.chemin_to_parcours.reverse
	end	
	return camino1.chemin_to_parcours
end

#Join <mark1> toward <mark2>, assuming both are on a face
def Junction.join_marks(mark1, mark2, distance, parcours_prev=nil)
	vecdir = Junction.compute_vecdir mark1, mark2, distance, parcours_prev
	pt1 = mark1.pt
	pt2 = mark2.pt
	face1 = mark1.face
	face2 = mark2.face
	
	#computing the Plane
	if face1 && face2
		v1 = vecdir * face1.normal
		v2 = vecdir * face2.normal
		v2 = v2.reverse if v1 % v2 < 0
		vec = OFSG.average_vector(v1, v2)
	elsif face1
		vec = vecdir * face1.normal
	elsif face2
		vec = vecdir * face2.normal
	end	
	vplane = [pt1, vec]
	
	#Computing the camino from mark1 to mark2
	camino = Camino.new vplane, mark1, vecdir
	camino.reach_target mark2
	camino
end

#Extract a list of marks from the chemin of a camino
def Junction.chemin_to_parcours(camino)
	parcours = []
	ptprev = nil
	camino.chemin.each do |node| 
		next if node.pt == ptprev
		parcours.push OFSG.create_mark(node.pt, node.face) 
		ptprev = node.pt
	end	
	parcours	
end

#Compute the initial practical direction between 2 points on the surface, handling difficult cases
def Junction.compute_vecdir(mark1, mark2, distance, parcours_prev=nil)
	sinus_limit = 0.05
	
	#regular vector, not too far from the plane of the face
	pt1 = mark1.pt
	vecdir = pt1.vector_to mark2.pt
	face1 = mark1.face
	return vecdir if face1 == nil
	sinus = Math.sin vecdir.angle_between(face1.normal)
	return vecdir if sinus.abs >= sinus_limit
	
	#Continuing the path
	if parcours_prev && parcours_prev.length > 1
		return parcours_prev.first.pt.vector_to(parcours_prev[1].pt)
	end
	
	#trying alternate face
	ent = mark1.edge
	ent = mark1.vertex unless ent
	if ent
		ent.faces.each do |f|
			next if f == face1
			sinus = Math.sin vecdir.angle_between(f.normal)
			if sinus.abs >= sinus_limit 
				mark1.face = f
				return vecdir
			end
		end
	end
	
	#Trying to compute the best direction by generating the camino to the middle point of the vertex next edge
	vd1 = mark1.signature
	return vecdir unless vd1
	vd2 = vd1.next_in_loop
	
	ed1 = vd1.lstedges[0]
	vd2.lstedges.each { |ed| ed1 = ed if vd1.lstedges.include?(ed) } if vd2
	edge1 = ed1.edge
	
	pt_start = edge1.start.position
	pt_end = edge1.end.position
	ptmid = Geom.linear_combination 0.5, pt_start, 0.5, pt_end
	
	#face1 = mark1.face
	face1 = ed1.face_in
	if vd1.vxs == vd1.vxs_in
		face = ed1.face_in
		vec = ed1.normal_in.reverse
	else
		vec = ed1.normal_out.reverse
		face = (ed1.face_out) ? ed1.face_out : ed1.face_in
	end		
	vplane = vec * face1.normal
	mark = OFSG.mark(ptmid, face, nil, edge1, nil)
	camino = Camino.new(vplane, mark, vec)
	mark = camino.extend_chemin distance.abs, 0
	return pt1.vector_to(mark.pt)
end

end	#Class Junction

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Class Camino to hold a path on a surface
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class Camino

attr_reader :chemin, :end

def initialize(vplane, mark, vecdir)
	@vplane = vplane
	@hedge = {}
	@end = false
	@chemin = []
	@snap = OFSG.dsnap / 5.0
	@vecprev = vecdir.reverse
	
	compute_backward_direction(mark, vecdir)
end

#Extract a list of marks from the chemin of a camino
def chemin_to_parcours
	parcours = []
	@chemin.each { |node| parcours.push OFSG.mark(node.pt, node.face, node.vertex, node.edge, nil) }
	parcours	
end

def point_within_chemin(distance, dsnap)
	#target point is beyond the chemin
	chemin = @chemin
	pthd = chemin.last
	
	if pthd.distance < distance
		return nil unless @end
		d = distance - pthd.distance
		pt = pthd.pt.offset(pthd.vec, d)
		#return OFSG.generate_mark(pt, pthd.face, nil, dsnap) 	
		return OFSG.generate_mark(pt, nil, nil, dsnap) 	
	end
	
	#Target point is within the chemin
	n = chemin.length - 1
	pthd = nil
	for i in 0..n
		pthd = chemin[i]
		return OFSG.generate_mark(pthd.pt, pthd.face, pthd.edge, dsnap) if pthd.distance == distance
		break if (pthd.distance > distance)
	end	
	d = pthd.distance - distance
	pt = pthd.pt.offset(pthd.vec.reverse, d)
	face = pthd.face
	return OFSG.generate_mark(pt, face, nil, dsnap)
end

#Compute the intersection of a plane and an edge
def intersection_edge_plane(e, plane)
	pt = nil
	begin
		pt = Geom.intersect_line_plane e.line, plane
	rescue
		return [-1, nil]
	end	
	return [-1, nil] unless pt
	
	#Check if point cross the edge
	pt_start = e.start.position
	pt_end = e.end.position
	return [1, pt] if (pt == pt_start) 
	return [2, pt] if (pt == pt_end)
	return [0, pt] if (pt.vector_to(pt_start) % pt.vector_to(pt_end) <= 0)
	return [-1, nil]
end

def next_from_node(node)
	if node.vertex
		vertex = node.vertex
		@lface = vertex.faces
		vertex.edges.each { |e| @hedge[e.to_s] = e }
	elsif node.edge
		edge = node.edge
		@lface = edge.faces
		@hedge[edge.to_s] = edge
	elsif node.face
		@lface = [node.face]
	else
		@lface = []
	end	
end

#Compute the backward direction, based on general direction given by <vecdir>
def compute_backward_direction(mark, vecdir)
	origin = mark.pt
	face = mark.face
	vertex = mark.vertex
	edge = mark.edge
	
	#No face
	unless face
		@vecprev = vecdir.reverse.normalize
		return
	end

	#identifying possible vertex or edge
	vertex = OFSG.find_vertex(face, origin) unless vertex
	edge = OFSG.find_edge(face, origin, "compute backwad") unless edge
	
	#Creating first node and initializing environment
	vecdir = vecdir.normalize
	nodefirst = OFSG.create_node(origin, 0.0, edge, face, vecdir, vertex)
	@chemin.push nodefirst
	next_from_node nodefirst
	
	#Finding all possible direction and keeping the one closest to <vecdir>
	vecgood = vecdir
	psgood = -2.0
	facegood = nil
	@lface.each do |face|
		face.edges.each do |e|
			next if @hedge[e]
			la = intersection_edge_plane e, @vplane
			next if la[0] == -1		#No intersection
			pt = la[1]
			next if pt == origin
			vec = origin.vector_to(pt).normalize 
			next unless vec.valid?
			ps = vec % vecdir
			if (ps > psgood)
				vecgood = vec
				psgood = ps
				facegood = face
			end	
		end
	end
	vecgood.reverse! if vecdir % vecgood < 0
	nodefirst.vec = vecgood
	@lface = [facegood] if facegood 
	@vecprev = vecgood.reverse
end

#Compute the path on a face from an origin, along a vector, and up to a certain distance
#Note: origin is located within the face, possibly on an edge
def chemin_from_node(nodelast)
	#computing the intersection with the edges of the face
	path = []
	leng = nodelast.distance
	origin = nodelast.pt
	
	#Loop to find intersection
	@lface.each do |face|
		face.edges.each do |e|
			next if @hedge[e]
			la = intersection_edge_plane e, @vplane
			next if la[0] == -1		#No intersection
			pt = la[1]
			next if pt == origin
			d = origin.distance(pt)
			vec = origin.vector_to(pt).normalize 
			ps = vec % @vecprev
			next if @vecprev.samedirection?(vec)	#make sure we do not go backward
			next if ps > 0.99
			vertex = [nil, e.start, e.end][la[0]]
			path.push OFSG.create_node(pt, d + leng, e, face, vec, vertex)
		end	
	end
		
	#No intersection found
	return nil if path.length == 0
	
	#Sorting intersections by distance
	path.sort! { |x, y| x.distance <=> y.distance } if (path.length > 1)	
	nextnode = path[0]
	@hedge[nextnode.edge] = nextnode.edge
	
	#Correction for points found twice (with approximation of distance)
	if path.length > 1 && path[0].vertex == nil
		nb = path.length - 1
		for i in 1..nb
			d01 = path[0].pt.distance path[i].pt
			break if d01 > @snap * 10
			if path[i].vertex
				nextnode = path[i]
				@hedge[nextnode.edge] = nextnode.edge
				break
			end
		end
	end	
	
	#Storing the new node
	@chemin.push nextnode
	@vecprev = nextnode.vec.reverse
	return nextnode
end

#compute the full path from an origin over the surface, up to a distance (optional)
#variable <chemin> should already contain at least one node
def extend_chemin(distance, dsnap)
	#Checking if the point is not already within the chemin
	mark = point_within_chemin(distance, dsnap)
	return mark if mark
		
	#Loop on exploring all faces and progressing on the surface	
	nodelast = @chemin.last
	while true
		nodelast = chemin_from_node nodelast
		
		#Path has reached an end
		unless nodelast
			@end = true
			return point_within_chemin(distance, dsnap)
		end	

		#Getting next face to treat
		next_from_node nodelast
		
		#Checking if point is within distance
		return point_within_chemin(distance, dsnap) if (nodelast.distance > distance)	
	end	
end

#Try to resolve unproper termination of chemin
def rescue_target(mark_target)
	mkpt = mark_target.pt
	
	nb = @chemin.length - 2
	for i in 0..nb
		j = nb - i
		node1 = @chemin[j]
		node2 = @chemin[j+1]
		d1 = node1.pt.distance mkpt
		d2 = node2.pt.distance mkpt
		vec1 = node1.pt.vector_to mkpt
		vec2 = node2.pt.vector_to mkpt
		break if d2 < d1 && vec1 % vec2 > 0
		next if d1 < d2 && vec1 % vec2 > 0
		@chemin[j+1..-1] = []
		break unless mark_target.face
		@chemin.push OFSG.create_node(mkpt, node1.distance + d1, nil, mark_target.face, vec1)
		OFSG.correction_mark @chemin.last
		return true
	end
	@end = true	
	return false
end

#Find the chemin to a target point <mark> 
def reach_target(mark)
	#Loop on exploring all faces and progressing on the surface	
	mkpt = mark.pt
	nodelast = @chemin.last
	while true	
		if @chemin.length > 2000
			return rescue_target(mark)
			#@end = true
			#return false
		end	
		nb_beg = @chemin.length - 1
		nodelast = chemin_from_node(nodelast)
		
		#Path has reached an end
		unless nodelast
			return rescue_target(mark)
			#@end = true
			#return false
		end	

		#Getting next face to treat
		next_from_node nodelast

		#Checking if the node is a vertex and determining the next face
		nb_end = @chemin.length - 2
			
		#Check if target has been reached
		for i in nb_beg..nb_end
			pt1 = @chemin[i].pt
			pt2 = @chemin[i+1].pt
			case OFSG.point_within_segment(mkpt, pt1, pt2)
			when 1	#close to pt1
				@chemin[i+1..(nb_end+1)] = []
				return true
			when 2	#close to pt2	
				@chemin[i+2..(nb_end+1)] = [] if i < nb_end
				return true
			when -1  #Within segment	
				node2 = @chemin[i+1]
				@chemin[i+1..(nb_end+1)] = []
				node = @chemin[i]
				@chemin.push OFSG.create_node(mkpt, node.distance + pt1.distance(mkpt), nil, node2.face, node.vec)
				OFSG.correction_mark @chemin.last
				return true
			end
		end
		
	end	#end infinite loop
	false
end

end #class Camino

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Watchlist: Utility class for visual debugging
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class Watchlist
@@watchlist = nil	#For debug purpose
@@watchlistf = nil	#For debug purpose

def Watchlist.add(lpt)
	@@watchlist = [] unless @@watchlist
	lpt.each { |pt| @@watchlist.push pt }
end

def Watchlist.add_face(lface)
	@@watchlistf = [] unless @@watchlistf
	lface.each { |f| @@watchlistf.push f }
end

def Watchlist.draw(view)
	wcolor = ["blue", "green", "yellow"]

	if @@watchlist
		for i in 0..(@@watchlist.length-1)
			j = i.modulo 3
			color = wcolor[j]
			view.draw_points @@watchlist[i], 8, 2, color
		end	
	end
	if @@watchlistf
		for i in 0..(@@watchlistf.length-1)
			j = i.modulo 3
			color = wcolor[j]		
			view.drawing_color = "orange"
			view.line_width = 5
			face = @@watchlistf[i]
			face.loops.each do |loop|
				pts = []
				loop.vertices.each { |v| pts.push v.position }
				pts.push pts.first
				view.draw GL_LINE_STRIP, pts
			end	
		end	
	end	
end

def Watchlist.clear
	@@watchlist = [] if @@watchlist
end

def Watchlist.clear_face
	@@watchlistf = [] if @@watchlistf
end


end	#Class Watchlist

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# OFSG: Utility class with standalone functions
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class OFSG
@@tsnap = nil

#Retrieve the length for snapping, also used as precision
def OFSG.dsnap
	op = Sketchup.active_model.options["UnitsOptions"] 
	d = op["LengthSnapLength"]
	d.to_f
end

def OFSG.snap_in_face(pt, face, edge, dsnap)
	#No face
	return OFSG.mark(pt, face, nil, nil) unless face
		
	vertex = OFSG.find_vertex face, pt	
	edge = OFSG.find_edge face, pt	
	return OFSG.mark(pt, face, vertex, edge)
end	

def OFSG.snap_to_vertex(pt, face, edge, dsnap)
	return OFSG.mark(pt, face, nil, nil) unless face
	
	#Close to a vertex
	face.vertices.each do |v|
		return OFSG.mark(v.position, face, v, nil) if pt.distance(v.position) <= dsnap
	end
		
	#Free point
	####face = (OFSG.within_face?(face, pt)) ? face : nil	###
	OFSG.mark(pt, face, nil, edge)
end

#Check if a point is within a segment (excluding vertices) - <pt> is supposed to be on the segment
#return 1 if pt1, 2 if pt2, -1 if within segment and 0 is not on segment
def OFSG.point_within_segment(pt, pt1, pt2)
	return 1 if (pt == pt1)
	return 2 if (pt == pt2)
	ptproj = pt.project_to_line [pt1, pt2]
	return -1 if (pt == ptproj) && (pt1.vector_to(ptproj) % pt2.vector_to(ptproj) < 0)
	return 0
end

#Find if a point if a point is on an edge of a face and return it
def OFSG.which_edge(face, pt)
	return nil unless face
	face.edges.each do |e|
		pt1 = e.start.position
		pt2 = e.end.position
		return e if (pt == pt1) || (pt == pt2)
		ptproj = pt.project_to_line [pt1, pt2]
		d = pt.distance_to_line [pt1, pt2]
		return e if (d == 0) && (ptproj.vector_to(pt1) % ptproj.vector_to(pt2) <= 0)
	end
	return nil
end

#Computing the average normal of 2 faces (regardless of their orientation) 
def OFSG.average_normal(face1, face2)
	normal1 = face1.normal.normalize
	return normal1 unless face2
	normal2 = face2.normal.normalize	
	normal2.reverse! if normal1 % normal2 < 0
	normal2 = normal1 if normal1.parallel? normal2
	Geom.linear_combination 0.5, normal1, 0.5, normal2
end

#Computing the average normal of 2 faces (regardless of their orientation) 
def OFSG.average_vector(vec1, vec2)
	return vec1 unless vec2 && vec2.valid?
	return vec2 unless vec1 && vec1.valid?
	vec2 = vec1 if vec1.parallel? vec2
	Geom.linear_combination 0.5, vec1.normalize, 0.5, vec2.normalize
end

#Create a Node structure
def OFSG.create_node(pt, distance, edge, face, vec, vertex=nil)
	pthd = OFS_Node.new
	pthd.distance = distance
	pthd.pt = pt.clone
	pthd.edge = edge
	pthd.face = face
	pthd.vec = vec
	pthd.vertex = vertex
	pthd
end

#create a Mark structure
def OFSG.create_mark(pt, face)
	mark = OFS_Mark.new
	mark.pt = (pt) ? pt.clone : nil
	mark.face = face
	mark
end

def OFSG.mark(pt, face, vertex, edge, signature=nil)
	mark = OFS_Mark.new
	mark.pt = (pt) ? pt.clone : nil
	mark.face = face
	mark.vertex = vertex
	mark.edge = edge
	mark.signature = signature
	mark
end

#calculate the normal to an edge of a face pointing toward the outside
def OFSG.normal_ex_to_edge(edge, face)
	pt1 = edge.start.position
	pt2 = edge.end.position
	vec = face.normal * pt1.vector_to(pt2)
	vec.length = 1.0
	edge.reversed_in?(face) ? vec : vec.reverse
end

#check whether a point is strictly within a face (edges and vertices excluded)
def OFSG.within_face?(face, pt)
	return false unless face
	return (face.classify_point(pt) == 1) if SU_MAJOR_VERSION_6
	pts = []
	face.outer_loop.vertices.each { |v| pts.push v.position }
	Geom.point_in_polygon_2D pt, pts, false
end

#check whether a point is  within a face (edges and vertices included)
def OFSG.within_face_extended?(face, pt)
	return false unless face
	if SU_MAJOR_VERSION_6
		case face.classify_point(pt)
		when 1, 2, 4
			return true
		else
			return false
		end
	end	
	pts = []
	face.outer_loop.vertices.each { |v| pts.push v.position }
	return false unless Geom.point_in_polygon_2D pt, pts, true
	return true if face.loops.length == 1
	
	face.loops.each do |loop|
		next if loop.outer?
		pts = []
		loop.vertices.each { |v| pts.push v.position }
		return false if Geom.point_in_polygon_2D pt, pts, true
	end
	return true
end

def OFSG.within_face_super?(face, pt)
	return false unless face
	pts = []
	face.outer_loop.vertices.each { |v| pts.push v.position }
	return false unless Geom.point_in_polygon_2D pt, pts, true
	return true if face.loops.length == 1
	
	face.loops.each do |loop|
		next if loop.outer?
		pts = []
		loop.vertices.each { |v| pts.push v.position }
		return false if Geom.point_in_polygon_2D pt, pts, true
	end
	return true
end

#Check if 2 points are on the same side of a plane
def OFSG.same_side_of_plane?(plane, pt1, pt2)
	return true if pt1.on_plane?(plane) || pt2.on_plane?(plane)
	pj1 = pt1.project_to_plane plane
	pj2 = pt2.project_to_plane plane
	pj1.vector_to(pt1) % pj2.vector_to(pt2) >= 0
end

#compute the intersection of 2 segments
def OFSG.segment_intersection(pt1_start, pt1_end, pt2_start, pt2_end, strict)
	vec1 = pt1_start.vector_to pt1_end
	vec2 = pt2_start.vector_to pt2_end
	return nil if !(vec1.valid?) || !(vec2.valid?) || (vec1.parallel? vec2)
	pt = Geom.intersect_line_line [pt1_start, pt1_end], [pt2_start, pt2_end] 
	return nil unless pt
	return ((strict) ? nil : pt) if (pt == pt1_start) || (pt == pt1_end) || (pt == pt2_start) || (pt == pt2_end)
	ok1 = (pt.vector_to(pt1_start) % pt.vector_to(pt1_end) <= 0)
	ok2 = (pt.vector_to(pt2_start) % pt.vector_to(pt2_end) <= 0)
	(ok1 && ok2) ? pt : nil
end

#Debug and report method to check is a point is on a face
def OFSG.track_face(text, face, pt)
	return unless SU_MAJOR_VERSION_6
	return 0 unless face
	return 0 unless pt
	a = face.classify_point(pt)
	puts "TRACK [#{a}] --> #{text} #{face} #{pt}" if (a >= 8 || a == 0)
	return a
end

#Create a cursor from a file path and assign the hot spot
def OFSG.create_cursor(cursorname, hotx=0, hoty=0)
	cursorfile = "TOS_cursor_" + cursorname + ".png"
	cursorpath = Sketchup.find_support_file cursorfile, "Plugins/" + TOS_DIR
	cursorpath = Sketchup.find_support_file cursorfile, "Plugins" unless cursorpath
	(cursorpath) ? UI::create_cursor(cursorpath, hotx, hoty) : 0
end

#check if a point on a face is at a vertex
def OFSG.find_vertex(face, pt)
	return nil unless face
	face.vertices.each { |v| return v if (pt == v.position) }
	nil
end

#check if a point on a face is at an edge
def OFSG.find_edge(face, pt, text="")
	return nil unless face
	face.edges.each do |e| 
		return e if pt.on_line?(e.line)
	end	
	nil
end

#Try to find the correct face for a point, by looking around
def OFSG.correction_face(pt, face, edge)
	return nil if face == nil && edge == nil

	#face and points are matching
	return face if OFSG.within_face_extended?(face, pt)
	
	#No Edge given	
	if edge == nil
		face.vertices.each do |v|
			v.faces.each do |f|
				next if f == face
				return f if OFSG.within_face_extended?(f, pt)
			end
		end
		return face	
	end
	
	edge.faces.each do |f|
		next if f == face
		return f if OFSG.within_face_extended?(f, pt)
	end
	edge.start.faces.each do |f|
		next if f == face
		return f if OFSG.within_face_extended?(f, pt)
	end	
	edge.end.faces.each do |f|
		next if f == face
		return f if OFSG.within_face_extended?(f, pt)
	end	
	
	#nothing found
	return nil
end

def OFSG.correction_mark(mark)	
	face = OFSG.correction_face mark.pt, mark.face, mark.edge
	if (face != mark.face)
		mark.face = face
	end	
		mark.vertex = OFSG.find_vertex mark.face, mark.pt
		mark.edge = OFSG.find_edge mark.face, mark.pt, "correction Mark" 
end

def OFSG.generate_mark(pt, face, edge, dsnap=0.0)
	if (dsnap > 0.0)
		return OFSG.snap_in_face(pt, face, edge, dsnap)
	end	
	face = OFSG.correction_face(pt, face, edge)
	vertex = OFSG.find_vertex face, pt
	edge = OFSG.find_edge face, pt, "generate mark"
	return OFSG.mark(pt, face, vertex, edge)
end

#Comute the length of a parcours
def OFSG.compute_parcours_length(parcours)
	d = 0.0
	return d unless parcours
	nb = parcours.length - 2
	return d if nb < 0
	for i in 0..nb
		d += parcours[i].pt.distance parcours[i+1].pt
	end	
	d
end

#Generate a Mark from the input point on a surface
def OFSG.mark_from_inputpoint(view, ip, x, y, track_face=true, planedef=nil, freedom=false)
	face = ip.face
	vertex = ip.vertex
	edge = ip.edge
	pt = ip.position.clone
	if !track_face
		face = nil
	elsif vertex
		face = vertex.faces[0]
	elsif edge
		face = edge.faces[0]
	end	
	
	ph = view.pick_helper
	ph.do_pick x,y
	best = ph.best_picked
	if best && (best.instance_of?(Sketchup::Group) || best.instance_of?(Sketchup::ComponentInstance))
		face = nil
		vertex = nil
		edge = nil

	elsif (face == nil && planedef && planedef[1])
		ray = view.pickray x, y
		pt = Geom.intersect_line_plane ray, planedef unless (freedom && ip.degrees_of_freedom <= 1)
		return OFSG.mark(pt, nil, nil, nil, nil) if pt
		
	elsif (face == nil)
		ph = view.pick_helper
		ph.do_pick x,y
		picked = ph.all_picked
		picked.each do |e|
			face = e if e.class == Sketchup::Face
			edge = e if e.class == Sketchup::Edge
		end
		ray = view.pickray x, y
		if vertex
			pt = vertex.position
		elsif face
			ptinter = Geom.intersect_line_plane ray, face.plane
			pt = ptinter if ptinter
		elsif edge
			ptinter = Geom.intersect_line_line ray, edge.line
			pt = ptinter if ptinter
		end	
		if face || !track_face
			face = nil unless track_face
			return OFSG.mark(pt, face, vertex, edge, nil)
		else
			
		end	
	end
	
	#Drawing outside, try to guide the plane
	#if (face == nil && planedef && planedef[1])
		#ray = view.pickray x, y
		#pt = Geom.intersect_line_plane ray, planedef unless ip.degrees_of_freedom <= 1
		#return OFSG.mark(pt, nil, nil, nil, nil) if pt
	#end		
	face = ip.face unless face
	
	#Computing the corresponding mark
	ray = view.pickray x, y
	mark = OFSG.find_face_from_ray(ray, face, pt, vertex, edge)
	mark.pt = pt if ip.degrees_of_freedom == 0
	return mark
end

def OFSG.real_freedom_01(view, ip, x, y)
	return false if ip.degrees_of_freedom > 1
	pt = view.screen_coords ip.position
	(pt.x - x).abs < 5 && (pt.y - y).abs < 5
end

#Find the right face and right point from a view Ray and an initial face, by looking at neighbors
def OFSG.find_face_from_ray(ray, face, ptdef, vertex, edge)
	#no face
	unless face
		return OFSG.mark(ptdef, nil, vertex, edge, nil)
	end	
		
	#All is right	
	return OFSG.mark(ptdef, face, vertex, edge, nil) if OFSG.within_face_extended?(face, ptdef)
	
	#Looking on the face
	pt = Geom.intersect_line_plane(ray, face.plane)
	return OFSG.mark(pt, face, nil, nil, nil) if pt && OFSG.within_face_extended?(face, pt)

	#Looking for neighbor faces
	if vertex
		vertex.faces.each do |f|
			pt = Geom.intersect_line_plane(ray, f.plane)
			return OFSG.mark(pt, f, nil, nil, nil) if OFSG.within_face_extended?(f, pt)
		end	
	end

	if edge
		edge.faces.each do |f|
			pt = Geom.intersect_line_plane(ray, f.plane)
			return OFSG.mark(pt, f, nil, nil, nil) if OFSG.within_face_extended?(f, pt)
		end	
	end
	
	face.vertices.each do |v|
		v.faces.each do |f|
			pt = Geom.intersect_line_plane(ray, f.plane)
			return OFSG.mark(pt, f, nil, nil, nil) if OFSG.within_face_extended?(f, pt)
		end
	end	

	#No neighbor found
	return OFSG.mark(ptdef, face, vertex, edge, nil)
end

def OFSG.set_polyline_attribute_entity(entity, attr)
	entity.set_attribute TOS___Dico, TOS___SignEdge, attr
end

def OFSG.get_polyline_attribute(edge)
	edge.get_attribute TOS___Dico, TOS___SignEdge
end

def OFSG.check_polyline_anchor(edge)
	edge.get_attribute TOS___Dico, TOS___AnchorEdge
end

def OFSG.set_polyline_anchor(edge, anchor)
	edge.set_attribute TOS___Dico, TOS___AnchorEdge, anchor
end

def OFSG.set_polyline_param(edge)
	s = OFSG.encode_param_edge(edge)
	edge.set_attribute TOS___Dico, TOS___ParamEdge, s
end

def OFSG.encode_param_edge(edge)
	s = ""
	s += 'H' if edge.hidden?
	s += 'S' if edge.soft?
	s += 'O' if edge.smooth?
	s
end

#Check if an edge can be deleted or if not, possibly restore its original attributes
#return true when edge should not be deleted, false if it can be deleted
def OFSG.restore_polyline_param(edge)
	sparam = edge.get_attribute TOS___Dico, TOS___ParamEdge
	sign = edge.get_attribute TOS___Dico, TOS___SignEdge
	edge.delete_attribute TOS___Dico, TOS___SignEdge
	
	#Edge was superseding a previous edge - just restoring the attributes
	if sparam
		edge.hidden = true if sparam.include? 'H'
		edge.soft = true if sparam.include? 'S'
		edge.smooth = true if sparam.include? 'O'
	end
	
	#checking if edge is coplanar
	if sparam == nil || sign
		faces = edge.faces
		return true if faces.length > 2
		return false if faces.length < 2
		return ! (faces[0].normal.parallel? faces[1].normal)
	end
	
	true
end

def OFSG.supersede_coseg(entities, list_coseg, attr)
	list_coseg.each do |l|
		le = entities.add_edges l[0], l[1]
		if le && le[0].class == Sketchup::Edge
			OFSG.set_polyline_attribute_entity le[0], attr
			OFSG.set_polyline_param le[0]
			le[0].soft = false
			le[0].hidden = false
			le[0].smooth = false
		end	
	end
end

def OFSG.set_cline_attribute(cline, attr)
	cline.set_attribute TOS___Dico, TOS___SignEdge, attr
end

def OFSG.set_polyline_attribute(ledge, attr, lst_anchors=nil)
	return unless ledge
	ledge.each do |e|
		e.set_attribute TOS___Dico, TOS___SignEdge, attr
		if (lst_anchors)
			lst_anchors.each do |pt|
				if pt == e.start.position 
					e.start.set_attribute TOS___Dico, TOS___AnchorEdge, 'S'
				elsif pt == e.end.position 
					e.end.set_attribute TOS___Dico, TOS___AnchorEdge, 'E'
				end
			end
		end	
	end	
end
	
#Change status of mark segments in <lmk> that are going to be collinear to segments of the model
def OFSG.compute_coseg(lmk, list_coseg)
	nb = lmk.length - 2
	return if nb < 0
	for i in 0..nb
		mk1 = lmk[i]
		mk2 = lmk[i+1]
		next unless (mk1.edge || mk1.vertex) && (mk2.edge || mk2.vertex)
		next if mk1.edge && !mk1.edge.valid?
		next if mk2.edge && !mk2.edge.valid?
		next if mk1.vertex && !mk1.vertex.valid?
		next if mk2.vertex && !mk2.vertex.valid?
		if mk1.edge == mk2.edge || (mk1.vertex && mk1.vertex.edges.include?(mk2.edge)) ||
		   (mk2.vertex && mk2.vertex.edges.include?(mk1.edge))
			list_coseg.push [mk1.pt, mk2.pt]
		end
	end
end
	
#Cut the curve in curve chunk based on anchors	
def OFSG.piecemeal_curve(entities, pts, lst_anchor)
	le = []
	ptcurve = []
	pts.each do |pt|
		ptcurve.push pt
		if lst_anchor.include?(pt) && ptcurve.length > 1
			g = entities.add_group
			g.entities.add_curve ptcurve
			le += g.explode		
			ptcurve = [pt]
		end
	end	
	le
end
	
def OFSG.commit_line(entities, pts, attr, option_nocurves, list_coseg, list_edges, lst_anchor=nil, lst_hard=nil)
	return if pts.length < 2
	OFSG.supersede_coseg entities, list_coseg, attr if list_coseg
	unless option_nocurves
		if lst_hard
			le = OFSG.piecemeal_curve entities, pts, lst_hard
		else
			g = entities.add_group
			g.entities.add_curve pts
			le = g.explode
		end	
	else
		le = entities.add_edges pts
	end		
	le.each do |e| 
		if e.class == Sketchup::Edge
			e.soft = e.hidden = false
			list_edges.push e
		elsif e.class == Sketchup::Curve
			e.each_edge do |ee|
				ee.soft = ee.hidden = false
				list_edges.push ee unless list_edges.include?(ee)
			end	
		end
	end	
	OFSG.set_polyline_attribute(list_edges, attr, lst_anchor)
	VoidTriangle.proceed_repair(list_edges, entities)
end

#generic transfer for any drawing element
def OFSG.transfer_drawing_element (old_entity, new_entity)
	new_entity.layer = old_entity.layer
	new_entity.material = old_entity.material
	new_entity.visible = old_entity.visible?
	new_entity.receives_shadows = old_entity.receives_shadows?
	new_entity.casts_shadows = old_entity.casts_shadows?
end

#generic transfer for any drawing element
def OFSG.transfer_face (oldface, newface)
	OFSG.transfer_drawing_element oldface, newface
	newface.back_material = oldface.back_material
	newface.reverse! if (newface.normal % oldface.normal < 0) 
end

#Rotate a vector by an angle, taking into account trigo sense (via view camera)
def OFSG.rotate_vector(mark_origin, vecref, angle, normaldef)
	angle = angle.modulo(DEUX_PI)
	angle = angle + DEUX_PI if angle < 0
	face = mark_origin.face
	normal = (face) ? face.normal : normaldef
	vcamera = Sketchup.active_model.active_view.camera.direction
	normal = normal.reverse if normal % vcamera > 0
	t = Geom::Transformation.rotation mark_origin.pt, normal, angle
	return vecref.transform(t)
end

def OFSG.draw_square(view, lpt, dim, color)
	lpt = [lpt] unless lpt.class == Array
	view.drawing_color = color
	lpt.each do |pt|
		pt = view.screen_coords pt
		x = pt.x
		y = pt.y
		pts = []
		pts.push Geom::Point3d.new(x-dim, y-dim)
		pts.push Geom::Point3d.new(x+dim, y-dim)
		pts.push Geom::Point3d.new(x+dim, y+dim)
		pts.push Geom::Point3d.new(x-dim, y+dim)
		view.draw2d GL_QUADS, pts
	end	
end

def OFSG.draw_triangle(view, lpt, dim, color, fill=true)
	lpt = [lpt] unless lpt.class == Array
	view.drawing_color = color
	view.line_stipple = ''
	view.line_width = 1
	lpt.each do |pt|
		pt = view.screen_coords pt
		x = pt.x
		y = pt.y
		pts = []
		pts.push Geom::Point3d.new(x-dim, y-dim)
		pts.push Geom::Point3d.new(x+dim, y-dim)
		pts.push Geom::Point3d.new(x, y+dim)
		if fill
			view.draw2d GL_TRIANGLES, pts
		else	
			view.draw2d GL_LINE_LOOP, pts
		end	
	end	
end

def OFSG.draw_rect(view, lpt, dim, color)
	lpt = [lpt] unless lpt.class == Array
	view.line_stipple = ''
	view.line_width = 1
	view.drawing_color = color
	lpt.each do |pt|
		pt = view.screen_coords pt
		x = pt.x
		y = pt.y
		pts = []
		pts.push Geom::Point3d.new(x-dim, y-dim)
		pts.push Geom::Point3d.new(x+dim, y-dim)
		pts.push Geom::Point3d.new(x+dim, y+dim)
		pts.push Geom::Point3d.new(x-dim, y+dim)
		view.draw2d GL_LINE_LOOP, pts
	end	
end

def OFSG.draw_plus(view, lpt, dim, color)
	lpt = [lpt] unless lpt.class == Array
	view.drawing_color = color
	view.line_stipple = ''
	view.line_width = 1
	lpt.each do |pt|
		pt = view.screen_coords pt
		x = pt.x
		y = pt.y
		pts = []
		pts.push Geom::Point3d.new(x-dim, y)
		pts.push Geom::Point3d.new(x+dim, y)
		pts.push Geom::Point3d.new(x, y-dim)
		pts.push Geom::Point3d.new(x, y+dim)
		view.draw2d GL_LINES, pts
	end	
end

def OFSG.draw_star(view, lpt, dim, color)
	lpt = [lpt] unless lpt.class == Array
	view.drawing_color = color
	view.line_stipple = ''
	view.line_width = 1
	lpt.each do |pt|
		pt = view.screen_coords pt
		x = pt.x
		y = pt.y
		pts = []
		pts.push Geom::Point3d.new(x-dim, y)
		pts.push Geom::Point3d.new(x+dim, y)
		pts.push Geom::Point3d.new(x, y-dim)
		pts.push Geom::Point3d.new(x, y+dim)
		t = Geom::Transformation.rotation pt, Z_AXIS, Math::PI * 0.25
		view.draw2d GL_LINES, pts
		view.draw2d GL_LINES, pts.collect { |p| t * p }
	end	
end

end #class OFSG

#--------------------------------------------------------------------------------------------------------------
# Class ATTR: Management of Attributes for polylines
#--------------------------------------------------------------------------------------------------------------

class ATTR

end	#class ATTR

#--------------------------------------------------------------------------------------------------------------
# Class PolyEdit: polyline contours for Edition
#--------------------------------------------------------------------------------------------------------------
class PolyEdit

def initialize
	reset
end

def reset
	@hedge0 = {}
	@hmarks = {}
	@hmarks['-'] = '-'	#For lines on surface
	
	@hedge_used = {}
	@hvx_anchors = {}
	@hvertices = {}
	@pts_marks = []
	@pts_anchors = []
	@edge_loops = []
	@pts_loops = []
	@pts_draw = []	
	@vx_pivots = nil
end

#Specify the initial edges of the contour, in order to build it all
def set_list_edge(ledge, selection=nil)
	#checking if a recompute is necessary
	recompute = true
	ledge.each do |e|
		recompute = false if @hedge_used[e.to_s]
	end
	return false unless recompute
	compute_loops(ledge)
	if selection
		selection.clear
		@edge_loops.each do |l|
			selection.add l
		end
	end	
	return (@edge_loops.length > 0)
end

#return the list of edges of the selected contour
def get_list_edge
	@edge_loops
end

#Compute the overall contour to be selected
def compute_loops(ledge)
	reset
	
	#storing the original edges in a Htable
	ledge.each do |e| 
		attr = OFSG.get_polyline_attribute(e)
		next unless attr
		@hedge0[e.to_s] = e 
		@hmarks[attr] = attr
	end	
	
	found = true
	while found
		found = false
		@hedge0.each do |key, e|
			pts_loop = []
			edge_loop = []
			build_loop_from_edge e, edge_loop, pts_loop
			@edge_loops.push edge_loop if edge_loop.length > 0
			@pts_loops.push pts_loop if pts_loop.length > 0
			found = true
			break
		end	
	end

	#Building the list of points and adding the anchors and marks
	@hvertices.each do |key, v|
		if OFSG.check_polyline_anchor(v)
			@pts_anchors.push v.position
			@hvx_anchors[v.to_s] = v
		else
			@pts_marks.push v.position
		end
	end	

	@edge_loops.each do |l|
		l.each do |e|
			@pts_draw.push e.start.position
			@pts_draw.push e.end.position
		end	
	end	
end

#Find next connected edge part of a polyline. <v> must be edge.start or edge.end
def find_next_from_edge(edge, v)	
	lenew = []
	v.edges.each do |e|
		next if e == edge
		next if @hedge_used[e.to_s]
		attr = OFSG.get_polyline_attribute(e)
		next unless @hmarks[attr]
		lenew.push e
		@hedge_used[e.to_s] = e
	end	
	lenew
end

#Find the next edge and vertex crossing from a given edge
def find_loop_from_edge(edge, vertex, ledge, pts)
	@hvertices[vertex.to_s] = vertex
	while edge
		lnext = find_next_from_edge edge, vertex
		break unless lnext.length == 1
		edge = lnext[0]
		vertex = edge.other_vertex vertex
		ledge.push edge
		pts.push vertex.position
		@hvertices[vertex.to_s] = vertex
		@hedge_used[edge.to_s] = edge
		@hedge0.delete edge.to_s		
	end
	lnext
end

#Build the loop of edges from a given edge
def build_loop_from_edge(edge, edge_loop, pts_loop)
	@hedge_used[edge.to_s] = edge
	@hedge0.delete edge.to_s
	
	lend = []
	pts_end = [edge.end.position]
	ln_end = find_loop_from_edge(edge, edge.end, lend, pts_end)
	ln_end.each { |e| @hedge0[e.to_s] = e }
	
	lstart = []
	pts_start = [edge.start.position]
	ln_start = find_loop_from_edge(edge, edge.start, lstart, pts_start)
	ln_start.each { |e| @hedge0[e.to_s] = e }
	
	if (lstart.length + lend.length > 0)
		le = lstart.reverse + [edge] + lend
		le.each { |e| edge_loop.push e }
		lpt = pts_start.reverse + pts_end
		lpt.each { |pt| pts_loop.push pt }
	else
		edge_loop.push edge
		pts_loop.push edge.start.position, edge.end.position
	end	
end

#Commit the Vertex edition and draw the new contour portion
def edition_vertex_commit(entities)
	edition_vertex_redraw entities, :OPS_EditVertex
end

#generate the new segments when a vertex has been edited
def edition_vertex_redraw(entities, operation)
	return false unless @vx_pivots 
	model = Sketchup.active_model
	model.start_operation T6[operation]
		
	#computing the list of cosegments
	@vx_pivots.each do |edvx|
		next if edvx.pts.length == 0
		edvx.list_coseg = []
		OFSG.compute_coseg edvx.parcours, edvx.list_coseg
	end
	
	#erasing the old edges
	lst_erase = []
	@vx_pivots.each do |edvx|
		edvx.ledges.each { |e| lst_erase.push e unless OFSG.restore_polyline_param(e) }
	end	
	lst_erase.each { |e| entities.erase_entities e if e.valid?}
	
	#recomputing the parcours
	unless @vx_pivots[0].parcours
	
	end
	
	#mkorigin = @vx_pivots[0].parcours.last	#####nil
	#edition_vertex_move(mkorigin)
	
	#creating the new edges
	new_edges = []
	@vx_pivots.each do |edvx|
		parcours = parcours_remove_colinear(edvx.parcours)
		next if parcours == nil || parcours.length < 2
		pts = []
		parcours.each { |mk| pts.push mk.pt }		
		lanchor = [pts.last] + ((edvx.anchor) ? [pts.first] : [])
		OFSG.commit_line entities, pts, edvx.attr, false, edvx.list_coseg, new_edges, lanchor
		new_edges.last.find_faces
	end	
	
	model.commit_operation
	
	#recomputing the polyline
	ledge = []
	@edge_loops.each do |l|
		l.each do |e| 
			next unless e.valid?
			ledge.push e unless lst_erase.include?(e) 
		end	
	end
	ledge += new_edges
	reset
	set_list_edge ledge, model.selection
	@vx_pivots = nil
	true
end

#Remove some extra useless points generated when moving a vertex having more than  edges
def parcours_remove_colinear(parcours)
	return parcours unless parcours
	nb = parcours.length - 3
	return parcours if nb < 0
	ls = []
	for i in 0..nb
		mark1 = parcours[i]
		mark2 = parcours[i+1]
		mark3 = parcours[i+2]
		line = [mark1.pt, mark3.pt]
		if mark2.pt.on_line? line
			vertex = mark2.vertex
			ls.push(i+1) if vertex == nil || !vertex.valid? || vertex.edges.length == 2	
		end	
	end
	parc = []
	nb = parcours.length - 1
	for i in 0..nb
		parc.push parcours[i] unless ls.include?(i)
	end	
	parc
end

#reverse Anchor
def edition_reverse_anchor(vertex)
	if (@hvx_anchors[vertex.to_s])
		@hvx_anchors[vertex.to_s] = nil
		@pts_marks.push vertex.position
		@pts_anchors.delete vertex.position
	else
		@hvx_anchors[vertex.to_s] = vertex
		@pts_marks.delete vertex.position
		@pts_anchors.push vertex.position
	end	
end

#Abort the Edition of a vertex
def edition_vertex_abort
	@vx_pivots = nil
end

#Erase a vertex
def edition_vertex_erase(entities, vertex)
	edition_build_pivots vertex, false	
	edition_vertex_compute_erase
	edition_vertex_redraw entities, :OPS_EraseVertex	
end

#Insert a new vertex on an edge at specified position <pt>
def edition_vertex_insert(entities, edge, pt)
	model = Sketchup.active_model
	model.start_operation T6[:OPS_InsertVertex]
	
	le = entities.add_edges edge.start.position, pt
	newedge = le[0]
	newedge.vertices.each do |v|
		if v.position == pt
			OFSG.set_polyline_anchor(v, true)
		end
	end	
	
	model.commit_operation
	
	#recomputing the polyline
	ledge = []
	@edge_loops.delete edge
	@edge_loops.each do |l|
		l.each do |e| 
			next unless e.valid?
			ledge.push e 
		end	
	end
	ledge.push newedge
	reset
	set_list_edge ledge, model.selection
	@vx_pivots = nil
	true
end

#Start the edition of a vertex at <vertex>
def edition_vertex_start(vertex, toggle_anchor)
	@vertex_edit = vertex
	@anchor_pivot = (@hvx_anchors[vertex.to_s])
	anchor = (@anchor_pivot) ? true : false
	anchor = !anchor if toggle_anchor

	edition_build_pivots vertex, anchor
end

#Build the structure with the pivots
def edition_build_pivots(vertex, anchor)
	@vx_pivots = []
	vertex.edges.each do |e|
		next unless @hedge_used[e.to_s]
		vxedit = OFS_EditVx.new
		@vx_pivots.push vxedit
		vxedit.ledges = []
		vxedit.pts = []
		edition_find_pivot vxedit, vertex, e, anchor
		vxedit.attr = OFSG.get_polyline_attribute(vxedit.ledges[0])
		mark_for_pivot vxedit
	end	
end

#Find the next pivot vertex on the branch
def mark_for_pivot(vxedit)
	vertex = vxedit.vxpivot
	pt = vertex.position
	vxedit.anchor = (@hvx_anchors[vertex.to_s]) ? true : false
	face = (vertex.faces && vertex.faces[0]) ? vertex.faces[0] : nil
	unless face
		vother = vxedit.edpivot.other_vertex vertex
		vother.faces.each do |f|
			if OFSG.within_face_extended?(f, pt)
				face = f
				break
			end	
		end
	end	
	vxedit.mark = OFSG.mark pt, face, vertex, vertex.edges[0], nil
end

#Find the pivot vertex on a path from the vertex
def edition_find_pivot(vxedit, vertex, edge, anchor)
	while true
		vxedit.ledges.push edge
		vertex = edge.other_vertex vertex
		if anchor == false || @hvx_anchors[vertex.to_s] 
			vxedit.vxpivot = vertex
			vxedit.edpivot = edge
			return
		end	
		le = []
		vertex.edges.each do |e|
			next if e == edge
			next unless @hedge_used[e.to_s]
			le.push e
		end
		if le.length != 1
			vxedit.vxpivot = vertex
			vxedit.edpivot = edge
			return
		end
		edge = le[0]
	end
end

#Move the vertex during Edition
def edition_vertex_move(mark_end)
	@vx_pivots.each do |edvx|
		edvx.parcours = Junction.calculate edvx.mark, mark_end
		edvx.pts = []
		edvx.parcours.each { |mk| edvx.pts.push mk.pt }		
	end
end

#Compute the new lines when erasing a vertex
def edition_vertex_compute_erase
	nb = @vx_pivots.length - 2
	for i in 0..nb
		edvx1 = @vx_pivots[i]
		edvx2 = @vx_pivots[i+1]
		edvx1.parcours = Junction.calculate edvx1.mark, edvx2.mark
		edvx1.pts = []
		edvx1.parcours.each { |mk| edvx1.pts.push mk.pt }		
	end	
end

#Draw routine for the Polyline, to be called from the Draw method of the tool
def draw_loops(view)

	#Draw the marks and anchors
	view.line_stipple = ""
	view.line_width = 1
	#view.draw_points @pts_marks, 6, 2, "green" if @pts_marks.length > 0
	OFSG.draw_square view, @pts_marks, 3, "green" if @pts_marks.length > 0
	view.line_width = 3
	#view.draw_points @pts_anchors, 6, 2, "red" if @pts_anchors.length > 0
	OFSG.draw_square view, @pts_anchors, 3, "red" if @pts_anchors.length > 0
	
	#Draw the Edition pivots
	if @vx_pivots
		view.line_width = 1
		view.drawing_color = "red"
		@vx_pivots.each do |edvx|
			view.draw GL_LINE_STRIP, edvx.pts if edvx.pts.length > 1
		end
		@vx_pivots.each do |edvx|
			#view.draw_points edvx.vxpivot.position, 12, 1, "red"
			OFSG.draw_rect view, edvx.vxpivot.position, 5, "red"
		end
	end	
end

end #Class PolyEdit

#--------------------------------------------------------------------------------------------------------------
# Class MakeFace: Correction of small empty trinagles
#--------------------------------------------------------------------------------------------------------------
class MakeFace

def MakeFace.generate_faces(selection)
	hfaces = {}
	selection.each do |e|
		next if e.class != Sketchup::Edge
		lf0 = e.faces
		already = false
		lf0.each do |f|
			if hfaces[f.to_s]
				already = true
				break
			end
		end
		next if already		
		nb = e.find_faces
		if nb > 0
			lf1 = e.faces - lf0
			lf1.each { |f| hfaces[f.to_s] = f }
			if lf0.length > 0
				face0 = lf0[0]
				lf1.each { |f| OFSG.transfer_face(face0, f) }
			end	
		end	
	end
end

def MakeFace.proceed(selection)
	model = Sketchup.active_model
	model.start_operation T6[:OPS_MakeFace]
	MakeFace.generate_faces selection
	model.commit_operation
end

end	#class MakeFace
#--------------------------------------------------------------------------------------------------------------
# Class VoidTriangle: Correction of small empty trinagles
#--------------------------------------------------------------------------------------------------------------
class VoidTriangle

def VoidTriangle.selection_check_for_menu
	@dsnap = OFSG.dsnap * 3 unless @dsnap
	model = Sketchup.active_model
	model.selection.find { |e| e.instance_of?(Sketchup::Edge) && e.length <= @dsnap && e.faces.length == 1 }
end

def VoidTriangle.proceed_repair(selection=nil, entities=nil)
	@dsnap = OFSG.dsnap * 3 unless @dsnap
	model = Sketchup.active_model
	selection = model.selection unless selection
	ledges = selection.find_all { |e| e.instance_of?(Sketchup::Edge) && e.length <= @dsnap && e.faces.length == 1 }
	return if ledges.empty?
	
	#Performing the repair
	entities = model.active_entities unless entities
	model.start_operation T6[:OPS_VoidTriangle]
	ledges.each do |edge|
		VoidTriangle.repair_edge edge, entities
	end	
	model.commit_operation
	status
end

#Repair a small triangle at an edge
def VoidTriangle.repair_edge(edge, entities)
	#Exploring other edges
	lstart = []
	edge.start.edges.each do |e|
		next if e == edge || e.length > @dsnap || e.faces.length > 1
		lstart.push e.other_vertex(edge.start)
	end	
	lend = []
	edge.end.edges.each do |e|
		next if e == edge || e.length > @dsnap || e.faces.length > 1
		lend.push e.other_vertex(edge.end)
	end		
	return false if lstart.length == 0 || lend.length == 0
	
	#checking that we have a triangle
	vertex = nil
	lstart.each do |v|
		if lend.include?(v)
			vertex = v
			break
		end	
	end	
	return false unless vertex
	
	#Repairing the vertex
	begin
		newface = entities.add_face [edge.start.position, edge.end.position, vertex.position]
		OFSG.transfer_face(edge.faces[0], newface) if newface
	rescue
	end
	
	return true
end

end	#Class VoidTriangle

#--------------------------------------------------------------------------------------------------------------
# Class LinePicker: select two points on a surface, with inferences
#--------------------------------------------------------------------------------------------------------------			 				   
class LinePicker

def initialize
	#initializing variables
	@ip_origin = Sketchup::InputPoint.new
	@ip_end = Sketchup::InputPoint.new
	@ip = Sketchup::InputPoint.new
	@planedef = Z_AXIS
	@protractor = ProtractorShape.new
	@protractor_on = false
	@angle_direction = nil
	init_color
	init_text
	
	#resetting context
	reset
end

#color in RGB
def init_color
	@colinf_AtVertex = Sketchup::Color.new MYDEFPARAM[:TOS_COLOR_Inference_AtVertex]
	@colinf_Collinear = Sketchup::Color.new MYDEFPARAM[:TOS_COLOR_Inference_Collinear]
	@colinf_Perpendicular = Sketchup::Color.new MYDEFPARAM[:TOS_COLOR_Inference_Perpendicular]
	@colinf_Angle = Sketchup::Color.new MYDEFPARAM[:TOS_COLOR_Inference_Angle]
	@colinf_None = Sketchup::Color.new MYDEFPARAM[:TOS_COLOR_Inference_None]
	
	@inference_precision = MYDEFPARAM[:TOS_DEFAULT_Inference_Precision]
end

def init_text
	@tip_inf_red_axis = T6[:TIP_INF_Red_Axis]
	@tip_inf_green_axis = T6[:TIP_INF_Green_Axis]
	@tip_inf_blue_axis = T6[:TIP_INF_Blue_Axis]
	@tip_inf_blue_plane = T6[:TIP_INF_Blue_Plane]
	@tip_inf_red_plane = T6[:TIP_INF_Red_Plane]
	@tip_inf_green_plane = T6[:TIP_INF_Green_Plane]
	@tip_inf_colinear_last = T6[:TIP_INF_Colinear_Last]
	@tip_inf_colinear = T6[:TIP_INF_Colinear]
	@tip_inf_perpendicular = T6[:TIP_INF_Perpendicular]
	@tip_inf_perpendicular_last = T6[:TIP_INF_Perpendicular_Last]
	@tip_inf_inf_45 = T6[:TIP_INF_45]
	@tip_inf_inf_45_last = T6[:TIP_INF_45_Last]
	
	@tip_angle = T6[:T_VCB_Angle]
end

def reset
	@state = STATE_ORIGIN
	@mark_origin = nil
	@mark_end = nil
	@moved = false
	@color = "black"
	@parcours = nil
	@infmode = ""
	@forced = false
	@normal_imposed = nil
	@length_imposed = nil
	@angle_vector = nil
	@angle_forced = false
	@axis_forced = nil
end

#Methods to return attributes of LinePicker instance
def color
	@color
end
	
def mark_origin
	@mark_origin
end

def mark_end
	@mark_end
end

def parcours
	@parcours
end

def moved?
	@moved
end
	
def end_forced
	@forced = false
	@axis_forced = nil
end		

def set_imposed_normal(vec)
	@normal_imposed = vec
end

def set_plane_def(axis)
	@planedef = axis
end

def set_plane_imposed(axis)
	@plane_imposed = axis
end

def set_parcours(parcours)
	@parcours = parcours
	@mark_origin = parcours.first
	@mark_end = parcours.last
end

#Set the Protractor on or off
def set_protractor_on(on=true)
	@protractor_on = on
end

#Get Angle via protractor
def get_protractor_angle
	@protractor.get_angle
end

def set_protractor_placement(mark_origin, normal, vecdir)
	@protractor.set_placement mark_origin, normal, vecdir
end

def adjust_protractor(vecdir)
	if @vecdir_prev
		####normal = (@mark_origin.face) ? @mark_origin.face.normal : @planedef
		normal = (@mark_origin.face) ? @mark_origin.face.normal : get_planedef(vecdir)
		vec = normal * @vecdir_prev
		normal = vec * @vecdir_prev
		@protractor.set_placement @mark_origin, normal, @vecdir_prev
	end
end

#Mouse Move method - Origin
def onMouseMove_origin(flags, x, y, view, mark_imposed=nil)
	@xorig = x
	@yorig = y
	@ip.pick view, x, y	
	@ip_origin.copy! @ip
	@mark_origin = (mark_imposed) ? mark_imposed : OFSG.mark_from_inputpoint(view, @ip_origin, x, y)
	@vertex_origin = @mark_origin.vertex
	@mark_end = nil
	@parcours = nil
	@moved = false
		
	@tooltip = @ip.tooltip
	return @mark_origin
end

#Mouse Move method - Origin
def onMouseMove_end(flags, x, y, view, freedom=false)
	return nil unless @mark_origin
	@xend = x
	@yend = y		
	@ip.pick view, x, y
	if (@ip != @ip_origin) && @ip.valid? && @mark_origin.pt	
		@ip_end.copy! @ip
		@mark_end = OFSG.mark_from_inputpoint view, @ip_end, x, y, @mark_origin.face, [@mark_origin.pt, @planedef], freedom
		compute_inference view, @ip.degrees_of_freedom, flags
		if @parcours && @parcours.length > 1
			vecdir = @parcours.first.pt.vector_to @parcours[1].pt
			compute_angle_with_prev_direction view, vecdir
		end	
		@moved = true
	end
	@tooltip = @ip.tooltip if @tooltip == ""
	adjust_protractor @vecdir if @vecdir
	@mark_end
end	

def simulate_move_end(flags, view)
	onMouseMove_end(flags, @xend, @yend, view)
end

def chain_origin(view, mark)
	ptv = view.screen_coords mark.pt
	onMouseMove_origin(0, ptv.x, ptv.y, view, mark)
	@moved = true
	@angle_forced = false
	@axis_forced = nil
end

#draw the input point for the linepicker
def draw_point(view, ip, pt, face)
	if ip.valid? #&& ip.display?
		if (face == nil)
			if pt != ip.position
				ip.draw view
				#view.draw_points pt, 15, 3, 'purple'
				OFSG.draw_plus view, pt, 3, 'purple'
			else
				#if (ip.degrees_of_freedom <= 1)
				if ip.display?
					ip.draw view
				else	
					#view.draw_points pt, 6, 2, 'purple'
					OFSG.draw_square view, pt, 3, 'purple'
				end	
			end	
		elsif OFSG.within_face_extended?(face, pt) == false
			#view.draw_points pt, 15, 5, 'orange'
			OFSG.draw_star view, pt, 5, 'red'
		else	
			ip.draw view
			#view.draw_points pt, 15, 3, 'purple' if pt != ip.position
			OFSG.draw_plus view, pt, 3, 'purple' if pt != ip.position
		end	
	end
end	

def set_drawing_parameters(color=nil, width=nil, stipple=nil)
	@param_color = color
	@param_width = width
	@param_stipple = stipple
end

def draw_line(view, active)
	#Drawing the origin and end points
	if (active)
		view.line_stipple = ""
		draw_point(view, @ip_origin, @mark_origin.pt, @mark_origin.face) if @mark_origin
		draw_point(view, @ip_end, @mark_end.pt, @mark_end.face) if @mark_end	
	end
	
	#Drawing the line
	stipple = @param_stipple
	stipple = "" unless stipple
	width = 1
	if active && @normal_imposed == nil
		color = @color
		factor = inference_factor
	else
		color = @param_color
		color = 'black' unless color
		factor = 1
	end	
	width = width + 1 if stipple != ""
	width = width * factor
	
	#drawing the line
	return unless @parcours && @parcours.length > 1
	pts = []
	@parcours.each { |mk| pts.push mk.pt }
	
	view.line_stipple = stipple
	view.line_width = width
	#view.drawing_color = color
	nb = @parcours.length - 2
	for i in 0..nb
		face1 = @parcours[i].face
		face2 = @parcours[i+1].face
		face = nil
		face = face1 if face2 ==nil
		face = face2 if face1 ==nil
		face = face2 if face == nil
		view.drawing_color = Couleur.color_at_face color, face2
		view.draw_line @parcours[i].pt, @parcours[i+1].pt
	end	
	#view.draw_line GL_LINE_STRIP, pts if pts.length > 1

	#drawing the inference mark
	if (active) && @normal_imposed == nil && pts.length > 1
		draw_inference_mark view, pts
		draw_inference_angle view, pts if @angle_forced
	end	
		
	#drawing the protractor
	@protractor.draw view if @protractor_on
end

#Add origin and extremity of parcours to the bounding box	
def bounds_add(bb)
	return bb unless @parcours && @parcours.length > 0
	bb = bb.add @parcours.first.pt, @parcours.last.pt
end
	
#Draw method for origin and end points
def draw(view)	
	draw_point(view, @ip_origin, @mark_origin.pt, @mark_origin.face) if @mark_origin
	draw_point(view, @ip_end, @mark_end.pt, @mark_end.face) if @mark_end && @ip_end.valid?
end

def draw_inference_mark(view, pts)
	case @infmode
	when 'P'
		sign = 1		#Open square for Plane inference
		size = 8
	when 'D'
		sign = 6		#Circle for Angle Inference
		size = 12
	else
		return
	end	
	n = pts.length / 2 - 1
	ptmid = Geom.linear_combination 0.5, pts[n], 0.5, pts[n+1]
	#view.line_stipple = ""
	#view.line_width = 1
	if sign == 1
		OFSG.draw_rect view, ptmid, 5, @color
	else	
		OFSG.draw_triangle view, ptmid, 4, @color, false
	end	
	#view.draw_points ptmid, 8, sign, @color
end
	
def draw_inference_angle(view, pts)
	sign = 7		#Open square
	n = pts.length / 2 - 1
	ptmid = Geom.linear_combination 0.5, pts[n], 0.5, pts[n+1]
	#view.line_stipple = ""
	#view.line_width = 1
	#view.draw_points ptmid, 8, sign, @color
	OFSG.draw_triangle view, ptmid, 3, @color
end
	
def tooltip
	@tooltip 
end
	
def set_prev_direction(parcours)
	return unless parcours && parcours.length > 1
	vec = parcours[0].pt.vector_to parcours[1].pt
	@vecdir_prev = vec.normalize
	####adjust_protractor
	adjust_protractor vec
end
		
def inference_factor
	(@forced || @angle_forced || @axis_forced) ? 2 : 1
end
	
def close_to_origin(x, y)
	((x - @xorig).abs < 2 && (y - @yorig).abs < 2)
end

def impose_length(length)
	@length_imposed = length
end

def get_planedef(vecdir)
	normal = nil
	if @vecdir_prev && @vecdir_prev.valid?
		normal = vecdir * @vecdir_prev
	end
	return normal if normal && normal.valid?
	
	normaldef = @planedef
	normaldef = Z_AXIS unless normaldef.valid?
	normal = vecdir * normaldef
	return normal if normal && normal.valid?
	
	[X_AXIS, Y_AXIS, Z_AXIS].each do |normaldef|
		normal = vecdir * normaldef
		return normal if normal && normal.valid?
	end
	Z_AXIS
end

#Force an axis direction
def set_forced_axis(axis)
	@axis_forced = (axis) ? axis.normalize : nil
end

#Compute and activate Inferences when drawing on surface
def compute_inference(view, dof, flags)
	#Computing the required path from the input point
	parcours = Junction.calculate @mark_origin, @mark_end, 0, @parcours
	return if parcours.length < 2
	vecdir = parcours.first.pt.vector_to parcours[1].pt
	vecdir = vecdir.normalize
	if (@length_imposed)
		parcours = Junction.to_distance @mark_origin, vecdir, @length_imposed
		@mark_end = parcours.last
	end	
	@forced = Traductor.shift_mask?(flags)  && !Traductor.ctrl_mask?(flags)
	@angle_forced = false if @forced
	@axis = false if @forced
		
	#Impose Axis
	return if impose_axis(view, parcours, vecdir)
	
	#Impose angle
	return force_angle_direction(parcours, vecdir) if @angle_vector && @angle_forced	
	
	#Impose direction
	return if impose_normal(parcours, vecdir)
	
	#Shift depressed - force inference by continuing in same direction
	return force_inference(parcours, vecdir) if @forced
	
	#Degree of freedom constrained
	if (dof == 0) || (Traductor.shift_mask?(flags) && Traductor.ctrl_mask?(flags))
		@parcours = parcours
		@color = @colinf_None
		@vecdir = vecdir
		@infmode = ""
		@tooltip = ""	
		return
	end
	
	#main Axis
	return if close_to_vector view, parcours, vecdir, X_AXIS, "red", @tip_inf_red_axis
	return if close_to_vector view, parcours, vecdir, Y_AXIS, "green", @tip_inf_green_axis
	return if close_to_vector view, parcours, vecdir, Z_AXIS, "blue", @tip_inf_blue_axis
	
	#Prolongation at origin vertex
	vertex = @vertex_origin
	edge = @mark_origin.edge
	face = @mark_origin.face
	if vertex
		vertex.edges.each do |e|
			vother = e.other_vertex vertex
			vecref = vother.position.vector_to(vertex.position)
			return if close_to_vector view, parcours, vecdir, vecref, @colinf_AtVertex, @tip_inf_colinear
			return if close_to_plane view, parcours, vecdir, vecref * face.normal, @colinf_AtVertex, @tip_inf_colinear if face
		end
		if vertex.edges.length == 1
			e = vertex.edges[0]
			vother = e.other_vertex vertex
			vecref = vother.position.vector_to vertex.position
			normal = (face) ? face.normal : (vecref * vecdir)
			vecperp = vecref * normal
			return if close_to_vector view, parcours, vecdir, vecperp, @colinf_Perpendicular, @tip_inf_perpendicular
			return if close_to_plane view, parcours, vecdir, vecperp, @colinf_Perpendicular, @tip_inf_perpendicular		
			vec45 = vecref.normalize + vecperp.normalize
			return if close_to_vector view, parcours, vecdir, vec45, @colinf_Angle, @tip_inf_inf_45
			return if close_to_plane view, parcours, vecdir, vec45, @colinf_Angle, @tip_inf_inf_45
			vec45 = vecref.normalize - vecperp.normalize
			return if close_to_vector view, parcours, vecdir, vec45, @colinf_Angle, @tip_inf_inf_45
			return if close_to_plane view, parcours, vecdir, vec45, @colinf_Angle, @tip_inf_inf_45
		end
		
	#Perpendicular to Edge
	elsif edge 
		vecedge = edge.start.position.vector_to edge.end.position
		####normal = (face) ? face.normal : @planedef
		normal = (face) ? face.normal : get_planedef(vecdir)
		return if close_to_vector view, parcours, vecdir, vecedge * normal, @colinf_Perpendicular, @tip_inf_perpendicular
	end	
	
	#Prolongation at previous vector
	if @vecdir_prev
		return if close_to_vector view, parcours, vecdir, @vecdir_prev, @colinf_Collinear, @tip_inf_colinear_last
		####normal = (face) ? face.normal : @planedef
		normal = (face) ? face.normal : get_planedef(vecdir)
		vecseq = @vecdir_prev * normal
		return if close_to_plane view, parcours, vecdir, vecseq, @colinf_Collinear, @tip_inf_colinear_last
		vecperp = @vecdir_prev * normal
		return if close_to_vector view, parcours, vecdir, vecperp, @colinf_Perpendicular, @tip_inf_perpendicular_last
		return if close_to_plane view, parcours, vecdir, vecperp, @colinf_Perpendicular, @tip_inf_perpendicular_last
		vec45 = @vecdir_prev.normalize + vecperp.normalize
		return if close_to_vector view, parcours, vecdir, vec45, @colinf_Angle, @tip_inf_inf_45_last
		return if close_to_plane view, parcours, vecdir, vec45, @colinf_Angle, @tip_inf_inf_45_last
		vec45 = @vecdir_prev.normalize - vecperp.normalize
		return if close_to_vector view, parcours, vecdir, vec45, @colinf_Angle, @tip_inf_inf_45_last
		return if close_to_plane view, parcours, vecdir, vec45, @colinf_Angle, @tip_inf_inf_45_last
	end

	#main Axis Plane
	return if close_to_plane view, parcours, vecdir, X_AXIS, "darkorange", @tip_inf_red_plane
	return if close_to_plane view, parcours, vecdir, Y_AXIS, "limegreen", @tip_inf_green_plane
	return if close_to_plane view, parcours, vecdir, Z_AXIS, "royalblue", @tip_inf_blue_plane
	
	#Protractor Inference
	return if inference_protractor view, parcours, vecdir
	
	#no inference detected
	@parcours = parcours
	@color = @colinf_None
	@vecdir = vecdir
	@infmode = ""
	@tooltip = ""
end

def points_close_on_view(view, pt1, pt2)
	vpt1 = view.screen_coords pt1
	vpt2 = view.screen_coords pt2
	(vpt1.distance(vpt2) < @inference_precision)
end

#store adjusted direction
def validate_direction(view, parcours, vecref, color, tooltip, infmode)
	d = length_of_parcours parcours
	parc = Junction.to_distance @mark_origin, vecref, d
	return false unless points_close_on_view view, parcours.last.pt, parc.last.pt
	prolonge_to_edge parc
	@color = color
	@vecdir = vecref
	@parcours = parc
	@tooltip = Traductor[tooltip]
	@infmode = infmode
	true
end

#Try to adjust the parcours to the edge found by the Input point, if any
def prolonge_to_edge(parcours)
	edge = @mark_end.edge
	return unless edge
	
	#checking if parcours and edge are collinear
	vecedge = edge.start.position.vector_to(edge.end.position).normalize
	vecdir = parcours[-2].pt.vector_to(parcours.last.pt).normalize
	return if (vecedge % vecdir).abs > 0.999
	
	#Stopping at intersection
	@mark_end = parcours.last
	markend = intersect_line_edge parcours[-2], parcours.last, edge
	unless markend
		ledges = edge.start.edges + edge.end.edges
		ledges.each do |e|
			markend = intersect_line_edge parcours[-2], parcours.last, e
			break if markend
		end	
	end
	if markend && mark_end.pt != @mark_end.pt
		@mark_end = markend
		parcours[-1] = markend
	end	
end

#Find intersection between a line and an edge and return a Mark
def intersect_line_edge(mark1, mark2, edge)
	line = [mark1.pt, mark2.pt]
	pt = Geom.intersect_line_line edge.line, line
	return nil unless pt
	if pt == edge.start.position
		markend = OFSG.mark pt, mark2.face, edge.start, edge, nil
	elsif pt == edge.end.position
		markend = OFSG.mark pt, mark2.face, edge.end, edge, nil
	elsif pt.vector_to(edge.start.position) % pt.vector_to(edge.end.position)
		markend = OFSG.mark pt, mark2.face, nil, edge, nil
	else
		markend = nil
	end
	markend	
end

#Check for inference protractor
def inference_protractor(view, parcours, vecdir)
	return unless @protractor_on && vecdir.valid?
	lres = @protractor.inference(view, @ip_end.position, vecdir, @angle_direction)
	return false unless lres
	vecref = lres[0]
	dangle = lres[1].radians
	a = dangle.modulo(15.0)
	if a < 0.1 || (a -15.0).abs < 0.1
		tooltip = @tip_angle + " = " + sprintf("%3.0f ", dangle) + "\°"
		inftype = 'D'
		color = @colinf_Angle
	else
		tooltip = ""
		inftype = ""
		color = @colinf_None
	end	
	return validate_direction(view, parcours, vecref, color, tooltip, inftype)
end

#check if the parcours is within a plane defined by axes
def close_to_plane(view, parcours, vecdir, normal, color, tooltip)
	return unless vecdir.valid? && normal.valid?
	normal = normal.normalize
	face = parcours[0].face
	#return false if face == nil || face.normal.parallel?(normal)
	return false if face == nil || ((face.normal.normalize % normal).abs > OFS_INFERENCE_PROXIMITY)
	origin = @mark_origin.pt
	ptright = origin.offset vecdir, 10
	ptproj = ptright.project_to_plane [origin, normal]
	vecref = origin.vector_to(ptproj).normalize
	ps = vecdir % vecref
	return false if (ps.abs < OFS_INFERENCE_PROXIMITY)
	
	#Close vector - computing new end point and parcours
	return validate_direction(view, parcours, vecref, color, tooltip, "P")
end

#check if the parcours is close to a particular vector <vec>
def close_to_vector(view, parcours, vecdir, vecref, color, tooltip)
	vecref = vecref.normalize
	ps = vecdir % vecref
	vecref = vecref.reverse if ps < 0
	return false if (ps.abs < OFS_INFERENCE_PROXIMITY)
	
	#Close vector - computing new end point and parcours
	return validate_direction(view, parcours, vecref, color, tooltip, "V")
end

#Force inference in a particular diretion
def force_inference(parcours, vecdir)
	return unless @vecdir
	d = length_of_parcours parcours
	vecref = @vecdir
	vecref = vecref.reverse if vecdir % vecref < 0
	parc = Junction.to_distance @mark_origin, vecref, d
	@mark_end = parc.last
	@parcours = parc
end

#Impose a direction perpendicular to <vecdir>
def impose_axis(view, parcours, vecdir)
	return false unless @axis_forced
	d = length_of_parcours parcours
	face = parcours[0].face
	
	#Make sure the direction is compatible with the face
	vecref = @axis_forced
	if face
		normal = face.normal
		ps = normal.normalize % vecref
		return false if ps.abs > 0.90
	end
	ps = vecref.normalize % vecdir.normalize
	if ps.abs < 0.1
		origin = @mark_origin.pt
		p1 = view.screen_coords origin
		p2 = view.screen_coords origin.offset(vecdir, d)
		p3 = view.screen_coords origin.offset(vecref, d)
		d1 = p1.distance p2
		d = view.pixels_to_model d1, origin 
		ps = p1.vector_to(p2).normalize % p1.vector_to(p3).normalize
	end	
	return false if ps.abs < 0.1
	vecref = vecref.reverse if ps < 0
	parc = Junction.to_distance @mark_origin, vecref, d * ps.abs
	@mark_end = parc.last
	@parcours = parc
	@color = Couleur.color_vector vecref, "black", face
	true
end

#Impose a direction perpendicular to <vecdir>
def impose_normal(parcours, vecdir)
	return false unless @normal_imposed && @normal_imposed.valid?
	d = length_of_parcours parcours
	vecref = (@normal_imposed * vecdir) * @normal_imposed
	vecref = vecref.reverse if vecdir % vecref < 0
	ps = vecref.normalize % vecdir.normalize
	parc = Junction.to_distance @mark_origin, vecref, d * ps
	@mark_end = parc.last
	@parcours = parc
	@color = "black"
	true
end

#Compute angle with previous direction in the range 0-360 degrees
def compute_angle_with_prev_direction(view, vecdir)
	return nil unless @vecdir_prev
	angle = @vecdir_prev.angle_between vecdir
	ps = (@vecdir_prev * vecdir) % view.camera.direction
	angle = (DEUX_PI - angle) if ps > 0
	@angle_direction = angle
end

#Force inference in a particular diretion
def force_angle_direction(parcours, vecdir)
	return unless @angle_vector
	d = length_of_parcours parcours
	vecref = @angle_vector
	vecref = vecref.reverse if vecdir % vecref < 0
	parc = Junction.to_distance @mark_origin, vecref, d
	@mark_end = parc.last
	@parcours = parc
end

def set_force_angle_direction(angle)
	set_angle_direction angle
	@angle_forced = true
end

def set_angle_direction(angle)
	return unless @vecdir_prev && @mark_origin && @parcours && @parcours.length > 1
	d = length_of_parcours @parcours
	vecdir = OFSG.rotate_vector @mark_origin, @vecdir_prev, angle, @planedef
	parcours = Junction.to_distance @mark_origin, vecdir, d
	set_parcours parcours
	@angle_direction = angle
	@angle_vector = parcours[0].pt.vector_to parcours[1].pt
end

#return the angle with previous direction between 0 and 360 degrees
def get_angle_direction
	(@angle_direction) ? @angle_direction.modulo(DEUX_PI) : nil
end

#Compute the length of a parcours
def length_of_parcours(parcours)
	nb = parcours.length - 2
	len = 0.0
	for i in 0..nb
		len += parcours[i].pt.distance(parcours[i+1].pt)
	end	
	len
end
	
def normal_at_origin
	face = @mark_origin.face
	normal = (face) ? face.normal : @planedef
	vcamera = Sketchup.active_model.active_view.camera.direction
	normal = normal.reverse if normal % vcamera < 0
	normal
end
	
end	#class LinePicker

#--------------------------------------------------------------------------------------------------------------
# Class ColorLine: Manage some utilities for colors
#--------------------------------------------------------------------------------------------------------------			 				   

class Couleur

#compute color based on a vector
def Couleur.color_vector(vec, colordef=nil, face=nil)
	colordef = "black" unless colordef
	if (vec == nil || vec.length == 0)
		color = colordef
	elsif (vec.parallel? X_AXIS)
		color = "red"
	elsif (vec.parallel? Y_AXIS)
		color = "green"
	elsif (vec.parallel? Z_AXIS)
		color = "blue"
	else
		color = colordef
	end
	
	return Couleur.color_at_face(color, face)		
end

#Compute the color based on vector and face, possibly changing the color so that it can be seen
def Couleur.color_at_face(color, face)	
	return color unless face
	view = Sketchup.active_model.active_view
	material = (view.camera.direction % face.normal <= 0) ? face.material : face.back_material
	return color unless material
	Couleur.revert_color color, material.color
end

def Couleur.revert_color(color, face_color)	
	color = Sketchup::Color.new(color) unless color.kind_of?(Sketchup::Color)
	prox = 100
	return color if ((color.red - face_color.red).abs > prox)
	return color if ((color.blue - face_color.blue).abs > prox)
	return color if ((color.green - face_color.green).abs > prox)
	Sketchup::Color.new 255 - color.red, 255 - color.green, 255 - color.blue 
end

end	# class Couleur

#--------------------------------------------------------------------------------------------------------------
# Class ProtractorShape: Input tool to show angle selection
#--------------------------------------------------------------------------------------------------------------			 				   
		
class ProtractorShape

def initialize
	@origin = nil
	
	#Basic colors
	@black_color = Sketchup::Color.new "black"
	@green_color = Sketchup::Color.new "lawngreen"
	@blue_color = Sketchup::Color.new "blue"
	@red_color = Sketchup::Color.new "red"
	@gray_color = Sketchup::Color.new "gray"
	
	#geometry of the protractor
	@bigcircle = []
	@graduations = []
	@inner_up = []
	@inner_down = []
	n = 24
	pi = Math::PI
	radius = 200.cm
	fact_grad = 0.9
	fact_inner = 0.75
	limit = Math::sin(pi / 12)
	
	#defining the Protractor
	for i in 0..n
		angle = 2 * pi * i / n
		cosinus = Math::cos angle
		sinus = Math::sin angle
		pt_ext = Geom::Point3d.new radius * cosinus, radius * sinus, 0
		@bigcircle.push pt_ext
		pt_int = Geom::Point3d.new radius * fact_grad * cosinus, radius * fact_grad * sinus, 0
		@graduations.push pt_int
		@graduations.push pt_ext
		if (sinus.abs >= limit)
			pt_ext = Geom::Point3d.new radius * fact_inner * cosinus, radius * fact_inner * sinus, 0
			if (sinus > 0.0)
				@inner_up.push pt_ext
			else
				@inner_down.push pt_ext
			end	
		end
	end
	@inner_up.push @inner_up[0]
	@inner_down.push @inner_down[0]
end

#specify the placement of the Protactor
def set_placement(mark_origin, normal, vecdir)
	#@mark_origin = mark_origin
	@origin = mark_origin.pt
	view = Sketchup.active_model.active_view
	@normal = (normal % view.camera.direction >= 0) ? normal : normal.reverse
	@vecdir = vecdir
	@color = Couleur.color_vector @normal, "black", mark_origin.face
end

#compute the angle
def get_angle
	return 0 unless @normal.valid?
	@axesD = @normal.axes
	angle = @axesD[0].angle_between @vecdir
	angle = -angle if @vecdir % @axesD[1] < 0
	angle
end

#compute the right transformation
def compute_transformation
	return nil unless @normal.valid?
	tdir = Geom::Transformation.rotation @origin, @normal, get_angle
	tdir * Geom::Transformation.axes(@origin, @axesD[0], @axesD[1], @axesD[2])
end

#Draw method for tool
def draw(view)
	return unless @origin
	
	#Compute the right scale to keep the protractor the same size
	size = view.pixels_to_model 1, @origin 	
	tdir = compute_transformation
	return unless tdir
	t = tdir * Geom::Transformation.scaling(size)
	
	#draw the protractor
	view.drawing_color = @color 
	view.line_stipple = ""
	view.line_width = 1

	pts = []
	@bigcircle.each { |pt| pts.push(t * pt)}
	@radius_bigcircle = @origin.distance pts[0]
	draw2d view, pts, GL_LINE_STRIP		#bug in Sketchup, need a first dummy drawing in 2d
	draw2d view, pts, GL_LINE_STRIP
	
	pts = []
	@inner_up.each { |pt| pts.push(t * pt)}
	draw2d view, pts, GL_LINE_STRIP
	
	pts = []
	@inner_down.each { |pt| pts.push(t * pt)}
	draw2d view, pts, GL_LINE_STRIP
	
	pts = []
	@graduations.each { |pt| pts.push(t * pt)}
	draw2d view, pts, GL_LINES

end

def draw2d(view, pts, type)
	pts2d = []
	pts.each { |pt| pts2d.push view.screen_coords(pt) }
	view.draw2d type, pts2d
end

#Return the direction for inference
def inference(view, pt, vecini, angle_sec)
	return nil unless @radius_bigcircle && @normal.valid?
	angle = @vecdir.angle_between vecini
	factor = @origin.distance(pt) / @radius_bigcircle
	anglenew = adjust_angle angle, factor
	return nil unless anglenew

	diffangle = angle - anglenew
	if (angle_sec >= Math::PI)
		diffangle = -diffangle
		anglenew = DEUX_PI - anglenew
	end 
	tdir = Geom::Transformation.rotation @origin, @normal, diffangle
	return [vecini.transform(tdir), anglenew]
end

#Adjust angleto round value,depending on distance of input point to Origin
def adjust_angle(angle, factor)
	fac = factor.to_i + 1
	incr = (fac <= 2) ? 15.0 : 5.0
	tolerance = 1.0 / 2.0 / fac
	dangle = angle.radians
	dangle = dangle.round if fac < 4
	a = dangle / incr
	around = a.round
	afinal = ((a - around).abs < tolerance) ? around * incr : dangle
	(afinal) ? afinal.degrees : nil
end

end	#class ProtractorShape

#--------------------------------------------------------------------------------------------------------------
# Class HELP: Uitlities for managin Script help
#--------------------------------------------------------------------------------------------------------------			 				   
				 	
class HELP

#check older files
def HELP.check_older_scripts
	MYPLUGIN.check_older_scripts
end

end	#class HELP
	
end #module SUToolsOnSurface
