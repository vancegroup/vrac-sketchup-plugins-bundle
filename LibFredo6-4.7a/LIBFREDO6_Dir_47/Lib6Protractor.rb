#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Nov. 2007 by Fredo6

# This software is provided as an example of using the Ruby interface to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name		:   LibProtractorTool.rb
# Type		:   Utility LIbrary as a Tool
# Description	:   Feature a Protractor tool for getting inputs of an origin, a plane,and 2 vectors
# Menu Item	:   none
# Context Menu	:   none
# Usage		:   See Tutorial 
# Date		:   15 Dec 2007
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************


module Traductor

T6[:T_MSG_Protractor_Origin] = "Select Origin and Plane"
T6[:T_MSG_Protractor_OriginShift] = "Shift or Arrows to lock plane"
T6[:T_MSG_Protractor_OriginDrag] = "Drag mouse to specify axis"
T6[:T_MSG_Protractor_Direction] = "Draw reference direction"
T6[:T_MSG_Protractor_LongClick] = "Long click to force input of Target"
T6[:T_MSG_Protractor_Rotation] = "Pick Rotation angle"
T6[:T_MSG_Protractor_Target] = "Pick Target point (for inference)"
T6[:T_MSG_Protractor_InferenceLine] = "Reference Endpoint on line"
T6[:T_VCB_Rotation] = "Rotation"
T6[:T_VCB_Direction] = "Direction"
T6[:T_VCB_Target] = "Target"

class StandardProtractorTool

STATE_ORIGIN = 0
STATE_DIRECTION = 1
STATE_TARGET = 1.5
STATE_ROTATION = 2
STATE_EXECUTION = 3

ProtractorToolDirection = Struct.new :ip, :pt, :vec, :angle_imposed, :freedom, :angle

#***********************************
# Placeholder for subclassing methods
#***********************************

include MixinCallBack

def sub_initialize(*args) ; end
def sub_activate ; end
def sub_deactivate(view) ; end
def sub_cursor_set ; nil ; end
def sub_exit_tool ; @model.select_tool nil ; end
def sub_onCancel(flag, view, state)  ; nil ; end
def sub_draw_before(view, state) ; true ; end
def sub_draw_after(view, state) ; true ; end
def sub_resume(view) ; end
def sub_change_state(state) ; end
def sub_execute(origin, normal, basedir, angle) ; end
def sub_rotate(origin, normal, basedir, angle) ; end
def sub_onLButtonDoubleClick(flags, x, y, view, state) ; end
def sub_getMenu_before(menu) ; false ; end
def sub_getMenu_after(menu) ; end
def sub_test_origin(pt_origin) ; true ; end
def sub_test_curangle(curangle) ; true ; end
def sub_get_title_tool() ; "" ; end
def sub_onKeyDown(key, rpt, flags, view) ; false ; end
def sub_onKeyUp(key, rpt, flags, view) ; false ; end

