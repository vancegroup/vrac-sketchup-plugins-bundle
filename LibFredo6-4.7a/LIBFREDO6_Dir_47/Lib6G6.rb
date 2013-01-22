=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Jan. 2009 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6G6.rb
# Original Date	:  03 Dec 2008 - version 3.0
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  Contains some standalone generic geometric methods
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module G6

#---------------------------------------------------------------------------------------------------------------------------------
# Grouponents, that is: Group or Component Instances
#---------------------------------------------------------------------------------------------------------------------------------

#check is an entity is a Group or a component instance
def G6.is_grouponent?(e)
	e.instance_of?(Sketchup::ComponentInstance) || e.instance_of?(Sketchup::Group)
end

#Detremine the definition of of component or group
def G6.grouponent_definition(e)
	return e.definition if e.instance_of?(Sketchup::ComponentInstance)
	return e.entities.parent if e.instance_of?(Sketchup::Group)
	Sketchup.active_model
end

#Check if a group is unique
def G6.is_group_unique?(g)
	entity = g.entities.find { |e| e.class != Sketchup::Group && e.class != Sketchup::ComponentInstance }
	return true unless entity.respond_to?(:parent)
	definition = entity.parent
	return true unless definition
	definition.count_instances == 1
end

#return the entities, either for a Group or for a component
def G6.grouponent_entities(entity)
	return Sketchup.active_model.active_entities if !entity || entity == Sketchup.active_model
	(entity.class == Sketchup::ComponentInstance) ? entity.definition.entities : entity.entities
end

# Compute the box around a component with offset
# Return the segment lines (list of pairs) to be drawn by view.draw GL_LINES
def G6.grouponent_box_lines(view, compo, tr=nil, pix=nil)
	pix = 1 unless pix
	tr = Geom::Transformation.new unless tr
	bb = G6.grouponent_definition(compo).bounds
	pts = [0, 1, 3, 2, 4, 5, 7, 6].collect { |i| tr * bb.corner(i) }
	ptsbox = pts.clone
	
	if pix > 0
		ptmid = Geom.linear_combination 0.5, pts[0], 0.5, pts[-1]
		size = view.pixels_to_model pix, ptmid
		
		normal = pts[0].vector_to pts[4]
		normal = (pts[0].vector_to pts[1]) * (pts[0].vector_to pts[2]) unless normal.valid?
		return [] unless normal.valid?
		[0, 1, 2, 3].each { |i| ptsbox[i] = ptsbox[i].offset normal, -size }
		[4, 5, 6, 7].each { |i| ptsbox[i] = ptsbox[i].offset normal, size }

		normal = pts[0].vector_to pts[1]
		normal = (pts[0].vector_to pts[3]) * (pts[0].vector_to pts[4]) unless normal.valid?
		return [] unless normal.valid?
		[0, 3, 4, 7].each { |i| ptsbox[i] = ptsbox[i].offset normal, -size }
		[1, 2, 5, 6].each { |i| ptsbox[i] = ptsbox[i].offset normal, size }

		normal = pts[0].vector_to pts[3]
		normal = (pts[0].vector_to pts[4]) * (pts[0].vector_to pts[1]) unless normal.valid?
		return [] unless normal.valid?
		[0, 1, 4, 5].each { |i| ptsbox[i] = ptsbox[i].offset normal, -size }
		[2, 3, 6, 7].each { |i| ptsbox[i] = ptsbox[i].offset normal, size }
	end
	
	[0, 1, 1, 2, 2, 3, 3, 0, 0, 4, 4, 5, 5, 6, 6, 7, 7, 4, 1, 5, 2, 6, 3, 7].collect { |i| ptsbox[i] } 
end

#Compute the full name of a container
def G6.grouponent_name(g)
	if g.class == Sketchup::Group
		name = "#{T6[:T_TXT_GROUP]} #{g.name}"
	elsif g.class == Sketchup::ComponentInstance
		cdef = g.definition
		if (g.name.empty?)
			imax = cdef.instances.length.to_s.length
			i = cdef.instances.rindex(g)
			inst_name = sprintf("%0#{imax}d", i+1)
		else
			inst_name = g.name
		end
		name = g.definition.name + " [#{inst_name}]"
	else
		name = 'unknown'
	end
	name
end

#---------------------------------------------------------------------------------------------------------------------------------
# Current Editing context in Open components
#---------------------------------------------------------------------------------------------------------------------------------

#Return the Component or Group instance currently open (or nil if at top level)
def G6.which_instance_opened
	model = Sketchup.active_model
	ee = model.active_entities
	mm = ee.parent
	
	#Current context is at the toplevel
	return nil unless mm.class == Sketchup::ComponentDefinition
	
	#Getting the instances and finding the one that has a transformation equal to Identity
	lsti = mm.instances
	return lsti[0] if lsti.length == 1
	lsti.each do |instance|
		center = instance.bounds.center
		return instance if instance.transformation * center == center
	end
	nil
end

#Find the component Instances at top level of the model that use a given Component definition
def G6.find_top_comp_where_used(cdef, lst_top=nil)
	lst_top = [] unless lst_top
	return lst_top unless cdef.instance_of?(Sketchup::ComponentDefinition)
	cdef.instances.each do |comp| 
		parent = comp.parent
		if parent.instance_of? Sketchup::Model
			lst_top.push comp unless lst_top.include?(comp)
		elsif parent.instance_of? Sketchup::ComponentDefinition
			find_top_comp_where_used parent, lst_top
		end	
	end
	lst_top
end


#determine if a component is a dynamic component
def G6.is_dynamic_component?(comp)
	(comp.attribute_dictionary "dynamic_attributes") ? true : false
end

#---------------------------------------------------------------------------------------------------------------------------------
# Geometry Operations (to account for SU7 features)
#---------------------------------------------------------------------------------------------------------------------------------

#Map the model.start_operation method, managing the optional optimization last parameter in SU7
def G6.start_operation(model, title, speedup=false, *args)
	(SU_MAJOR_VERSION < 7) ? model.start_operation(title) : model.start_operation(title, speedup, *args)
end

def G6.continue_operation(model, title, speedup=false, *args)
	model.start_operation(title, speedup, *args) if (SU_MAJOR_VERSION >= 7)
end

#Compute the wireframe for a list of entities
#return a flat list of pairs of points to be usually drawn by view.draw GL_LINES
def G6.wireframe_entities(entities, hsh_edgeID=nil)
	G6._aux_wireframe_entities entities, Geom::Transformation.new, {}, [], 'model', hsh_edgeID
end

def G6._aux_wireframe_entities(entities, t, hedges, lcomp, parent, hsh_edgeID=nil)
	return [] unless entities
	entities.each do |e|
		if e.class == Sketchup::Edge
			next if hedges[e.to_s] == parent
			hedges[e.to_s] = parent
			lcomp.push t * e.start.position, t * e.end.position
			if hsh_edgeID
				hsh_edgeID[e.entityID] = true
				hsh_edgeID[e.start.entityID] = true
				hsh_edgeID[e.end.entityID] = true
			end	
		elsif e.class == Sketchup::Face
			e.edges.each do |edge|
				next if hedges[edge.to_s] == parent
				hedges[edge.to_s] = parent
				lcomp.push t * edge.start.position, t * edge.end.position
				if hsh_edgeID
					hsh_edgeID[edge.entityID] = true
					hsh_edgeID[edge.start.entityID] = true
					hsh_edgeID[edge.end.entityID] = true
				end	
			end	
		elsif e.class == Sketchup::Group
			G6._aux_wireframe_entities e.entities, t * e.transformation, hedges, lcomp, e, hsh_edgeID	
		elsif e.class == Sketchup::ComponentInstance
			G6._aux_wireframe_entities e.definition.entities, t * e.transformation, hedges, lcomp, e, hsh_edgeID	
		end	
	end
	lcomp	
end

#Transform a vector. The method accounts for non orthogonal axes, as often the case when shearing was applied
def G6.transform_vector(vector, t)
	return vector unless vector && vector.valid? && t
	axdt = vector.axes.collect { |v| t * v }
	vec = axdt[0] * axdt[1]
	vec.length = vector.length
	vec
end

#General average based on distance measure
def G6.multi_average(lval, ldist)
	n = ldist.length - 1
	dsum = 0
	prod = []
	for i in 0..n
		prod[i] = 1
		for j in 0..n
			prod[i] *= ldist[j] unless i == j
		end
		dsum += prod[i]
	end	
	prod = prod.collect { |x| x / dsum }
	
	if lval[0].class == Array
		newval = []
		for k in 0..lval[0].length-1
			newval[k] = 0
			for i in 0..n
				newval[k] += lval[i][k] * prod[i]
			end	
		end	
	else
		newval = 0
		for i in 0..n
			newval += lval[i] * prod[i]
		end	
	end
	newval
end

#---------------------------------------------------------------------------------------------------------------------------------
# OpenGL instructions
#---------------------------------------------------------------------------------------------------------------------------------

#Process the drawing of instructions
def G6.process_GL_instructions(view, t, lgl)
	return false unless lgl && lgl.length > 0
	view.drawing_color = 'black'
	view.line_stipple = ''
	view.line_width = 1
	
	lgl.each do |ll|
		code = ll[0]
		begin
			next unless ll[1]
			if code.class == String
				G6.view_draw_text view, t * ll[1], code
			elsif code.class == String && code == 'T'
				G6.view_draw_text view, t * ll[1], ll[2]
			else
				view.drawing_color = ll[2] if ll[2]
				view.line_width = ll[3] if ll[3]			
				view.line_stipple = ll[4] if ll[4]
				pts = ll[1].collect { |pt| t * pt }
				view.draw2d ll[0], pts
			end	
		rescue
			puts "problem with draw GL"
		end
	end	
	true
