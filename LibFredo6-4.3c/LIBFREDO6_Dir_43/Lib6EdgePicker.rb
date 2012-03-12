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
# Name			:   HoverSelect_Main.rb
# Original Date	:   8 May 2009 - version 1.0
# Description	:   Script to select Edges with the Eraser metaphor
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

#---------------------------------------------------------------------------------------------------------------------------
#Constants for HoverSelect Module (do not translate here, use Translation Dialog Box instead)	
#---------------------------------------------------------------------------------------------------------------------------

# Strings for the application
T6[:MSG_Status_Select] = "Click down and mouse over model to select edges (see options in contextual menu)"
T6[:TIP_Edge_Add] = "Click to Select Edge"
T6[:TIP_Edge_Del] = "Click to Unselect Edge"
T6[:TIP_Vertex_Add] = "Click to Select Edges at vertex"
T6[:TIP_Vertex_Del] = "Click to Unselect Edges at vertex"
T6[:TIP_Face] = "Click to select all edges of the face"
T6[:TIP_Exit] = "Click to Exit tool"
T6[:TIP_Group_Delete] = "Click to remove contour"
T6[:TIP_Group_Order] = "Click to change contour sorting"
T6[:TIP_Add] = "Add to selection"
T6[:TIP_Remove] = "Remove from selection"

T6[:VCB_Extend_Connected] = "ALL CONNECTED"
T6[:VCB_Extend_Curve] = "CURVE"
T6[:VCB_Extend_Follow] = "FOLLOW"
T6[:VCB_Mode_Erase] = "UNSELECT"
T6[:VCB_Rect_Processing] = "PROCESSING..."

#Contextual menus
T6[:MNU_Done] = "Done and Exit tool (Enter or click in empty space)"
T6[:MNU_Cancel] = "Clear all selection (Esc)"
T6[:MNU_History_Last] = "Undo%1"
T6[:MNU_History_Next] = "Redo%1"
T6[:MNU_History_Clear] = "Clear All selection"
T6[:MNU_History_Restore] = "Restore All selection"
T6[:MNU_History_AddEdges] = "Add edges"
T6[:MNU_History_RemoveEdges] = "Remove edges"
T6[:MNU_History_MakeContour] = "Freeze as contour"
T6[:MNU_History_RemoveContour] = "Remove contour"
T6[:MNU_History_SortContour] = "Sort contours"

T6[:MNU_Extend_By_Edges] = "Edge by Edge"
T6[:MNU_Extend_Connected] = "Extend selection to all connected edges"
T6[:MNU_Extend_Curve] = "Extend selection to curve"
T6[:MNU_Extend_Follow] = "Extend selection to cofacial and aligned edges"
T6[:MNU_AngleMax] = "Maximum Edge Angle for Follow mode in degree"
T6[:MNU_Stop_at_Crossing] = "Stop prolongation at Edge crossings"

T6[:MNU_EdgePropFilter] = "Filter on Edge properties"
T6[:MNU_EdgePropFilter2] = "Edge Prop. Filter"
T6[:MNU_RemoveFilter] = "Click to remove filter"
T6[:MNU_Init_Clear] = "Automatic Clear at startup"

#Labels for Default Parameters
T6[:DEFAULT_SectionAll] = "Active Options at start up"
T6[:DEFAULT_Flag_InitClear] = "Clear Selection when tool activated"
T6[:DEFAULT_Aperture] = "Aperture for picking in pixel (0 means Sketchup default)"
T6[:DEFAULT_Flag_Modifiers] = "Selection modifiers"
T6[:DEFAULT_Flag_EdgePropFilter] = "Filter for Edge properties"
T6[:DEFAULT_AngleMax] = "Maximum Edge Angle for Follow mode (degree)"
T6[:DEFAULT_RectMaxNum] = "Feedback for Rectangle selection when nb of elements is lower than"

#--------------------------------------------------------------------------------------------------------------
# Selection Tool for picking up entities
#--------------------------------------------------------------------------------------------------------------			 				   

class EdgePicker

# Class Variables
@@hsh_cursors = nil

#--------------------------------------------------------------------------------------------------------------
# Initialization Methods
#--------------------------------------------------------------------------------------------------------------			 				   

#Initialization of the instance
def initialize(*args)
	#Default parameters
	@anglemax = 30.degrees unless @anglemax
	@edge_prop_filter = 'P' unless @edge_prop_filter
	@modifier = 'N'
	
	#parsing the arguments
	args.each do |arg|	
		arg.each { |key, value|  parse_args(key, value) } if arg.class == Hash
	end
	
	#Initialize the Curl Manager
	hsh = { :anglemax => @anglemax.radians, :rail_display => @rail_display }
	hsh[:mesh] = true if @mode_mesh
	@curlman = CurlManager6.new hsh	
	
	@dbclick_all = false
	@option_single_remove = false

	#Configuration
	@aperture = 5 unless @aperture 
	@too_fast = @aperture * 2
	@tr_id = Geom::Transformation.new
	@rect_maxnum = 100	
	#@lightblack = 'DarkSlateGray'
	@lightblack = G6.color_edge_sel
	
	#Other initializations
	init_text
	init_cursors
	reset
end

#Assign the individual propert for the palette
def parse_args(key, value)
	skey = key.to_s
	case skey
	when /notify_proc/i
		@notify_proc = value
	when /modifier/i
		@modifier = value
	when /anglemax/i
		set_anglemax value
	when /aperture/i
		@aperture = value
	when /edge_prop_filter/i
		@edge_prop_filter = value
	when /unit_remove/i
		@option_single_remove = value
	when /dbclick_all/i
		@dbclick_all = value
	when /mesh/i
		@mode_mesh = value
	when /title/i
		@title = value
	when /stop_at_crossing/i
		@stop_at_crossing = value
	when /rail_display/i
		@rail_display = value
		
	end	
end

#Text Initialization
def init_text
	@status_text = T6[:MSG_Status_Select]
	@text_extend_connected = T6[:VCB_Extend_Connected]
	@text_extend_curve = T6[:VCB_Extend_Curve]
	@text_extend_follow = T6[:VCB_Extend_Follow]
	@text_rect_processing = T6[:VCB_Rect_Processing]
	@text_mode_erase = T6[:VCB_Mode_Erase]
	@tip_edge_add = T6[:TIP_Edge_Add]
	@tip_edge_del = T6[:TIP_Edge_Del]
	@tip_vertex_add = T6[:TIP_Vertex_Add]
	@tip_vertex_del = T6[:TIP_Vertex_Del]
	@tip_add = T6[:TIP_Add]
	@tip_remove = T6[:TIP_Remove]
	@tip_face = T6[:TIP_Face]
	@tip_exit = T6[:TIP_Exit]
	
	@mnu_clear_all = T6[:MNU_Cancel]
	@mnu_done = T6[:MNU_Done]
	
	@tip_navig_down = Traductor.encode_tip T6[:MNU_History_Clear], :arrow_down
	@tip_navig_up = Traductor.encode_tip T6[:MNU_History_Restore], :arrow_up
	@tip_history_add_edges = T6[:MNU_History_AddEdges]
	@tip_history_remove_edges = T6[:MNU_History_RemoveEdges]
	@tip_history_make_contour = T6[:MNU_History_MakeContour]
	@tip_history_remove_contour = T6[:MNU_History_RemoveContour]
	@tip_history_sort_contour = T6[:MNU_History_SortContour]
	
	@tip_connected = Traductor.encode_tip T6[:MNU_Extend_Connected], :ctrl_shift
	@tip_curve = Traductor.encode_tip T6[:MNU_Extend_Curve], :ctrl
	@tip_follow = Traductor.encode_tip T6[:MNU_Extend_Follow], :shift
	@tip_edge_by_edge = Traductor.encode_tip T6[:MNU_Extend_By_Edges]
	@tip_stop_at_crossing = Traductor.encode_tip T6[:MNU_Stop_at_Crossing]
	@mnu_edge_by_edge = Traductor.encode_menu @tip_edge_by_edge
	@mnu_connected = Traductor.encode_menu @tip_connected
	@mnu_curve = Traductor.encode_menu @tip_curve
	@mnu_follow = Traductor.encode_menu @tip_follow
	@tip_anglemax = T6[:MNU_AngleMax]
	@mnu_anglemax = @tip_anglemax
	@mnu_stop_at_crossing = @tip_stop_at_crossing
	
	@mnu_init_clear = T6[:MNU_Init_Clear]
end

#Activation of the tool
def reset
	@model = Sketchup.active_model
	@selection = @model.selection
	@view = @model.active_view
	@eye = @view.camera.eye
	
	#@ph = @view.pick_helper
	@ip = Sketchup::InputPoint.new		
	@button_down = false
	@ctrl_down = false
	@shift_down = false	
	@timer_toggle = nil
	@xdown = nil
	@ydown = nil	
	
	@mode_erase = false
	@face = nil
	
	@history = []
	@ipos_history = 0
	
	@hsh_all_vertices = {}
	
	@hsh_sel_edges = {}
	@hsh_sel_faces = {}
end

def reset_selection
	@hsh_all_vertices = {}
	
	@hsh_sel_edges = {}
	@hsh_sel_faces = {}
end

#---------------------------------------------------------------------------------------------------------------------------
# Cursor Management
#---------------------------------------------------------------------------------------------------------------------------

def init_cursors
	return if @@hsh_cursors
	@@hsh_cursors = {}
	@hotx = 2
	@hoty = 2
	@size_cursor = 32
	
	#Void
	['N', 'C', 'F', 'A'].each do |mod|
		create_cursor 'Void', mod
		['0', 'M', 'P'].each do |sign|
			create_cursor 'Edge', sign, mod
			create_cursor 'Face', sign, mod
			create_cursor 'Vertex', sign, mod
		end
	end
	create_cursor 'Invalid'
	create_cursor 'Validate'
	create_cursor 'Rectangle'
	create_cursor 'Empty'				
end

def create_cursor(*args)
	name = args.join '_'
	@@hsh_cursors[name] = MYPLUGIN.create_cursor 'Cursor_Picker_' + name, @hotx, @hoty
end

def get_cursor_id(lnames)
	ic = @@hsh_cursors[lnames.join('_')]
	(ic) ? ic : 0
end

#Setting the proper cursor
def onSetCursor
	ln = (@outside) ? ['Empty'] : ['Void', @modifier]
	if @mode_rectangle
		ln = ['Rectangle']
	elsif @no_entity
		ln = ['Edge', 'P', @modifier] if @button_down && @entity_down
	elsif @deny_entity
		ln = ['Invalid']
	elsif @mode_erase || (@entity && !@button_down && selection_include?(@entity))
		ln = (@vertex_sel && !@button_down) ? ['Vertex', 'M', @modifier] : ['Edge', 'M', @modifier]
	elsif @face
		ln = ['Face', '0', @modifier] unless (@button_down && !@xdown)
	elsif @entity
		ln = (@vertex_sel && !@button_down) ? ['Vertex', 'P', @modifier] : ['Edge', 'P', @modifier]
	end	
	get_cursor_id ln
end

#---------------------------------------------------------------------------------------------------------------------------
# Initial Selection
#---------------------------------------------------------------------------------------------------------------------------