#Initialization method
def initialize(caller, *args)
	#Setting the caller
	_register_caller caller
	
	#Creating the Protractor Shape
	@pshape = G6::ShapeProtractor.new
	
	#Instance variables for driving the tool
	@model = Sketchup.active_model
	@view = @model.active_view
	@ip_origin = Sketchup::InputPoint.new
	@ip_target = Sketchup::InputPoint.new
	@ip_plane = Sketchup::InputPoint.new
	@ph = @view.pick_helper
	@tr_id = Geom::Transformation.new
	
	@view_tooltip = nil
	@hparam_help_tips = { :justif => 'LH', :bk_color => 'lightgreen', :fr_color => 'green', :dy => 85 }
	@hparam_view_tips = { :justif => 'LH', :bk_color => 'lightyellow', :fr_color => 'black', :fr_width => 0, 
	                      :dx => 30, :dy => -20, :xmargin => 8 }
	
	@origin = ORIGIN
	@axis_def = Y_AXIS
	@angle_def = 0.0
	@normal_def = @axis_def
	@normal = @axis_def
	@pt_ref = ORIGIN
	@prev_curangle = 0
	@hsh_entID = nil
	@lock_plane = false
	@to_target = false
	@target = nil 
	@edges_target = @face_target = nil
	@angle_offset = nil
	@offset = nil
	@lock_line_target = false
			
	#Custom initialization
	_sub :initialize, *args	
	
	#Message texts
	@title_tool = ""
	@title_tool = _sub :get_title_tool
	@title = (@title_tool && @title_tool != "") ? @title_tool + ': ' : ""
	@title_origin = T6[:T_MSG_Protractor_Origin]
	@title_origin += " [" + T6[:T_MSG_Protractor_OriginShift] + "]"
	@title_origin += " [" + T6[:T_MSG_Protractor_OriginDrag] + "]"
	@tip_origin = [T6[:T_MSG_Protractor_Origin], T6[:T_MSG_Protractor_OriginShift], T6[:T_MSG_Protractor_OriginDrag]].join "\n"
	@title_direction = T6[:T_MSG_Protractor_Direction]
	@title_longclick = T6[:T_MSG_Protractor_LongClick]
	@title_ref_online = T6[:T_MSG_Protractor_InferenceLine]
	@title_rotation = T6[:T_MSG_Protractor_Rotation]
	@title_target = T6[:T_MSG_Protractor_Target]
	@vcb_direction = T6[:T_VCB_Direction]
	@vcb_rotation = T6[:T_VCB_Rotation]
	@vcb_target = T6[:T_VCB_Target]
	@mode_length_direction = false
	@mark_forbidden = G6::DrawMark_Forbidden.new
	
	#Initializing the structures to hold the direction and rotation transformations
	@dir_base = direction_create 1
	@dir_rot = direction_create 0		
end

def _select
	Sketchup.active_model.select_tool self
end
	
def set_mode_length_direction(mode=true)
	@mode_length_direction = mode
end
	
#Create a Direction Structure
def direction_create(freedom)
	dir = ProtractorToolDirection.new()
	dir.ip = Sketchup::InputPoint.new
	dir.freedom = freedom
	dir.angle = 0
	dir
end

def activate
	set_state STATE_ORIGIN
	_sub :activate
end

def deactivate(view)
	_sub :deactivate, view
	view.invalidate
end

def get_origin
	@origin
end

#Resume view after change of view of zoom
def resume(view)
	_sub :resume, view
end

#Set the cursor
def onSetCursor
	idcur = _sub :cursor_set
	UI::set_cursor((idcur) ? idcur : 0)
end

#Contextual menu
def getMenu(menu)
	#Custom menu item before 
	return if _sub :getMenu_before, menu

	#Menu with orientation
	if @state == STATE_ORIGIN
		menu.add_item(T6[:T_STR_Inference_Blue_Plane] + " (" + T6[:T_MNU_ArrowUp] + ")") { orientation_axes Z_AXIS }
		menu.add_item(T6[:T_STR_Inference_Red_Plane] + " (" + T6[:T_MNU_ArrowLeft] + ")") { orientation_axes X_AXIS }
		menu.add_item(T6[:T_STR_Inference_Green_Plane] + " (" + T6[:T_MNU_ArrowRight] + ")") { orientation_axes Y_AXIS }
		menu.add_item(T6[:T_STR_Inference_Unlock_Plane] + " (" + T6[:T_MNU_ArrowDown] + ")") { orientation_axes nil }
	end	
	menu.add_item(T6[:T_MNU_Cancel]) { onCancel 0, @view } if @state != STATE_ORIGIN
	menu.add_item(T6[:T_MNU_Done]) { set_state STATE_EXECUTION } if @state == STATE_ROTATION
	
	#Custom menu item after 
	_sub :getMenu_after, menu
	
	true
end