end

#---------------------------------------------------------------------------------------------------------------------------------
# Text Drawing 2D
#---------------------------------------------------------------------------------------------------------------------------------

@@wid_filter = [["A-Z", 9], ["a-z", 6], [" ", 7], ["0-9", 8], [".,;:", 3]]
@@hgt_char = 16

#Compute the length in pixel of a single line text
def G6.simple_text_size(text)
	return [7, @@hgt_char] unless text
	nc = text.length
	wid = 0
	@@wid_filter.each do |ls|
		s, w = ls
		c = text.count(s)
		wid += w * c
		nc -= c
	end	
	wid += nc * 8
	wid -= 3 * text.count('il')
	wid -= 5 * text.count('I')
	[wid, @@hgt_char]
end

#Compute the length in pixel of a multi line text
def G6.text_size(text)
	return G6.simple_text_size(text) unless text
	ltx = text.split "\n"
	wtx = 0
	htx = 0
	ltx.each do |s|
		w, h = G6.simple_text_size(s)
		htx += h
		wtx = w if w > wtx
	end	
	[wtx, htx]
end

def G6.text_box_instructions(text, x, y, wid, hgt, justif=nil)
	return nil unless text
	justif = 'LT' unless justif
	ltx = text.split "\n"
	ntx = ltx.length
	ydec = 0
	xdec = 0
	
	#tStart Position for Y
	if justif =~ /B/i
		ybeg = hgt - @@hgt_char * ntx
	elsif justif =~ /H/i
		ybeg = (hgt - @@hgt_char * ntx) / 2 
	else
		ybeg = 0
	end	
	ybeg = y - ydec - ybeg
	
	#Coordinates of each line of text
	instructions = []
	ltx.each do |s|
		w, = G6.simple_text_size(s) if justif =~ /R|M/i
		if justif =~ /R/i
			xbeg = wid - w
		elsif justif =~ /M/i
			xbeg = (wid - w) / 2
		else
			xbeg = 0
		end	
		xbeg += x + xdec
		instructions.push [s, Geom::Point3d.new(xbeg, ybeg, 0)]
		ybeg -= @@hgt_char	
	end
	instructions
end

#Draw a small rectangle with the new text of the label
def G6.draw_rectangle_text(view, x, y, text, bk_color, fr_color, txdec=0, fr_width=2)
	return unless x
	hgttext = 16
	y = y - 25 - hgttext
	y = y + 40 if y < 0
	vpx = view.vpwidth
	vpy = view.vpheight
	len = text.length + txdec
	widtext = len * 7
	x = vpx - widtext - 6 if (x + widtext) > vpx
	y = vpy - hgttext - 3 if (y + hgttext) > vpy
	pts = G6.pts_rectangle x-5, y, widtext+4, hgttext + 4
	
	#Drawing the box
	view.drawing_color = bk_color
	view.draw2d GL_POLYGON, pts	
	view.line_width = fr_width
	view.line_stipple = ''
	view.drawing_color = fr_color
	view.draw2d GL_LINE_LOOP, pts
	
	#drawing the text
	hmac = (RUN_ON_MAC) ? 4 : 0
	view.draw_text Geom::Point3d.new(x, y+hmac), text
end

#Draw a small rectangle with the new text of the label
def G6.draw_rectangle_multi_text(view, x, y, text, hargs={})
	return unless x && text
	
	#Parameters
	bk_color = hargs.fetch :bk_color, 'lightyellow'
	fr_color = hargs.fetch :fr_color, 'green'
	fr_width = hargs.fetch :fr_width, 2
	dx = hargs.fetch :dx, 0
	dy = hargs.fetch :dy, 40
	xmargin = hargs.fetch :xmargin, 4
	ymargin = hargs.fetch :ymargin, 4
	justif = hargs.fetch :justif, 'LT'
	tr = hargs.fetch :tr, nil
	
	#Size of the text
	wtex, htex = G6.text_size text
	wbox = wtex + 2 * xmargin
	hbox = htex + 2 * ymargin
	
	#Positioning the box
	vpx = view.vpwidth
	vpy = view.vpheight
	ybox = y - dy
	ybox = y + dy + hbox if ybox - hbox < 0
	ybox = vpy if ybox > vpy
	xbox = x + dx
	xbox = vpx - wbox if xbox + wbox > vpx 
	xbox = 0 if xbox < 0 

	#Drawing the box
	pts = G6.pts_rectangle xbox, ybox - hbox, wbox, hbox
	
	view.drawing_color = bk_color
	view.draw2d GL_POLYGON, pts
	
	if fr_color && fr_width > 0
		view.line_width = fr_width
		view.line_stipple = ''
		view.drawing_color = fr_color
		view.draw2d GL_LINE_LOOP, pts
	end
	
	#Drawing the text
	xtex = xbox + xmargin
	ytex = ybox - ymargin
	tr = Geom::Transformation.scaling(Geom::Point3d.new(xtex, ybox - hbox/2), 1, -1, 1) unless tr
	lgl = G6.text_box_instructions text, xtex, ytex, wtex, htex, justif	
	G6.process_GL_instructions view, tr, lgl
end

#---------------------------------------------------------------------------------------------------------------------------------
# Inference Utilities
#---------------------------------------------------------------------------------------------------------------------------------

#Check whether inference can apply, given a hash table of Entity Ids
def G6.not_auto_inference?(ip, hsh_entID)
	return true unless hsh_entID
	v = ip.vertex
	e = ip.edge
	f = ip.face
	return false if (e && hsh_entID[e.entityID]) || (v && hsh_entID[v.entityID]) ||
	                (f && hsh_entID[f.entityID])
	true
end

#Determine if an inference is a true one (close to vertex) or a remote one
def G6.true_inference_vertex?(view, ip, x, y)
	vertex = ip.vertex
	return false unless vertex
	pt2d = view.screen_coords ip.transformation * vertex.position
	return false if (pt2d.x - x).abs > 10 || (pt2d.y - y).abs > 10
	true
end

#  Calculate the intersection points of a segment and a sphere
#  Credit to Paul Bourke (1992)- see http://local.wasp.uwa.edu.au/~pbourke/geometry/sphereline/
def G6.intersect_segment_sphere(pt1, pt2, center, radius)
	tolerance = 0.001.cm
   
	#Calculation
    dpx = pt2.x - pt1.x
    dpy = pt2.y - pt1.y
    dpz = pt2.z - pt1.z
   
	a = dpx * dpx + dpy * dpy + dpz * dpz
	b = 2 * (dpx * (pt1.x - center.x) + dpy * (pt1.y - center.y) + dpz * (pt1.z - center.z))
	c = center.x * center.x + center.y * center.y + center.z * center.z
	c += pt1.x * pt1.x + pt1.y * pt1.y + pt1.z * pt1.z
	c -= 2 * (center.x * pt1.x + center.y * pt1.y + center.z * pt1.z)
	c -= radius * radius
	bb4ac = b * b - 4 * a * c
   
	#NO solution
	return nil if (a.abs < tolerance || bb4ac < 0)

	#Computing the Intersection point
	sq = Math.sqrt(bb4ac)
    mu1 = (-b + sq) / (2 * a)
    mu2 = (-b - sq) / (2 * a)
	[Geom.linear_combination(1.0 - mu1, pt1, mu1, pt2), Geom.linear_combination(1.0 - mu2, pt1, mu2, pt2)]
end

#---------------------------------------------------------------------------------------------------------------------------------
# Stipple Properties
#---------------------------------------------------------------------------------------------------------------------------------

def G6.stipple_from_code(code)
	case code
	when 'D' ; '-'
	when 'U' ; '_'
	when 'P' ; '.'
	when 'A' ; '-.-'
	else ; ''
	end
end

#---------------------------------------------------------------------------------------------------------------------------------
# Edges Properties
#---------------------------------------------------------------------------------------------------------------------------------

#Dialog box for Dicing parameters - Return a list [dice, dice_format]
def G6.ask_edge_prop_filter(titletool, edge_prop)
	#Creating the dialog box
	hparams = {}
	title = ((titletool) ? titletool + ' - ' : '') + T6[:T_DLG_EdgeProp_Title]
	dlg = Traductor::DialogBox.new title
		
	enum_yesno = { 'Y' => T6[:T_DLG_YES], 'N' => T6[:T_DLG_NO] }
	ted = ' '
	dlg.field_enum "Plain", ted + T6[:T_DLG_EdgePlain], 'Y', enum_yesno
	dlg.field_enum "Soft", ted + T6[:T_DLG_EdgeSoft], 'Y', enum_yesno
	dlg.field_enum "Smooth", ted + T6[:T_DLG_EdgeSmooth], 'Y', enum_yesno
	dlg.field_enum "Hidden", ted + T6[:T_DLG_EdgeHidden], 'N', enum_yesno

	#Invoking the dialog box
	hparams["Plain"] = (edge_prop =~ /P/i) ? 'Y' : 'N'
	hparams["Soft"] = (edge_prop =~ /S/i) ? 'Y' : 'N'
	hparams["Smooth"] = (edge_prop =~ /M/i) ? 'Y' : 'N'
	hparams["Hidden"] = (edge_prop =~ /H/i) ? 'Y' : 'N'
	
	#Cancel dialog box
	return edge_prop unless dlg.show! hparams		
	
	#Transfering the parameters
	ep = []
	ep.push 'P' if hparams["Plain"] == 'Y'
	ep.push 'S' if hparams["Soft"] == 'Y'
	ep.push 'M' if hparams["Smooth"] == 'Y'
	ep.push 'H' if hparams["Hidden"] == 'Y'
	ep.join ';;'	
end

