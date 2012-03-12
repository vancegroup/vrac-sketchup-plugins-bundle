=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed April / August 2008 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   FreehandOnSurface.rb
# Original Date	:   12 Jul 2008 - version 1.3
# Revisions		:	12 Aug 2008 - version 1.4
#					(Added construction points to help with inferences)
#					31 Jul 2009 - version 1.5
# Type			:   Sketchup Tools
# Description	:   Roughly analog to the Sketchup Freehand tool, but on a surface
# Usage			:   See Tutorial and Quick Ref Card in PDF format
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module SUToolsOnSurface

#Constants for LineOnSurface Module (do not translate)
T6[:TIT_FreeHand] = "FREE HAND"

T6[:MSG_Tell_Pause] = "Press or toggle CTRL to pause"
T6[:MSG_Tell_Inference] = "Press or toggle SHIFT to enable inference"
T6[:MSG_Pause] = "PAUSE - Press CTRL to resume"
T6[:MSG_Pixel_Precision] = "Pixel sampling"
T6[:MSG_Freehand_Origin] = "Enter Origin"
T6[:MSG_Freehand_End] = "Freehand Drawing (keep Ctrl down to pause input, Shift down to use inference)"
T6[:MSG_Terminate_Before] = "Do you wish to validate the drawing before exiting?"
T6[:MSG_Double_Click] = "Click to pick points - Double Click to finish"
T6[:MSG_Double_Click_Lock] = "Click to pick inference points - Double Click to finish"
T6[:MSG_Interim_Click] = "Release Shift to capture inference point"
T6[:MSG_Single_Click] = "Drag to capture points - Single Click to finish"
T6[:MSG_UndoingGoBack] = "Go back to last point to resume input"

#TOS_ICON_FREEHAND = "Freehand"	
TOS_CURSOR_FREEHAND_LINE = "Freehand_Line"
TOS_CURSOR_FREEHAND_LINE_CLICK = "Freehand_Line_Click"
TOS_CURSOR_FREEHAND_CLINE = "Freehand_Cline"
TOS_CURSOR_FREEHAND_CLINE_CLICK = "Freehand_Cline_Click"
				 
#--------------------------------------------------------------------------------------------------------------
# Top Calling functions: create the classes and launch the tools
#--------------------------------------------------------------------------------------------------------------			 				   

def SUToolsOnSurface.launch_freehand(linemode=true)
	MYPLUGIN.check_older_scripts
	@tool_freehand = TOSToolFreehand.new linemode
	Sketchup.active_model.select_tool @tool_freehand
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TOSToolLine: Tool to draw line (plain or construction) on a surface
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					
class TOSToolFreehand < Traductor::PaletteSuperTool

def make_proc(&proc) ; proc ; end