#Set the orientation of the protrator
def orientation_axes(newnormal)
	unless newnormal
		@lock_plane = false
		onMouseMove_zero
		return
	end
	
	@axis_def = newnormal
	@normal_def = @axis_def
	@normal = @axis_def
	@pshape.set_placement @origin, @normal, nil, nil
	@lock_plane = true
	@angle_def = 0.0
	@view.invalidate
	info_angle
end

#Handle Key down events
def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false
	@num_keydown = 0 unless @num_keydown
	@num_keydown += 1
	
	#Custom handling of key
	return if _sub :onKeyDown, key, rpt, flags, view
	
	#Handling arrows for protractor base orientation
	case key
	when 13			#Return key
		Traductor::ReturnUp.set_off
	
	when CONSTRAIN_MODIFIER_KEY
		if @state == STATE_ORIGIN
			@lock_plane = !@lock_plane
		elsif @state == STATE_ROTATION

		end	
		@shift_down = @num_keydown
		@time_shift_down = Time.now.to_f
		onMouseMove_zero

	when COPY_MODIFIER_KEY
		@ctrl_down = @num_keydown
		
	when VK_UP
		orientation_axes Z_AXIS
	when VK_RIGHT
		orientation_axes X_AXIS	
	when VK_LEFT
		orientation_axes Y_AXIS	
	when VK_DOWN
		orientation_axes nil
	end
end

#Handle key up events
def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true
		
	return if key == 13 && Traductor::ReturnUp.is_on?
	
	#Custom handling of key
	return if _sub :onKeyUp, key, rpt, flags, view
	
	case key
	when 13			#Return key
		set_next_state
		Traductor::ReturnUp.set_off

	when CONSTRAIN_MODIFIER_KEY
		if @state == STATE_ORIGIN && @time_shift_down && (Time.now.to_f - @time_shift_down) > 1
			@lock_plane = !@lock_plane
		elsif @state == STATE_ROTATION && @shift_down == @num_keydown
			@lock_line_target = !@lock_line_target
		end	
		@shift_down = false

	when COPY_MODIFIER_KEY
		@time_ctrl_up = Time.now
		if @ctrl_down && @ctrl_down == @num_keydown		#control alone
			toggle_to_target
		end	
		@ctrl_down = false

	else
		@num_keydown = 0 unless @num_keydown
		@num_keydown += 1
		return false
	end	
	true
end

#Text typed in the VCB
def onUserText(text, view)
	Traductor::ReturnUp.set_on
	
	#Parse the input as Length when setting the direction
	if @state == STATE_DIRECTION && @mode_length_direction && @dir_base.vec.valid?
		len = parse_as_length text
		if len
			@dir_base.pt = @origin.offset @dir_base.vec, len
		else
			return UI.beep
		end	
	
	#Parse the input as an angle
	elsif angle = parse_as_angle(text)
		if @state == STATE_ORIGIN && @prev_origin
			call_execute @prev_origin, @prev_normal, @prev_basedir, angle
			@state = -1
		elsif @state <= STATE_DIRECTION
			direction_set_angle @dir_base, angle
		else	
			direction_set_angle @dir_rot, angle
		end
	
	#Angle not valid	
	else
		return UI.beep
	end
	
	set_next_state
	view.invalidate
	info_angle
end

#Parse the VCB text as an angle (degree, radians, grade) or slope
def parse_as_angle(text)
	dangle = Traductor.string_to_angle_degree text, true
	return nil unless dangle
	dangle = dangle.modulo 360
	dangle.degrees
end

#Parse the VCB text as an angle (degree, radians, grade) or slope
def parse_as_length (text)
	Traductor.string_to_length_formula text
end

#Execution invokation
def call_execute(origin, normal, basedir, curangle)
	_sub(:execute, origin, normal, basedir, curangle)
	@prev_origin = origin.clone
	@prev_normal = normal.clone
	@prev_basedir = basedir.clone
	@prev_curangle = curangle
end