#check the filtering by edge property
def G6.edge_filter?(edge, filter)
	filter = 'P;;S;;M;;H' unless filter && filter.length > 0
	
	return false if edge.smooth? && !(filter =~ /M/i)
	return false if edge.soft? && !(filter =~ /S/i)
	return false if edge.hidden? && !(filter =~ /H/i)
	return false if !(edge.smooth? || edge.soft? || edge.hidden?) && !(filter =~ /P/i)
	true
end

#Check the filtering by edge property
def G6.edge_filter_text(filter)
	return T6[:T_DLG_EdgeAll] unless filter && filter.length > 0
	return T6[:T_DLG_EdgeAll] if filter =~ /P/i && filter =~ /S/i && filter =~ /M/i && filter =~ /H/i
	
	ls = []
	ls.push T6[:T_DLG_EdgePlain] if filter =~ /P/i
	ls.push T6[:T_DLG_EdgeSoft] if filter =~ /S/i
	ls.push T6[:T_DLG_EdgeSmooth] if filter =~ /M/i
	ls.push T6[:T_DLG_EdgeHidden] if filter =~ /H/i
	
	ls.join '+'
end

def G6.edge_prop_check_plain(prop)
	if prop == nil || prop == ''
		return 'P'
	elsif prop =~ /S|M|H/i
		lst = []
		lst.push 'S' if prop =~ /S/i
		lst.push 'M' if prop =~ /M/i
		lst.push 'H' if prop =~ /H/i
		return lst.join(';;')
	end	
	prop
end

#---------------------------------------------------------------------------------------------------------------------------------
# Geometry Utilities
#---------------------------------------------------------------------------------------------------------------------------------

#Compute a plane from 3 points
def G6.plane_by_3_points(pt1, pt2, pt3)
	vec1 = pt1.vector_to pt2
	vec2 = pt1.vector_to pt3
	[pt1, vec1 * vec2]
end

#calculate the normal to an edge of a face pointing toward the inside
def G6.normal_in_to_edge(edge, face)
	pt1 = edge.start.position
	pt2 = edge.end.position
	vec = face.normal * pt1.vector_to(pt2)
	vec.length = 1.0
	edge.reversed_in?(face) ? vec.reverse : vec
end

#Determine the intersection point between an edge and a line. return nil if no intersection
def G6.intersect_edge_line(edge, line)
	pt = Geom.intersect_line_line edge.line, line
	return nil unless pt
	ptbeg = edge.start.position
	return pt if pt == ptbeg
	ptend = edge.end.position
	return pt if pt == ptend
	(pt.vector_to(ptbeg) % pt.vector_to(ptend) < 0) ? pt : nil
end

#detremine if two edges and face for a convex corner at a vertex
def G6.convex_at_vertex(vertex, face, edge1, edge2, face2=nil)
	vother1 = edge1.other_vertex vertex
	vec1 = vertex.position.vector_to vother1.position
	vecin1 = G6.normal_in_to_edge edge1, face
	vecin2 = G6.normal_in_to_edge edge2, ((face2) ? face2 : face)
	((vec1 * vecin1) % (vecin1 * vecin2) >= 0) 
end

#Determine the bissector vector of two edges crossing at a vertex
#Origin of the returned vector is the vertex
def G6.bissector_edges_at_vertex(vertex, edge1, edge2, face)
	vother1 = edge1.other_vertex vertex
	vother2 = edge2.other_vertex vertex
	vec1 = vertex.position.vector_to vother1.position
	vec2 = vertex.position.vector_to vother2.position
	(vec1.parallel?(vec2)) ? vec1 * face.normal : Geom.linear_combination(0.5, vec1, 0.5, vec2) 
end

#Compute the oriented vector of an edge Start --> End
def G6.vector_edge(edge)
	edge.start.position.vector_to edge.end.position
end

#Compute the other edge that is bordering the given face at a given vertex
def G6.other_edge_to_face_at_vertex(vertex, edge, face)
	vertex.edges.each do |e|
		return e if e != edge && (e.faces & [face] == [face])
	end
	nil
end

#Calculate the average center of a list of point
def G6.straight_barycenter(lpt)
	return nil unless lpt && lpt.length > 0
	return lpt[0] if lpt.length == 1
	lpt = lpt[0..-2] if (lpt.first == lpt.last)
	x = y = z = 0
	lpt.each do |pt|
		x += pt.x
		y += pt.y
		z += pt.z
	end
	n = lpt.length
	Geom::Point3d.new x / n, y / n, z / n
end

#Calculate the average center of a contiguous curve
def G6.curve_barycenter(lpt)
	return nil unless lpt && lpt.length > 0
	return lpt[0] if lpt.length == 1
	lptmid = []
	dtot = 0.0
	x = y = z = 0
	for i in 1..lpt.length-1
		d = lpt[i].distance lpt[i-1]
		dtot += d
		ptmid = Geom.linear_combination 0.5, lpt[i], 0.5, lpt[i-1]
		x += ptmid.x * d
		y += ptmid.y * d
		z += ptmid.z * d
	end
	Geom::Point3d.new x / dtot, y / dtot, z / dtot
end

#Check if a curve roughly fits a plane direction according to a given factor
#Return [quasi, plane, bary], where quasi is:
#   1 if perfectly plane
#  -1 if quasi plane
#   0 if not plane
def G6.curve_quasi_plane(pts, plane=nil, bary=nil, factor=0.1)
	plane = Geom.fit_plane_to_points pts unless plane
	bary = G6.curve_barycenter pts unless bary
	return [0, plane, bary] unless plane
	d_proj = pts.collect { |pt| pt.distance_to_plane(plane) }
	delta = d_proj.max - d_proj.min
	return [1, plane, bary] if delta < 0.00001
	
	n = d_proj.length
	m = 0
	sig = 0
	d_proj.each do |d| 
		m += d 
		sig += d * d
	end	
	m /= n
	sig = Math.sqrt(sig / n - m * m)
	
	dbary = pts.collect { |pt| bary.distance pt }
	[((sig < factor * dbary.max) ? -1 : 0), plane, bary]
end

#Determine the intersection point between a segment [ptbeg, ptend] and a line. return nil if no intersection
def G6.intersect_segment_line(ptbeg, ptend, line)
	return ptbeg if ptbeg.on_line?(line)
	return ptend if ptend.on_line?(line)
	pt = Geom.intersect_line_line [ptbeg, ptend], line
	(pt && pt.vector_to(ptbeg) % pt.vector_to(ptend) < 0) ? pt : nil
end

#Calculate the intersection of 2 segments
#Segments are a pair of points
def G6.intersect_segment_segment(seg1, seg2)
	ptinter = Geom.intersect_line_line seg1, seg2
	return nil unless ptinter
	(seg1 + seg2).each { |pt| return pt if pt == ptinter }
	within1 = (ptinter.vector_to(seg1[0]) % ptinter.vector_to(seg1[1]) <= 0)
	return nil unless within1
	(ptinter.vector_to(seg2[0]) % ptinter.vector_to(seg2[1]) <= 0) ? ptinter : nil
end

#Compute the intersection of 2 segments in 3D space
#  --> Return nil if no intersection or [d, pt1, pt2] where
#         - d is an indication of proximity
#         - pt1 is the intersection point on first segment
#         - pt2 is the intersection point on second segment
def G6.segments_intersection3D(pt1beg, pt1end, pt2beg, pt2end, plane=nil)
	
	#Segments with null length or segments parallel
	vec1 = pt1beg.vector_to pt1end
	return nil unless vec1.valid?
	vec2 = pt2beg.vector_to pt2end
	return nil unless vec2.valid?
	return nil if vec1.parallel?(vec2)
	
	#True intersection
	d, pt1, pt2 = G6.proximity_segments pt1beg, pt1end, pt2beg, pt2end
	return [0, pt1, pt2] if d == 0
		
	#Plane of elevation
	plane = [ORIGIN, vec1 * vec2] unless plane
	ppt1beg, ppt1end, ppt2beg, ppt2end = [pt1beg, pt1end, pt2beg, pt2end].collect { |pt| pt.project_to_plane plane }
	
	d, = G6.proximity_segments ppt1beg, ppt1end, ppt2beg, ppt2end
	[d, pt1, pt2]
end

#Check if a set of points are coplanar
#  --> Return the plane or nil
def G6.points_coplanar?(pts)
	n = pts.length
	return nil if n < 3
	return Geom.fit_plane_to_points(pts) if n == 3
	
	n1 = [n / 2, 3].max
	n2 = [n - n1, 3].max
	plane1 = Geom.fit_plane_to_points *(pts[0..n1-1])
	plane2 = Geom.fit_plane_to_points *(pts[n-n2..n-1])
	normal1 = Geom::Vector3d.new *plane1[0..2]
	normal2 = Geom::Vector3d.new *plane2[0..2]
	(normal1.parallel?(normal2) && pts[0].on_plane?(plane2)) ? plane1 : nil
end

#Check if a point pt is within the segment [pt1, pt2]
#  --> Return true or false
def G6.point_within_segment?(pt, pt1, pt2)
	return true if pt == pt1 || pt == pt2
	vec1 = pt.vector_to pt1
	vec2 = pt2.vector_to pt
	vec1.samedirection?(vec2)
end

#Check if a segment [pt1, pt2] crosses a given plane
#  --> Return the intersection point or nil
def G6.intersect_segment_plane(pt1, pt2, plane)
	return pt1 if pt1.on_plane?(plane)
	return pt2 if pt2.on_plane?(plane)
	pt = Geom.intersect_line_plane [pt1, pt2], plane
	return pt if pt == pt1 || pt == pt2
	(pt && (pt.vector_to(pt1) % pt.vector_to(pt2) < 0)) ? pt : nil
end