#check initial selection
def check_initial_selection(accept=true)
	return @selection.clear if @init_clear
	
	@old_selection = @selection.to_a.clone
	@selection.clear
	
	if @curlman
		lst_groups = @curlman.analyze_initial_selection @old_selection
		return if lst_groups.length == 0
		@from_preselection = (lst_groups.length > 0) 
		accept_current_selection
		history_initial
	else
		ls = @old_selection.find_all { |e| check_entity?(e) }
		unless ls.empty?
			selection_add ls, true	
			#notify_action :curl_accept if accept
		end	
	end	
end

#Check the order of curves
def set_contours_order(lorder)
	return unless @curlman && lorder
	@curlman.group_set_order lorder
end

#Indicate if the analysis was done from a user preselection or an interactive selection
def from_user_selection?
	@from_preselection
end

#Clear selection
def clear_selection
	selection_clear
	onMouseMove_zero
end

#Compute the contours
def get_contours
	@curlman.get_contours
end

def get_cells
	@curlman.get_cells
end
#---------------------------------------------------------------------------------------------------------------------------
# Selection and Callbacks Management interface for calling application
#---------------------------------------------------------------------------------------------------------------------------

def notify_action(action, ls=true)
	if action == :outside
		action = :finish if @outside
		@outside = !@outside
	else
		@outside = false
	end
	
	if @notify_proc && !(action.to_s =~ /curl/)
		status = @notify_proc.call action, ls
		return nil unless status
		ls = status if status.class == Array
	end
	return ls unless @curlman
	
	#Updating the Curl Manager
	case action
	when :edge_add, :edge_remove
		@curlman.update_current_selection action, ls, @tr, @parent
		@notify_proc.call :curl_update, ls if @notify_proc
	when :outside, :curl_accept
		@from_preselection = false
		accept_current_selection
	end
	
	ls
end

def curlman_group_restore(lgrp)
	return if lgrp.length == 0
	@curlman.group_restore lgrp
	reset_selection
	@notify_proc.call :curl_accept, true if @notify_proc
end

#Accept current selection
def accept_current_selection(nostore=false)
	newgroups = @curlman.accept_current_selection
	return if newgroups.length == 0
	history_store 'G+', newgroups, @tip_history_make_contour unless nostore
	reset_selection
	@notify_proc.call :curl_accept, true if @notify_proc
end

#Force termination of Selection process
def terminate_current_selection
	notify_action :outside
	notify_action :outside
end

#---------------------------------------------------------------------------------------------------------------------------
# Parameter Management	
#---------------------------------------------------------------------------------------------------------------------------

#dialog box for Edge property filter
def ask_prop_filter
	result = G6.ask_edge_prop_filter T6[:MNU_EdgePropFilter], @edge_prop_filter
	filter_edges result if result
end

def filter_edges(filter)
	if filter != @edge_prop_filter
		@edge_prop_filter = filter
		ldel = @hsh_sel_edges.values.find_all { |e| !check_entity?(e) }
		selection_remove ldel if ldel.length > 0
	end	
end

#toggle the auto clear at startup	
def toggle_init_clear
	@init_clear = !@init_clear
end
	
#toggle functions for options
def toggle_plain_edges
	@plain_edges = !@plain_edges
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

def toggle_stop_at_crossing
	@stop_at_crossing = !@stop_at_crossing
end

def save_toggles
	@old_modifier = @modifier
end

def restore_toggles
	return if @toggle_now && Time.now.to_f - @toggle_now < 0.8
	@modifier = @old_modifier
end

#---------------------------------------------------------------------------------------------------------------------------
# Cursor Management 	
#---------------------------------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------------------------------
# Palette and Contextual Menu Management	
#---------------------------------------------------------------------------------------------------------------------------

def make_proc(&proc) ; proc ; end

#Palette contribution
def contribute_palette(palette)
	draw_local = self.method "draw_button_opengl"

	hshb = {:width => 20, :height => 16, :main_color => 'blue' }
	
	proc = make_proc() { @modifier ==  'N' }
	hsh = { :value_proc => proc, :tooltip => @tip_edge_by_edge, :draw_proc => draw_local, :rank => 1 }
	palette.declare_button(:t_extend_edge_by_edge, hsh, hshb) { toggle_modifier 'N' }

	proc = make_proc() { @modifier == 'F' }
	hsh = { :value_proc => proc, :tooltip => @tip_follow, :draw_proc => :arrow_RL }
	palette.declare_button(:t_extend_follow, hsh, hshb) { toggle_extend_follow }
	
	proc = make_proc() { @modifier ==  'A' }
	hsh = { :value_proc => proc, :tooltip => @tip_connected, :draw_proc => :arrow_RULD, :rank => 1 }
	palette.declare_button(:t_extend_connected, hsh, hshb) { toggle_modifier 'A' }
	
	proc = make_proc() { @modifier == 'F' }
	tproc = make_proc() { sprintf "%2i", @anglemax.radians }
	hsh = { :value_proc => proc, :text_proc => tproc, :tooltip => @tip_anglemax,
            :main_color => 'green', :frame_color => 'red'}
	palette.declare_button(:t_anglemax, hsh, hshb) { ask_angle_max }

	proc = make_proc() { @modifier == 'C' }
	hsh = { :value_proc => proc, :tooltip => @tip_curve, :draw_proc => :circle_E2, :rank => 1,
            :main_color => 'blue', :draw_scale => 0.75 }
	palette.declare_button(:t_extend_curve, hsh, hshb) { toggle_extend_curve }
	
	proc = make_proc() { @stop_at_crossing }
	hsh = { :value_proc => proc, :tooltip => @tip_stop_at_crossing, :draw_proc => draw_local }
	palette.declare_button(:t_stop_at_crossing, hsh, hshb) { toggle_stop_at_crossing }
	

	palette.declare_separator
	
	tip_proc = make_proc() { |code| history_proc_tip code }
	gray_proc = make_proc() { |code| history_proc_gray code }
	hsh = { :grayed_proc => gray_proc, :tip_proc => tip_proc, :compact => true }
	palette.declare_historical(:t_group_ep_history, hsh) { |code| history_proc_action code }
end
	
#Custom drawing of buttons
def draw_button_opengl(symb, dx, dy)
	code = symb.to_s
	lst_gl = []
	xmid = dx / 2
	ymid = dy / 2
	x4 = dx / 4
	y4 = dy / 4
	
	case code
	
	#Strict Offset
	when /t_extend_edge_by_edge/i
		pts = []
		pts.push Geom::Point3d.new(1, 2, 0)
		pts.push Geom::Point3d.new(1, dy-2, 0)
		lst_gl.push [GL_LINE_STRIP, pts, 'black', 1]
		pts = []
		pts.push Geom::Point3d.new(1, dy-2, 0)
		pts.push Geom::Point3d.new(dx-1, dy-2, 0)
		lst_gl.push [GL_LINE_STRIP, pts, 'blue', 2]
		pts = []
		pts.push Geom::Point3d.new(dx-1, dy-2, 0)
		pts.push Geom::Point3d.new(dx-1, 2, 0)
		lst_gl.push [GL_LINE_STRIP, pts, 'black', 1]

	#Rounding option	
	when /t_stop_at_crossing/i
		pts = []
		pts.push Geom::Point3d.new(2, 1, 0)
		pts.push Geom::Point3d.new(xmid, ymid, 0)
		lst_gl.push [GL_LINE_STRIP, pts, 'blue', 2, '']
		pts = []
		pts.push Geom::Point3d.new(xmid, ymid, 0)
		pts.push Geom::Point3d.new(dx-1, dy-1, 0)
		lst_gl.push [GL_LINE_STRIP, pts, 'black', 1, '']
		pts = []
		pts.push Geom::Point3d.new(xmid, ymid, 0)
		pts.push Geom::Point3d.new(1, dy-1, 0)
		lst_gl.push [GL_LINE_STRIP, pts, 'black', 1, '']
		
		pts = []
		pts.push Geom::Point3d.new(xmid-2, ymid-2, 0)
		pts.push Geom::Point3d.new(xmid-2, ymid+2, 0)
		pts.push Geom::Point3d.new(xmid+2, ymid+2, 0)
		pts.push Geom::Point3d.new(xmid+2, ymid-2, 0)
		lst_gl.push [GL_QUADS, pts, 'red']
		
	end
	
	lst_gl
end
	
#Contextual menu
def contextual_menu_contribution(cxmenu)
	#Modifiers
	cxmenu.add_sepa
	cxmenu.add_item(@mnu_connected) { toggle_extend_connected }
	cxmenu.add_item(@mnu_curve) { toggle_extend_curve }
	cxmenu.add_item(@mnu_follow) { toggle_extend_follow }
	cxmenu.add_item(@mnu_anglemax) { ask_angle_max }
	cxmenu.add_item(@mnu_stop_at_crossing) { toggle_stop_at_crossing }
	
	#Function Key menus
	cxmenu.add_sepa
	cxmenu.add_item(T6[:MNU_EdgePropFilter], :tab, G6.edge_filter_text(@edge_prop_filter)) { ask_prop_filter }

	#Navigation in history 
	cxmenu.add_sepa
	mnu_navig_left = Traductor.encode_menu @tip_navig_left
	mnu_navig_right = Traductor.encode_menu @tip_navig_right	
	mnu_navig_down = Traductor.encode_menu @tip_navig_down
	mnu_navig_up = Traductor.encode_menu @tip_navig_up
	cxmenu.add_item(mnu_navig_left) { history_undo } unless history_proc_gray(:undo)
	cxmenu.add_item(mnu_navig_right) { history_redo } unless history_proc_gray(:redo)
	cxmenu.add_item(mnu_navig_down) { history_clear } unless history_proc_gray(:clear)
	cxmenu.add_item(mnu_navig_up) { history_restore } unless history_proc_gray(:restore)
end

#Prompt a dialog box to ask for the Max angle in Follow mode
def ask_angle_max
	val = @anglemax.radians
	hparams = {}
	title = @mnu_anglemax
	label = @mnu_anglemax
	
	#invoking the dialog box
	results = [val.to_s + 'd']
	while true
		results = UI.inputbox [label], results, [], title
		return nil unless results
		resval = Traductor.string_to_angle_degree results[0], true
		break if resval
	end	

	#Transfering the parameter
	set_anglemax resval
end

#---------------------------------------------------------------------------------------------------------------------------
# Mouse Click Management	
#---------------------------------------------------------------------------------------------------------------------------

#Cancel event
def onCancel(flag, view)
	#User did an Undo
	case flag
	when 1, 2	#Undo or reselect the tool
		activate
		return
	when 0	#user pressed Escape
		handle_escape
	end
end

#Handle the Escape key event
def handle_escape
	if @mode_rectangle
		@mode_rectangle = false
		@button_down = false
	else	
		history_undo
	end	
	onMouseMove_zero
end

#Button click - Means that we end the selection
def onLButtonDown(flags, x, y, view)
	#selection of a group for deletion
	#return if @curlman && @curlman.group_selected?(x, y, true)
	return if @curlman && @curlman.onLButtonDown(flags, x, y, view)

	entity = entity_under_mouse(view, x, y)
	@entity_down = @entity
	@parent_down = @parent
	@button_down = true
	@last_entity = nil
	@xdown = x
	@ydown = y
	if entity && selection_include?(entity)
		@mode_erase = true
	else
		@mode_erase = false
	end	

	#onMouseMove_zero