#Impose the initial origin and normal
def impose_direction(origin, normal, basedir=nil, face=nil)
	origin2d = @view.screen_coords origin
	@ip_origin.pick @view, origin2d.x, origin2d.y
	@face = face
	@origin = origin.clone
	@normal = normal.clone
	@imposed_direction = true
	@pshape.set_placement @origin, @normal, basedir, @face
	set_state STATE_ORIGIN
end

def toggle_to_target
	return if @imposed_direction
	@to_target = !@to_target
	@view.invalidate
end
	
def set_to_target
	return if @imposed_direction
	@to_target = true
end
	
#Return the corrected angle (with offset)	
def correct_angle
	angle = @pshape.cur_angle
	angle = angle - @angle_offset if @state >= STATE_ROTATION && @angle_offset
	angle
end
	
#Control the 4 states of the tool
def set_state(state)
	state = STATE_DIRECTION if state == STATE_ORIGIN && @imposed_direction
	@state = state
	@lock_line_target = false
	if @state >= STATE_EXECUTION
		call_execute @pshape.origin, @pshape.normal, @pshape.basedir, correct_angle
		@state = STATE_ORIGIN
	elsif @state >= STATE_DIRECTION
		@prev_curangle = 0
	end	
	if @state < STATE_TARGET
		@target = nil 
		@edges_target = @face_target = nil
		@angle_offset = nil
		@offset = nil
	end
	if @state < STATE_ROTATION
		@dir_rot.vec = nil
		@dir_rot.pt = nil
	end	
	@dir_base.angle_imposed = false if state == STATE_ROTATION
	if @state == STATE_ORIGIN
		@dir_base.pt = nil
		@dir_rot.vec = nil
		@select_plane = false
	end	
	_sub :change_state, @state
	onMouseMove_zero
	info_show
end

def set_next_state
	case @state
	when STATE_ORIGIN
		@to_target = true
		@state = STATE_DIRECTION
	when STATE_DIRECTION
		@state = (@to_target) ? STATE_TARGET : STATE_ROTATION
	when STATE_TARGET
		@to_target = true
		@state = STATE_ROTATION
	when STATE_ROTATION
		@state = STATE_EXECUTION
	else
		@state = STATE_ORIGIN
	end	
	set_state @state
end

def set_previous_state
	case @state
	when STATE_ROTATION
		@state = (@to_target) ? STATE_TARGET : STATE_DIRECTION
	when STATE_TARGET
		@state = STATE_DIRECTION
	else
		@state = STATE_ORIGIN
	end	
	set_state @state
end

#Set the hash table for entity Ids to avoid when searching for inferences
def set_hsh_entityID(hsh)
	@hsh_entID = hsh
end
	
def get_state
	@state
end

def onLButtonUp(flags, x, y, view)
	if @xdown && @state == STATE_ROTATION && (x - @xdown).abs < 2 && (y - @ydown).abs < 2
		set_state STATE_TARGET if Time.now - @time_clickdown > 0.8
	elsif @state == STATE_ROTATION
		set_next_state
	end
	
	#Getting to next state
	if @state == STATE_ORIGIN && @select_plane
		@select_plane = false
		set_next_state
	end	
end
	
def onLButtonDown(flags, x, y, view)
	@time_clickdown = Time.now
	@xdown = x
	@ydown = y
	if @state == STATE_ORIGIN
		@select_plane = true
	else
		compute_target_offset if @state == STATE_TARGET
		set_next_state
	end	
end

#Double click - Exit by default
def onLButtonDoubleClick(flags, x, y, view)
	a = _sub(:onLButtonDoubleClick, flags, x, y, view, @state)
	_sub(:exit_tool) unless a
end

#Handle Escape key
def onCancel(flag, view)
	_sub :onCancel, flag, view, @state
	set_previous_state
end

#OnMouseMove method for Tool
def onMouseMove_zero ; onMouseMove(0, @x, @y, @view) if @x ; end