#Construct the list of points dividing a segment [pt1, pt2] into n subsegments
#  --> Return the list of points (so n+1 elements)
def G6.divide_segment(pt1, pt2, nbseg)
	pts = [pt1]
	ratio = 1.0 / nbseg
	for i in 1..nbseg-1
		f = i * ratio
		pts.push Geom.linear_combination(1-f, pt1, f, pt2)
	end
	pts.push pt2
	pts
end

#Check if a point in 2d (x, y) is close to a segment in 3d (pts)
def G6.close_to_segment_2d(view, x, y, pts, prox=8)
	n = pts.length - 1
	return nil if n == 0
	ptxy = Geom::Point3d.new x, y, 0
	for i in 0..n-1
		pt1_2d = view.screen_coords pts[i]
		pt2_2d = view.screen_coords pts[i+1]
		next if pt1_2d == pt2_2d
		ptproj = ptxy.project_to_line [pt1_2d, pt2_2d]
		next if ptxy.distance(ptproj) > prox
		return i if G6.point_within_segment?(ptproj, pt1_2d, pt2_2d)
	end	
	nil
end

#Check if 2 points are close on the screen
def G6.points_close_in_pixel?(view, pt1, pt2, pixels=5)
	vpt1 = view.screen_coords pt1
	vpt2 = view.screen_coords pt2
	(vpt1.distance(vpt2) <= pixels)
end


#---------------------------------------------------------------------------------------------------------------------------------
# PROXIMITY methods: points, segments, curves
#---------------------------------------------------------------------------------------------------------------------------------

#Compute the minimum distance and proximity points between two segments	
def G6.proximity_segments(pt1beg, pt1end, pt2beg, pt2end)
	ls = Geom.closest_points [pt1beg, pt1end], [pt2beg, pt2end]
	
	pt1 = G6.proximity_fit_point_within_segment ls[0], pt1beg, pt1end
	pt2 = G6.proximity_fit_point_within_segment ls[1], pt2beg, pt2end

	pt2 = pt1.project_to_line [pt2beg, pt2end]
	pt2 = G6.proximity_fit_point_within_segment pt2, pt2beg, pt2end

	pt1 = pt2.project_to_line [pt1beg, pt1end]
	pt1 = G6.proximity_fit_point_within_segment pt1, pt1beg, pt1end
	
	[pt1.distance(pt2), pt1, pt2]
end 

#Find the closest point within the segment, given a point on the SAME line
def G6.proximity_fit_point_within_segment(pt, ptbeg, ptend)
	return pt if pt == ptbeg || pt == ptend || pt.vector_to(ptbeg) % pt.vector_to(ptend) < 0
	(pt.vector_to(ptbeg) % ptbeg.vector_to(ptend) < 0) ? ptend : ptbeg
end

#Compute the minimum distance and proximity points between a point and a segment
def G6.proximity_point_segment(pt, ptbeg, ptend)
	pt2 = pt.project_to_line [ptbeg, ptend]
	pt2 = G6.proximity_fit_point_within_segment(pt2, ptbeg, ptend)
	[pt.distance(pt2), pt, pt2]
end

#Compute the minimum distance and proximity points between two curves	
def G6.proximity_curves(pts1, pts2)	
	return nil unless pts1 && pts2 && pts1.length > 0 && pts2.length > 0
	n1 = pts1.length - 1
	n2 = pts2.length - 1
	pts1_first = pts1[0]
	pts2_first = pts2[0]
	
	#Curves reduced to a single point
	if n1 == 0
		return [pts1_first.distance(pts2_first), 1, 1, pts1_first, pts2_first] if n2 == 0
		return G6.proximity_point_curve(pts1_first, pts2)
	end
	
	if n2 == 0
		res = G6.proximity_point_curve(pts2_first, pts1)
		return [res[0], res[2], res[1], res[4], res[3]]
	end
	
	#Compute the proximity parameters between curves
	d0 = pts1_first.distance pts2_first
	res = [d0, 1, 1, pts1_first, pts2_first]
	
	for i in 1..n1
		pt1beg = pts1[i-1]
		pt1end = pts1[i]
		for j in 1..n2
			pt2beg = pts2[j-1]
			pt2end = pts2[j]
			d, pt1, pt2 = G6.proximity_segments pt1beg, pt1end, pt2beg, pt2end
			if d < d0
				res = [d, i, j, pt1, pt2]
				return res if d == 0
				d0 = d
			end
		end
	end	
	res
end

#Compute the minimum distance and proximity points between a point and a curve
def G6.proximity_point_curve(pt, pts)
	n = pts.length - 1
	
	d0 = pt.distance pts[0]
	res = [d0, 1, pt, pts[0]]
	
	for i in 1..n
		ptbeg = pts[i-1]
		ptend = pts[i]
		d, pt1, pt2 = G6.proximity_point_segment pt, ptbeg, ptend
		if d < d0
			res = [d, i, pt1, pt2]
			return res if d == 0
			d0 = d
		end
	end	
	res
end

#---------------------------------------------------------------------------------------------------------------------------------
# Mirror Transformation
#---------------------------------------------------------------------------------------------------------------------------------

#Compute the mirror of a list of points about a given plane
def G6.tr_mirror_about_plane(origin, normal)
	if normal.parallel?(Z_AXIS)
		trot = Geom::Transformation.new
	else	
		trot = Geom::Transformation.rotation origin, normal * Z_AXIS, normal.angle_between(Z_AXIS)
	end	
	ts = Geom::Transformation.scaling origin, 1, 1, -1
	trot.inverse * ts * trot
end

#---------------------------------------------------------------------------------------------------------------------------------
# SU Colors
#---------------------------------------------------------------------------------------------------------------------------------

@@sel_colors = nil
@@su_colors = nil

#Colors useful for edge selection (light colors)
def G6.color_selection(i)
	unless @@sel_colors
		@@sel_colors = ['orange', 'yellow', 'tomato', 'red', 'gold', 'lightgreen', 'coral', 'salmon', 
					    'orangered', 'sandybrown', 'greenyellow']
	end
	@@sel_colors[i.modulo(@@sel_colors.length)]
end

#Sketchup Colors
def G6.color_su(i)
	unless @@su_colors
		@@su_colors = Sketchup::Color.names.find_all do |n| 
			c = Sketchup::Color.new(n)
			g = c.red + c.blue + c.green
			g < 510 && g > 100 && g != 255
		end	
	end
	@@su_colors[i.modulo(@@su_colors.length)]
end

#Color just lighter than the edge color
def G6.color_edge_sel
	color_sel = Sketchup.active_model.rendering_options['ForegroundColor']
	dec = 80
	lc = [color_sel.red, color_sel.blue, color_sel.green].collect { |c| c + dec }
	Sketchup::Color.new *lc
end

#---------------------------------------------------------------------------------------------------------------------------------
# Edges Around a surface
#---------------------------------------------------------------------------------------------------------------------------------

#Determine all connected faces to the face (i.e. if bording edge is soft or hidden)
#note: the recursive version seems to bugsplat on big number of faces. So I use an iterative version
def G6.face_neighbours(face, hsh_faces=nil)
	lface = [face]
	hsh_faces = {} unless hsh_faces
	
	while lface.length > 0
		f = lface.shift
		next if hsh_faces[f.entityID]
		hsh_faces[f.entityID] = f
		f.edges.each do |e|
			if e.soft? || e.smooth? || e.hidden?
				e.faces.each do |ff| 
					lface.push ff unless ff == f || hsh_faces[ff.entityID]
				end	
			end	
		end
	end	
	hsh_faces.values
end

#Calculate the contour of the surface (i.e. edges with only one face)
#Return as a Hash table, indexed by entityID of edges
def G6.edges_around_face(face, hsh_good_edges=nil, hsh_bad_edges=nil)
	#calculate the nieghbour faces
	hsh_faces = {}
	hsh_good_edges = {} unless hsh_good_edges
	hsh_bad_edges = {} unless hsh_bad_edges
	G6.face_neighbours face, hsh_faces
	
	#Calculate the bordering edges
	hsh_good_edges = {}
	hsh_faces.each do |key, face|
		face.outer_loop.edges.each do |e|
			n = 0
			e.faces.each { |f| n += 1 if hsh_faces[f.entityID] }
			if (n == 1)
				hsh_good_edges[e.entityID] = e
			else
				hsh_bad_edges[e.entityID] = e
			end	
		end
	end	
	hsh_good_edges.values
end

#Compute the contours of the faces belonging to the session
def G6.contour_of_faces(hsh_or_lst_faces)
	return nil unless hsh_or_lst_faces
	
	#If a list of face is given, transform it into a hash array
	if hsh_or_lst_faces.class == Array
		hsh_faces = {}
		hsh_or_lst_faces.each { |f| hsh_faces[f.entityID] = f }
	elsif hsh_or_lst_faces.class == Hash
		hsh_faces = hsh_or_lst_faces
	else
		return nil
	end	
	
	#Computing the edges which have only one bordering face of the group of faces
	hsh_edges = {}	
	hsh_faces.each do |key, face|
		face.edges.each do |edge|
			next if hsh_edges[edge.entityID]
			n = 0
			edge.faces.each do |f|
				n += 1 if hsh_faces[f.entityID]
				break if n > 1
			end	
			hsh_edges[edge.entityID] = edge if n == 1
		end			
	end
	
	#Creating the contour as a list of lines
	contour = []
	hsh_edges.each do |key, edge|
		contour.push edge.start.position, edge.end.position
	end	
	contour
end

#Compute the angle between 2 edges at a given vertex
def G6.edges_angle_at_vertex(e1, e2, vertex)
	v1 = e1.other_vertex vertex
	v2 = e2.other_vertex vertex
	vec1 = vertex.position.vector_to(v1).normalize
	vec2 = vertex.position.vector_to(v2).normalize
	vec1.angle_between vec2