def initialize(linemode=true)
	@title = T6[:TIT_FreeHand]
	
	#Loading strings and cursors
	@msg_freehand_origin = T6[:MSG_Freehand_Origin]
	@msg_freehand_end = T6[:MSG_Freehand_End]
	@msg_pixel_precision = T6[:MSG_Pixel_Precision]
	@msg_double_click = T6[:MSG_Double_Click]
	@msg_double_click_lock = T6[:MSG_Double_Click_Lock]
	@msg_interim_click = T6[:MSG_Interim_Click]
	@msg_single_click = T6[:MSG_Single_Click]
	@msg_undoing_goback = T6[:MSG_UndoingGoBack]
	@msg_pause = T6[:MSG_Pause]
	@msg_tell = " -- " + T6[:MSG_Tell_Pause] + " - " + T6[:MSG_Tell_Inference]
	@vcb_edges = T6[:VCB_Edges]
	
	@idcursor_line = MYPLUGIN.create_cursor TOS_CURSOR_FREEHAND_LINE, 0, 32
	@idcursor_line_click = MYPLUGIN.create_cursor TOS_CURSOR_FREEHAND_LINE_CLICK, 0, 32
	@idcursor_cline = MYPLUGIN.create_cursor TOS_CURSOR_FREEHAND_CLINE, 0, 32
	@idcursor_cline_click = MYPLUGIN.create_cursor TOS_CURSOR_FREEHAND_CLINE_CLICK, 0, 32

	#initializing variables
	@ip_origin = Sketchup::InputPoint.new
	@ip = Sketchup::InputPoint.new
	@time_delta = MYDEFPARAM[:TOS_DEFAULT_Freehand_Time]
	@normaldef = Z_AXIS
	@planedef = [ORIGIN, @normaldef]
	@pix_min = 3

	#Creating the palette manager
	lst_options = [ "undo_last", "inference_lock", "clickmode", "precision", "linemode", "cpoint", 
	                "group", "genfaces", "gencurves"]
	proc_exec = make_proc() { execute_but_last }
	proc_gray = make_proc() { @lst_marks.length < 3 }
	hsh = { 'title' => @title, 'list_options' => lst_options, 'linemode' => linemode,
            'finish_proc_gray' => proc_gray, 'finish_proc_exec' => proc_exec }
	@palman = PaletteManager.new(self, 'FreeHand', hsh) { refresh_view }
	
	#Initializing parameters	
	@tmpops = false
end

def activate
	@palman.initiate
	@model = Sketchup.active_model
	@view = @model.active_view
	@renderop = @model.rendering_options
	@selection = @model.selection
	@entities = @model.active_entities
	@bb = @model.bounds	
	
	@enter_down = false
	@pts = []
	@distance = 0
	@parcours = []
	@edges = nil
	set_state STATE_ORIGIN
	@button_down = false
	
	@view.invalidate
end

def reset
	@lst_points2d = []
	@lst_marks = []
	@lst_parcours = []
	@bigparcours = []
	@lst_cpoints = []
	@pause_on = false
	#@inference_lock = false
	@palman.set_inference_on false
	@palman.set_message
	tmp_operation_start
end

def set_message
	if @pause_on
		@undoing = false
		@palman.set_message @msg_pause, 'W'
	else	
		@palman.set_message
	end	
end

#Event for tool deactivation
def deactivate(view)
	terminate_before
	@palman.terminate
	tmp_operation_abort
	view.invalidate
end

#Def go back to active mode of the tool
def resume(view)
	onMouseMove_zero
	view.invalidate
end

#Prompt the user for terminating before exiting the tool
def terminate_before
	return if @lst_marks.length <= 1
	status = UI.messagebox T6[:MSG_Terminate_Before], MB_YESNO 
	if status == 6
		execute_but_last
	end	
end

def execute_but_last
	return if @lst_marks.length < 3
	@lst_marks.pop
	execute
end

#Return bounding box	
def getExtents
	return @bb if @state == STATE_ORIGIN	
	@bb = @bb.add @lst_marks.last.pt if @lst_marks.last
    @bb
end

#Temporary operations
def tmp_operation_start
	return if @tmpops
	@model.start_operation "Freehand Temporary"
	@tmpops = true
end

def tmp_operation_abort
	return unless @tmpops
	@model.abort_operation
	@tmpops = false
end

def onCancel(flag, view)
	#User did an Undo
	case flag
	when 1, 2	#Undo or reselect the tool
		tmp_operation_abort
		return
	when 0	#user pressed Escape
		return  if (@state == STATE_ORIGIN)  #Exiting the tool
		undo_last
	end
end

def undo_last
	if @lst_marks.length < 2
		set_state STATE_ORIGIN
	else
		replace_last_mark
		#replace_last_mark if @palman.clickmode
		@mark_last = @lst_marks.last
		@undoing = true unless @palman.clickmode
		onMouseMove_zero
	end	
end

def onSetCursor
	ic = super
	return (ic != 0) if ic
	if @palman.clickmode
		UI::set_cursor((@palman.linemode) ? @idcursor_line_click : @idcursor_cline_click)
	else	
		UI::set_cursor((@palman.linemode) ? @idcursor_line : @idcursor_cline)
	end	