def onMouseMove(flags, x, y, view)
	return if @moving
	@moving = true
	@x = x
	@y = y
	@view_tooltip = nil
	case @state	
	when STATE_ORIGIN		#input Origin and Plane
		if @select_plane && @origin
			@ip_plane.pick view, x, y, @ip_origin
			@view_tooltip = @ip_plane.tooltip	
			pt = @ip_plane.position
			unless G6.points_close_in_pixel?(view, pt, @origin, 10) 
				@normal = @origin.vector_to pt
				@pshape.set_placement @origin, @normal, nil, nil
				@pt_plane = pt
			else
				@pt_plane = nil
			end	
			view.invalidate
			return
		end
		@ip_origin.pick view, x, y
		@view_tooltip = @ip_origin.tooltip
		@face = @ip_origin.face
		@origin = @ip_origin.position
		unless @lock_plane		#unless Shift Key is down, to lock plane
			if (@face)
				@normal = G6::transform_vector @face.normal, @ip_origin.transformation
			else
				@normal = normal_in_the_blues @ip_origin
			end
		end	
		@pshape.set_placement @origin, @normal, nil, @face
	
	when STATE_TARGET
		@target = pick_target view, x, y
		
	when STATE_DIRECTION		#input direction and lock plane
		direction_move @dir_base, x, y, view
		
	when STATE_ROTATION			#placing the construction line
		direction_move @dir_rot, x, y, view
		_sub :rotate, view, @pshape.origin, @pshape.normal, @pshape.basedir, correct_angle
	end	
	view.invalidate	
	info_angle
end

#Check if the point is close to the initial target
def pick_target(view, x, y)
	ini_target = @dir_base.pt
	target2d = view.screen_coords ini_target
	@ip_target.pick view, x, y
	vx = @ip_target.vertex
	edge = @ip_target.edge
	@edges_target = (vx) ? vx.edges : ((edge) ? [edge] : nil)
	return ini_target if (target2d.x - x).abs < 6 && (target2d.y - y).abs < 6
	plane = [@origin, @normal]
	if @ip_target.degrees_of_freedom == 0 || edge
		target = @ip_target.position.clone####.project_to_plane plane
		@view_tooltip = @ip_target.tooltip
	else
		pickray = view.pickray x, y
		target = Geom.intersect_line_plane pickray, plane			
	end	
	target
end

#Find orientation of protractor when point is in the empty space
def normal_in_the_blues(ip)
	pt = ip.position
	li = [0, 1, 2].find_all { |i| pt[i] == 0.0 }
	laxis = [X_AXIS, Y_AXIS, Z_AXIS]
	case li.length
	when 0
		return @normal_def
	when 1
		return laxis[li[0]]
	when 2
		return laxis[li[0]] * laxis[li[1]]
	else
		return Z_AXIS
	end	
end

#Check if the target touches a line or face
def inference_target_to_line(view, x, y)
	@line_inference_edge = nil
	return nil unless @state == STATE_ROTATION && @moving_target
	pt2d = @view.screen_coords @moving_target

	#Check if there is a valid edge close to the moving target
	ph_edge, tr, parent = G6.picking_edge_under_mouse(pt2d.x, pt2d.y, view, 10)
	tr = @tr_id unless tr
	
	return nil unless ph_edge && !@hsh_entID[ph_edge.entityID] && (@edges_target == nil || !@edges_target.include?(ph_edge))
	edge = ph_edge
	
	#Check if Target is close to edge
	plane = [@origin, @normal]
	pt1, pt2 = [edge.start, edge.end].collect { |pt| tr * pt.position }
	lenref = @origin.distance @moving_target
	ptinter1, ptinter2 = G6.intersect_segment_sphere pt1, pt2, @origin, lenref
	ptinter = ptinter1
	ptinter = ptinter2 if ptinter && @moving_target.distance(ptinter2) < @moving_target.distance(ptinter1)
	if ptinter
		return nil unless ptinter.on_plane?(plane)
		@moving_target = ptinter
		@line_inference_edge = [pt1, pt2]
		@view_tooltip = @title_ref_online
	end	
	ptinter