end

def cancel_button_down(flags)
	if (flags >= 0) && @button_down && (flags & 1 != 1)
		@button_down = false
		@mode_rectangle = false
		return true
	end	
	false
end	
	
#Button click - Means that we end the selection
def onLButtonUp(flags, x, y, view)
	prevbut = @button_down
	@button_down = false
	@double_click = false
	@parent_down = nil
	
	#rectangle mode
	if @mode_rectangle
		set_warning @text_rect_processing
		UI.start_timer(0.3) { rectangle_compute_selection }
		return
	
	elsif @curlman && (laction = @curlman.onLButtonUp(flags, x, y, view))
		execute_from_curlman laction
		return
		
	#Exit the tool
	elsif @no_entity && @last_entity == nil
		onMouseMove_zero
		return click_outside if prevbut
	end	
	
	#selection mode
	#notify_action :end_edit
	entity = entity_under_mouse(view, x, y)
	if close_down_in_pixel(x, y) && !@entity_down
		@face_init = (@face) ? @face : nil
	end	
	@mode_erase = false
	@last_entity = nil
	#onMouseMove_zero
end

#Execute actions from Curlman interactive GUI
def execute_from_curlman(laction)
	action, param = laction
	case action
	when :group_remove
		curlman_group_remove
	when :group_sort
		curlman_group_sort param
	end	
end

def enter_selection_mode(flags, x, y, view)
	entity_under_mouse(view, x, y)
	if close_down_in_pixel(x, y) && !@entity_down
		@face_init = (@face) ? @face : nil
	end	
	@mode_erase = false
	@last_entity = nil
	onMouseMove_zero
end

def onLButtonDoubleClick(flags, x, y, view)
	if !@no_entity
		@double_click = true
		enter_selection_mode flags, x, y, view
		@double_click = false			
	elsif !@deny_entity
		notify_action :finish
	end
end

#Check if the current mouse position is closed from the Click down position
def close_down_in_pixel(x, y)
	return false unless @xdown
	(x - @xdown).abs < 3 && (y - @ydown).abs < 3
end
	
#---------------------------------------------------------------------------------------------------------------------------
# Key Management	
#---------------------------------------------------------------------------------------------------------------------------
	
#Key Down received
def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false
	case key			
	when CONSTRAIN_MODIFIER_KEY
		@shift_down = true
		if @mode_rectangle
			rectangle_toggle_shift
		else
			@timer_toggle = UI.start_timer(0.5) { toggle_both } unless @timer_toggle
		end	

	when COPY_MODIFIER_KEY
		@ctrl_down = true
		if @mode_rectangle
			rectangle_toggle_ctrl
		else
			@oldmodifier = @modifier
			@time_key = Time.now.to_f
			@timer_toggle = UI.start_timer(0.5) { toggle_both } unless @timer_toggle
		end	
	
	else
		if @mode_rectangle
			rectangle_toggle_reverse if [VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT].include?(key)
		else
			history_navigate key
		end	
	end
	view.invalidate	
end

#Key up received
def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true
	case key			
	when CONSTRAIN_MODIFIER_KEY
		@shift_down = false
		restore_toggles
	when COPY_MODIFIER_KEY
		@ctrl_down = false
		restore_toggles
	when 8
		toggle_init_clear
	when 9
		ask_prop_filter
	else	
		if @time_key && (Time.now.to_f - @time_key < 0.8)
			@modifier = @oldmodifier
		end	
	end
	view.invalidate	
end

#Return key received
def onReturn(view)
	click_outside
end

#History_navigation
def history_navigate(key)
	case key
	when VK_LEFT
		history_undo
	when VK_RIGHT
		history_redo
	when VK_DOWN
		history_clear
	when VK_UP
		history_restore
	end
end
	
#Check the validity of entity
def check_class?(entity)
	entity && entity.class == Sketchup::Edge
end

def check_prop?(entity)
	G6.edge_filter?(entity, @edge_prop_filter) || entity.faces.length < 2
end

def check_entity?(entity)
	check_class?(entity) && check_prop?(entity)
end

#---------------------------------------------------------------------------------------------------------------------------
# Information Management	
#---------------------------------------------------------------------------------------------------------------------------

def set_tooltip(tip, noinfo=false)
	@view.tooltip = (tip) ? "    " + tip : ''
end

def set_warning(tip)
	@view.tooltip = tip
end

#Manage the status bar
def info_show()
	title = ((@title) ? @title + ' : ' : '') + @status_text
	Sketchup.set_status_text title + ' --> ' + G6.edge_filter_text(@edge_prop_filter)
	svalue = ""
	label = ""
	if @modifier == 'A'
		label = @text_extend_connected
	elsif @modifier == 'F'
		label = @text_extend_follow
	elsif @modifier == 'C'
		label = @text_extend_curve
	end	
	if @mode_erase
		label = @text_mode_erase
	elsif @rect_processing
		label = @text_rect_processing
	end
	text_angle = (@modifier == 'F') ? sprintf("%3.1f", @anglemax.radians) + " deg." : ""
	
	Sketchup.set_status_text label, SB_VCB_LABEL
	Sketchup.set_status_text text_angle, SB_VCB_VALUE
end

#---------------------------------------------------------------------------------------------------------------------------
# Drawing methods	
#---------------------------------------------------------------------------------------------------------------------------

#Drawing method - Used to add cursor indicator
def draw(view)
	if @mode_rectangle
		rectangle_draw(view) if @x
	else
		#draw_faces_hi view, @ls_faces_hi, @tr
		@curlman.draw_contours view
		draw_component view, @parent if @parent && @parent != @model
	end	

	if @entity.class == Sketchup::Edge
		view.drawing_color = @lightblack
		view.line_width = 3
		view.line_stipple = ''
		lpt = [@entity.start.position, @entity.end.position]
		view.draw GL_LINE_STRIP, lpt.collect { |pt| G6.small_offset view, @tr * pt }
	end	
	
end

#Change of view - Resetting the parameters for rectangle selection
def resume(view)
	@lst_all_entities = nil
	@eye = @view.camera.eye
end

def draw_component(view, parent)
	return unless parent.valid?
	view.line_stipple = ''
	view.line_width = 1
	view.drawing_color = 'gray'
	llines = G6.grouponent_box_lines(view, parent, @tr)
	view.draw GL_LINES, llines unless llines.empty?
end

def draw_faces_hi(view, lfaces, tr)
	return unless lfaces
	view.drawing_color = 'lightgrey'
	lfaces.each do |face|
		lp = face.outer_loop.vertices.collect { |v| G6.small_offset(view, tr * v.position) }
		view.draw GL_POLYGON, lp
	end
end

def selection_draw(view)
	llines = @hsh_sel_edges.values.collect { |e| [G6.small_offset(view, e.start.position), G6.small_offset(view, e.end.position)] }
	llines.flatten!
	view.drawing_color = 'orange'
	view.line_stipple = ''
	view.line_width = 3
	view.draw GL_LINES, llines if llines.length > 0
end

#---------------------------------------------------------------------------------------------------------------------------
# Mouse Move Management	
#---------------------------------------------------------------------------------------------------------------------------

#Mouse Move method
def onMouseMove_zero
	onMouseMove(-1, @x, @y, @view) if @x
end

def onMouseMove(flags, x, y, view)
	#check if within the palette
	return unless x
	@x = x
	@y = y
	
	#Consistency of state for mouse and keyboard
	cancel_button_down(flags) if flags

	if flags && flags >= 0 && Traductor.shift_mask?(flags) != @shift_down
		@modifier = @old_modifier
		@shift_down = false
	end	
	
	#Checking if the mouse is in a Group
	#if @curlman && @curlman.onMouseMove(flags, x, y, view)
	if !@button_down && @curlman && @curlman.onMouseMove(flags, x, y, view)
		compute_tooltip
		return
	end	
	
	#Manage rectangle mode
	if @mode_rectangle
		return rectangle_continue(x, y)
	end
	
	#checking Rectangle selection mode
	unless close_down_in_pixel(x, y)
		if @entity_down == nil && @button_down
			return rectangle_start
		else
			@xdown = nil
			@ydown = nil
		end
	end
	
	#Checking if Mouse moving too fast
	fly_over(view, x, y) if @button_down
	
	#checking entity under mouse	
	entity_under_mouse view, x, y 
	
	#Determining the tooltip
	compute_tooltip
	
	#Computing the entity
	if @face_init
		manage_selection()
		@last_entity = nil
	elsif @entity
		if @button_down || @double_click
			manage_selection()
		elsif !@face_init	
			if selection_include?(@entity)
				set_tooltip((@vertex_sel) ? @tip_vertex_del : @tip_edge_del)
			else	
				set_tooltip((@vertex_sel) ? @tip_vertex_add : @tip_edge_add)
			end	
			@last_entity = nil
		end	
	end	
	
	@xprev = x
	@yprev = y
end	

#Compute the tooltip based on status
def compute_tooltip
	ttip = nil
	if @curlman && (ttip = @curlman.get_tooltip)
		ttip = nil if ttip == ''
	elsif @no_entity && @last_entity == nil && !@button_down
		if @curlman
			ttip = @curlman.get_tooltip_in_void
		end	
		ttip = @tip_exit unless ttip
	elsif @face && !@button_down
		ttip = @tip_face
	else
		ttip = (@mode_erase) ? @tip_remove : @tip_add
	end	
	set_tooltip ttip
end

#Find the closest edge to the mouse
def closest_entity(view, ip, x, y)
	ip_entity = [ip.vertex, ip.edge, ip.face].find { |e| e }
	return ip_entity if !ip_entity.instance_of?(Sketchup::Vertex)
	ledges = ip_entity.edges.find_all { |e| check_entity?(e) }
	return @ip.face if ledges.empty?
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

#Identify the entity under the mouse
def entity_under_mouse(view, x, y)
	#initialization
	@deny_entity = false
	@entity = nil
	@no_entity = false
	@face = nil
	@vertex_sel = nil
	
	#Picking entities
	@ip.pick view, x, y, @ip
	pt2d = view.screen_coords(@ip.position)
	entity = closest_entity view, @ip, x, y
	
	#Determining the component parent and the transformation
	ll = @model.raytest view.pickray(x, y)
	@parent = @model
	@tr = @tr_id
	if ll	
		lcomp = ll[1].reverse.find_all { |e| G6.is_grouponent?(e) }
		comp = lcomp.first
		if comp	
			lcomp.each { |c| @tr = c.transformation * @tr }
			@parent = comp
		end	
	end
	if entity == nil || entity.parent == @model
		@parent = @model
		@tr = @tr_id
	elsif entity.parent != G6.grouponent_definition(@parent) 
		#####if entity.parent.instances.length == 1
		if defined?(entity.parent.instances) && entity.parent.instances.length >= 1
			@parent = entity.parent.instances[0]
			@tr = @ip.transformation
		else
			entity = nil
		end	
	end
				
	#Computing the resulting entity
	if entity
		if @parent_down && @parent != @parent_down
			@deny_entity = true
		elsif check_entity?(entity)
			if @ip.vertex && (!@button_down || @entity_down == entity) && 
			   (entity.length > view.pixels_to_model(20, @tr * @ip.vertex.position))
				@vertex_sel = @ip.vertex if @modifier == 'N'
			end	
			@entity = entity
		elsif entity.class == Sketchup::Face
			@face = entity
		else
			@deny_entity = true
		end	
	elsif [@ip.vertex, @ip.edge, @ip.face].find { |e| e }
		@deny_entity = true
	else
		@no_entity = true	
	end
	@entity
