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

T6[:T_MSG_Protractor_Origin] = "Select Origin and Plane (Shift / Arrow to lock plane, drag mouse to specify axis)"
T6[:T_MSG_Protractor_Direction] = "Draw reference direction"
T6[:T_MSG_Protractor_Rotation] = "Pick Rotation angle"
T6[:T_VCB_Rotation] = "Rotation"
T6[:T_VCB_Direction] = "Direction"

class StandardProtractorTool

STATE_ORIGIN = 0
STATE_DIRECTION = 1
STATE_ROTATION = 2
STATE_EXECUTION = 3

ProtractorToolDirection = Struct.new("ProtractorToolDirection", :ip, :pt, :vec, :angle_imposed, 
                                                                :freedom, :angle) 

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
	@ip_plane = Sketchup::InputPoint.new
	@origin = ORIGIN
	@axis_def = Y_AXIS
	@angle_def = 0.0
	@normal_def = @axis_def
	@normal = @axis_def
	@pt_ref = ORIGIN
	@prev_curangle = 0
	@hsh_entID = nil
	@lock_plane = false
			
	#Custom initialization
	_sub :initialize, *args	
	
	#Message texts
	@title_tool = ""
	@title_tool = _sub :get_title_tool
	title = (@title_tool && @title_tool != "") ? @title_tool + ': ' : ""
	@title_origin = title + T6[:T_MSG_Protractor_Origin]
	@title_direction = title + T6[:T_MSG_Protractor_Direction]
	@title_rotation = title + T6[:T_MSG_Protractor_Rotation]
	@vcb_direction = T6[:T_VCB_Direction]
	@vcb_rotation = T6[:T_VCB_Rotation]
	@mode_length_direction = false
	
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
	menu.add_item(T6[:T_MNU_Cancel]) { onCancel 0, @view } if @state >= STATE_DIRECTION
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
	
	#Custom handling of key
	return if _sub :onKeyDown, key, rpt, flags, view
	
	#Handling arrows for protractor base orientation
	case key
	when 13			#Return key
		Traductor::ReturnUp.set_off
	
	when CONSTRAIN_MODIFIER_KEY
		@lock_plane = !@lock_plane
		@time_shift_down = Time.now.to_f
		onMouseMove_zero
	
	when VK_UP
		orientation_axes Z_AXIS
	when VK_RIGHT
		orientation_axes X_AXIS	
	when VK_LEFT
		orientation_axes Y_AXIS	
	when VK_DOWN
		#orientation_axes @axis_def
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
		set_state @state + 1
		Traductor::ReturnUp.set_off

	when CONSTRAIN_MODIFIER_KEY
		if @time_shift_down && (Time.now.to_f - @time_shift_down) > 1
			@lock_plane = !@lock_plane
		end	

	else
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
	
	set_state @state + 1
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

#Control the 4 states of the tool
def set_state(state)
	state = STATE_DIRECTION if state == STATE_ORIGIN && @imposed_direction
	@state = state
	if @state >= STATE_EXECUTION
		call_execute @pshape.origin, @pshape.normal, @pshape.basedir, @pshape.cur_angle
		@state = STATE_ORIGIN
	elsif @state >= STATE_DIRECTION
		@prev_curangle = 0
	end	
	@dir_base.angle_imposed = false if state == STATE_ROTATION
	if @state == STATE_ORIGIN
		@dir_base.pt = nil
		@dir_rot.vec = nil
		@select_plane = false
	end	
	_sub :change_state, @state
	info_show
end

#Set the hash table for entity Ids to avoid when searching for inferences
def set_hsh_entityID(hsh)
	@hsh_entID = hsh
end
	
def get_state
	@state
end

def onLButtonUp(flags, x, y, view)
	#getting to next state
	if @state == STATE_ORIGIN && @select_plane
		@select_plane = false
		set_state @state + 1
	end	
end
	
def onLButtonDown(flags, x, y, view)
	#getting to next state
	if @state == STATE_ORIGIN
		@select_plane = true
	else	
		set_state @state + 1
	end	
end

#Handle Escape key
def onCancel(flag, view)
	_sub :onCancel, flag, view, @state
	set_state STATE_ORIGIN
end

#OnMouseMove method for Tool
def onMouseMove_zero ; onMouseMove(0, @x, @y, @view) if @x ; end

def onMouseMove(flags, x, y, view)
	return if @moving
	@moving = true
	@x = x
	@y = y
	case @state	
	when STATE_ORIGIN		#input Origin and Plane
		if @select_plane && @origin
			@ip_plane.pick view, x, y, @ip_origin
			view.tooltip = @ip_plane.tooltip	
			pt = @ip_plane.position
			unless close_in_pixel(view, pt, @origin, 10) 
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
		view.tooltip = @ip_origin.tooltip
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
		
	when STATE_DIRECTION		#input direction and lock plane
		direction_move @dir_base, x, y, view
		
	when STATE_ROTATION			#placing the construction line
		direction_move @dir_rot, x, y, view
		_sub :rotate, view, @pshape.origin, @pshape.normal, @pshape.basedir, @pshape.cur_angle
	end	
	view.invalidate	
	info_angle
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

def close_in_pixel(view, pt1, pt2, pixels)
	vpt1 = view.screen_coords pt1
	vpt2 = view.screen_coords pt2
	(vpt1.distance(vpt2) <= pixels)
end

#Input method on Mouse move for Direction structures @dir_base et @dir_rot
def direction_move(dir, x, y, view)
	ip = dir.ip
	ip.pick view, x, y, @ip_origin
	view.tooltip = ip.tooltip
	plane = [@origin, @normal]
	if (ip.degrees_of_freedom <= dir.freedom) && G6.true_inference_vertex?(view, ip, x, y) &&
	   (@state != STATE_ROTATION || G6.not_auto_inference?(ip, @hsh_entID))
		dir.pt = ip.position.project_to_plane plane
		dir.angle_imposed = true
	else
		pickray = view.pickray x, y
		dir.pt = Geom.intersect_line_plane pickray, plane
		dir.angle_imposed  = false
	end	
	dir.vec = @origin.vector_to(dir.pt)
	len = @origin.distance dir.pt
	@base_length = len if len > 0
	pt = (dir.angle_imposed) ? nil : dir.pt
	if (dir == @dir_base)
		dir.vec = @pshape.set_basedir dir.vec, pt
	else	
		dir.vec = @pshape.set_curdir dir.vec, pt
	end
	dir.pt = @origin.offset dir.vec, len if pt
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
	if (@state >= STATE_DIRECTION)
		direction_draw @dir_base, view, false
	end
	
	#Draw the rotation line
	if (@state >= STATE_ROTATION)
		direction_draw @dir_rot, view, true
	end
	
	_sub :draw_after, view, @state	
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
		@pshape.draw_dashed_line view
	elsif dir.vec && dir.pt
		view.line_stipple = "-"
		view.line_width = 2
		view.drawing_color = Couleur.color_vector dir.vec, "black", @face
		view.draw GL_LINE_STRIP, [@origin, dir.pt] if @origin != dir.pt
	end
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
		angle = @pshape.cur_angle
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

#display information in the Sketchup status bar
def info_show
	case @state
	when STATE_ORIGIN
		msg = @title_origin
		label = ""
	when STATE_DIRECTION
		msg = @title_direction
		label = @vcb_direction
	else
		msg = @title_rotation
		label = @vcb_rotation
	end
	Sketchup.set_status_text msg
	Sketchup.set_status_text label, SB_VCB_LABEL
	info_angle
end
	
end #Class StandardProtractorTool


end #End module Traductor