end

#Procedure to refresh the view ehn options are changed
def refresh_view
	onMouseMove_zero
end

#Finishes the current segment and exit
def done_and_exit
	@lst_marks.pop if @lst_marks.length > 2
	execute
	@model.select_tool nil 
end

#Return key pressed
def onReturn(view)
	done_and_exit
end

#Compute all parameters of the contour for drawing or creating the curve
def compute_contour
	@pts_contour = []
	nb = @lst_marks.length - 2
	return if nb < 0
	@bigparcours = [@lst_marks.first]
	for i in 0..nb
		mk1 = @lst_marks[i]
		mk2 = @lst_marks[i+1]
		parcours = Junction.calculate mk1, mk2
		@bigparcours += parcours[1..-1] if parcours.length > 0 
		pts = []
		parcours.each { |mk| pts.push mk.pt }
		@pts_contour += pts[0..-1]
	end	
end

#Creation method for the line
def execute_drawing
	return if @lst_marks.length < 2
	
	#Stopping the temporary operation mode
	tmp_operation_abort	
	
	#Starting geometry creation
	@model.start_operation @title

	#identifying the Group if needed
	if @palman.option_group
		grp = @palman.current_group
		unless grp
			@model.abort_operation
			return
		end	
		entities = grp.entities
	else
		entities = @entities
	end
	
	#Creating the complete path
	compute_contour
	lst_vert = []
	@lst_marks.each { |mk| lst_vert.push mk.pt }
	
	#creating the new edges or construction lines
	pts = @pts_contour
	attr = '-'
	list_coseg = []
	OFSG.compute_coseg(@bigparcours, list_coseg) if @palman.linemode && @bigparcours.length > 1
	if @palman.linemode
		edges = []
		OFSG.commit_line(entities, pts, attr, !@palman.option_gencurves, list_coseg, edges, lst_vert)
		#edges[0].find_faces if @palman.option_genfaces
		edges.each { |edge| edge.find_faces if @palman.option_genfaces }
	else
		nb = pts.length - 2
		for i in 0..nb
			cline = entities.add_cline pts[i], pts[i+1]
			OFSG.set_cline_attribute cline, attr
		end
	end	
	if @palman.option_cpoint
		pts.each do |pt|
			cpoint = entities.add_cpoint pt 
			OFSG.set_cline_attribute cpoint, attr
		end
	end	
	@model.commit_operation	
end

#Control the states of the tool
def set_state(state)
	@state = state
	case @state
	when STATE_EXECUTION 
		execute
	when STATE_ORIGIN
		reset
	when STATE_END
		
	end
	info_show
end

def execute
	execute_drawing
	set_state STATE_ORIGIN
end

#Contextual menu
def getMenu(menu)
	@palman.init_menu
	@palman.menu_add_done { done_and_exit } if (@state >= STATE_END)
	@palman.menu_add_undo_last
	@palman.option_menu menu
	true
end

#Button Down - Start input of End point
def onLButtonDown(flags, x, y, view)
	return if super
	@time_mouse_down = Time.now
	@time_move = 0
	@xdown = x
    @ydown = y
	@button_down = true
	reset_mark @mark_last if @state == STATE_ORIGIN
	if @palman.inference_lock || @palman.clickmode
		register_mark
		set_state @state + 1 if @state == STATE_ORIGIN
	else
		set_state @state + 1
	end	
end

def close_to_last_point(x, y)
	return false if @lst_points2d.length == 0
	pt = @lst_points2d.last
	((pt.x - x).abs < 3) && ((pt.y - y).abs < 3)
end

#Button Up - execute if move has happened, otherwise ignore
def onLButtonUp(flags, x, y, view)
	return if super
	return if @state == STATE_ORIGIN
	return if Time.now - @time_mouse_down < 0.2
	return if @button_down && ((@xdown - x).abs < 2) && ((@ydown - y) < 2)
	if (@lst_points2d.length > 1)
		set_state @state + 1
	end	
	@button_down = false