end

#Manage selection when mouse passes over point x, y
def fly_over(view, x, y)

	#check whether the next mouse position is far from previous
	d = move_too_fast(x, y)
	return unless d
	
	#SCanning the intermediate position
	aperture = (@aperture) ? @aperture : 5
	n = (d / aperture).ceil
	origin = Geom::Point3d.new @xprev, @yprev, 0
	target = Geom::Point3d.new x, y, 0
	incr = 1.0 / n
	for i in 1..n-1
		step = i * incr
		pt = Geom.linear_combination step, origin, 1 - step, target
		entity_under_mouse view, pt.x, pt.y
		manage_selection if @entity
	end	
end

#Check if mouse move is too fast
def move_too_fast(x, y)
	return nil unless @xprev
	d = Math.sqrt((x - @xprev) * (x - @xprev) + (y - @yprev) * (y - @yprev))
	(d > @too_fast) ? d : nil
end

#---------------------------------------------------------------------------------------------------------------------------
# Exceution of actions	
#---------------------------------------------------------------------------------------------------------------------------

#Add Edges to the current selection
def selection_add(ls, nostore=false)
	ls = ls.find_all { |e| e && e.valid? && !selection_include?(e)}
	return ls if ls.empty?
	ls.uniq!
	ls = notify_action :edge_add, ls
	return ls unless ls && !ls.empty?
	history_store 'A', ls, @tip_history_add_edges unless nostore
	ls.each { |e| @hsh_sel_edges[get_id_entity(e)] = e }
	ls
end

#Remove Edges from the current selection
def selection_remove(lse, nostore=false)
	ls = lse.find_all { |e| e && e.valid? && selection_include?(e)}
	return ls if ls.empty?
	ls = notify_action :edge_remove, ls
	return ls unless ls && !ls.empty?
	history_store 'E', ls, @tip_history_remove_edges unless nostore
	ls.each { |e| @hsh_sel_edges.delete get_id_entity(e) }
	ls
end

def selection_clear
	selection_remove @hsh_sel_edges.values 
	@hsh_sel_edges = {}
end

def selection_include?(entity)
	return false unless entity.valid?
	(@hsh_sel_edges[get_id_entity(entity)] != nil)
end

def selection_include_all?(lentity)
	le = lentity.find_all { |e| selection_include?(e) }
	(le.length == lentity.length)
end

def get_id_entity(entity)
	entity.entityID.to_s + @parent.inspect + @tr.to_a.inspect
end

#Action to be executed
def click_outside
	notify_action :outside
end

#Remove a group for Curl Manager
def curlman_group_remove(grp=nil, nostore=false)
	grp = @curlman.group_which_selected? unless grp
	return unless grp
	@curlman.group_remove grp
	history_store 'G-', grp, @tip_history_remove_contour unless nostore
end

#Resort groups for Curl Manager
def curlman_group_sort(lspec, nostore=false)
	@curlman.group_sort_from_spec lspec
	history_store 'Sort', lspec, @tip_history_sort_contour unless nostore
end

def curlman_group_reinsert(grp)
	@curlman.group_reinsert grp
end

#---------------------------------------------------------------------------------------------------------------------------
# Management of Edge selection	
#---------------------------------------------------------------------------------------------------------------------------

#Manage the selection for adding or removing edges to the selection
def manage_selection
	return if @last_entity && @last_entity == @entity
	ls = []
	
	#Erase mode
	if @mode_erase && @option_single_remove
		ls = (@vertex_sel && @last_entity == nil) ? @vertex_sel.edges.to_a : [@entity]
		selection_remove ls
		@last_entity = @entity
		return
	end

	#Connected extension
	if @face_init
		if @modifier == 'A' || @double_click
			ls = @face_init.all_connected.find_all { |e| check_entity?(e) }
		else
			ls = G6.edges_around_face @face_init
		end	
		@face_init = nil
		if !@double_click && selection_include_all?(ls)
			selection_remove ls
			return
		end	
	else
		ls = (@vertex_sel && @last_entity == nil) ? @vertex_sel.edges.to_a : [@entity]
	end	
	
	#Finding the list of edges based on Modifier
	if @entity
		if @modifier == 'A' || @double_click
			ls |= G6.curl_all_connected(@entity).find_all { |e| check_entity?(e) }
		elsif @modifier == 'C'
			curve = @entity.curve
			ls |= curve.edges if curve
		elsif @modifier == 'F'
			ls |= G6.curl_edges @entity
			ls |= G6.curl_follow_extend(@entity, @anglemax, @stop_at_crossing) { |e| check_entity?(e) } #if ls.length == 1
		end	
		@last_entity = @entity
	end
		
	#adding to the selection
	if @mode_erase && !@double_click
		selection_remove ls
	else
		selection_add ls
	end	
end	

#---------------------------------------------------------------------------------------------------------------------------
# History Management	
#---------------------------------------------------------------------------------------------------------------------------

#Store action for History navigation
def history_store(code, ls, text=nil)
	@history[@ipos_history..-1] = []
	@history.push [code, ls, @tr, @parent, text]
	@ipos_history += 1
	history_compute_texts
end

def history_compute_texts	
	if @ipos_history > 0
		txundo = ' --> ' + @history[@ipos_history-1][4]
	else
		txundo = ''
	end	
	@tip_navig_left = Traductor.encode_tip T6[:MNU_History_Last, txundo], [:escape, :arrow_left]
	
	if @ipos_history < @history.length
		txredo = ' --> ' + @history[@ipos_history][4]
	else
		txredo = ''
	end	
	@tip_navig_right = Traductor.encode_tip T6[:MNU_History_Next, txredo], :arrow_right
end

#Construct the initial history
def history_initial
	@history = @curlman.simulate_history @tip_history_add_edges, @tip_history_make_contour
	@ipos_history = @history.length
	history_compute_texts
	@history.each do |h|
		code, ledges, tr, parent = h
		if code == 'A'
			ledges.each do |e|
				id = e.entityID.to_s + parent.inspect + tr.to_a.inspect
			end	
		end
	end	
end

#Undo one step from history
def history_undo
	return if @ipos_history == 0
	@ipos_history -= 1
	code, ls, tr, parent = @history[@ipos_history]
	@tr = tr
	@parent = parent
	case code
	when 'A'
		selection_remove ls, true
	when 'E'
		selection_add ls, true
	when 'G-'
		curlman_group_reinsert ls
	when 'G+'
		ll = @curlman.group_unmake ls
		ll.each do |info|		
			ls, @tr, @parent = info
			selection_add ls, true
		end	
	when 'Sort'	
		curlman_group_sort ls, true
	else
		return
	end	
	history_compute_texts
end

#Redo one step from history
def history_redo
	return UI.beep if @ipos_history == @history.length
	code, ls, tr, parent = @history[@ipos_history]
	@tr = tr
	@parent = parent
	case code
	when 'A'
		selection_add ls, true
	when 'E'
		selection_remove ls, true
	when 'G-'
		curlman_group_remove ls, true
	when 'G+'
		curlman_group_restore ls
		@outside = true
	when 'Sort'	
		curlman_group_sort ls, true
	else
		return
	end	
	@ipos_history += 1
	history_compute_texts
end

#Clear all from history
def history_clear
	return UI.beep if @ipos_history == 0
	for i in 1..@ipos_history
		history_undo
	end	
end

#Restore all from history
def history_restore
	len = @history.length
	return UI.beep if @ipos_history == len
	for i in @ipos_history..len
		history_redo
	end	
end

#Notification proc for action of History buttons
def history_proc_action(code)
	case code
	when :undo
		history_undo
	when :redo
		history_redo
	when :clear
		history_clear
	else
		history_restore
	end
end

#Notification proc for tooltips of History buttons
def history_proc_tip(code)
	case code
	when :undo
		@tip_navig_left
	when :redo
		@tip_navig_right
	when :clear
		@tip_navig_down
	else
		@tip_navig_up
	end
end

def history_make_text(code)

end

#Notification proc for state of History buttons
def history_proc_gray(code)
	case code
	when :undo, :clear
		@ipos_history == 0
	when :redo, :restore
		@ipos_history >= @history.length
	else
		false
	end
end

#---------------------------------------------------------------------------------------------------------------------------
# Rectangle Selection	
#---------------------------------------------------------------------------------------------------------------------------

#draw the selection rectangle
def rectangle_draw(view)
	return false unless @mode_rectangle
	return true unless @pt_rect
	view.drawing_color = (@rect_erase) ? 'red' : 'green'
	view.line_width = (@rect_hidden) ? 4 : 2
	if @rect_reverse
		view.line_stipple = '-'
	else
		view.line_stipple = ''
	end
	
	view.draw2d GL_LINE_STRIP, @pt_rect
	
	view.line_stipple = ''
	if @rect_erase
		view.line_width = 3
		view.drawing_color = 'black'	
	else
		view.line_width = 3
		view.drawing_color = 'blue'	
	end
	view.drawing_color = (@rect_erase) ? 'lightcoral' : 'lime'	
	view.draw GL_LINES, @entities_pairs.collect { |pt| G6.small_offset(view, pt) } if @entities_pairs && @entities_pairs.length > 1
	
	true
end

#Start Rectangle Selection mode
def rectangle_start
	@mode_rectangle = true
	@parent = @model
	@tr = @tr_id
	@rect_erase = @ctrl_down
	@rect_hidden = @shift_down
	@rect_inv = false
	origin = Geom::Point3d.new(@xdown, @ydown, 0) 
	@pt_rect = [origin, origin.clone, origin.clone, origin.clone, origin]
	if entities_too_big?
		@nb_all_entities = @rect_maxnum + 1
		@lst_all_entities = nil	
	end	
	rectangle_tooltip
	@view.invalidate
end

#Continue Rectangle Selection mode
def rectangle_continue(x, y)
	@mode_rectangle = true
	@pt_rect[1].y = y
	@pt_rect[2].x = x
	@pt_rect[2].y = y
	@pt_rect[3].x = x
	@rect_reverse = (@pt_rect[0].x > @pt_rect[2].x)
	@rect_reverse = !@rect_reverse if @rect_inv
	rectangle_tooltip
	rectangle_eval_selection if @nb_all_entities < @rect_maxnum
	@view.invalidate
end

def rectangle_tooltip
	tip = "Selection by rectangle:"
	tip += (@rect_reverse) ? " PARTIAL" : " TOTAL"
	tip += (@rect_hidden) ? " - All" : " - Visible"
	tip += (@rect_erase) ? " - REMOVE" : " - ADD"
	set_tooltip tip, false