end

#Check if mouse cursor is close to target
def close_to_target(x, y)
	return false unless @target
	target2d = @view.screen_coords @target
	((x - target2d.x).abs < 5 && (y - target2d.y).abs < 5)
end

#Input method on Mouse move for Direction structures @dir_base et @dir_rot
def direction_move(dir, x, y, view)
	ip = dir.ip
	ip.pick view, x, y
	
	#Input Point inference	
	plane = [@origin, @normal]
	#if !@shift_down && ip.degrees_of_freedom <= dir.freedom && (@state != STATE_ROTATION || G6.not_auto_inference?(ip, @hsh_entID))
	if !@shift_down && ip.degrees_of_freedom <= dir.freedom 
		@pt_picked = ip.position.project_to_plane plane
		angle_imposed = true
		@view_tooltip = ip.tooltip
	elsif !@shift_down && close_to_target(x, y)
		@pt_picked = @target
		angle_imposed  = true
	else
		pickray = view.pickray x, y
		@pt_picked = Geom.intersect_line_plane pickray, plane
		angle_imposed  = false
	end	
	
	#Storing the information
	direction_store dir, angle_imposed
	
	#Computing the moving target
	if @state == STATE_ROTATION
		tr = Geom::Transformation.rotation @origin, true_normal, correct_angle
		pt = (@target) ? @target : @dir_base.pt
		@moving_target = tr * pt
		@moving_target = @moving_target.project_to_plane plane
	end	
	
	#Check if there is an inference on line
	if @state == STATE_ROTATION && !angle_imposed 
		ptinter = inference_target_to_line(view, x, y)
		if ptinter
			@pt_picked = ptinter
			direction_store dir, true
		end
	end	
end

def direction_store(dir, angle_imposed)
	dir.angle_imposed = angle_imposed
	dir.pt = @pt_picked
	dir.vec = @origin.vector_to(dir.pt)
	len = @origin.distance @pt_picked
	return if !dir.vec.valid? || dir.vec.parallel?(@normal)
	@base_length = len if len > 0
	pt = (dir.angle_imposed || (@offset && @offset != 0) || @shift_down) ? nil : dir.pt
	if (dir == @dir_base)
		dir.vec = @pshape.set_basedir dir.vec, pt
	else	
		dir.vec = @pshape.set_curdir dir.vec, pt
	end
	dir.pt = @origin.offset dir.vec, len if dir.vec.valid? && pt
	
	#Correction angle for the target
	len = @origin.distance @pt_picked.project_to_plane([@origin, @normal])
	begin
		@angle_offset = Math.asin @offset / len if @offset
	rescue
		return
	end		
end

#Compute the effective normal depending on camera
def true_normal
	(@normal % @view.camera.direction < 0) ? @normal : @normal.reverse
end

#Compute the offset from target
def compute_target_offset
	target_proj = @target.project_to_plane [@origin, @normal]
	line_base = [@origin, @dir_base.vec]
	pt_offset = target_proj.project_to_line line_base
	vec2 = pt_offset.vector_to target_proj
	@offset = target_proj.distance pt_offset
	if @offset == 0
		@offset = nil
	else	
		@offset = -@offset if @dir_base.vec * vec2 % true_normal < 0
	end	
end

#Return the extremity of the base dir vector
def get_basedir_point
	db = @dir_base
	return nil unless db && db.vec && db.vec.valid?
	return db.pt if db.pt
	@origin.offset db.vec, @base_length
end

def get_normal ; @normal ; end

def get_basedir_vector
	(@dir_base) ? @dir_base.vec : nil
end