end

#Double Click to repeat with same length
def onLButtonDoubleClick(flags, x, y, view)
	if (@palman.inference_lock || @palman.clickmode) && @lst_points2d.length > 1
		set_state @state + 1
	end		
end

#Toggle Pause mode
def toggle_pause_on
	@pause_on = !@pause_on
	set_message
	onMouseMove_zero
end

#Key Up
def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true

	case key
	#Pause Mode
	when COPY_MODIFIER_KEY
		if @control_down
			@control_down = false
			onMouseMove_zero
			return if (Time.now - @time_ctrl_down) > 0.5
			toggle_pause_on
		end	
	
	#Inference Locking	
	when CONSTRAIN_MODIFIER_KEY
		if @shift_down
			@shift_down = false
			#@palman.set_inference_on false
			onMouseMove_zero
			if (Time.now - @time_shift_down) > 0.5
				register_mark unless @palman.clickmode
				@palman.set_inference_on false
				return
			else	
				@palman.set_inference_on false
				@palman.toggle_option_inference_lock
			end	
		end	
		
	when 9
		@palman.toggle_option_clickmode
		
	end	
	
	@control_down = false
	@shift_down = false
end

#Key down
def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false

	#Check options keys
	if @palman.check_function_key(key, rpt, flags, view)
		@control_down = false
		return
	end

	case key			
		#Calling options
		when COPY_MODIFIER_KEY
			@control_down = true
			@time_ctrl_down = Time.now
			return
			
		when CONSTRAIN_MODIFIER_KEY
			@shift_down = true
			@time_shift_down = Time.now
			@palman.set_inference_on true
			return
			
		else
			@control_down = false
			return
			
	end	
	@control_down = false
	@shift_down = false
	
	view.invalidate
	info_show
end

def replace_point?(pt2d, register=false)
	return 1 if @lst_points2d.length < 2
	if @palman.clickmode
		return (register || @lst_marks.length == 1) ? 1 : -1
	end
	
	#Undoing operation
	return 1 if @lst_marks.length < 2
	ptlast = @lst_points2d.last
	ptmlast = @view.screen_coords(@lst_marks[-2].pt)
	if @undoing
		if ptmlast.distance(ptlast) < @palman.px_precision * 0.5
			@undoing = false
		end	
		return -1
	end
	
	#checking for time
	delta = Time.now - @time_move
	return 0 if delta.to_f < @time_delta
	
	#checking for distance in pixel
	return -1 if @pt2d_last.distance(ptlast) < @palman.px_precision
		
	return 1
end

#Append a mark to the list
def append_mark(mark)
	return unless @state == STATE_END
	@lst_marks.push mark
end

def reset_mark(mark)
	@lst_marks = [mark]
	return unless @button_down
end

def replace_last_mark(mark=nil)
	return unless @state == STATE_END && @lst_marks.length > 1
	@lst_marks[-1..-1] = nil
	append_mark mark if mark
end

#Register a mark - used for Click mode and Inference lock mode
def register_mark
	if @state == STATE_ORIGIN
		accept_point @view, @pt_picked2d
	else	
		accept_point @view, @pt_picked2d, @palman.inference_lock || @inference_on, true
	end	
end

#Check if the current point is close to the curve being drawn
def close_to_curve(view, x, y)
	@mark_curve = nil
	return false if @lst_marks.length <= 3
	
	#checking if close to a vertex of the curve
	@lst_marks[0..-4].each do |mark|
		pt = mark.pt
		pt2d = view.screen_coords pt
		if (pt2d.x - x).abs < 5 && (pt2d.y - y).abs < 5
			@mark_curve = mark
			return true
			return false
		end
	end
	false
end