end

def rectangle_toggle_shift
	@rect_hidden = !@rect_hidden
	rectangle_tooltip
	onMouseMove_zero
end

def rectangle_toggle_ctrl
	@rect_erase = !@rect_erase
	rectangle_tooltip
	onMouseMove_zero
end

def rectangle_toggle_reverse
	@rect_inv = !@rect_inv
	rectangle_tooltip
	onMouseMove_zero
end

#Compute the selection with the rectangle
def rectangle_compute_selection
	@rect_processing = true
	info_show
	@view.invalidate
	entities_build_list
	rectangle_eval_selection
	if @entities_rect.length > 0
		if @rect_erase
			selection_remove @entities_rect
		else	
			selection_add @entities_rect
		end	
	end	
	@rect_processing = false
	@mode_rectangle = false
	@rect_erase = false	
	@rect_hidden = false		
	@pt_rect = nil
	@entities_pairs = nil
	info_show
	onMouseMove_zero
end

#Evaluate the selections enclosed within a rectangle
def rectangle_eval_selection
	@entities_rect = []
	@entities_pairs = []
	xmin = [@pt_rect[0].x, @pt_rect[2].x].min
	xmax = [@pt_rect[0].x, @pt_rect[2].x].max
	ymin = [@pt_rect[0].y, @pt_rect[2].y].min
	ymax = [@pt_rect[0].y, @pt_rect[2].y].max
	@lst_all_entities.each do |entity|
		next unless check_prop?(entity)
		line = edge_cross_rectangle(@view, entity, @pt_rect, xmin, xmax, ymin, ymax)
		if line && edge_visible?(entity)
			@entities_rect.push entity
			if selection_include?(entity)
				@entities_pairs += [entity.start.position, entity.end.position] if @rect_erase
			else
				@entities_pairs += [entity.start.position, entity.end.position] unless @rect_erase
			end	
		end	
	end
end

def cross_rectangle?(edge, xmin, xmax, ymin, ymax)
	ptbeg = @view.screen_coords(edge.start.position)
	ptend = @view.screen_coords(edge.end.position)
	return nil if ptbeg.x < xmin && ptend.x < xmin
	return nil if ptbeg.y < ymin && ptend.y < ymin
	return nil if ptbeg.x > xmax && ptend.x > xmax
	return nil if ptbeg.y > ymax && ptend.y > ymax
	ptbeg.z = ptend.z = 0
	[ptbeg, ptend]
end

def fully_within_rectangle?(edge, xmin, xmax, ymin, ymax)
	ptbeg = @view.screen_coords(edge.start.position)
	return nil if ptbeg.x < xmin || ptbeg.y < ymin || ptbeg.x > xmax || ptbeg.y > ymax
	ptend = @view.screen_coords(edge.end.position)
	return nil if ptend.x < xmin || ptend.y < ymin || ptend.x > xmax || ptend.y > ymax
	ptbeg.z = ptend.z = 0
	[ptbeg, ptend]
end

#Build List of edges in the model
def entities_build_list
	return if @lst_all_entities
	w = @view.vpwidth
	h = @view.vpheight
	@hsh_all_vertices = {}
	nbmax = 0
	@lst_all_entities = @model.active_entities.find_all do |e| 
		check_class?(e) && cross_rectangle?(e, 0, w, 0, h)
	end	
	@nb_all_entities = @lst_all_entities.length
	false
end

#Test List of edges in the model
def entities_too_big?
	return false if @lst_all_entities
	w = @view.vpwidth
	h = @view.vpheight
	@hsh_all_vertices = {}
	nbmax = 0
	@lst_all_entities = []
	@model.active_entities.each do |e|
		return true if nbmax > @rect_maxnum
		if check_class?(e) && cross_rectangle?(e, 0, w, 0, h)
			@lst_all_entities.push e 
			nbmax += 1
		end	
	end	
	@nb_all_entities = @lst_all_entities.length
	false
end

#Refresh the screen coords of edges when view is changed
def edge_cross_rectangle(view, edge, ptrect, xmin, xmax, ymin, ymax)
	return fully_within_rectangle?(edge, xmin, xmax, ymin, ymax) unless @rect_reverse
	line = cross_rectangle?(edge, xmin, xmax, ymin, ymax)
	return nil unless line
	iref = nil
	for i in 0..3
		ptproj = ptrect[i].project_to_line line
		vecref = ptrect[i].vector_to ptproj
		if vecref.valid?
			iref = i+1 
			break
		end	
	end
	return nil unless iref
	
	psref = nil
	for i in iref..3
		ptproj = ptrect[i].project_to_line line
		vec = ptrect[i].vector_to(ptproj)
		next unless vec.valid?
		return line if vec % vecref <= 0
	end
	nil
end

def edge_visible?(edge)
	return true if @rect_hidden
	status1 = vertex_visible(edge.start)
	status2 = vertex_visible(edge.end)
	case (status1 + status2)
	when 0
		return false
	when 2
		return true
	end
	point_visible?(Geom.linear_combination(0.5, edge.start.position, 0.5, edge.end.position))
end

def vertex_visible(vertex)
	status = @hsh_all_vertices[vertex.entityID]
	return status if status
	@hsh_all_vertices[vertex.entityID] = (point_visible?(vertex.position)) ? 1 : 0
end

def point_visible?(pt)
	ll = @model.raytest [@eye, @eye.vector_to(pt)]
	ll[0] == pt
end

end	#class EdgePicker

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CurlManager6: Management of contiguous edges, aka Curl
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					
class CurlManager6

#----------------------------------------------------------------------------
#  Data structures used by the Algorithm
#----------------------------------------------------------------------------

@@su_colors = nil

#Describe a self-sufficient group of edges
CURL_Group6 = Struct.new :lledges, :tr, :losange, :lead_line, :ptbeg_2d, :parent, :order, :mid_point, :lines, :pts,
                         :pts_order, :pts_plus, :pts_minus, :rail_display

#----------------------------------------------------------------------------
#  Initialization
#----------------------------------------------------------------------------

def initialize(*args)
	@model = Sketchup.active_model
	@view = @model.active_view
	@selection = @model.selection
	@tr_id = Geom::Transformation.new
	@order = 0
	
	#parsing the arguments
	args.each do |arg|	
		arg.each { |key, value|  parse_args(key, value) } if arg.class == Hash
	end

	@anglemax = 30.degrees unless @anglemax
	
	@mesh = MeshManager6.new if @mode_mesh
	
	@tip_group_delete = T6[:TIP_Group_Delete]
	@tip_group_order = T6[:TIP_Group_Order]

	init_colors
	reset
end

#Initialize the colors
def init_colors
	return if @@su_colors
	@@su_colors = Sketchup::Color.names.find_all do |n| 
		c = Sketchup::Color.new(n)
		g = c.red + c.blue + c.green
		g < 510 && g > 100 && g != 255
	end	
end

#Assign the individual propert for the palette
def parse_args(key, value)
	skey = key.to_s
	case skey
	when /anglemax/i
		@anglemax = value.degrees
	when /mesh/i
		@mode_mesh = value
	when /rail_display/i
		@rail_display = value
	
	end	
end

#Reset the current selection
def reset
	@hsh_parents = {}
	@lst_groups = []
	@lst_groups_cur = []
	@outside = false
	@hsh_priority = {}
	@priority = 0
end	

#----------------------------------------------------------------------------
#  Mouse events
#----------------------------------------------------------------------------

#Button down
def onLButtonDown(flags, x, y, view)
	@button_down = true
	@grp_down = group_selected?(x, y)
	return true if @grp_down
	@order_down = locate_order_label(x, y)
	return (@order_down) ? true : false
end

#Button up
def onLButtonUp(flags, x, y, view)
	#return false unless @grp_down
	@button_down = false
	if @grp_down && @grp_down == group_selected?(x, y)
		@grp_down = nil
		return [:group_remove]
	end
	@grp_down = nil
	
	if @order_down && @order_down == locate_order_label(x, y)
		laction = order_execute
		@order_down = nil
		return laction
	end
	@order_down = nil
	
	false	
end

#Execute the reordering of groups
def order_execute
	grp, code = @order_down
	case code
	when 1	#plus
		lspec = [grp.order, grp.order-1]
	when 2	#minus
		lspec = [grp.order-1, grp.order-2]
	when 0	#ask
		newpos = order_ask grp
		lspec = []
	else
		lspec = []
	end	
	[:group_sort, lspec]
end

#Dialog box for asking order
def order_ask(grp)
	UI.messagebox "not yet implemented"
	
	[]
end

def onMouseMove(flags, x, y, view)
	if flags && (flags >= 0) && @button_down && (flags & 1 != 1)
		@button_down = false
	end
	grp = group_selected?(x, y)
	grp = locate_order_label(x, y) unless grp	
	return true if @grp_down || @order_down
	#return false if @button_down
	(grp != nil)
end

#Compute tooltip when mouse in labels
def get_tooltip
	tip = nil
	
	if @group_selected
		tip = (@grp_down && @grp_down != @group_selected) ? '' : @tip_group_delete
	elsif @order_selected
		tip = (@order_down && @order_down != @order_selected) ? '' : @tip_group_order
	elsif @grp_down || @order_down
		tip = ''
	end
	tip
end

def get_tooltip_in_void
	if @lst_groups_cur.length > 0
		ttip = "click to validate contours"
	elsif @lst_groups.length > 0
		ttip = "transition"
	else
		ttip = nil
	end
	ttip
end

#----------------------------------------------------------------------------
#  Group Management
#----------------------------------------------------------------------------

#Create a Group structure
def group_create(tr=nil, parent=nil)
	grp = CURL_Group6.new
	grp.lledges = []
	grp.tr = (tr) ? tr : @tr_id
	grp.parent = parent
	grp.order = @order
	@order += 1
	grp
end

#Get the Lines from a Group
def group_get_lines(grp)
	grp.lines
	#lpt = grp.lledges.collect { |le| [grp.tr * le[1], grp.tr * le[2]] }
	#lpt.flatten
end

#Return the edges of the current groups
def get_current_edges
	lledges = []
	@lst_groups_cur.each do |grp|
		lledges += grp.lledges.collect { |ll| ll[0] }
	end
	lledges
end

#Operations when groups are about to be validated
def group_finishing
	#Sorting the current groups
	@lst_groups_cur = priority_sort_groups @lst_groups_cur
	
	order = @lst_groups.length
	@lst_groups_cur.each do |grp|
		#Computing the index
		order += 1
		grp.order = order
	
		#Compute the lines
		lpt = grp.lledges.collect { |le| [grp.tr * le[1], grp.tr * le[2]] }
		grp.lines = lpt.flatten
		grp.pts = grp.lledges.collect { |le| grp.tr * le[1] } + [grp.lines.last]
		
		#Computing the mid points
		grp.mid_point = G6.curl_mid_point grp.pts
	end
end

#decalre an order for the groups
def group_set_order(lorder)
	return unless @lst_groups.length > 0
	lgroups = []
	lorder.each_with_index do |i, j|
		lgroups.push @lst_groups[i]
		lgroups[j].order = j + 1
	end	
	@lst_groups = lgroups	
end

