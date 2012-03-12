=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed by Fredo6 - Copyright April 2009

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   Lib6Selmode.rb
# Original Date	:   8 May 2009 - version 1.0
# Description	:   Utility for managing selection mode for other scripts
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end


module Traductor

T6[:T_DEFAULT_Section_EdgeSelection] = "Parameters for Edge Selection"
T6[:T_DEFAULT_Flag_SelectionAperture] = "Aperture for picking in pixel (0 means Sketchup default)"
T6[:T_DEFAULT_Flag_SelectionModifiers] = "Edge Selection mode"
T6[:T_DEFAULT_Flag_SelectionAnglemax] = "Maximum Edge Angle for Follow mode (degree)"

T6[:T_MNU_Extend_None] = "Selection edge by edge"
T6[:T_MNU_Extend_Connected] = "Extend selection to all connected edges (CTRL + SHIFT)"
T6[:T_MNU_Extend_Curve] = "Extend selection to curve (CTRL)"
T6[:T_MNU_Extend_Follow] = "Extend selection to cofacial and aligned edges (SHIFT)"
T6[:T_MNU_Extend_Anglemax] = "Maximum deviation angle in degree (in VCB followed by d)"

T6[:T_OPT_Extend_None] = "Edge by Edge"
T6[:T_OPT_Extend_Connected] = "All connected edge"
T6[:T_OPT_Extend_Curve] = "Curve"
T6[:T_OPT_Extend_Follow] = "Follow mode"

#--------------------------------------
# Valid Mode
#	'N'    : Edge by edge
#	'A' : All connected
#	'C' : Curve
#	'F' : Follow (based on an angle max)
#--------------------------------------

class SelMode

#--------------------------------------
# Class initialization
#--------------------------------------

def initialize(*args)
	#parsing the arguments
	args.each do |arg|	
		arg.each { |key, value|  parse_args(key, value) } if arg.class == Hash
	end
	
	#Getting default_parameters
	@modifier = 'N' unless @modifier
	@anglemax = 30.degrees unless @anglemax
	
	
	#Other initializations
	@shift_down = false
	@ctrl_down = false
	@mark_extended = G6::DrawMark_FourArrows.new
	@mark_follow = G6::DrawMark_H2Arrows.new
	@mark_curve = G6::DrawMark_Curve.new
	@renderop = Sketchup.active_model.rendering_options
	
	init_text
end

#Assign the individual propert for the palette
def parse_args(key, value)
	skey = key.to_s
	case skey
	when /modifier/i
		@modifier = value
	when /anglemax/i
		set_anglemax value
	end	
end

#Text initialization
def init_text
	@mnu_none = T6[:T_MNU_Extend_None]
	@mnu_connected = T6[:T_MNU_Extend_Connected]
	@mnu_curve = T6[:T_MNU_Extend_Curve]
	@mnu_follow = T6[:T_MNU_Extend_Follow]
	@mnu_anglemax = T6[:T_MNU_Extend_Anglemax]
end

def get_modifier
	@modifier
end

def get_anglemax
	@anglemax.radians
end
	
#--------------------------------------
# Class Methods
#--------------------------------------

#Contribute to the default parameters
def SelMode.default_param(defparam, symbroot, default=nil, options=nil)
	options = 'NACF' unless options
	default = 'N' unless default
	
	klist = []
	klist.push ['N', T6[:T_OPT_Extend_None]] if options =~ /N/i
	klist.push ['A', T6[:T_OPT_Extend_Connected]] if options =~ /A/i
	klist.push ['C', T6[:T_OPT_Extend_Curve]] if options =~ /C/i
	klist.push ['F', T6[:T_OPT_Extend_Follow]] if options =~ /F/i
	
	text_flag = T6[:T_DEFAULT_Flag_SelectionModifiers]
	text_angle = T6[:T_DEFAULT_Flag_SelectionAnglemax]
	text_aperture = T6[:T_DEFAULT_Flag_SelectionAperture]
	
	defparam.separator :T_DEFAULT_Section_EdgeSelection
	defparam.declare SelMode.default_symb_aperture(symbroot), 0, 'I:>=0<=30', nil, text_aperture
	defparam.declare SelMode.default_symb_modifier(symbroot), 'N', 'H',  klist, text_flag
	defparam.declare SelMode.default_symb_anglemax(symbroot), 30.0, 'F:>=0<=90', nil, text_angle	
end

def SelMode.default_symb_modifier(symbroot)
	s = symbroot.to_s + '__Selmode_modifier'
	s.intern
end

def SelMode.default_symb_anglemax(symbroot)
	s = symbroot.to_s + '__Selmode_anglemax'
	s.intern
end

def SelMode.default_symb_aperture(symbroot)
	s = symbroot.to_s + '__Selmode_aperture'
	s.intern
end

#--------------------------------------
# Manage modifiers flags
#--------------------------------------

def make_proc(&proc) ; proc ; end