#Accept a new input point and map it on the surface
def accept_point(view, pt2d, lock=false, register=false)
	#getting the next marks
	return unless pt2d
	@ip_constrained = false
	if close_to_curve(view, pt2d.x, pt2d.y)
		mark = @mark_curve
		replace = 1
		replace_last_mark unless register
	elsif (lock || register) && ip_contrained?(@ip, view, pt2d.x, pt2d.y)
		mark = OFSG.mark_from_inputpoint view, @ip, pt2d.x, pt2d.y, [@mark_last.pt, @normaldef]
		replace = replace_point?(pt2d, register)
		dof = @ip.degrees_of_freedom
		dof = 3 unless ip_displayed?(@ip)
		if (dof <= 1)
			#puts "lock = #{lock} reg = #{register} ip = #{@ip.position} mark = #{mark.pt} last = #{@lst_marks.last.pt}"
			replace = 1 
			replace_last_mark unless register
			@ip_constrained = true
		end	
	else
		@lst_points2d.each { |pt| pt2d = pt if pt2d.distance(pt) < @pix_min }
		mark = compute_mark view, pt2d
		replace = replace_point?(pt2d, register)
	end	
	return unless mark
	
	#Replacing or adding the last point
	case replace
	when -1, 0
		@lst_points2d[-1..-1] = [pt2d]
		replace_last_mark mark
	when 1
		@lst_points2d.push pt2d
		append_mark mark
		@pt2d_last = pt2d
		@mark_last = mark
		@time_move = Time.now
	end	
end

#Check if the current screen position corresponds to a real inference
def ip_contrained?(ip, view, x, y)
	ip.pick view, x, y
	dof = ip.degrees_of_freedom
	return false if (dof == 0 && ip.vertex == nil && ip.edge == nil) || (dof == 1 && ip.edge == nil)
	#return false if (dof == 0 && ip.vertex == nil) || (dof == 1 && ip.edge == nil)
	return true if ip_displayed?(ip)
	#ip.clear
	false	
end

#Check if an input point is visible, based on Show Hidden state
def ip_displayed?(ip)
	return true if @renderop["DrawHidden"]
	vertex = ip.vertex
	if vertex
		nvis = 0
		vertex.edges.each { |e| nvis += 1 unless e.soft? || e.smooth? || e.hidden? }
		return nvis > 0
	end
	edge = ip.edge
	if edge
		return !(edge.soft? || edge.smooth? || edge.hidden?)
	end
	true
end

#Compute the mark corresponding to the point 2d
def compute_mark(view, pt2d)
	ray = view.pickray pt2d.x, pt2d.y
	ph = view.pick_helper 
	ph.do_pick pt2d.x, pt2d.y
	
	#finding the face
	face = nil
	edge = nil
	picked = ph.all_picked
	picked.each do |e|
		face = e if e.class == Sketchup::Face
		edge = e if e.class == Sketchup::Edge
	end
	
	unless face
		@ip.pick view, pt2d.x, pt2d.y
		face = @ip.face
	end
	
	#No face
	unless face
		plane = [@mark_last.pt, @normaldef]
		pt = Geom.intersect_line_plane ray, plane
		return OFSG.mark(pt, nil, nil, nil, nil)
	end
	
	#Face - Sepcial treatment for making sure the point is on the face
	plane = face.plane
	pt = Geom.intersect_line_plane ray, plane
	return OFSG.mark(pt, face, nil, edge, nil) if pt && OFSG.within_face_extended?(face, pt)

	face.vertices.each do |v|
		v.faces.each do |f|
			next if f == face
			pt = Geom.intersect_line_plane ray, f.plane
			next unless pt
			return OFSG.mark(pt, f, nil, nil, nil) if OFSG.within_face_extended?(f, pt)
		end
	end
	return nil
end

#Input of length in the VCB
def onUserText(text, view) 
	begin
		px = Traductor.string_to_integer_formula text
		return UI.beep if px == nil || px < 10 || px > 200
	rescue
		return UI.beep
	end	
	
	@palman.set_precision px
	
	view.invalidate
	info_show