#Reorder all groups
def group_reorder
	iorder = 1
	@lst_groups.each do |grp|
		grp.order = iorder
		iorder += 1
	end	
	@lst_groups_cur.each do |grp|
		grp.order = iorder
		iorder += 1
	end	
end

def group_sort_from_spec(lspec)
	return if @lst_groups.length < 2
	@lst_groups = Traductor.sort_specify(lspec, @lst_groups)
	group_reorder
end

#Remove an individual group (click on label)
def group_remove(grp=nil)
	grp = @group_selected unless grp
	return false unless grp
	igrp = grp.order - 1
	grp = @lst_groups[igrp]
	@lst_groups.delete_at igrp
	@group_selected = nil
	group_reorder
	true
end

#Reinsert a group deleted by label
def group_reinsert(newgrp)
	iorder = newgrp.order
	lgroups = []
	@lst_groups.each do |grp|
		lgroups.push newgrp if grp.order == iorder
		lgroups.push grp
	end	
	lgroups.push newgrp if iorder > @lst_groups.length
	@lst_groups = lgroups
	@group_selected = nil
	group_reorder
end

#Restore a list of groups previously deleted
def group_restore(lgrp)
	@hsh_parents = {}
	@lst_groups_cur = []
	@hsh_edges_grp = {}
	@hsh_edges = {}
	@lst_groups += lgrp
	group_reorder
end

#Remove groups from the current list and put them back in the selection
def group_unmake(lgrp)
	@lst_groups -= lgrp
	lledges = []
	lgrp.each do |grp|
		lledges.push [grp.lledges.collect { |ll| ll[0] }, grp.tr, grp.parent]
	end
	lledges
end

def group_which_selected?
	@group_selected
end
		
#Check if the mouse is within the losange of a group
def group_selected?(x, y)
	@group_selected = nil
	return nil unless @lst_groups
	
	#Checking if the mouse is in the label
	ptxy = Geom::Point3d.new x, y, 0
	igroup = nil
	llgrp = []
	@lst_groups.each_with_index do |grp, i|
		group_compute_label grp
		pts = grp.losange
		if Geom.point_in_polygon_2D(ptxy, pts, true)
			center = Geom.linear_combination 0.5, pts[0], 0.5, pts[2]
			llgrp.push [grp, ptxy.distance(center)]
		end	
	end
	return nil if llgrp.length == 0
	llgrp.sort! { |a, b| a[1] <=> b[1] }
	@group_selected = llgrp[0][0]
end

#Locate the mouse in the order label areas
def locate_order_label(x, y)
	@order_selected = nil
	return nil unless @lst_groups && @lst_groups.length > 1
	
	#Checking if the mouse is in the label
	ptxy = Geom::Point3d.new x, y, 0
	igroup = nil
	llgrp = []
	@lst_groups.each_with_index do |grp, i|
		[grp.pts_order, grp.pts_plus, grp.pts_minus].each_with_index do |pts, j|
			if pts && Geom.point_in_polygon_2D(ptxy, pts, true)
				center = Geom.linear_combination 0.5, pts[0], 0.5, pts[2]
				llgrp.push [[grp, j], ptxy.distance(center)]
			end	
		end	
	end
	return nil if llgrp.length == 0
	llgrp.sort! { |a, b| a[1] <=> b[1] }
	@order_selected = llgrp[0][0]
end

#----------------------------------------------------------------------------
#  Analyse selection of entities (edges or Faces)
#----------------------------------------------------------------------------

#Method to anlayze the initial selection
def analyze_initial_selection(selection=nil)
	selection = @selection.to_a unless selection
	update_current_selection :edge_add, selection
	@lst_groups_cur
end

#Analyze a list of entities
def analyze_selection(lparent)
	@hsh_edges_grp = {}
	@hsh_edges = {}
	lst_groups_cur = []
	ledges = (lparent[0].class == Hash) ? lparent[0].values : lparent[0]
	tr = lparent[1]
	parent = lparent[2]
	parent = @model unless parent
	
	lledges = []
	ledges.each do |e|
		if e.instance_of?(Sketchup::Edge)
			lledges.push e unless @hsh_edges[e.object_id]
			@hsh_edges[e.object_id] = e
		elsif e.instance_of?(Sketchup::Face)
			e.outer_loop.edges.each do |ee|
				lledges.push ee unless @hsh_edges[ee.object_id]
				@hsh_edges[ee.object_id] = ee
			end	
		end
	end
	return [] if @hsh_edges.length == 0
	@lst_edges = lledges
	
	while analyze_edges(lst_groups_cur, tr, parent) do
	end

	lst_groups_cur
end

#analyzes edges in the selection
def analyze_edges(lst_groups, tr=nil, parent=nil)
	edge0 = @lst_edges.find { |e| @hsh_edges_grp[e.object_id] == nil && edge_plain?(e) }
	return false unless edge0
	grp = group_create tr, parent
	grp.lledges.push [edge0, edge0.start.position, edge0.end.position, edge0.start, edge0.end]
	lst_groups.push grp
	@hsh_edges_grp[edge0.object_id] = grp
	
	pursue_edge edge0, grp, false
	pursue_edge edge0, grp, true
	true
end

#Continue potential prolongation of edge, either forward or backward
def pursue_edge(edge, grp, to_front=false)
	vertex = (to_front) ? edge.start : edge.end
	while true
		pt1 = vertex.position
		v1 = vertex
		ledges = vertex.edges.find_all { |e| e != edge && @hsh_edges[e.object_id] && edge_plain?(e) }
		edge = edge_affinity vertex, edge, ledges
		break if edge == nil || @hsh_edges_grp[edge.object_id] #== grp
		@hsh_edges_grp[edge.object_id] = grp
		vertex = edge.other_vertex vertex
		if to_front
			grp.lledges.unshift [edge, vertex.position, pt1, vertex, v1]
		else
			grp.lledges.push [edge, pt1, vertex.position, v1, vertex]
		end	
	end	
end

#Find a next edge having affinity with given edge
def edge_affinity(vertex, edge, ledges)
	return nil if ledges.length == 0
	
	#Same curve
	curve = edge.curve
	if curve
		ec = ledges.find { |e| e.curve == curve }
		return ec if ec
	end

	#A single edge connected
	if ledges.length == 1	
		e0 = ledges[0]	
		an = Math::PI - G6.edges_angle_at_vertex(edge, e0, vertex)
		return e0 if @angle_max == nil || an <= @anglemax
	end	
		
	#Share faces and others don't
	vfaces = vertex.faces
	fledges = ledges.find_all { |e| !(e.faces & vfaces).empty? }
	return nil if edge.faces.empty? && !fledges.empty?
	ll = [edge] + ((fledges.empty?) ? ledges : fledges)
	
	n = ll.length - 1
	vpos = vertex.position
	lvec = []
	for i in 0..n
		e1 = ll[i]
		v1 = vpos.vector_to e1.other_vertex(vertex).position
		for j in i+1..n
			e2 = ll[j]
			v2 = vpos.vector_to e2.other_vertex(vertex).position
			lvec.push [e1, e2, v1.angle_between(v2)]
		end	
	end
	lvec.sort! { |a, b| a[2] <=> b[2] }
	good = lvec.last
	(edge == good[0]) ? good[1] : nil
end

#Check if an edge is Plain
def edge_plain?(e)
	!(e.smooth? || e.soft? || e.hidden?) || e.faces.length < 2
end

#----------------------------------------------------------------------------
#  Building curls as group of edges
#----------------------------------------------------------------------------

#Update the current selection to @lst_group_cur
def update_current_selection(action, ledges, tr=nil, parent=nil)
	#Identifying the context
	parent = @model unless parent
	tr = @tr_id unless tr
	id = parent.object_id.to_s + tr.to_a.inspect
	lparent = @hsh_parents[id]
	lparent = @hsh_parents[id] = [ {}, tr, parent] unless lparent
	hedges_cur = lparent[0]
	
	#Adding or removing the edges
	if action == :edge_add
		ledges.each { |e| hedges_cur[e.entityID] = e }
		priority_add ledges, tr, parent
	elsif action == :edge_remove
		ledges.each { |e| hedges_cur.delete e.entityID }
		priority_remove ledges, tr, parent
	else
		return
	end	
	
	#analysing the selections
	@lst_groups_cur = []
	@hsh_parents.each { |key, lparent| @lst_groups_cur += analyze_selection(lparent) }

	#Finishing the groups (Order, mid_point, ...)
	group_finishing
end

#Rmove edges from priority list
def priority_add(ledges, tr, parent)
	key = parent.inspect + tr.to_a.inspect
	ledges.each do |e|
		id = e.entityID.to_s + key
		@hsh_priority[id] = @priority
		@priority += 1
	end
end

#Declare list of edges for priority recording
def priority_remove(ledges, tr, parent)
	key = parent.inspect + tr.to_a.inspect
	ledges.each do |e|
		id = e.entityID.to_s + key
		@hsh_priority.delete id
	end
end

#Compute the right ordering of groups by order of click
def priority_sort_groups(groups)
	lsgrp = []
	groups.each_with_index do |grp, i|
		ledges = grp.lledges.collect { |ll| ll[0] }
		key = grp.parent.inspect + grp.tr.to_a.inspect 
		lprio = ledges.collect { |e| @hsh_priority[e.entityID.to_s + key] }
		minprio = lprio.compact.min
		minprio = i unless minprio
		lsgrp.push [grp, minprio]
	end
	lsgrp.sort! { |a, b| a[1] <=> b[1] }
	lsgrp.collect { |a| a[0] }
end

#Transfer the current working selection to the @lst_group
def accept_current_selection
	newgroups = @lst_groups_cur
	####@lst_groups = @lst_groups + newgroups
	@lst_groups += @lst_groups_cur
	@hsh_parents = {}
	@lst_groups_cur = []
	if @mode_mesh
		@mesh.compute_all get_contours, get_vertices
	end
	newgroups
end

#Build an history for cases of direct initial selection
def simulate_history(tip_history_add_edges, tip_history_make_contour)
	history = []
	@lst_groups.each do |grp|
		lledges = grp.lledges.collect { |ll| ll[0] }
		history.push ['A', lledges, grp.tr, grp.parent, tip_history_add_edges]
		history.push ['G+', [grp], nil, nil, tip_history_make_contour]
	end
	history
end

#----------------------------------------------------------------------------
#  Information methods
#----------------------------------------------------------------------------
	
#Compute the contours
def get_contours
	@lst_groups.collect do |group| 
		tr = group.tr
		group.lledges.collect { |ll| tr * ll[1] } + [tr * group.lledges.last[2]] 
	end	
end

#Compute all vertices lists cooresponding to the contours
def get_vertices
	@lst_groups.collect do |group| 
		group.lledges.collect { |ll| ll[3] } + [group.lledges.last[4]] 
	end	
end

#return all cells of the mesh
def get_cells
	return [] unless @mesh
	@mesh.get_cells
end

#return the SU vertex corresponding to a given point of the mesh
def get_vertex(pt)
	return nil unless @mesh
	@mesh.get_vertex pt
end

#----------------------------------------------------------------------------
#  Drawing methods
#----------------------------------------------------------------------------