end

#Compute the normal to 2 edges
def G6.edges_normal(e1, e2)
	vec1 = e1.start.position.vector_to e1.end.position
	vec2 = e2.start.position.vector_to e2.end.position
	vec1 * vec2
end

#Test if an edge is Plain
def G6.edge_plain?(e)
	!(e.smooth? || e.soft? || e.hidden?)
end

#Test is an edge is a diagonal
def G6.edge_is_diagonal?(edge)
	!edge.casts_shadows?
end

#Mark an edge is a diagonal
def G6.mark_diagonal(edge)
	edge.casts_shadows = !edge.casts_shadows?
end

#Find non-cloinear vertices on a face
def G6.face_best_three_vertices(face)
	vertices = face.vertices
	v0 = vertices[0]
	v1 = vertices[1]
	vertices[2..-1].each do |vx|
		return [v0, v1, vx] unless vx.position.on_line?([v0.position, v1.position])
	end
	vertices[0..2]
end

#Calculate the list of edges in order from a sequence of vertices	
def G6.edges_from_vertices_in_sequence(lvx)
	ledges = []
	for i in 0..lvx.length-2
		edge = lvx[i].common_edge lvx[i+1]
		ledges.push edge if edge
	end	
	ledges
end

#Calculate the list of vertices in order from a sequence of edges	
def G6.vertices_from_edges_in_sequence(ledges, ptfirst=nil)
	edge0 = ledges[0]
	vx0 = (edge0.end.position == ptfirst) ? edge0.end : edge0.start 
	lvx = [vx0]
	ledges.each { |edge| lvx.push edge.other_vertex(lvx.last) }	
	lvx
end

#---------------------------------------------------------------------------------------------------------------------------------
# Viewport drawing utilities
#---------------------------------------------------------------------------------------------------------------------------------

#Draw a text in a view (with correction of Y for Mac)
@@is_mac = (RUBY_PLATFORM =~ /darwin/i)
def G6.view_draw_text(view, pt, text)
	if @@is_mac 
		pt = pt.clone
		pt.y += 3
	end
	view.draw_text pt, text
end

#Draw all selected edges
def G6.draw_lines_with_offset(view, lpt, color, width, stipple, pix=1)
	return if lpt.length == 0
	lpt = lpt.collect { |pt| G6.small_offset view, pt, pix }
	view.line_width = width
	view.line_stipple = stipple
	view.drawing_color = color
	view.draw GL_LINES, lpt
end

def G6.draw_gl_with_offset(view, gl_code, lpt, pix=1)
	return if lpt.length < 2
	lpt = lpt.collect { |pt| G6.small_offset view, pt, pix }
	view.draw gl_code, lpt
end

#Calculate the point slightly offset to cover the edges
def G6.small_offset(view, pt, pix=1)
	pt2d = view.screen_coords pt
	ray = view.pickray pt2d.x, pt2d.y
	vec = ray[1]
	size = view.pixels_to_model pix.abs, pt
	size = -size if pix < 0
	pt.offset vec, -size
end

#Compute the points of a square centered at x, y with side 2 * dim
def G6.pts_square(x, y, dim)
	pts = []
	pts.push Geom::Point3d.new(x-dim, y-dim)
	pts.push Geom::Point3d.new(x+dim, y-dim)
	pts.push Geom::Point3d.new(x+dim, y+dim)
	pts.push Geom::Point3d.new(x-dim, y+dim)
	pts
end

#Compute the points of a square centered at x, y with side 2 * dim
def G6.pts_rectangle(x, y, dimx, dimy)
	pts = []
	pts.push Geom::Point3d.new(x, y)
	pts.push Geom::Point3d.new(x+dimx, y)
	pts.push Geom::Point3d.new(x+dimx, y+dimy)
	pts.push Geom::Point3d.new(x, y+dimy)
	pts
end

#Compute the points of a square centered at x, y with side 2 * dim
def G6.pts_triangle(x, y, dim=2, vdir=Y_AXIS)
	pts = []
	pts.push Geom::Point3d.new(x-dim, y-dim)
	pts.push Geom::Point3d.new(x+dim, y-dim)
	pts.push Geom::Point3d.new(x, y+dim)
	
	angle = Y_AXIS.angle_between vdir
	angle = -angle if (Y_AXIS * vdir) % Z_AXIS < 0
	return pts if angle == 0
	
	ptmid = Geom::Point3d.new x, y, 0
	t = Geom::Transformation.rotation ptmid, Z_AXIS, angle
	pts.collect { |pt| t * pt }
end

#Compute the points of a circle centered at x, y with radius
def G6.pts_circle(x, y, radius, n=12)
	pts = []
	angle = Math::PI * 2 / n
	for i in 0..n
		a = angle * i
		pts.push Geom::Point3d.new(x + radius * Math.sin(a), y + radius * Math.cos(a))
	end	
	pts
end

#Compute the points of a cross centered at x, y with half-length
#Return the 4 poinst in sequences for use by GL_LINES
def G6.pts_cross(x, y, half_length)
	pt1 = Geom::Point3d.new x - half_length, y, 0
	pt2 = Geom::Point3d.new x + half_length, y, 0
	pt3 = Geom::Point3d.new x, y + half_length, 0
	pt4 = Geom::Point3d.new x, y - half_length, 0
	[pt1, pt2, pt3, pt4]
end

#Compute the quads of a Bounding Box
def G6.bbox_quads_lines(bbox)
	corners = []
	for i in 0..7
		corners[i] = bbox.corner i
	end
	if corners[4] == corners[0]
		lq = [0, 1, 3, 2]		
		ll = [0, 1, 1, 3, 3, 2, 2, 0]
	else
		lq = [0, 1, 3, 2, 0, 1, 5, 4, 1, 3, 7, 5, 3, 2, 6, 7, 2, 0, 4, 6, 4, 5, 7, 6]
		ll = [0, 1, 1, 3, 3, 2, 2, 0, 0, 4, 1, 5, 2, 6, 3, 7, 4, 5, 5, 7, 7, 6, 6, 4]
	end	
	[lq.collect { |i| corners[i] }, ll.collect { |i| corners[i] }]
end

#--------------------------------------------------------------------------------
# UV Management
#--------------------------------------------------------------------------------

#Get the real UV at a given 3d Point
def G6.uv_at_point(face, pt, recto, tw=nil)
	unless tw
		@tw = Sketchup.create_texture_writer unless @tw
		tw = @tw
	end	
	uvh = face.get_UVHelper(true, true, tw)
	uv = (recto) ? uvh.get_front_UVQ(pt) : uvh.get_back_UVQ(pt)
	Geom::Point3d.new uv.x / uv.z, uv.y / uv.z, 1
end

#Get the real UV at a given list of 3d Point
def G6.uv_at_points(face, lpt, recto, tw=nil)
	unless tw
		@tw = Sketchup.create_texture_writer unless @tw
		tw = @tw
	end	
	uvh = face.get_UVHelper(true, true, tw)
	luv = []
	if recto
		lpt.each { |pt| luv.push uvh.get_front_UVQ(pt) }
	else
		lpt.each { |pt| luv.push uvh.get_back_UVQ(pt) }
	end
	luv.collect { |uv| Geom::Point3d.new(uv.x / uv.z, uv.y / uv.z, 1) }
end

#---------------------------------------------------------------------------------------------------------------------------------
# Sketchup Capability
#      - M1 = 8.0.4810+
#	- M2 = 8.0.11751+
#---------------------------------------------------------------------------------------------------------------------------------

def G6.suversion
	Sketchup.version =~ /(.+)\.(.+)\.(.+)/
	[$1.to_i, $2.to_i, $3.to_i]
end

def G6.suversion_after_8M1
	if @suafter_8M1 == nil
		major, minor, build = G6.suversion
		@suafter_8M1 = (major >= 8 && minor >= 0 && build >= 4810)
	end	
	@suafter_8M1
end	

def G6.suversion_after_8M2
	if @suafter_8M2 == nil
		major, minor, build = G6.suversion
		@suafter_8M2 = (major >= 8 && minor >= 0 && build >= 11751)
	end	
	@suafter_8M2
end	

#Check if the current version of SU can display polygons with color (>= SU 8.0 M1)
def G6.su_capa_color_polygon ; G6.suversion_after_8M1 ; end

#---------------------------------------------------------------------------------------------------------------------------------
# Drawing utilities
#---------------------------------------------------------------------------------------------------------------------------------

def G6.draw_face(view, face, color, t)
	return unless face && color
	mesh = face.mesh
	pts = mesh.points
	triangles = []
	mesh.polygons.each do |p|
		triangles += p.collect { |i| t * pts[i.abs-1] }
	end
	view.drawing_color = color
	view.draw GL_TRIANGLES, triangles
end

def G6.face_triangles(face, t)
	return [] unless face
	mesh = face.mesh
	pts = mesh.points
	triangles = []
	mesh.polygons.each do |p|
		triangles += p.collect { |i| t * pts[i.abs-1] }
	end
	triangles
end

def G6.face_polygons(face, t)
	return [] unless face
	mesh = face.mesh
	pts = mesh.points
	polygons = []
	mesh.polygons.each do |p|
		polygons.push p.collect { |i| t * pts[i.abs-1] }
	end
	polygons
end

#---------------------------------------------------------------------------------------------------------------------------------
# Sun Shadow
#---------------------------------------------------------------------------------------------------------------------------------

@@shadow_props = []