#Draw method for tool
def draw(view)
	@moving = false
	return unless @origin
	_sub :draw_before, view, @state
	
	if @state == STATE_ORIGIN && @select_plane && @pt_plane
		@ip_plane.draw view
		view.drawing_color = Couleur.color_vector @normal, 'black', @ip_plane.face
		view.line_stipple = "-"
		view.line_width = 1
		pt1 = view.screen_coords @origin
		pt2 = view.screen_coords @pt_plane
		view.draw2d GL_LINE_STRIP, pt1, pt2
	end
	
	if (@state >= STATE_ORIGIN)
		@ip_origin.draw view
		@pshape.draw view		
	end
	
	#Draw the direction line
	if @state >= STATE_DIRECTION
		direction_draw @dir_base, view, false
	end
	
	#Draw the direction line
	if @state >= STATE_TARGET
		draw_target view
	end
	
	#Draw the rotation line
	if (@state >= STATE_ROTATION)
		direction_draw @dir_rot, view, true
	end
	
	#draw_mark_target view if @to_target
	draw_tooltip view
	
	_sub :draw_after, view, @state	
end

def draw_target(view)
	target = (@state == STATE_TARGET) ? @target : @pt_picked.project_to_plane([@origin, @normal])
	pt2d = view.screen_coords target
	if @state == STATE_TARGET
		color = 'red'
	else	
		color = 'green'
		if @offset && @origin.distance(@pt_picked) < @offset
			@mark_forbidden.draw_at_point3d view, @pt_picked
			return
		end
	end	
	draw_cross view, pt2d, color
	
	if @state == STATE_TARGET
		ini_target = @dir_base.pt
		pt2d = view.screen_coords ini_target
		pts = G6.pts_square pt2d.x, pt2d.y, 2
		view.drawing_color = 'red'
		view.draw2d GL_POLYGON, pts
		@ip_target.draw view
	elsif @state == STATE_ROTATION && @moving_target
		pt2d = view.screen_coords @moving_target
		pts = G6.pts_square pt2d.x, pt2d.y, 4
		view.drawing_color = 'orange'
		view.draw2d GL_POLYGON, pts	
		if @line_inference_edge
			view.line_width = 2
			view.line_stipple = ''
			view.draw GL_LINES, @line_inference_edge.collect { |pt| G6.small_offset view, pt }
		end	
	end	
end

def draw_mark_target(view)
	ptxy = Geom::Point3d.new @x, @y, 0
	vecm = Geom::Vector3d.new 32, 32, 0
	pt2d = ptxy.offset vecm
	draw_cross view, pt2d, 'magenta'
end

def draw_cross(view, pt2d, color)
	dec = 8
	vecx = X_AXIS + Y_AXIS
	vecy = X_AXIS - Y_AXIS
	ptx0 = pt2d.offset vecx, -dec
	ptx1 = pt2d.offset vecx, dec
	pty0 = pt2d.offset vecy, -dec
	pty1 = pt2d.offset vecy, dec
	view.drawing_color = color
	view.line_width = 2
	view.line_stipple = ''
	view.draw2d GL_LINES, [ptx0, ptx1, pty0, pty1]
end

#Draw method for Direction structures @dir_base et @dir_rot
def direction_draw(dir, view, flgbox)
	return unless dir.pt
	ip = dir.ip
	ip.draw view if dir.angle_imposed	
	view.line_width = 1
	view.line_stipple = "_"
	if (dir.angle_imposed && dir.pt != ip.position)
		vec = dir.pt.vector_to(ip.position)
		view.drawing_color = Couleur.color_vector vec, "purple", @face
		view.draw GL_LINES, [dir.pt, ip.position]
	end	
	if (flgbox)
		if @offset && @offset != 0
			draw_dashed_with_offset view		
		else	
			@pshape.draw_dashed_line view
		end	
	elsif dir.vec && dir.pt
		view.line_stipple = "-"
		view.line_width = 2
		view.drawing_color = Couleur.color_vector dir.vec, "black", @face
		view.draw GL_LINE_STRIP, [@origin, dir.pt] if @origin != dir.pt
	end
	if @state == STATE_DIRECTION
		if ip.degrees_of_freedom > 1
			pt2d = view.screen_coords dir.pt
			#pt2d = Geom::Point3d.new @x, @y
			pts = G6.pts_square pt2d.x, pt2d.y, 3
			view.drawing_color = 'red'
			view.draw2d GL_POLYGON, pts
		else
			ip.draw view
		end
	end