#draw the contours in the view
def draw_contours(view)	
	if @mode_mesh
		@mesh.draw_contours view
	else	
		draw_validated_contours view
	end	
	draw_current_contours view	
end

#Draw validated contours
def draw_validated_contours(view)
	colors = @@su_colors
	nc = colors.length
	nrail, color_rail, wid_rail = @rail_display
	
	@lst_groups.each_with_index do |grp, i|
		lines = group_get_lines grp
		next if lines.empty?
		lpt = lines.collect { |pt| G6.small_offset(view, pt) }
		color = colors[i.modulo(nc)]
		color_label = color
		wid = 3
		stipple = (grp.parent == @model) ? '' : '-'
		if nrail && i <= nrail
			color = color_rail if color_rail
			wid = wid_rail if wid_rail
			stipple = ''
			color_label = color
		end
		view.line_width = wid
		view.line_stipple = stipple
		view.drawing_color = color
		view.draw GL_LINES, lpt
		draw_label view, grp, lpt, color_label
		draw_mid_point view, grp, color_label
	end	
end

#Draw current contours (non validated)
def draw_current_contours(view)
	@lst_groups_cur.each_with_index do |grp, i|
		lines = group_get_lines grp
		next if lines.empty?
		lpt = lines.collect { |pt| G6.small_offset(view, pt, 2) }
		view.line_stipple = (grp.parent == @model) ? '' : ''
		color = G6.color_selection(i)
		view.line_width = 3
		view.drawing_color = color
		view.draw GL_LINES, lpt
		draw_mid_point view, grp, color, true
	end	
end

#Draw a small label with the Order number
def draw_mid_point(view, grp, color, current=false)
	text = grp.order.to_s
	n = text.length
	dec = 8
	ydec = 6
	xdec = 6 * n
	pt2d = view.screen_coords grp.mid_point
	
	#Drawing the central label
	x = pt2d.x
	y = pt2d.y
	pts = []
	pts.push Geom::Point3d.new(x - xdec, y - ydec, 0)
	pts.push Geom::Point3d.new(x + xdec, y - ydec, 0)
	pts.push Geom::Point3d.new(x + xdec, y + ydec, 0)
	pts.push Geom::Point3d.new(x - xdec, y + ydec, 0)
	ptx = Geom::Point3d.new(x - xdec + 3, y - ydec - 2, 0)
	grp.pts_order = pts
		
	#Current groups only
	if current
		view.line_stipple = ''
		view.line_width = 1
		view.drawing_color = 'lightgrey'
		view.draw2d GL_QUADS, pts
		view.drawing_color = color
		view.draw2d GL_LINE_LOOP, pts
		G6.view_draw_text view, ptx, text
		return
	end
	
	#Drawing the plus triangle
	ptsplus = nil
	if grp.order < @lst_groups.length
		ptp = Geom::Point3d.new x + xdec + dec, y, 0
		ptsplus = [pts[1], pts[2], ptp]
	end
	grp.pts_plus = ptsplus
	
	#Drawing the minus triangle
	ptsminus = nil
	if grp.order > 1
		ptp = Geom::Point3d.new x - xdec - dec, y, 0
		ptsminus = [pts[0], pts[3], ptp]
	end
	grp.pts_minus = ptsminus
	
	#Drawing the order and triangles
	locolor = 'lightblue'
	hicolor = 'red'
	selcolor = 'purple'
	
	bkcolors = [locolor, locolor, locolor]
	if @order_selected && (@order_down == nil || @order_down == @order_selected)
		grp_sel, zone = @order_selected
		bkcolors[zone] = (@button_down) ? selcolor : hicolor if grp_sel == grp
	end
	
	view.drawing_color = bkcolors[0]
	view.draw2d GL_QUADS, pts
	view.drawing_color = bkcolors[1]
	view.draw2d GL_TRIANGLES, ptsplus if ptsplus
	view.drawing_color = bkcolors[2]
	view.draw2d GL_TRIANGLES, ptsminus if ptsminus
	
	view.line_stipple = ''
	view.line_width = 1
	view.drawing_color = color
	view.draw2d GL_LINE_LOOP, pts
	view.draw2d GL_LINE_LOOP, ptsplus if ptsplus
	view.draw2d GL_LINE_LOOP, ptsminus if ptsminus
	G6.view_draw_text view, ptx, text
end

#Draw the losange label
def draw_label(view, grp, lpt, color)
	#Recomputing the label if needed
	group_compute_label grp
	highlight = @group_selected == grp && (@grp_down == nil || grp == @grp_down)
	
	#Draw the leading line
	view.drawing_color = color
	view.line_width = 1
	view.line_stipple = '-'
	view.draw2d GL_LINE_STRIP, grp.lead_line
	
	#Draw the losange
	pts = grp.losange
	view.draw2d GL_QUADS, pts #unless @group_selected == grp
	view.line_width = 1
	view.line_stipple = ''
	view.drawing_color = 'yellow'
	view.draw2d GL_LINE_LOOP, pts
	
	#Draw cross is group selected
	#if @group_selected == grp && (@grp_down == nil || grp == @grp_down)
	if highlight
		vec02 = pts[0].vector_to pts[2]
		vec13 = pts[1].vector_to pts[3]
		pt0 = pts[0].offset vec02.reverse, 2
		pt2 = pts[2].offset vec02, 2
		pt1 = pts[1].offset vec13.reverse, 2
		pt3 = pts[3].offset vec13, 1
		view.line_width = 3
		view.line_stipple = ''
		view.drawing_color = (@grp_down == @group_selected) ? 'purple' : 'red'
		view.draw2d GL_LINE_STRIP, pt0, pt2
		view.draw2d GL_LINE_STRIP, pt1, pt3
	end
end

def group_compute_label(grp)
	#Checking if computing needed
	pt2d = @view.screen_coords grp.pts[0]
	return if grp.losange && pt2d == grp.ptbeg_2d
	grp.ptbeg_2d = pt2d
	
	#computing the vector
	lpt = grp.pts
	pt0, pt1 = lpt
	vec2d = nil
	if (pt0 == lpt.last)
		vec = Geom.linear_combination 0.5, pt0.vector_to(pt1).normalize, 0.5, pt0.vector_to(lpt[-2]).normalize
		vec2d = pt2d.vector_to @view.screen_coords(pt0.offset(vec, 10)) if vec.valid?
	else
		vec = pt2d.vector_to @view.screen_coords(pt1)
		vec2d = vec * Z_AXIS if vec.valid?
	end
	vec2d = Y_AXIS unless vec2d
	vec2dp = vec2d * Z_AXIS
	
	#Comptuing the dotted line
	leng = 10
	dec = 12
	ptend = pt2d.offset vec2d, -leng
	if ptend.y < dec
		ptend = pt2d.offset vec2d, leng
		dec = -dec
	end	
	grp.lead_line = [pt2d, ptend]
		
	#Compute the losange
	dec2 = dec / 2
	ptop = ptend.offset vec2d, -dec
	ptmid = ptend.offset vec2d, -dec2
	pt1 = ptmid.offset vec2dp, dec2
	pt2 = ptmid.offset vec2dp, -dec2
	pts = [ptend, pt1, ptop, pt2]
	pts.each { |pt| pt.z = 0 }
	grp.losange = pts
end

end	#End Class CurlManager6

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MeshManager6: Management of meshes
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					
class MeshManager6

#----------------------------------------------------------------------------
#  Data structures used by the Algorithm
#----------------------------------------------------------------------------

@@su_colors = nil

#Describe an individual pseudo vertex
MESH_Vertex6 = Struct.new :vertex, :key, :point, :others, :vx_others, :stop, :lcarnacs

#Describe a sequence of edges
MESH_Carnac6 = Struct.new :lvx, :key

#Describe a diagonal between vertices (used by the Cell algorithm)
MESH_Diago6 = Struct.new :vx0, :vx1, :vx2, :key, :used



#----------------------------------------------------------------------------
#  Initialization
#----------------------------------------------------------------------------

def initialize(*args)
	@model = Sketchup.active_model
	@selection = @model.selection
	@tr_id = Geom::Transformation.new
	
	#parsing the arguments
	args.each do |arg|	
		arg.each { |key, value|  parse_args(key, value) } if arg.class == Hash
	end

	@anglemax = 30.degrees unless @anglemax
	
	init_colors
	
	reset_all
end

#Initialize the colors
def init_colors
	return if @@su_colors
	@@su_colors = Sketchup::Color.names.find_all do |n| 
		c = Sketchup::Color.new(n)
		g = c.red + c.blue + c.green
		g < 510 && g > 100 && g != 255
	end	
end

#Assign the individual propert for the palette
def parse_args(key, value)
	skey = key.to_s
	case skey
	when /anglemax/i
		@anglemax = value.degrees
	
	end	
end

#Reset the current selection
def reset_all
	@hsh_cells = {}
	@hsh_cells_2_points = {}
	@hsh_pedges = {}
	@hsh_pvertex = {}
	@hsh_edge_parents = {}
	@hsh_unexplored = {}
	@lst_crossings = []
	@lst_alones = []
	@lst_borders = []
	@lst_carnacs = []
	@hsh_carnacs = {}
	@hsh_key_carnacs = {}
	@hsh_diagos = {}
	@lst_cells = []
end

#----------------------------------------------------------------------------
#  Analyse selection of entities (edges or Faces)
#----------------------------------------------------------------------------

#Compute the list of cells from the given contours
def compute_all(lcontours, llvertices=nil)
	reset_all
	
	llvertices = [] unless llvertices
	
	index = 0
	lcontours.each_with_index do |contour, ic|
		lvertices = llvertices[ic]
		for i in 1..contour.length-1
			register_pseudo_edge i, index, contour, lvertices
		end
		index += 1
	end	
	
	compute_stops
	compute_carnacs_all
	compute_loops
	#puts "CROSSING = #{@lst_crossings.length}"
	#puts "BORDERS = #{@lst_borders.length}"
	#puts "ALONE = #{@lst_alones.length}"
	#puts "CARNACS = #{@lst_carnacs.length}"
	#puts "UNEXPLORED = #{@hsh_unexplored.length}"
	
	compute_diagonals_all
	compute_cells_all
	
	#puts "DIAGO = #{@hsh_diagos.length}"
	#puts "CELLS = #{@hsh_cells.length}"
end

#Compute a hash key for a point
def hash_point(point)
	((point.to_a.collect { |u| sprintf("%6f", u) }).join 'a').reverse
end

#Compute a unique hash key for 2 pseudo vertices
def hash_edge(*lvx)
	lskey = lvx.collect { |vx| vx.key }
	lskey.sort! { |a, b| a <=> b }
	lskey.join ' '
end

#Register an edge and create pseudo vertices for its extremities
def register_pseudo_edge(i, key_parent, contour, lvertices=nil)
#def register_pseudo_edge(point1, point2, key_parent, edge=nil)
	#create the vertex
	lvertices = [] unless lvertices
	point1 = contour[i-1]
	point2 = contour[i]
	vx1 = create_pseudo_vertex point1, point2, lvertices[i-1]
	vx2 = create_pseudo_vertex point2, point1, lvertices[i]
	vx1.vx_others.push vx2
	vx2.vx_others.push vx1
	key_edge = hash_edge(vx1, vx2)
	@hsh_edge_parents[key_edge] = key_parent	