#Set or restore the option for shadow setting
#this is needed in SU 7 to make surfaces black when drawn because of a bug in the SU API
def G6.set_sun(shad=nil)
	return unless SU_MAJOR_VERSION >= 7 && Sketchup.version < '8.0.4811'
	shinfo = Sketchup.active_model.shadow_info
	props = ['UseSunForAllShading', 'Light', 'Dark', 'DisplayShadows']
	if @@shadow_props.empty?
		@@shadow_props = props.collect { |a| shinfo[a] }
	end	
	if shad
		shinfo['UseSunForAllShading'] = true
		shinfo['Light'] = 0
		shinfo['Dark'] = 100
		shinfo['DisplayShadows'] = false
	else
		props.each_with_index { |a, i| shinfo[a] = @@shadow_props[i] }
		@@shadow_props = []
	end	
end

@@shadow_toggled_once = nil

#Check if Shadow Switch on / off has been done once - This is only for SU7 and because of a bug in the SU API concerning surface colors
def G6.shadow_toggled_once?
	return true if SU_MAJOR_VERSION < 7 || @@shadow_toggled_once
	@@shadow_toggled_once = true
	false
end

#---------------------------------------------------------------------------------------------------------------------------------
# Curl - Edge chaining methods
#---------------------------------------------------------------------------------------------------------------------------------

#Compute the total length of a curve
def G6.curl_length(pts)
	d = 0.cm
	for i in 1..pts.length-1
		d += pts[i-1].distance pts[i]
	end
	d
end

#Evaluate a range specification as a range
def G6.range(range, ibeg, iend)
	if range == nil
		range = ibeg..iend
	elsif range.class == Fixnum
		range = (range < ibeg && ipos > iend) ? ibeg..iend : range..range
	end
	range
end

#Compute the triplet a points around one or at each points of the curve (based on ipos)
#  --> return a list of points triplet [pt1, pt2, pt3] where
#          - pt2 is the point of the curve
#          - pt1 is the previous point which is different from pt2 or nil
#          - pt3 is the next point which is different from pt2 or nil
def G6.curl_triplets(crvpts, range=nil)
	nb = crvpts.length
	ncrv = nb - 1
	loop = (crvpts.first == crvpts.last)

	ltriplets = []
	range = G6.range range, 0, ncrv
	
	for i in range
		pt1 = pt3 = nil
		pt2 = crvpts[i]
		for j in 1..ncrv
			k = i + j
			k -= ncrv if k > ncrv && loop
			break if k > ncrv
			pt3 = crvpts[k]
			break unless pt3 && pt3 == pt2
		end	
		for j in 1..ncrv
			k = i - j
			k += ncrv if k < 0 && loop
			break if k < 0
			pt1 = crvpts[k]
			break unless pt1 && pt1 == pt2
		end	
		pt1 = nil if pt1 == pt2
		ltriplets[i] = [pt1, pt2, pt3]
	end
	ltriplets
end

#Compute the mid point of a curl
def G6.curl_mid_point(pts)
	n = pts.length - 1
	return pts[0] if n == 0
	return Geom.linear_combination(0.5, pts[0], 0.5, pts[1]) if n == 1
	d = 0
	tdist = [0]
	for i in 1..n
		d += pts[i].distance(pts[i-1])
		tdist.push d
	end
	mid_dist = tdist.last * 0.5
	return pts[0] if mid_dist == 0
	
	ibeg = 1
	for i in 1..n
		if tdist[i] >= mid_dist 
			ratio = (tdist[i] - mid_dist) / (tdist[i] - tdist[i-1])
			return Geom.linear_combination(ratio, pts[i-1], 1 - ratio, pts[i])
		end	
	end
	pts[n/2]
end

#Sample points on a curve based on a division by a number n
def G6.curl_sample(pts, n)
	dtot = G6.curl_length pts
	delta = dtot / n
	
	lspt = [pts[0]]
	d = 0
	dcur = delta
	
	for i in 0..pts.length-2
		dseg = pts[i].distance pts[i+1]
		d += dseg
		while true
			break if d <= dcur
			r = (d - dcur) / dseg
			lspt.push Geom.linear_combination(r, pts[i], 1-r, pts[i+1])
			dcur += delta
		end	
	end
	lspt.push pts.last
	lspt
end

#Determine if two open curves must be joined by beg-beg or beg-end
#   Return 1 if beg-beg
#   Return -1 if beg-end
def G6.curl_trigo_sense(pts1, pts2)
	n = 10
	spt1 = G6.curl_sample pts1, n
	spt2 = G6.curl_sample pts2, n
	spt2r = spt2.reverse
	
	dsum = dsum_rev = 0
	for i in 0..n
		dsum += spt1[i].distance(spt2[i])
		dsum_rev += spt1[i].distance(spt2r[i])
	end
	
	(dsum <= dsum_rev) ? 1 : -1
end

#Check if a sequence of points is aligned
def G6.curl_is_aligned?(pts)
	n = pts.length - 1
	return true if n < 2
	vecprev = nil
	for i in 1..n
		vec = pts[i-1].vector_to pts[i]
		next unless vec.valid?
		if vecprev
			return false unless vec.parallel?(vecprev)
		end	
		vecprev = vec
	end
	true
end

#Get theTOS attribute for an edge - nil if not part of a TOS curve
def G6.curl_tos(edge)
	edge.get_attribute 'skp', 'ToolOnSurface'
end

#Compute the list of edges belonging to a curl  or a curve from a given edge
def G6.curl_edges(edge)
	tos_attr = G6.curl_tos(edge)
	if tos_attr
		hsh = { edge.entityID => edge }
		ls = G6.curl_tos_extend edge, tos_attr, hsh
		while !ls.empty?
			ll = []
			ls.each { |e| ll += G6.curl_tos_extend(e, tos_attr, hsh) }
			ls = ll
		end
		return hsh.values	
	end
	curve = edge.curve
	return [edge] unless curve
	curve.edges
end

#Compute the list of edges belonging to a curl from a given edge
def G6.curl_tos_extend(edge, tos_attr, hsh_edges)
	ls = []
	[edge.start, edge.end].each do |vertex|
		le = vertex.edges.find_all { |e| !hsh_edges[e.entityID] &&  G6.curl_tos(e) == tos_attr }
		if le.length == 1
			e1 = le[0]
			hsh_edges[e1.entityID] = e1
			ls.push e1
		end	
	end
	ls
end

#Compute the edges connected to an edge.
#This function is required because 'all_connected' method has a side effect to deactivate the visibility of the selection
def G6.curl_all_connected(edge)
	hsh_v = {}
	hsh_e = {}
	vstart = edge.start
	all_v = [vstart]
	lst_v = [vstart]
	hsh_v[vstart.entityID] = vstart
	while true
		new_v = []
		lst_v.each do |vertex|
			vertex.edges.each do |e|
				v = e.other_vertex vertex
				unless hsh_v[v.entityID]
					new_v.push v 
					hsh_v[v.entityID] = v
				end	
			end
		end	
		break if new_v.length == 0
		lst_v = new_v.clone
		all_v += new_v
	end
	
	all_v.each do |v|
		v.edges.each do |e|
			hsh_e[e.entityID] = e
		end
	end	
	hsh_e.values
end

#extend selection in follow mode for edge at vertex
def G6.curl_follow_extend(edge, anglemax, stop_at_crossing=false, &proc)
	common_normal = nil
	ls_edges = []
	[edge.start, edge.end].each do |vertex|
		edgenext = edge
		while edgenext
			le = vertex.edges.to_a.find_all { |ee| ee != edgenext && G6.edge_plain?(ee) }
			len = le.length
			if len == 1
				e = le[0]
				an = Math::PI - G6.edges_angle_at_vertex(edgenext, e, vertex)
				ls = (an > anglemax) ? [] : [[an, e]]
			elsif len > 0 && stop_at_crossing
				break
			else	
				le = vertex.edges.to_a.find_all { |ee| ee != edgenext } if len == 0 ####
				ls = []
				le.each do |e|
					next if e == edgenext
					next if proc && !proc.call(e)
					an = Math::PI - G6.edges_angle_at_vertex(edgenext, e, vertex)
					next if an > anglemax
					if common_normal && common_normal.valid?
						vn = G6.edges_normal(e, edgenext)
						if vn.valid? && vn.parallel?(common_normal)
							ls.push [an, e] 
							next
						end	
					end	
					if e.common_face(edgenext)
						ls.push [an, e]
					elsif an < anglemax
						ls.push [an, e]
					end	
				end
			end
			break if ls.length == 0
			
			ls.sort! { |a1, a2| a1[0] <=> a2[0] } if ls.length > 1
			e = ls[0][1]
			break if e == edge || ls_edges.include?(e)
			common_normal = G6.edges_normal(e, edgenext) unless common_normal && common_normal.valid?
			edgenext = e
			vertex = e.other_vertex(vertex)
			ls_edges.push edgenext
			
		end	#while true
	end	#loop on end and start
	
	return ls_edges
end

#Remove the duplicated points (except if at beginning and end)
def G6.curl_deduplicate(crvpts)
	new_pts = []
	for i in 0..crvpts.length-1
		pt = crvpts[i]
		new_pts.push pt if pt != new_pts.last
	end
	new_pts
end

#Concatenate a list of sequences of points
def G6.curl_concat(lpt)
	lres = []
	lpt.each do |pts|
		lres += (pts[0] == lres.last && pts.length > 1) ? pts[1..-1] : pts
	end	
	lres	
end