end

#Porcedure to refresh the view ehn options are changed
def refresh_view
	@view.invalidate
	info_show
end

#Mouse Move method
def onMouseMove_zero
	onMouseMove @flags, @xmove, @ymove, @view
end
	
def onMouseMove(flags, x, y, view)
	#Event for the palette
	return unless x
	if super
		@not_in_viewport = true
		return
	end	
	@not_in_viewport = false
	@flags = flags

	@xmove = x
	@ymove = y
	
	#Origin Point
    if (@state == STATE_ORIGIN) #&& @button_down
		@ip.pick view, x, y
		@ip_origin.copy! @ip
		mark = OFSG.mark_from_inputpoint(view, @ip, x, y, @planedef)
		view.tooltip = @ip.tooltip
		@pt2d_last = view.screen_coords @ip.position
		@pt2d_last.z = 0
		@pt_picked2d = @pt2d_last
		@lst_points2d = [@pt2d_last]
		@mark_last = mark
		@time_move = Time.now
		
	#End Point	
	elsif (@state == STATE_END)
		return if @pause_on || Traductor.ctrl_mask?(flags)
		@pt_picked2d = Geom::Point3d.new(x, y)
		accept_point view, @pt_picked2d, @palman.inference_on || @palman.inference_lock
		if @palman.inference_on || @palman.inference_lock
			@ip.pick view, x, y
			view.tooltip = @ip.tooltip
		else
			view.tooltip = ""
		end
	end
	
	view.invalidate
	info_show
end	

#Draw method for tool
def draw(view)
	#drawing the origin
	if @state < STATE_END
		@ip_origin.draw view
		super
		return
	end	
	if (@palman.inference_on || @palman.inference_lock) && @ip_constrained
		@ip.draw view 
	elsif @mark_curve
		#view.draw_points @mark_curve.pt, 8, 2, "red"
		OFSG.draw_square view, @mark_curve.pt, 3, "red"
	end
	#view.draw_points @ip_origin.position, 6, 2, "purple"
	OFSG.draw_square view, @ip_origin.position, 3, "purple"
	
	#Drawing the Line contour
	if @palman.linemode
		if (@palman.option_group)
			color = 'darkred'
			stipple = "-.-"
		else	
			color = 'red' 
			stipple = ""
		end	
	else
		color = (@palman.option_group) ? 'orange' : 'red'
		stipple = "_"
	end
	width = 1
	view.line_width = width
	view.line_stipple = stipple
	view.drawing_color = color
	
	compute_contour
	view.draw GL_LINE_STRIP, @pts_contour if @pts_contour.length > 1
		
	#Drawing marks at control points
	if @lst_marks.length > 2
		@lst_marks[1..-2].each do |mk|
			#view.draw_points mk.pt, 6, 2, "orange"
			OFSG.draw_square view, mk.pt, 3, "orange"
		end	
	end	
		
	#Drawing the palette
	super
	
end

#display information in the Sketchup status bar
def info_show
	case @state
	when STATE_ORIGIN
		message = @msg_freehand_origin + @msg_tell
	when STATE_END
		message = @msg_freehand_end + @msg_tell
	when STATE_EXECUTION
		message = @title
	end
	
	if @palman.clickmode
		sclick = @msg_double_click
	elsif @palman.inference_lock
		sclick = @msg_double_click_lock
	elsif @palman.inference_on
		sclick = @msg_interim_click
	else
		sclick = @msg_single_click
	end
	
	if @palman.clickmode
		@palman.info_show message, { 'nbseg' => @bigparcours.length, 'msg_comp' => sclick }
	else	
		@palman.info_show message, { 'nbseg' => @bigparcours.length, 'precision' => @palman.px_precision, 'msg_comp' => sclick }
		@palman.set_message((@undoing) ? @msg_undoing_goback : nil)
	end	
end

end	#End Class TOSToolFreehand

end	#End Module SUToolsOnSurface