end
	
#Create a pseudo vertex structure	
def create_pseudo_vertex(point, point2=nil, vertex=nil)
	key = hash_point point
	vx = @hsh_pvertex[key]
	unless vx
		vx = MESH_Vertex6.new
		vx.key = key
		vx.point = point
		vx.others = []
		vx.vx_others = []
		vx.lcarnacs = []
		vx.vertex = vertex
		@hsh_pvertex[key] = vx
		@hsh_unexplored[key] = vx
	end
	vx.others.push point2 if point2
	vx
end
	
#Compute the vertices where to stop contiguity: corners, alone termination, specified discontinuity	
def compute_stops
	@hsh_pvertex.each do |key, vx|
		n = vx.vx_others.length
		vx.stop = true
		if n > 2
			@lst_crossings.push vx
		elsif n == 1	
			@lst_alones.push vx
		elsif @hsh_edge_parents[hash_edge(vx, vx.vx_others[0])] != @hsh_edge_parents[hash_edge(vx, vx.vx_others[1])]
			@lst_borders.push vx
		else
			vx.stop = false
		end
	end	
end

#Compute all carnacs (alignments)
def compute_carnacs_all
	(@lst_alones + @lst_crossings + @lst_borders).each do |vx|
		vx.vx_others.each do |vvx| 
			create_carnac vx, vvx
		end	
	end	
end
	
#Create a sequence of edges between two stop vertices	
def create_carnac(vx1, vx2)
	#Check if already created
	#keyc = hash_edge vx1, vx2
	#carnac = @hsh_carnacs[keyc]
	carnac = @hsh_carnacs[vx1.key + ' ' + vx2.key]
	return carnac if carnac
	
	#Pursue the edges until a true crossing
	@hsh_unexplored.delete vx1.key
	lvx = [vx1, vx2]
	vxprev = vx1
	while true
		vx = lvx.last
		@hsh_unexplored.delete vx.key
		break if vx.stop || vx == vx1
		vxnext = vx.vx_others.find { |v| v != vxprev }
		lvx.push vxnext
		vxprev = vx
	end	
	
	#puts "creating carnac unexplored = #{@hsh_unexplored.length}"
	carnac = MESH_Carnac6.new
	carnac.lvx = lvx
	carnac.key = hash_edge vx1, lvx.last
	@hsh_key_carnacs[carnac.key] = carnac
	#@hsh_carnacs[keyc] = carnac
	@hsh_carnacs[vx1.key + ' ' + vx2.key] = carnac
	@hsh_carnacs[lvx[-1].key + ' ' + lvx[-2].key] = carnac
	@lst_carnacs.push carnac
	vx1.lcarnacs.push carnac.lvx
	lvx.last.lcarnacs.push carnac.lvx.reverse
	
	carnac
end	

#Compute the remaining loops, where no stop vertices can be found
def compute_loops
	while @hsh_unexplored.length > 0
		vx = @hsh_unexplored.values[0]
		carnac = create_carnac vx, vx.vx_others[0]
		#puts "Compute loops carnac = #{carnac.lvx.length}"
		key = hash_edge vx
		@hsh_cells[key] = [carnac.lvx.collect { |vx| vx.point }]
	end
end
	
def compute_diagonals_all
	#@lst_carnacs.each { |val| puts "\nKK = #{val.lvx.first.point}\n    #{val.lvx.last.point}" }
	(@lst_crossings + @lst_borders).each do |vx|
		compute_diagonals vx
	end
	#puts "Top diag #{@hsh_diagos.length}"

end	

#Compute the diagonals at a given crossing
def compute_diagonals(vx)
	lcarnacs = vx.lcarnacs
	lvxends = lcarnacs.collect { |lvx| lvx.last }
	n = lvxends.length-1
	#puts "\nVX = #{vx.point}"
	#lvxends.each { |vv| puts "vxends = #{vv.point}" }
	for i in 0..n-1
		vx1 = lvxends[i]
		#puts "VX1 = #{vx1.point}"
		next if @lst_alones.include?(vx1)
		for j in i+1..n
			vx2 = lvxends[j]
			next if @lst_alones.include?(vx2)
			#next if vx1.point == vx2.point
			
			diago = create_diagonal vx, vx1, vx2 unless diago_is_wrong?(vx, vx1, vx2)
		end
	end
end
	
def diago_is_wrong?(vx0, vx1, vx2)
	lcarnac0 = vx0.lcarnacs
	#puts "\nLcarnac0 = #{lcarnac0.length}"
	#puts "vx0 = #{vx0.point}"
	#puts "vx1 = #{vx1.point}"
	#puts "vx2 = #{vx2.point}"
	
	lcarnac0.each do |lvx0|
		vx = lvx0.last
		next if vx == vx1 || vx == vx2
		#puts "vx = #{vx.point}"
		key1 = hash_edge vx, vx1
		key2 = hash_edge vx, vx2
		#puts "Wrong" if @hsh_key_carnacs[key1] && @hsh_key_carnacs[key2]
		return true if @hsh_key_carnacs[key1] && @hsh_key_carnacs[key2]
	end
	false	
end
		
#Create a diagonal object	
def create_diagonal(vx0, vx1, vx2)
	#return nil if vx1.point == vx2.point
	#puts "create diagonal #{vx0.point} \n#{vx1.point} \n#{vx2.point}" if vx0.point == vx1.point || vx0.point == vx2.point || vx1.point == vx2.point
	diago = MESH_Diago6.new
	diago.vx0 = vx0
	diago.vx1 = vx1
	diago.vx2 = vx2
	diago.key = hash_edge(vx1, vx2)
	h = @hsh_diagos[diago.key]
	h = @hsh_diagos[diago.key] = [] unless h
	h.push diago
	diago
end
	
def diagonal_as_carnac
	@lst_carnacs.each do |carnac|
		#next if @lst_alones.include?(carnac.lvx[0]) || @lst_alones.include?(carnac.lvx[-1])
		ldiago = @hsh_diagos[carnac.key]
		next unless ldiago
		#puts "ldiago carnac len = #{ldiago.length}"
		ldiago.each do |diago|
			#puts "diago as carnac"
			#next if diago.vx0.point == diago.vx1.point && diago.vx1.point == diago.vx2.point
			#next if diago_is_wrong?(diago.vx0, diago.vx1, diago.vx2)
			#puts "\nDIAGO CARNAC"
			#puts "vx0 = #{diago.vx0.point}"
			#puts "vx1 = #{diago.vx1.point}"
			#puts "vx2 = #{diago.vx2.point}"
			lscarnac = [diago.vx0, diago.vx1, diago.vx2]
			construct_cell lscarnac, [[0, 1], [1, 2], [2, 0]]
			diago.used = true
		end
	end	
end

#Compute the Cells
def compute_cells_all	
	diagonal_as_carnac

	@hsh_diagos.each do |key, ldiago|
		#puts "\n===ldiago = #{ldiago.length}"
		if ldiago.length == 2
			next if ldiago.find { |diago| diago.used }
			diago = ldiago[0]
			#puts "\nDIAGO 2"
			#puts "vx0 = #{diago.vx0.point}"
			#puts "vx1 = #{diago.vx1.point}"
			#puts "vx2 = #{diago.vx2.point}"
			compute_cells_by_four ldiago
		elsif ldiago[0].vx1.point == ldiago[0].vx2.point
			construct_cell_between_two_points ldiago[0].vx0, ldiago[0].vx1
		end
	end	
	
	@lst_cells = @hsh_cells.values
end	

#Compute the celles with 4 corners, based on two diagonals
def compute_cells_by_four(ldiago)
	#puts "compute Diago"
	dg1 = ldiago[0]
	dg2 = ldiago[1]
	lscarnac = [dg1.vx0, dg1.vx1, dg2.vx0, dg1.vx2]
	
	construct_cell lscarnac, [[0, 1], [1, 2], [2, 3], [3, 0]]
end
	
def construct_cell(lscarnac, lnums)
	key = hash_edge(*lscarnac)
	
	#cell already treated
	return if @hsh_cells[key] || @hsh_cells_2_points[key]
	
	#Creating the cell
	lcontours = []
	lnums.each do |ll|
		vx1 = lscarnac[ll[0]]
		vx2 = lscarnac[ll[1]]
		contour = vx1.lcarnacs.find { |carnac| carnac.last == vx2 }
		lcontours.push(contour.collect { |vx| vx.point })
	end
	@hsh_cells[key] = lcontours
	#puts "construct cell = #{@hsh_cells.length} key = #{key}"
end
	
def construct_cell_between_two_points(vx1, vx2)
	#key = hash_edge(vx1, vx2, vxdup)
	key = hash_edge(vx1, vx2)
	
	#cell already treated
	return if @hsh_cells[key]
	return if @hsh_cells_2_points[key]
	#@hsh_cells[key] = true#####
	@hsh_cells_2_points[key] = true
	
	contours = vx1.lcarnacs.find_all { |carnac| carnac.last == vx2 }
	
	#puts "\nspecial diago key = #{key}"
	#puts "key = #{key} contours 2 points = #{contours.length}"
	#contours.each { |c| puts "Cc len = #{c.length}" }
	nc = contours.length
	
	if nc == 1
		@hsh_cells[key] = [contours[0].collect { |vx| vx.point }]
		return
	elsif nc == 2
		if contours[0] == contours[1].reverse
			@hsh_cells[key] = [contours[0].collect { |vx| vx.point }]
			return		
		end
		lsc = [[contours[0]], [contours[1]]]
	else
		lsc = []
		contours.each do |contour|
			curve = contour.collect { |vx| vx.point }
			leng = G6.curl_length curve
			lsc.push [contour, leng]
		end	
		lsc.sort! { |a, b| a[1] <=> b[1] }
	end	
		
	c1 = lsc[0][0]	
	ptbeg = c1[0].point
	n = contours.length - 1
	for i in 1..n
		c2 = lsc[i][0]
		c2 = c2.reverse if c2.first.point == ptbeg
		key = key + "#{i}"
		@hsh_cells[key] = [c1, c2].collect { |c| c.collect { |vx| vx.point } }
	end

end
	
#Return all the cells of the mesh
def get_cells
	#puts "Mesh cel = #{@lst_cells.inspect}"
	@lst_cells
end

#Return a SU vertex corresponding to the point of the mesh
def get_vertex(pt)
	key = hash_point pt
	vx = @hsh_pvertex[key]
	(vx) ? vx.vertex : nil
end

#----------------------------------------------------------------------------
#  Drawing methods
#----------------------------------------------------------------------------

#draw the contours in the view
def draw_contours(view)
	return unless @lst_carnacs
	
	@lst_carnacs.each_with_index do |carnac, i|
		pts = carnac.lvx.collect { |vx| vx.point }
		color = G6.color_su(i)
		view.line_width = 3
		view.line_stipple = ''
		view.drawing_color = color
		view.draw GL_LINE_STRIP, pts.collect { |pt| G6.small_offset(view, pt) }
	end	
	
end

end	#Class MeshManager6
	
end	#Module Traductor