#Harmonize two curves to have the same number of matching vertices
def G6.curl_harmonize(curl1, curl2, simplify_factor=0.025)
	return [curl1, curl2] if curl1 == nil || curl2 == nil

	#Special case when one curve is reduced to a single point
	if curl1.length == 1
		curl1 = Array.new curl2.length, curl1.first
		return [curl1, curl2]
	end
	if curl2.length == 1
		curl2 = Array.new curl1.length, curl2.first
		return [curl1, curl2]
	end
	
	#computing the total distance for first curve
	n1 = curl1.length
	dtot1 = 0.0
	lnorm1 = [[0.0, 0, nil]]
	for i in 1..n1-1
		dtot1 += curl1[i].distance(curl1[i-1])
		lnorm1.push [dtot1, i, nil]
	end	
	
	#computing the total distance for second curve
	n2 = curl2.length
	dtot2 = 0.0 
	lnorm2 = [[0.0, nil, 0]]
	for i in 1..n2-1
		dtot2 += curl2[i].distance(curl2[i-1])
		lnorm2.push [dtot2, nil, i]
	end	
	
	#Matching the curls
	ratio = dtot2 / dtot1
	lnorm1.each { |ll| ll[0] = ll[0] / dtot1 }
	lnorm2.each { |ll| ll[0] = ll[0] / dtot2 }

	lnorm = (lnorm1 + lnorm2).sort { |a, b| a[0] <=> b[0] }
	
	i1 = 0
	i2 = 0
	lpairs = [[curl1[0], curl2[0], 0, 0]]
	lnorm[2..-3].each do |ll|
		d = ll[0]
		j1 = ll[1]
		j2 = ll[2]
		if j1
			i1 = j1
			pt1 = curl1[i1]
			if lnorm2[i2][0] == d
				pt2 = curl2[i2]
				j2 = i2
			elsif d == 1.0
				pt2 = curl2.last
				j2 = i2 + 1
			else	
				ratio = (d - lnorm2[i2][0]) / (lnorm2[i2+1][0] - lnorm2[i2][0])
				pt2 = Geom.linear_combination 1.0 - ratio, curl2[i2], ratio, curl2[i2+1]
			end	
		elsif j2
			i2 = j2
			pt2 = curl2[i2]
			if lnorm1[i1][0] == d
				pt1 = curl1[i1]
				j1 = i1
			elsif d == 1.0
				pt1 = curl1.last
				j1 = i1 + 1
			else	
				ratio = (d - lnorm1[i1][0]) / (lnorm1[i1+1][0] - lnorm1[i1][0])
				pt1 = Geom.linear_combination 1.0 - ratio, curl1[i1], ratio, curl1[i1+1]
			end	
		end	
		lpairs.push [pt1, pt2, j1, j2]
	end
	lpairs.push [curl1[-1], curl2[-1], n1-1, n2-1]
	
	#Removing duplicates
	lpairs_final = [lpairs[0]]
	n = lpairs.length
	for i in 1..n-1
		pair = lpairs[i]
		pair_prev = lpairs_final.last
		if pair[0].distance(pair_prev[0]) == 0.0 || pair[1].distance(pair_prev[1]) == 0.0
			pair_prev[2] = pair_prev[3] = :node
		else
			lpairs_final.push pair
		end	
	end	

	#Scanning the pairs to check which one should be merged
	lmerge = []
	lp = lpairs_final
	n = lp.length - 1
	for i in 1..n
		pair_prev = lp[i-1]
		pair = lp[i]
		d1 = pair[0].distance(pair_prev[0]) / dtot1
		d2 = pair[1].distance(pair_prev[1]) / dtot2
		
		if d1 <= simplify_factor && d2 <= simplify_factor
			if pair[2] && !pair[3] && pair_prev[3] && !pair_prev[2]
			   lmerge.push [i, i-1, d1, d2]
			elsif !pair[2] && pair[3] && !pair_prev[3] && pair_prev[2]
			   lmerge.push [i-1, i, d1, d2]
			 end
		end
	end

	#Filtering the merges
	lmerge.sort! { |a, b| (a[2] + a[3]) <=> (b[2] + b[3]) }
	
	hexclude = {}
	htreated = {}
	lmerge.each do |lm|
		i1 = lm[0]
		i2 = lm[1]
		pair1 = lp[i1]
		pair2 = lp[i2]
		next if htreated[i1] || htreated[i2]
		d1 = lm[2]
		d2 = lm[3]
		if d1 < d2
			pair1[3] = :node
			pair1[1] = pair2[1]
			hexclude[i2] = true
		else
			pair2[2] = :node
			pair2[0] = pair1[0]
			hexclude[i1] = true
		end
		htreated[i1] = htreated[i2] = true
	end
	
	#Executing the merge
	lpairs_final = []
	for i in 0..lp.length-1
		lpairs_final.push lp[i] unless hexclude[i]
	end	
	
	#Rebalancing the pairs
	lp = lpairs_final
	n = lp.length - 2
	for i in 1..n
		pair_prev = lp[i-1]
		pair_next = lp[i+1]
		pair = lp[i]
		if pair[2] && pair[3] == nil
			d1 = pair_next[0].distance(pair_prev[0])
			d = pair[0].distance(pair_prev[0])
			ratio = d / d1
			pair[1] = Geom.linear_combination 1.0 - ratio, pair_prev[1], ratio, pair_next[1]
		
		elsif pair[2] == nil && pair[3]
			d2 = pair_next[1].distance(pair_prev[1])
			d = pair[1].distance(pair_prev[1])
			ratio = d / d2
			pair[0] = Geom.linear_combination 1.0 - ratio, pair_prev[0], ratio, pair_next[0]		
		end
	end
	
	#Returning the new curl value
	curl1 = lpairs_final.collect { |pair| pair[0] }
	curl2 = lpairs_final.collect { |pair| pair[1] }

	[curl1, curl2]	
end

#----------------------------------------------------------------------------
# Utilities for Curl Deformations
#----------------------------------------------------------------------------

#Compute the avreage of twin curves (assumed to have matching points)
def G6.curl_average_curve(pts1, pts2, smooth=false)
	n = pts1.length - 1
	d1 =[0.0]
	d2 =[0.0]
	iend = nil
	ibeg = nil
	for i in 1..n
		d1[i] = d1[i-1] + pts1[i-1].distance(pts1[i])
		ibeg = i if d1[i] == d1[i-1]
		d2[i] = d2[i-1] + pts2[i-1].distance(pts2[i])
		if iend == nil && d2[i] == d2[i-1]
			iend = i-1
		end	
	end	
	dtot1 = d1.last
	dtot2 = d2.last
	
	pts_res = [pts1[0]]
	for i in 1..n
		if d1[i] == 0
			ratio = 0.0
		elsif d2[i] == 0 || d2[i] == dtot2
			ratio = 1.0
		else	
			ratio1 = d1[i] / dtot1
			ratio2 = d2[i] / dtot2
			a = ratio2
			b = ratio1
			ratio = (a * ratio1 + b * ratio2) / (a + b)
			ratio = ratio1 / (1.0 + ratio1 - ratio2)
		end	
		puts "ratio too high #{ratio}" if ratio > 1
		ratio = G6.scurve_ratio ratio if smooth
		pts_res.push Geom.linear_combination(1 - ratio, pts1[i], ratio, pts2[i])
	end	
	pts_res
end

#Compute a smooth ratio between 0 and 1 (method Cubic Bezier)
def G6.scurve_ratio(t)
	3 * t * t * (1 - t) + t * t * t
end

#----------------------------------------------------------------------
# Curve Stretching
#----------------------------------------------------------------------

#Deform a sequence of points from the translation of the last point
def G6.curl_move_extremities(pts, ptbeg, ptend)
	if ptbeg == ptend
		return Array.new(pts.length, ptbeg)
	end	

	vec = pts[0].vector_to ptbeg
	if vec.valid?
		t = Geom::Transformation.translation vec
		pts = pts.collect { |pt| t * pt }
	end	
	G6.curl_move_end_point pts, ptend
end

#Deform a sequence of points from the translation of the last point
def G6.curl_move_end_point(pts, ptarget)
	ptend = pts.last
	ptbeg = pts.first
	return pts if ptend == ptarget
	return pts if ptbeg == ptarget
	
	if pts[0] == pts[1]
		return Array.new(pts.length, ptarget)
	end	
	for i in 1..pts.length-1
		puts "DOUBLE PTS = #{i} - pt = #{pts[i]}" if pts[i-1] == pts[i]
	end
	
	#Computing the base and target configuration
	vec_base = ptbeg.vector_to ptend
	vec_targ = ptbeg.vector_to ptarget
	normal = vec_base * vec_targ
	if normal.valid?
		angle = vec_base.normalize.angle_between vec_targ.normalize
		t = Geom::Transformation.rotation ptbeg, normal, angle
	else
		t = Geom::Transformation.new
	end	
	dbase = ptbeg.distance(ptend)
	dtarg = ptbeg.distance(ptarget)
	ratio = dtarg / dbase
	
	#Rotating the curl
	pts_rot = pts.collect { |pt| t * pt }
	
	#Constructing the resulting curve by stretching the segments
	pts_final = [ptbeg]
	for i in 1..pts_rot.length-1
		pt1 = pts[i-1]
		pt2 = pts[i]
		d = pt1.distance(pt2) * ratio
		puts "PT DOUBLE = #{i} - #{pts_rot[i-1]}" if pts_rot[i-1] == pts_rot[i]
		vec = pts_rot[i-1].vector_to pts_rot[i]
		pt = (vec.valid?) ? pts_final.last.offset(vec, d) : pts_final.last	
		pts_final.push pt
	end
	pts_final
end

#----------------------------------------------------------------------
# Area Calculations
#----------------------------------------------------------------------

#Area of a planar polygon (points given in 2D)
def G6.polygon_area(lpt_2d)
	area = 0.0
	for i in 0..lpt_2d.length-2
		pt1 = lpt_2d[i]
		pt2 = lpt_2d[i+1]
		area += pt1.x * pt2.y - pt2.x * pt1.y
	end
	0.5 * area.abs
end