#Palette contribution
def contribute_palette(palette)

	hshb = {:width => 20, :height => 16, :main_color => 'blue' }
	
	proc = make_proc() { @modifier ==  'A' }
	hsh = { :value_proc => proc, :tooltip => @mnu_connected, :draw_proc => :arrow_RULD, :rank => 1 }
	palette.declare_button(:t_extend_connected, hsh, hshb) { toggle_modifier 'A' }
	
	proc = make_proc() { @modifier == 'F' }
	hsh = { :value_proc => proc, :tooltip => @mnu_follow, :draw_proc => :arrow_RL }
	palette.declare_button(:t_extend_follow, hsh, hshb) { toggle_extend_follow }
	
	proc = make_proc() { @modifier == 'C' }
	hsh = { :value_proc => proc, :tooltip => @mnu_curve, :draw_proc => :circle_E2, :rank => 1,
            :main_color => 'blue', :draw_scale => 0.75 }
	palette.declare_button(:t_extend_curve, hsh, hshb) { toggle_extend_curve }
	
	proc = make_proc() { @modifier == 'F' }
	tproc = make_proc() { sprintf "%2i", @anglemax.radians }
	hsh = { :value_proc => proc, :text_proc => tproc, :tooltip => @mnu_anglemax,
            :main_color => 'green', :frame_color => 'red'}
	palette.declare_button(:t_anglemax, hsh, hshb) { puts "change angle max" }

end

#Contextual menu contribution
def contribution_menu(menu)
	menu.add_separator
	menu.add_item(@mnu_none) { toggle_extend_none }
	menu.add_item(@mnu_connected) { toggle_extend_connected }
	menu.add_item(@mnu_curve) { toggle_extend_curve }
	menu.add_item(@mnu_follow) { toggle_extend_follow }
end

#Change the angle for follow mode (angle in degree)
def set_anglemax(anglemax=nil)
	return unless anglemax
	@anglemax = anglemax.degrees
end

#Toggle the mode modifier value
def set_modifier(modifier)
	@modifier = modifier
	@refresh_proc.call if @refresh_proc
end

#Toggle the mode modifier value
def toggle_modifier(value)
	@modifier = (@modifier == value) ? 'N' : value
	@refresh_proc.call if @refresh_proc
end

def toggle_extend_curve
	toggle_modifier 'C'
end

def toggle_extend_follow
	toggle_modifier 'F'
end

def toggle_extend_connected
	toggle_modifier 'A'
end

def toggle_extend_none
	toggle_modifier 'N'
end

def toggle_both
	return unless @timer_toggle
	@toggle_now = Time.now.to_f
	save_toggles
	UI.stop_timer @timer_toggle
	@timer_toggle = nil
	if @ctrl_down && @shift_down
		toggle_extend_connected
	elsif @modifier == 'A'
		toggle_extend_connected
	elsif @ctrl_down
		toggle_extend_curve
	elsif @shift_down
		toggle_extend_follow
	end
end

def save_toggles
	@old_modifier = @modifier
end

def restore_toggles
	return if @toggle_now && Time.now.to_f - @toggle_now < 0.8
	@modifier = @old_modifier
end

def onMouseMove(flags, x, y, view)
	if Traductor.shift_mask?(flags) != @shift_down
		@modifier = @old_modifier
		@shift_down = false
	end	
end

#Handle key down events
def onKeyDown(key, rpt, flags, view)	
	#Keys for selection modifiers
	case key			
	when CONSTRAIN_MODIFIER_KEY
		#puts "Shift DOWN --> #{@shift_down}"
		@shift_down = true
		@timer_toggle = UI.start_timer(0.5) { toggle_both } unless @timer_toggle

	when COPY_MODIFIER_KEY
		@ctrl_down = true
		@oldmodifier = @modifier
		@time_key = Time.now.to_f
		@timer_toggle = UI.start_timer(0.5) { toggle_both } unless @timer_toggle
		
	else
		return false
	end
	true
end

def resume(view)
	#@toggle_now = Time.now.to_f - 3.0
end

#Handle key up events
def onKeyUp(key, rpt, flags, view)	
	case key			
	when CONSTRAIN_MODIFIER_KEY
		#puts "Shift UP --> #{@shift_down}"
		@shift_down = false
		restore_toggles
	when COPY_MODIFIER_KEY
		@ctrl_down = false
		restore_toggles
	else
		if @time_key && (Time.now.to_f - @time_key < 0.8)
			@modifier = @oldmodifier
		end	
		return false
	end
	true
end

#Drawing method - Used to add cursor indicator
def draw_mark(view, x, y, size_cursor=24)
	return unless x && @modifier != 'N'
	x = x
	y = y + size_cursor + 6
	if @modifier == 'A'
		@mark_extended.draw_at_xy view, x, y	
	elsif @modifier == 'F'
		@mark_follow.draw_at_xy view, x, y
	elsif @modifier == 'C'
		@mark_curve.draw_at_xy view, x, y	
	end	
end

#--------------------------------------------------------------
# Manage selection edges according to current mode
#--------------------------------------------------------------

def is_edge_concealed?(edge)
	(edge.soft? || edge.smooth? || edge.hidden?)