end

#Draw the direction line when there is an offset
def draw_dashed_with_offset(view)
	return unless @offset && @offset != 0
	vec = @dir_rot.vec
	normal = true_normal
	t = Geom::Transformation.rotation @origin, normal, -@angle_offset
	vec = t * vec
	vecp = normal * vec
	ptor = @origin.offset vecp, @offset
	ptof = ptor.offset vec, 100
	ptor2d = view.screen_coords ptor
	ptof2d = view.screen_coords ptof
	vec2d = ptor2d.vector_to ptof2d
	d = view.vpwidth * 5
	pt1 = ptor2d.offset vec2d, d
	pt2 = ptor2d.offset vec2d, -d
	view.drawing_color = 'purple'
	view.line_stipple = '_'
	view.line_width = 2
	view.draw2d GL_LINE_STRIP, [pt1, pt2]
end

#Force a particular value of the angle (from the VCB usually)
def direction_set_angle(dir, angle)
	d = (dir.pt) ? @origin.distance(dir.pt) : nil
	if (dir == @dir_base)
		@pshape.set_baseangle angle
		dir.vec = @pshape.basedir
	else
		@pshape.set_curangle angle
		dir.vec = @pshape.curdir
	end
	dir.pt = @origin.offset dir.vec, d if d
	@target = nil
	@angle_offset = nil
	@edges_target = @face_target = nil
	dir.angle_imposed  = false
end

#display angle value in the VCB
def info_angle
	angle = nil
	leng = nil
	case @state
	when STATE_ORIGIN, STATE_EXECUTION
		angle = @prev_curangle
	when STATE_DIRECTION
		if @mode_length_direction
			leng = (@dir_base.pt) ? @origin.distance(@dir_base.pt) : 0
		else
			angle = @pshape.base_angle
		end	
	when STATE_ROTATION
		angle = correct_angle
	end	
	if angle
		#angle = Math::PI * 2 - angle if (angle >= Math::PI)
		angle = angle.modulo(Math::PI * 2)
		angle = angle - Math::PI * 2 if (angle > Math::PI)
		text_angle = sprintf("%3.1f", angle.radians) + " deg."
		if (angle.modulo(Math::PI * 0.5) - (Math::PI * 0.5)).abs > 0.01
			#text_angle += ', ' + sprintf("%3.1f", Math.tan(angle) * 100) + "%"
		end	
	elsif leng
		text_angle = leng
	else
		text_angle = ""
	end	
	Sketchup.set_status_text text_angle, SB_VCB_VALUE
end

def draw_tooltip(view)
	#Instructions for help
	case @state
	when STATE_ORIGIN
		msg = @tip_origin
	when STATE_DIRECTION
		msg = @title_direction
		msg += "\n" + @title_longclick unless @to_target
	when STATE_TARGET
		msg = @title_target
	else
		msg = @title_rotation + "\n" + sprintf("%3.1f", correct_angle.radians) + " deg."
	end
	G6.draw_rectangle_multi_text @view, @x, @y, msg, @hparam_help_tips
	
	#Picking Inference
	if @view_tooltip
		G6.draw_rectangle_multi_text @view, @x, @y,  @view_tooltip, @hparam_view_tips
	end
end

#display information in the Sketchup status bar
def info_show
	case @state
	when STATE_ORIGIN
		msg = @title_origin
		label = ""
	when STATE_DIRECTION
		msg = @title_direction
		label = @vcb_direction
	when STATE_TARGET
		msg = @title_target
		label = @vcb_target
	else
		msg = @title_rotation
		label = @vcb_rotation
	end
	Sketchup.set_status_text @title + msg
	Sketchup.set_status_text label, SB_VCB_LABEL
	info_angle
end
	
end #Class StandardProtractorTool


end #End module Traductor