#Calculate the area of a face, possibly with holes
def G6.face_area(face, t=nil)
	if t
		loops = face.loops.collect { |loop| loop.vertices.collect { |v| t * v.position } }
		pt1 = face.outer_loop.vertices[0].position
		normal = (t * pt1).vector_to(t * pt1.offset(face.normal, 1))
	else
		loops = face.loops.collect { |loop| loop.vertices.collect { |v| v.position } }
		pt1 = face.outer_loop.vertices[0].position
		normal = pt1.vector_to(pt1.offset(face.normal, 1))
	end

	#Finding the plane
	axes = normal.axes
	tr_axe = Geom::Transformation.axes loops[0][0], *axes
	tr_axe_inv = tr_axe.inverse
	
	#Area for outer_loop
	lpt_2d = loops[0].collect { |pt| tr_axe_inv * pt }
	lpt_2d.push lpt_2d[0]
	area = G6.polygon_area lpt_2d
	
	#Area for inner loops
	if loops.length > 1
		loops[1..-1].each do |loop|
			lpt_2d = loop.collect { |pt| tr_axe_inv * pt } 
			lpt_2d.push lpt_2d[0]
			area -= G6.polygon_area lpt_2d
		end
	end	
	area
end

#---------------------------------------------------------------------------------------------
# Utilities for picking components
#---------------------------------------------------------------------------------------------

#Find the closest edge to the mouse
def G6.closest_entity(view, ip, x, y, &check_edge_proc)
	ip_entity = [ip.vertex, ip.edge, ip.face].find { |e| e }
	return ip_entity if !ip_entity.instance_of?(Sketchup::Vertex)
	ledges = ip_entity.edges
	ledges = ledges.find_all { |e| check_edge_proc.call(e) } if check_edge_proc
	return ip.face if ledges.empty?
	return ledges[0] if ledges.length == 1
	
	#At vertex: finding the closest edge
	ls = []
	lsback = []
	tr = ip.transformation
	ptvx = tr * ip.vertex.position
	ptxy = Geom::Point3d.new x, y
	ledges.each do |edge|
		ptbeg = view.screen_coords(tr * edge.start.position)
		ptend = view.screen_coords(tr * edge.end.position)
		ptproj = ptxy.project_to_line([ptbeg, ptend])
		if G6.point_within_segment?(ptproj, ptbeg, ptend)
			ls.push [edge, ptxy.distance(ptproj)]
		else	
			lsback.push [edge, ptproj.distance(ptvx)]
		end	
	end
	if ls.length > 0
		ls.sort! { |a, b| a[1] <=> b[1] }
		return ls.first[0]
	end
	lsback.sort! { |a, b| a[1] <=> b[1] }
	lsback.first[0]
end

#Determining the component parent and the transformation
@@tr_id = Geom::Transformation.new

def G6.pick_component(view, ip, x, y, entity=nil)
	#Getting the entity, if not provided
	ip.pick view, x, y
	entity_ip = G6.closest_entity(view, ip, x, y)
	entity = entity_ip unless entity
	
	#Getting the hierachical list of groups and components
	model = Sketchup.active_model
	ll = model.raytest view.pickray(x, y)
	parent = model
	tr = @@tr_id
	if ll	
		lcomp = ll[1].reverse.find_all { |e| G6.is_grouponent?(e) }
		comp = lcomp.first
		if comp	
			lcomp.each { |c| tr = c.transformation * tr }
			parent = comp
		end	
	end
	if entity == nil || entity.parent == model || entity.parent == nil
		parent = model
		tr = @@tr_id
	elsif entity.parent != G6.grouponent_definition(parent) 
		if entity.parent.instances.length >= 1
			parent = entity.parent.instances[0]
			ph = view.pick_helper
			ph.do_pick x, y
			tr = ph.transformation_at 0
		else
			entity = nil
		end	
	end
	parent = model if model.active_entities == G6.entities_from_parent(parent)
	if tr == nil || (parent != model && tr.identity?)
		parent = model
		tr = (ip.transformation.identity?) ? @@tr_id : ip.transformation
	end	
	
	[parent, tr]
end

def G6.parent_transformation(parent)
	tr = @@tr_id
	return tr
	while true
		parent = parent.parent
		break if parent == Sketchup.active_model
		tr = parent.transformation * tr
	end
	tr
end

#Retrieve the entities from parent
def G6.entities_from_parent(parent)
	if parent.instance_of?(Sketchup::ComponentInstance)
		entities = parent.definition.entities
	elsif parent.instance_of?(Sketchup::Group)
		entities = parent.entities
	else
		entities = Sketchup.active_model.active_entities
	end
	entities	
end

#Draw the component contour if any
def G6.draw_component(view, parent, tr, default=false)
	return unless parent && parent.valid? && parent != Sketchup.active_model
	if default
		view.drawing_color = 'gray'
		if parent.instance_of?(Sketchup::ComponentInstance)
			view.line_stipple = ''
			view.line_width = 1
		else
			view.line_stipple = '-'
			view.line_width = 2
		end
	end	
	llines = G6.grouponent_box_lines(view, parent, tr)
	view.draw GL_LINES, llines unless llines.empty?
end

#Compute a losange label with lead line at position ipos of a 3d point array
#Return [pt_losange, pt1, pt2] information in 2D for drawing
def G6.compute_losange_label(view, pts, ipos=0, ratio=1, length=10)
	n = pts.length - 1
	ipos = 0 if ipos == nil || n == 0
	pt1 = pts[ipos]
	pt2 = pts[ipos-1]
	pt2 = pt1 unless pt2
	ratio = 1 if ratio == nil || ratio < 0 || ratio > 1
	ptmid = Geom.linear_combination ratio, pt1, 1-ratio, pt2
	pt2d = view.screen_coords ptmid
	pt1_2d = view.screen_coords pt1
	pt2_2d = view.screen_coords pt2
	
	#Computing the lead line
	if ratio > 0 || ipos < 3 || ipos == n
		vec = pt1_2d.vector_to pt2_2d
		vec2d = (vec.valid?) ? vec * Z_AXIS : Y_AXIS
	else	
		vec = Geom.linear_combination 0.5, pt1.vector_to(pts[ipos-1]).normalize, 0.5, pt1.vector_to(pt2).normalize
		vec2d = (vec.valid?) ? pt2d.vector_to(@view.screen_coords(pt1.offset(vec, 10))) : Y_AXIS
	end
	vec2dp = vec2d * Z_AXIS

	length = 10 unless length
	dec = length + 3
	ptend = pt2d.offset vec2d, -length
	if ptend.y < dec
		ptend = pt2d.offset vec2d, length
		dec = -dec
	end	
		
	#Compute the losange
	dec2 = dec / 2
	ptop = ptend.offset vec2d, -dec
	ptmid = ptend.offset vec2d, -dec2
	pt1 = ptmid.offset vec2dp, dec2
	pt2 = ptmid.offset vec2dp, -dec2
	pts_losange = [ptend, pt1, ptop, pt2]
	pts_losange.each { |pt| pt.z = 0 }
	
	[[pt2d, ptend], pts_losange]
end

#Draw a losange label
def G6.draw_losange_label(view, lead_line, losange, color)
	#Draw the leading line
	view.drawing_color = color
	view.line_width = 1
	view.line_stipple = '-'
	view.draw2d GL_LINE_STRIP, lead_line
	
	#Draw the losange
	pts = losange
	view.draw2d GL_QUADS, pts 
	view.line_width = 1
	view.line_stipple = ''
	view.drawing_color = 'gray'
	view.draw2d GL_LINE_LOOP, pts
end

#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
# Mouse Picking utilities (based on PickHelper)
#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------

#Determine Face, Edge and Element under the mouse
def G6.picking_under_mouse(x, y, view, precision=nil)
	ph = view.pick_helper
	(precision.class == Fixnum) ? ph.do_pick(x, y, precision) : ph.do_pick(x, y)
	
	ph_edge = ph.picked_edge
	ph_face = ph.picked_face
	ph_elt = ph.picked_element
	lst_elt = [ph_face, ph_edge, ph_elt]
				
	#Finding the parent and transformation
	lst_info = []
	lst_elt.each do |elt|
		unless elt
			lst_info.push nil
			next
		end	
		tr = nil
		parent = nil
		for i in 0..ph.count
			ls = ph.path_at(i)
			if ls && ls.include?(elt)
				parent = ls[-2]
				tr = ph.transformation_at(i)
				break
			end
		end	
		tr = @@tr_id unless tr
		lst_info.push [elt, tr, parent]
	end	
	lst_info
end

#Determine Edge under the mouse
def G6.picking_edge_under_mouse(x, y, view, precision=nil)
	ph = view.pick_helper
	(precision.class == Fixnum) ? ph.do_pick(x, y, precision) : ph.do_pick(x, y)
	
	ph_edge = ph.picked_edge
	return nil unless ph_edge
	
	#Finding the parent and transformation
	tr = nil
	parent = nil
	for i in 0..ph.count
		ls = ph.path_at(i)
		if ls && ls.include?(ph_edge)
			parent = ls[-2]
			tr = ph.transformation_at(i)
			break
		end
	end	
	[ph_edge, tr, parent]
end

#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
# ViewTracker: track if view has changed
#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------

class ViewTracker

def initialize
	@view = Sketchup.active_model.active_view
	@ptref = [ORIGIN, ORIGIN.offset(X_AXIS), ORIGIN.offset(Y_AXIS)]
	@ptref_2d = []
end

def changed?
	view = Sketchup.active_model.active_view
	ptref_2d = @ptref.collect { |pt| view.screen_coords pt }
	if view != @view || ptref_2d[0] != @ptref_2d[0] || ptref_2d[1] != @ptref_2d[1] || ptref_2d[2] != @ptref_2d[2]
		@view == view
		@ptref_2d = ptref_2d
		return true
	end
	false
end
	
end	#class ViewTracker

end #Module G6