end

#Check which entity is picked with draw_hidden turned off
def entity_with_draw_hidden(entity)
	return entity if entity.class == Sketchup::Face
	if !@renderop["DrawHidden"]
		if (entity.class == Sketchup::Edge && is_edge_concealed?(entity)) ||
		   (entity.class == Sketchup::Vertex && (!entity.edges.find { |e| !is_edge_concealed?(e) }))
			entity2 = entity.faces[0]
			return entity2 if entity2
		end
	end
	entity
end

#Determine the entity picked according to the selection mode
def entity_picked_from_mode(entity)
	
	#Replacing edges and vertex 
	entity = entity_with_draw_hidden entity
	
	#Extending the entity according to mode
	objclass = entity.class
	
	if objclass == Sketchup::Face
		if @modifier == 'A'
			lentity = []
			entity.edges.each { |edge| lentity |= edge.all_connected }
		else
			lentity = edges_around_face entity
		end
	
	elsif objclass == Sketchup::Vertex
		if @modifier == 'A'
			lentity = []
			entity.edges.each { |edge| lentity |= edge.all_connected }
		elsif @modifier == 'C'|| @modifier == 'F' 
			lentity = []
			ledges = entity.edges.find_all { |e| !is_edge_concealed?(e) }
			ledges.each { |e| lentity |= entity_picked_from_mode(e) }
			return lentity	
		else
			lentity = entity.edges
		end
	
	elsif objclass == Sketchup::Edge
		if @modifier == 'A'
			lentity = [entity] + entity.all_connected 
		elsif @modifier == 'C'
			curve = entity.curve
			lentity = (curve) ? curve.edges : [entity]
		elsif @modifier == 'F'
			curve = entity.curve
			lentity = (curve) ? curve.edges : [entity]
			lentity |= follow_extend entity
		else
			lentity = [entity]
		end
		
	end

	lentity = lentity.find_all { |e| e.class == Sketchup::Edge }
	lentity
end

#Determine all connected faces to the face (i.e. if bording edge is soft or hidden)
#note: the recursive version seems to bugsplat on big number of faces. So I use an iterative version
def face_neighbours(face, hsh_faces = nil)
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
def edges_around_face(face, hsh_good_edges=nil, hsh_bad_edges=nil)
	#calculate the nieghbour faces
	hsh_faces = {}
	hsh_good_edges = {} unless hsh_good_edges
	hsh_bad_edges = {} unless hsh_bad_edges
	face_neighbours face, hsh_faces
	
	#Calculate the bordering edges
	hsh_good_edges = {}
	hsh_faces.each do |key, face|
		face.edges.each do |e|
			n = 0
			e.faces.each { |f| n += 1 if hsh_faces[f.entityID] }
			if (n == 1)
				hsh_good_edges[e.entityID] = e
			else
				hsh_bad_edges[e.entityID] = e
			end	
		end
	end	
	hsh_good_edges.values #+ ((@renderop["DrawHidden"]) ? [] : hsh_bad_edges.values)
end

#extend selection in follow mode for edge at vertex
def follow_extend(edge)
	@common_normal = nil
	follow_extend_at_vertex(edge, edge.start) + follow_extend_at_vertex(edge, edge.end)
end

#extend selection in follow mode for edge at vertex
def follow_extend_at_vertex(edge, vertex)
	anglemax = @anglemax
	ls_edges = []
	edgenext = edge
	while edgenext
		len = vertex.edges.length
		break if len == 1
		if len == 2
			ls = [[0, vertex.edges.to_a.find { |ee| ee != edgenext }]]
		else	
			ls = []
			vertex.edges.each do |e|
				next if e == edgenext
				#next unless check_entity?(e)
				an = Math::PI - angle_edge(edgenext, e, vertex)
				next if an > anglemax
				if @common_normal && @common_normal.valid?
					v = edge_normal(e, edgenext)
					ls.push [an, e] if v.valid? && v.parallel?(@common_normal)
					next
				elsif e.common_face(edgenext)
					ls.push [an, e]
				elsif an < anglemax
					ls.push [an, e]
				end	
			end
		end
		break if ls.length == 0
		
		ls.sort! { |a1, a2| a1[0] <=> a2[0] } if ls.length > 1
		e = ls[0][1]
		break if e == edge
		@common_normal = edge_normal(e, edgenext) unless @common_normal && @common_normal.valid?
		edgenext = e
		vertex = e.other_vertex(vertex)
		ls_edges.push edgenext
	end
	
	return ls_edges
end

def angle_edge(e1, e2, vertex)
	v1 = e1.other_vertex vertex
	v2 = e2.other_vertex vertex
	vec1 = vertex.position.vector_to v1
	vec2 = vertex.position.vector_to v2
	vec1.angle_between vec2
end

def edge_normal(e1, e2)
	vec1 = e1.start.position.vector_to e1.end.position
	vec2 = e2.start.position.vector_to e2.end.position
	vec1 * vec2
end

end	# class SelMode

end	#module Traductor

