=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Nov. 2008 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Tool.rb
# Original Date	:  03 Dec 2008 - version 3.0
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  Contains some standard interactive tools (selection, pick line, ...)
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

#All Tools
T6[:T_WARNING_InvalidOrigin] = "Invalid Origin" 
T6[:T_WARNING_InvalidTarget] = "Invalid Target" 
T6[:T_STR_Warning] = "WARNING"
T6[:T_STR_Distance] = "Distance"
T6[:T_STR_Coords] = "Coords"
T6[:T_VCB_Steps] = "Step"
T6[:T_VCB_Entities] = "Entities"
T6[:T_VCB_Curves] = "Curves"
T6[:T_VCB_SoftEdges] = "New Edges"
T6[:T_VCB_MakeUnique] = "Make Unique"
T6[:T_VCB_Dicing] = "Slicing"
T6[:T_STR_RedAxis] = "Red axis"
T6[:T_STR_GreenAxis] = "Green axis"
T6[:T_STR_BlueAxis] = "Blue axis"
T6[:T_MNU_Cancel] = "Cancel and Back (ESC)"
T6[:T_MNU_Done] = "Done"
T6[:T_MNU_PropNewEdges] = "Property of newly created edges"

T6[:T_MNU_ArrowUp] = "Arrow Up"
T6[:T_MNU_ArrowLeft] = "Arrow Left"
T6[:T_MNU_ArrowRight] = "Arrow Right"
T6[:T_MNU_ArrowDown] = "Arrow Down"
T6[:T_MNU_Escape] = "Escape"
T6[:T_MNU_BackSpace] = "BackSpace"
T6[:T_MNU_Enter] = "Enter"
T6[:T_MNU_Tab] = "Tab"
T6[:T_MNU_Shift] = "Shift"
T6[:T_MNU_Ctrl] = "Ctrl"
T6[:T_MNU_CtrlShift] = "Ctrl+Shift"
T6[:T_MNU_On] = "On"
T6[:T_MNU_Off] = "Off"
T6[:T_MNU_YES] = "YES"
T6[:T_MNU_NO] = "NO"
T6[:T_MNU_SU_Undo] = "SU Undo, CTRL-Z"
T6[:T_MNU_SU_Redo] = "SU Redo, CTRL-Y"

#Selection Tool
T6[:T_MNU_Selection_Done] = "Done with Selection"
T6[:T_MNU_Selection_Extended] = "Extend selection to connected entities (SHIFT)"
T6[:T_STR_Selection_StatusText] = "Select entities - SHIFT to extend to connected entities"
T6[:T_VCB_Selection_Extended] = "Extended"
T6[:T_VCB_Angle_Slope] = "Angle, Slope"
T6[:T_VCB_Angle] = "Angle"
T6[:T_VCB_Degree] = "Degree"

#PickLine Tool
T6[:T_MSG_PickLine_Origin] = "Click Origin"
T6[:T_MSG_PickLine_Target] = "Click Target - Arrows = force Axis - SHIFT = lock direction"

#Dicer
T6[:T_DLG_EdgeProp_Title] = "Properties for New Edges"
T6[:T_DLG_DicerParam_Title] = "Slicing Parameters"
T6[:T_DLG_DicerParam_Nb] = "Number of slices"
T6[:T_DLG_DicerParam_Auto] = "Negative for based on 12-Edge circle"
T6[:T_DLG_DicerParam_SkipStart] = "Skip Start border"
T6[:T_DLG_DicerParam_SkipEnd] = "Skip End border"
T6[:T_DLG_EdgeAdditional] = "Additional Edges:"
T6[:T_DLG_EdgeSoft] = "Soft"
T6[:T_DLG_EdgeSmooth] = "Smooth"
T6[:T_DLG_EdgeHidden] = "Hidden"
T6[:T_DLG_EdgeCastShadows] = "Cast Shadows"
T6[:T_DLG_EdgeDiagonal] = "Diagonal of quads"
T6[:T_DLG_EdgeKeep] = "Keep if Colinear"
T6[:T_DLG_YES] = "YES"
T6[:T_DLG_NO] = "NO"

#inference colors and Tooltip
T6[:T_MNU_Inference_Toggle] = "Toggle Inference Lock"
T6[:T_MNU_Inference_RedAxis] = "Lock Red Axis (ARROW RIGHT)"
T6[:T_MNU_Inference_GreenAxis] = "Lock Green Axis (ARROW LEFT)"
T6[:T_MNU_Inference_BlueAxis] = "Lock Blue Axis (ARROW UP)"
T6[:T_MNU_Inference_NoAxis] = "Release Axis Lock (ARROW DOWN)"
T6[:T_STR_Inference_Blue_Plane] = "Horiz. plane Red/Green"
T6[:T_STR_Inference_Red_Plane] = "Vert. plane Blue/Green"
T6[:T_STR_Inference_Green_Plane] = "Vert. plane Blue/Red"
T6[:T_STR_Inference_Unlock_Plane] = "Unlock plane"
T6[:T_STR_Inference_Colinear_Last] = "Parallel to edge"
T6[:T_STR_Inference_Colinear] = "Collinear to edge"
T6[:T_STR_Inference_Perpendicular] = "Perpendicular to edge"
T6[:T_STR_Inference_Perpendicular_Last] = "Perpendicular to previous"
T6[:T_STR_Inference_45] = "45 degrees"
T6[:T_STR_Inference_45_Last] = "45 degrees to previous"

T6[:T_DEFAULT_InferenceSection] = "Inference for lines"
T6[:T_DEFAULT_InferencePrecision] = "Precision in screen pixels"
T6[:T_DEFAULT_InferenceColor_None] = "Color when NO inference"
T6[:T_DEFAULT_InferenceColor_Collinear] = "Color when line is collinear or parallel"
T6[:T_DEFAULT_InferenceColor_Perpendicular] = "Color when line is perpendicular"
T6[:T_DEFAULT_SectionFunctionKey] = "Function Keys"

#Function Keys
T_TABLE_FKEY = { 'F2' => 113, 
			     'F3' => 114,	
			     'F4' => 115,	
			     'F5' => 116,	
			     'F6' => 117,	
			     'F7' => 118,	
			     'F8' => 119,	
			     'F9' => 120	
			   }	
T6[:T_MNU_FKeyOn] = "ON"
T6[:T_MNU_FKeyOff] = "OFF"

#--------------------------------------------------------------------------------------------------------------
# Shared Utilities
#--------------------------------------------------------------------------------------------------------------			 

#Create a cursor from a Lib6 file
def Traductor.create_cursor(name, hotx=0, hoty=0)
	MYPLUGIN.create_cursor name, hotx, hoty
end

#Translate Short cuts
@@hsh_shortcuts = nil
def Traductor.translate_shortcut(symb)
	return '' unless symb
	unless @@hsh_shortcuts
		hsh = @@hsh_shortcuts = {}
		hsh[:arrow_up] = T6[:T_MNU_ArrowUp]
		hsh[:arrow_left] = T6[:T_MNU_ArrowLeft]
		hsh[:arrow_right] = T6[:T_MNU_ArrowRight]
		hsh[:arrow_down] = T6[:T_MNU_ArrowDown]
		hsh[:escape] = T6[:T_MNU_Escape]
		hsh[:esc] = T6[:T_MNU_Escape]
		hsh[:backspace] = T6[:T_MNU_BackSpace]
		hsh[:enter] = T6[:T_MNU_Enter]
		hsh[:shift] = T6[:T_MNU_Shift]
		hsh[:ctrl] = T6[:T_MNU_Ctrl]
		hsh[:ctrl_shift] = T6[:T_MNU_CtrlShift]
		hsh[:tab] = T6[:T_MNU_Tab]
		hsh[:on] = T6[:T_MNU_On]
		hsh[:off] = T6[:T_MNU_Off]
		hsh[:yes] = T6[:T_MNU_YES]
		hsh[:no] = T6[:T_MNU_NO]
		hsh[:su_undo] = T6[:T_MNU_SU_Undo]
		hsh[:su_redo] = T6[:T_MNU_SU_Redo]
	end	
	text = @@hsh_shortcuts[symb]
	(text) ? text : symb.to_s
end

#Encode a menu or a tooltip
#If the tip contains a parenthese in last position, then it is assumed to contain the short cut
#if <tab> is passed, then the \t<tab> is appended
def Traductor.encode_menu(text, shortcut=nil, status=nil)
	Traductor.encode_menutip true, text, shortcut, status
end
def Traductor.encode_tip(text, shortcut=nil, status=nil)
	Traductor.encode_menutip false, text, shortcut, status
end

def Traductor.encode_menutip(menu_or_tip, text, shortcut=nil, status=nil)
	if shortcut.class == Array
		ls = shortcut.collect { |s| Traductor.translate_shortcut s }
		shortcut = ls.join ", "
	elsif shortcut	
		shortcut = Traductor.translate_shortcut shortcut
	end	
	if text =~ /(.*)\((.*)\)\Z/
		text = $1
		shortcut = $2 unless shortcut && shortcut.length > 0
	end
	if status == true 
		status = T6[:T_MNU_On]
	elsif status == false	
		status = T6[:T_MNU_Off]
	end	
	text = text + " --> #{status}" if status
	text = text + ((menu_or_tip) ? "\t" + shortcut : ' (' + shortcut + ')') if shortcut
	text
end

#--------------------------------------------------------------------------------------------------------------
# Class ReturnUp: Utility to manage the Return keyup event after dialog boxes and VCB
#                            inputs (as they can be misinterpreted
#--------------------------------------------------------------------------------------------------------------			 

class ReturnUp

@@return_up = false

def ReturnUp.is_on?
	@@return_up
end

def ReturnUp.set_on
	@@return_up = true
end	

def ReturnUp.set_off
	@@return_up = false
end	

end	#class ReturnUp

#--------------------------------------------------------------------------------------------------------------
# Class FKeyOption: Manage Function Key options
#--------------------------------------------------------------------------------------------------------------			 

class FKeyOption

attr_reader :fkey

def initialize(menutext, fkey, lonofftext=nil, &proc)
	@menutext = menutext
	@fkey = fkey
	@proc = proc
	@lonofftext = lonofftext
end

def FKeyOption.fkeys
	T_TABLE_FKEY.keys
end

#Insert a menu item for the function key in the given <menu>
def create_menu_flag(menu, flag, parenth=false)
	menu.add_item(build_text(flag, parenth)) { @proc.call if @proc} 
end

#Create a Sketchup command (for menu) out of a function key
def create_cmd(flag, parenth=false)
	#####UI::Command.new(build_text(flag)) { @proc.call if @proc }
	[build_text(flag, parenth), @proc]
end

def build_text(flag, parenth=false)
	onoff = nil
	if @lonofftext && @lonofftext.class == Array
		onoff = (flag) ? @lonofftext[0] : @lonofftext[1]
	end	
	onoff = ((flag) ? T6[:T_MNU_FKeyOn] : T6[:T_MNU_FKeyOff]) unless onoff
	onoff = get_onoff_text flag
	t = @menutext + " --> " + onoff
	if @fkey
		if parenth
			t += "  (" + @fkey + ")"
		else
			t += "\t#{@fkey}"
		end	
	end	
	t
end

def test_key(key)
	return false unless key == T_TABLE_FKEY[@fkey]
	@proc.call if @proc
	true
end	

def FKeyOption.get_menu_text(menutext, flag, fkey)
	txtcur = T6[:T_MNU_Current]
	#onoff = (flag) ? T6[:T_MNU_FkeyOn] : T6[:T_MNU_FkeyOff]
	onoff = get_onoff_text flag
	text = menutext + " (#{txcur} " + onoff + ") --> " + fkey
end

def FKeyOption.oldget_menu_text(menutext, flag, fkey)
	txtcur = T6[:T_MNU_Current]
	#onoff = (flag) ? T6[:T_MNU_FkeyOn] : T6[:T_MNU_FkeyOff]
	onoff = get_onoff_text flag
	text = menutext + " (#{txcur} " + onoff + ") --> " + fkey
end

def get_onoff_text(flag)
	if flag.class == TrueClass || flag.class == FalseClass || flag.class == NilClass
		onoff = nil
		if @lonofftext && @lonofftext.class == Array
			onoff = (flag) ? @lonofftext[0] : @lonofftext[1]
		end	
		onoff = ((flag) ? T6[:T_MNU_FKeyOn] : T6[:T_MNU_FKeyOff]) unless onoff
	elsif @lonofftext.class == Array || @lonofftext.class == Hash
		onoff = KeyList.to_value @lonofftext, flag
	else
		onoff = flag.to_s
	end
	onoff
end

def FKeyOption.get_key_value(fkey)
	T_TABLE_FKEY[fkey]
end

end	#class FKeyOption

#--------------------------------------------------------------------------------------------------------------
# Class AllTools: Common methods to ALL tools 
#--------------------------------------------------------------------------------------------------------------			 

class AllStandardTools

#Method to select the tool as active
def _select
	Sketchup.active_model.select_tool self
end

end	#class AllTools

#--------------------------------------------------------------------------------------------------------------
# Selection Tool for picking up entities
#--------------------------------------------------------------------------------------------------------------			 				   

class StandardSelectionTool < AllStandardTools

#***********************************
# Placeholder for subclassing methods
#***********************************

include MixinCallBack

def sub_initialize(*args) ; end
def sub_cursor_set(entity, extend_selection) ; 0 ; end
def sub_exit_tool ; @model.select_tool nil ; end
def sub_cancel_tool(flag=nil) ; end
def sub_deactivate(view) ; end
def sub_check_entity(entity) ; true ; end
def sub_getMenu_before(menu) ; false ; end
def sub_getMenu_after(menu) ; false ; end
def sub_draw(view) ; end
def sub_get_title_tool() ; "" ; end
def sub_extend_entity(entity, extend_selection, view_hidden) ; nil ; end

#***********************************
# Class Methods
#***********************************

attr_accessor :extend_selection, :extend_face, :keep_selection

#Initialization of the tool
def initialize(caller, *args)
	#Setting the caller
	_register_caller caller

	#Other initializations
	@model = Sketchup.active_model
	@view = @model.active_view
	@extend_selection = false
	@extend_face = false
	@keep_selection = false
	@extended_text = T6[:T_VCB_Selection_Extended]
	@mark_forbidden = G6::DrawMark_Forbidden.new
	@mark_extended = G6::DrawMark_FourArrows.new
	@status_text = T6[:T_STR_Selection_StatusText]
	set_cursor
	
	#Custom initialization
	_sub :initialize, *args
	
	@titletool = _sub :get_title_tool
end

def set_cursor(idcursor=0, sizecursor=24, hotx=0, hoty=0)
	@default_cursor = idcursor
	@sizecursor = sizecursor
	@hotx = hotx
	@hoty = hoty
end

#Activation of the tool
def activate
	@model = Sketchup.active_model
	@selection = @model.selection
	@button_down = false
	validate_pre_selection
	reset_selection
	if @keep_selection
		@stored_entities = @selection.to_a
	else
		#return exit_tool if validate_pre_selection
		return exit_tool if @selection.length > 0
		@selection.clear
	end	
	@rendering_options = @model.rendering_options
	show_info
end

def deactivate(view)
	@x = nil
	_sub :deactivate, view
	view.invalidate
end

#Activation of the tool
def reset_selection
	@icursor = 0
	@ctrl_down = false
	@lst_entities = nil
	@stored_entities = []
	@lst_forbid = []
end

#Validate pre-existing selection if any
def validate_pre_selection
	@lst_entities = nil
	@selection.each do |e| 
		@selection.remove e unless e.class != Sketchup::Drawingelement && _sub(:check_entity, e) 
	end	
	@selection.length > 0
end

#Cancel event
def onCancel(flag, view)
	#User did an Undo
	case flag
	when 1, 2	#Undo or reselect the tool
		activate
		return
	when 0	#user pressed Escape
		reset_selection
		@selection.clear
	end
	_sub :cancel_tool, flag
	view.invalidate
end

#Setting the proper cursor
def onSetCursor
	ic = _sub :cursor_set, @entity, @extend_selection
	UI::set_cursor((ic) ? ic : @default_cursor)
end

#Contextual menu
def getMenu(menu)
	#Custom menu item before 
	return if _sub :getMenu_before, menu
	
	#own menus
	menu.add_item(T6[:T_MNU_Selection_Extended]) { toggle_extend_selection }
	if @selection.length > 0
		menu.add_separator
		menu.add_item(T6[:T_MNU_Selection_Done]) { exit_tool }
	end	

	#Custom menu item after 
	_sub :getMenu_after, menu
	true
end

#Button click - Means that we end the selection
def onLButtonDown(flags, x, y, view)
	@button_down = true
	#execute_action
end

#Button click - Means that we end the selection
def onLButtonUp(flags, x, y, view)
	@button_down = false
	execute_action
end

def toggle_extend_selection
	@extend_selection = ! @extend_selection
	onMouseMove_zero
	#onMouseMove 0, @x, @y, @model.active_view
end

#Trap Modifier keys for extended and Keep selection
def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false
	case key			
	when CONSTRAIN_MODIFIER_KEY
		toggle_extend_selection

	when COPY_MODIFIER_KEY
		@ctrl_down = true
		onMouseMove_zero unless unselect()
	
	when 13
		Traductor::ReturnUp.set_off

	end	
end

def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true
	case key			
	when COPY_MODIFIER_KEY
		@ctrl_down = false
	when 13
		execute_action if Traductor::ReturnUp.is_on?
	end	
	show_info
end

#Drawing method - Used to add cursor indicator
def draw(view)
	return unless @x	
	x = @x + @sizecursor - @hotx + 4
	y = @y - @hoty + 4
	if @deny_entity
		@mark_forbidden.draw_at_xy view, x, y
	elsif @extend_selection
		@mark_extended.draw_at_xy view, x, y	
	end	
	_sub :draw, view
end

#Mouse Move method
def onMouseMove_zero
	onMouseMove(0, @x, @y, @view) if @x
end

def onMouseMove(flags, x, y, view)
	return unless x
	@x = x
	@y = y

	#Finding the picked entity
	ph = view.pick_helper
	ph.do_pick x, y
	@entity = ph.best_picked

	manage_selection()
	
	onSetCursor
	view.invalidate
end	

def execute_action
	return if @selection.length == 0
	#return unless @entity
	exit_tool
end

def exit_tool
	@selection.add @lst_entities if @lst_entities
	_sub :exit_tool
end

def manage_selection
	#Highlighting the entities
	@selection.remove(@lst_entities - @stored_entities) if @lst_entities
	
	#Filtering entities
	@deny_entity = false
	@deny_entity = !_sub(:check_entity, @entity) if @entity
	@entity = nil if @deny_entity
	
	#Handling entity, with possible extension
	if @entity
		view_hidden = @rendering_options["DrawHidden"]
		@lst_entities = [@entity]
		
		ls = _sub :extend_entity, @entity, @extend_selection, view_hidden
		@lst_entities |= ls if ls
		if @extend_selection
			unless ls || (@entity.class != Sketchup::Face && @entity.class != Sketchup::Edge)
				@lst_entities |= @entity.all_connected
			end	
		elsif @entity.class == Sketchup::Face && (view_hidden == false || @extend_face)
			@lst_entities |= face_neighbours @entity
		elsif @entity.class == Sketchup::Edge && (curve = @entity.curve)
			@lst_entities |= curve.edges
		end	
		
		@lst_entities = @lst_entities.find_all { |e| _sub(:check_entity, e) }
		
		if (@lst_forbid & @lst_entities).length == 0
			@selection.add @lst_entities
			@lst_forbid = []
		end	
		
		if @ctrl_down
			@stored_entities |= @lst_entities
			@lst_entities = nil
		end
	else
		@lst_forbid = []
	end	
end	

#Unselect a stored selection when CTRL is pressed
def unselect
	return false unless @lst_entities && (@lst_entities & @stored_entities).length > 0 
	@stored_entities = @stored_entities - @lst_entities
	@selection.remove @lst_entities
	@lst_forbid = @lst_entities.clone
	true
end

#Determine all connected faces to the face (i.e. if bording edge is soft or hidden)
#note: the recursive version seems to bugsplat on big number of faces. So I use an iterative version
def face_neighbours(face)
	@hsh_faces = {}
	lface = [face]
	
	while true
		break if lface.length == 0
		f = lface[0]
		if @hsh_faces[f.entityID]
			lface[0..0] = []
			next
		end	
		lface[0..0] = []
		@hsh_faces[f.entityID] = f
		f.edges.each do |e|
			if e.hidden? || e.soft?
				e.faces.each do |ff| 
					lface.push ff unless ff == f || @hsh_faces[ff.entityID]
				end	
			end	
		end
	end	
	@hsh_faces.values
end

def show_info()
	title = @status_text
	title = @titletool + ': ' + title if @titletool && @titletool != ""
	Sketchup.set_status_text title
	label = (@extend_selection) ? @extended_text : ""
	Sketchup.set_status_text label, SB_VCB_LABEL
end

end	#class StandardSelectionTool

#--------------------------------------------------------------------------------------------------------------
# Class StandardPickLineTool: Tool for picking 2 points with inference
#--------------------------------------------------------------------------------------------------------------			 				   
class StandardPickLineTool < AllStandardTools

#***********************************
# Placeholder for subclassing methods
#***********************************

include MixinCallBack

def sub_initialize(*args) ; end
def sub_activate ; end
def sub_deactivate(view) ; end
def sub_cursor_set ; nil ; end
def sub_exit_tool ; @model.select_tool nil ; end
def sub_onCancel(flag, view)  ; nil ; end
def sub_draw_before(view, pt_origin, pt_target) ; true ; end
def sub_draw_after(view, pt_origin, pt_target) ; true ; end
def sub_move(view, pt_origin, pt_target) ; true ; end
def sub_resume(view) ; end
def sub_change_state(state) ; end
def sub_execute(pt_origin, pt_target) ; end
def sub_onLButtonDoubleClick(flags, x, y, view, state) ; end
def sub_getMenu_before(menu) ; false ; end
def sub_getMenu_after(menu) ; false ; end
def sub_test_origin(pt_origin) ; true ; end
def sub_test_target(pt_target) ; true ; end
def sub_get_title_tool() ; "" ; end
def sub_onKeyDown(key, rpt, flags, view) ; false ; end
def sub_onKeyUp(key, rpt, flags, view) ; false ; end

#***********************************
# Class Methods
#***********************************

#Initialization of the tool
def initialize(caller, *args)
	#Setting the caller
	_register_caller caller

	#Initialization
	@model = Sketchup.active_model
	@view = @model.active_view
	@ip1 = Sketchup::InputPoint.new
	@ip2 = Sketchup::InputPoint.new
	@warning_origin = T6[:T_WARNING_InvalidOrigin]
	@warning_target = T6[:T_WARNING_InvalidTarget]
	@mark_forbidden = G6::DrawMark_Forbidden.new 8

	@vec_line = nil
	@normal_plane = nil
	
	@inference = VecInference.new
	
	#Custom initialization
	_sub :initialize, *args
	
	#Title initialization
	@title_tool = _sub :get_title_tool
	title = (@title_tool && @title_tool != "") ? @title_tool + ': ' : ""
	@title_origin = title + T6[:T_MSG_PickLine_Origin]
	@title_target = title + T6[:T_MSG_PickLine_Target]
	@title_distance = T6[:T_STR_Distance]
	@title_warning = T6[:T_STR_Warning]
end

#Activation of the tool
def activate
	@model = Sketchup.active_model
	@selection = @model.selection
	@view = @model.active_view
	@exiting = false
	reset
	_sub :activate
	@view.invalidate
	show_info
	onSetCursor
end

#Set the line style
def set_line_style(width, stipple=nil)
	@inference.set_line_style width, stipple
end

def deactivate(view)
	@exiting = true
	_sub :deactivate, view
	view.invalidate
end

#Resume view after change of view of zoom
def resume(view)
	_sub :resume, view
	view.invalidate
end

#Activation of the tool
def reset
	@icursor = 0
	@state = 0
	@pt_origin = nil
	@pt_target = nil
	@pt_target_proj = nil
	@distance = 0
	@ok_origin = true
	@ok_target = true
	@prev_origin = nil
	@prev_vec = nil
end

#Cancel event
def onCancel(flag, view)
	#User did an Undo
	case flag
	when 1, 2	#Undo or reselect the tool
		_sub :onCancel, flag, view
		exit_tool()
		return
	when 0	#user pressed Escape
		if @state == 0 || (@state >= 1 && @forced_origin)
			_sub :onCancel, flag, view
			exit_tool()
		else
			_sub :move, view, @pt_origin, @pt_origin
			set_state @state - 1
		end	
	end
end

#Setting the proper cursor
def onSetCursor
	idcur = _sub :cursor_set
	UI::set_cursor((idcur) ? idcur : 0)
end

#Restart the tool for a new input
def restart
	@prev_origin = @pt_origin
	if @pt_origin && @pt_target
		@prev_vec = @pt_origin.vector_to @pt_target
	else
		@prev_vec = nil
	end
	set_state 0	
	@model.active_view.invalidate
end

#Control the State of the tool
def set_state(state)
	return if @state == state
	return UI.beep if state == 1 && !@ok_origin
	#return UI.beep if state == 2 && !@ok_target
	@state = state
	if state > 1	
		@state = 2
		_sub :execute, @pt_origin, @pt_target
		return
	end	
	_sub :change_state, @state
	if state <= 1
		@pt_target = nil
	end	
	if state <= 0
		@pt_origin = nil
	end	
	show_info
end

#Contextual menu
def getMenu(menu)
	#Custom menu item before 
	return if _sub :getMenu_before, menu

	@inference.contextual_menu menu

	menu.add_separator
	if @state == 1
		menu.add_item(T6[:T_MNU_Done]) { set_state 2 }
	elsif @state == 0	
		menu.add_item(T6[:T_MNU_Cancel]) { onCancel 0, @model.active_view }
	end	
	
	#Custom menu item before 
	_sub :getMenu_after, menu
	true
end

def lock_axis(axis_code)
	@inference.lock_axis axis_code
end

def set_custom_axes(axes, tooltip=nil)
	@inference.set_custom_axes axes, tooltip
end

def set_origin(pt_origin)
	ptxy = @view.screen_coords pt_origin
	@xdown = ptxy.x
	@ydown = ptxy.y
	@forced_origin = pt_origin
	onMouseMove(0, @xdown, @ydown, @view)
	set_state 1
end

#Set the hash table for entity Ids to avoid when searching for inferences
def set_hsh_entityID(hsh)
	@hsh_entID = hsh
end

def set_mark_origin(lmark, width=2, stipple="")
	@mark_origin = lmark
	@mark_origin_width = width
	@mark_origin_stipple = stipple
end

def set_mark_target(lmark, width=2, stipple="")
	@mark_target = lmark
	@mark_target_width = width
	@mark_target_stipple = stipple
end

#Toggle usage of inference
def toggle_inference
	@flag_inference = !@flag_inference
end

#Button click - Means that we start or end the point selection
def onLButtonDown(flags, x, y, view)
	set_state @state + 1
	@xdown = x
	@ydown = y
end

#Button release - Means that we end or continue the point selection
def onLButtonUp(flags, x, y, view)
	return if @xdown && (@xdown - x).abs < 5 && (@ydown - y).abs < 5
	set_state @state + 1
end

#Recieved a Double click with left mouse button
def onLButtonDoubleClick(flags, x, y, view)
	_sub :onLButtonDoubleClick, flags, x, y, view, @state
end

#Trap Modifier keys for extended and Keep selection
def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false
	
	#Inference modifiers
	if @inference.handleKeyDown(key, rpt, flags, view)
		onMouseMove_zero
		#onMouseMove 0, @x, @y, view
		return
	end	

	Traductor::ReturnUp.set_off if key == 13

	#Checking other keys
	_sub :onKeyDown, key, rpt, flags, view
end

def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true
	
	#Inference modifiers
	if @inference.handleKeyUp(key, rpt, flags, view)
		onMouseMove_zero
		return
	end	

	#Other keys
	case key			
	when 13
		set_state @state+1 unless Traductor::ReturnUp.is_on?
	end	
	
	#Checking other keys
	_sub :onKeyUp, key, rpt, flags, view
end

#Mouse Move method
def onMouseMove_zero
	onMouseMove(0, @x, @y, @view) if @x
end

#Move method
def onMouseMove(flags, x, y, view)
	#Synchronize draw and move
	return if @moving
	@moving = true

	return unless x
	@x = x
	@y = y

	#Picking the Origin
	if @state == 0
		@pt_target = nil
		@ip1.pick view, x, y
		@pt_origin = (@forced_origin) ? @inference.force_origin(@forced_origin) : @inference.set_xy_origin(view, x, y)
		@ok_origin = _sub :test_origin, @pt_origin
		validate_origin view
	
	#Picking the target
	elsif @state == 1
		@ip2.pick view, x, y, @ip1
		@inference.set_hsh_entityID @hsh_entID
		@pt_target = @inference.compute_xy_inference view, x, y
		validate_target view	
	end

	view.invalidate
	show_info
	onSetCursor
end	

#Validation of the input for origin
def validate_origin(view)
	@ok_origin = _sub :test_origin, @pt_origin
	if @ok_origin
		@pt_origin = @ok_origin if @ok_origin.class == Geom::Point3d 
		view.tooltip = @ip1.tooltip
		_sub :move, view, @pt_origin, nil
	else
		view.tooltip = @warning_origin
	end	
end

#Validation of the input for target
def validate_target(view, execute=false)
	@ok_target = _sub :test_target, @pt_target
	if @ok_target
		@pt_target = @ok_target if @ok_target.class == Geom::Point3d
		@distance = @pt_origin.distance @pt_target
		view.tooltip = @inference.get_tooltip
		_sub :move, view, @pt_origin, @pt_target
		_sub :execute, @pt_origin, @pt_target if execute
	else
		view.tooltip = @warning_target
	end	
end

#Draw Method
def draw(view)
	@moving = false
	return if @exiting
	
	#Drawing before
	pt_origin = (@state >= 0 && @ok_origin) ? @pt_origin : nil
	pt_target = (@state >= 1 && @ok_target) ? @pt_target : nil
	_sub :draw_before, view, pt_origin, pt_target

	#drawing the input points
	view.line_width = 1
	if @state >= 0
		@ip1.draw view if @state == 0
		@mark_forbidden.draw_at_point3d view, @ip1.position unless @ok_origin
	end
	
	if @state >= 1
		@ip2.draw view if @ip2.position == @pt_target && @inference.no_autoinference
		@mark_forbidden.draw_at_point3d view, @pt_target unless @ok_target
		@inference.draw2d view if @pt_target
	end

	#Drawing after
	_sub :draw_after, view, pt_origin, pt_target
	draw_mark(view, pt_origin, pt_target)	
end

#default drawing for the marks
def draw_mark(view, pt_origin, pt_target)
	if pt_origin && @mark_origin
		view.line_width = @mark_origin_width
		view.line_stipple = @mark_origin_stipple	
		m = @mark_origin
		view.draw_points pt_origin, m[0], m[1], m[2]
	end
	
	if pt_target && @mark_target
		view.line_width = @mark_target_width
		view.line_stipple = @mark_target_stipple		
		m = @mark_target
		view.draw_points pt_target, m[0], m[1], m[2]
	end
end

#Exit the Tool
def exit_tool
	_sub :exit_tool
end

#Standard method to accept text in the VCB
def onUserText(text, view)   
	Traductor::ReturnUp.set_on
	unless @prev_vec
		if @state == 0
			return UI.beep
		elsif @pt_target == nil
			return UI.beep
		end
	end	

	#Imposing the length
	len = Traductor.string_to_length_formula text
	return UI.beep unless len
	
	#Modify current or previous input
	if @state == 0 && @prev_vec
		@pt_origin = @prev_origin
		@pt_target = @pt_origin.offset @prev_vec, len
	else
		vec = @pt_origin.vector_to @pt_target
		@pt_target = @pt_origin.offset vec, len
	end	
	validate_target view, true
end

#Manage the display of the status bar and VCB
def show_info
	if @state == 0
		stext = @title_origin
	else
		stext = @title_target
	end
	
	svalue = ""
	if @distance
		svalue = (@ok_target) ? @distance.to_l : @warning_target
		label = @title_distance
		stext += '  ' + Traductor.format_point(@pt_target) if @pt_target
	elsif !@ok_origin	
		svalue = @warning_origin
		label = @title_warning
	elsif @pt_origin != nil
		stext += '  ' + Traductor.format_point(@pt_origin)	
	else
		label = ""
	end
	
	Sketchup.set_status_text stext
	Sketchup::set_status_text label, SB_VCB_LABEL
	Sketchup::set_status_text svalue, SB_VCB_VALUE		
end

end	#class StandardPickLineTool

#--------------------------------------------------------------------------------------------------------------
# Class VecInference: Manage inference between 2 points
#--------------------------------------------------------------------------------------------------------------			 				   

class VecInference

attr_reader :no_autoinference

Traductor_InferenceType = Struct.new "Traductor_InferenceType", :code, :color, :tooltip

@@hsh_types = nil		#Store parameters for the standard inference types

def initialize
	@ip1 = Sketchup::InputPoint.new
	@ip2 = Sketchup::InputPoint.new
	
	@precision = MYDEFPARAM[:T_DEFAULT_InferencePrecision]
	@color_none = MYDEFPARAM[:T_DEFAULT_InferenceColor_None]
	@color_collinear = MYDEFPARAM[:T_DEFAULT_InferenceColor_Collinear]
	@color_perpendicular = MYDEFPARAM[:T_DEFAULT_InferenceColor_Perpendicular]
	
	build_all_types
		
	@vecdir_forced = nil
	@tooltip = ""
	@x = @y = nil
	@axes_ref = [X_AXIS, Y_AXIS, Z_AXIS]
	@width = 1
	@stipple = ""
end

#Methods to get information
def get_target ; @pt_target ; end
def get_tooltip ; @tooltip ; end

#Build a static list of all Inference types
def build_all_types
	return if @@hsh_types
	@@hsh_types = {}
	build_inference_type '', @color_none, ""
	build_inference_type 'X', 'red', :T_STR_RedAxis
	build_inference_type 'Y', 'green', :T_STR_GreenAxis
	build_inference_type 'Z', 'blue', :T_STR_BlueAxis
	build_inference_type '//', @color_collinear, :T_STR_Inference_Colinear
	build_inference_type 'PP', @color_perpendicular, :T_STR_Inference_Perpendicular
end

def build_inference_type(code, color, symb_tooltip)
	stype = Traductor_InferenceType.new
	stype.code = code
	stype.color = color
	stype.tooltip = T6[symb_tooltip]
	@@hsh_types[code] = stype
end

def set_line_style(width, stipple=nil)
	@width = width.abs if width && width.class == Integer
	@stipple = stipple if stipple && stipple.class == String
end

def set_custom_axes(axes, tooltip=nil)
	if axes
		@axes_ref = axes
		@axes_ttip = tooltip
		@axes_custom = true
	else
		@axes_ref = [X_AXIS, Y_AXIS, Z_AXIS]
		@axes_ttip = nil
		@axes_custom = false
	end	
end

def lock_axis(axis_code)
	case axis_code
	when 'X', 'x'
		set_forced_direction @axes_ref[0], 'X'
	when 'Y', 'y'
		set_forced_direction @axes_ref[1], 'Y'
	when 'Z', 'z'
		set_forced_direction @axes_ref[2], 'Z'
	else
		set_forced_direction nil, ''
	end	
end

#Integrate the menu items related to Inference in the contextual menu
def contextual_menu(menu)
	menu.add_item(T6[:T_MNU_Inference_Toggle]) { toggle_inference }
	menu.add_item(T6[:T_MNU_Inference_RedAxis]) { lock_axis 'X' }
	menu.add_item(T6[:T_MNU_Inference_GreenAxis]) { lock_axis 'Y' }
	menu.add_item(T6[:T_MNU_Inference_BlueAxis]) { lock_axis 'Z' }
	menu.add_item(T6[:T_MNU_Inference_NoAxis]) { lock_axis '' }
end

def set_xy_origin(view, x, y)
	@ip1.pick view, x, y
	set_ip_origin view, @ip1
end

def force_origin(pt_origin)
	@lst_para = []
	@lst_perp = []
	@pt_origin = pt_origin.clone
end

#Set the Origin Input Point
def set_ip_origin(view, ip_origin)
	@ip_origin = ip_origin
	@pt_origin = @ip_origin.position.clone
	
	vertex = @ip_origin.vertex
	edge = @ip_origin.edge
	face = @ip_origin.face
	tr = @ip_origin.transformation
	@lst_para = []
	@lst_perp = []
	if vertex
		@lst_para = vertex.edges.collect { |e| (tr * e.start.position).vector_to(tr * e.end.position) }
		if face
			vnorm = tr * face.normal
			@lst_perp = @lst_para.collect { |v| v * vnorm }
		end	
	elsif edge
		vecedge = (tr * edge.start.position).vector_to(tr * edge.end.position)
		@lst_para = [vecedge]
		@lst_perp = edge.faces.collect { |f| (tr * f.normal) * vecedge }
	end
	@pt_origin
end

def set_target(pt_target)
	@pt_target = pt_target.clone
end

#toggle inference lock	
def toggle_inference
	set_forced_direction((@vecdir_forced) ? nil : @vecdir)
end
	
#Trap Modifier keys for Inference Control
def handleKeyDown(key, rpt, flags, view)
	case key	

	#Shift Key to lock inference
	when CONSTRAIN_MODIFIER_KEY	
		@time_shift = Time.now.to_f
		set_forced_direction((@vecdir_forced) ? nil : @vecdir)

	#Arrow Keys to lock axes	
	when VK_UP
		lock_axis 'Z'
	when VK_RIGHT
		lock_axis 'X'
	when VK_LEFT
		lock_axis 'Y'
	when VK_DOWN
		lock_axis ''
			
	#Ignore all other keys	
	else
		return false
	end	
	
	return true
end

def handleKeyUp(key, rpt, flags, view)
	case key			
	when CONSTRAIN_MODIFIER_KEY		#Shift Key
		set_forced_direction nil if (Time.now.to_f - @time_shift) > 0.6
	else
		return false
	end	
	
	return true
end
	
#Set a forced reference direction	
def set_forced_direction(vecdir, code=nil)
	if vecdir && vecdir.valid?
		@vecdir_forced = vecdir
		@vecdir = vecdir
		@code = code if code
	else
		@vecdir_forced = nil
	end	
end
	
def prepare_directions
	lst = []
	
	#Model Axes
	lst.push [@axes_ref[0], "X"] if @axes_ref[0]
	lst.push [@axes_ref[1], "Y"] if @axes_ref[1]
	lst.push [@axes_ref[2], "Z"] if @axes_ref[2]
	
	#Parallel and Perpendicular to edges at origin
	@lst_para.each { |vec| lst.push [vec, "//"] if vec.valid? }
	@lst_perp.each { |vec| lst.push [vec, "PP"] if vec.valid? }
	
	#returning the list
	lst
end
	
def set_hsh_entityID(hsh)
	@hsh_entID = hsh
end
	
def compute_xy_inference(view, x, y)
	@ip2.pick view, x, y, @ip1
	@x = x
	@y = y
	compute_inference view, @ip2
	@pt_target
end

def compute_ip_inference(view, ip_target)
	compute_inference view, ip_target
	@pt_target
end

def guess_ip_position(view, pt_origin, ip, x, y, hsh_entID)
	dof = ip.degrees_of_freedom
	no_autoinference = ((dof == 0 && ip.vertex) || (dof == 1 && ip.edge)) && 
	                     G6.not_auto_inference?(ip, hsh_entID)
	return ip.position if no_autoinference
	pt2d = view.screen_coords pt_origin
	ray = view.pickray pt2d.x, pt2d.y
	ray2 = view.pickray x, y
	pt = Geom.intersect_line_plane ray2, [pt_origin, ray[1]]
	(pt) ? pt : ip.position
end

# Top method to compute the direction infered by the target point
def compute_inference(view, ip_target)
	@ip_target = ip_target
	@dof = @ip_target.degrees_of_freedom
	pt = @ip_target.position
	#pt = guess_ip_position view, @pt_origin, @ip_target, @x, @y, @hsh_entID
	@tooltip = @ip_target.tooltip	
	@color = @color_none
	@pt_target = pt.clone
	@no_autoinference = false
	
	#Inference forced 
	return close_to_vector(view, pt, @vecdir_forced, @code) if @vecdir_forced
			
	#Testing if the direction is valid
	vecdir = @pt_origin.vector_to pt
	return unless vecdir.valid?
	@vecdir = vecdir
	
	#Inference along particular directions
	prepare_directions.each { |ldir| return if close_to_vector view, pt, ldir[0], ldir[1] }
	
	#Degree of freedom constrained
	@no_autoinference = ((@dof == 0 && @ip_target.vertex) || (@dof == 1 && @ip_target.edge)) && 
	                     G6.not_auto_inference?(@ip_target, @hsh_entID)
	#return if @no_autoinference

	#No inference
	@code = ""
end

def true_inference_vertex?(view, ip)
	vertex = ip.vertex
	return false unless vertex
	pt2d = view.screen_coords vertex.position
	return false if (pt2d.x - @x).abs > 10 || (pt2d.y - @y).abs > 10
	[/from/i, /von/i, /de/i].each do |pat|
		return false if ip.tooltip && ip.tooltip =~ pat
	end		
	true
end

#Trigger inference if the direction is close to a given reference vector
def close_to_vector(view, pt, vecref, code)
	#Compute the real point if possible
	pt = @ip_target.position
	vertex = @ip_target.vertex
	edge = @ip_target.edge
	face = @ip_target.face
	tr = @ip_target.transformation
	if @vecdir_forced == nil && (vertex || edge || face)
		vecdir = @pt_origin.vector_to pt
		ps = vecdir.normalize % vecref.normalize
		return false if ps.abs < 0.996
		@pt_target = pt.project_to_line [@pt_origin, vecref]
		@vecdir = @pt_origin.vector_to @pt_target

	elsif @vecdir_forced && @x && G6.true_inference_vertex?(view, @ip_target, @x, @y)
		ptproj = pt.project_to_line [@pt_origin, @vecdir_forced]
		@pt_target = ptproj
		@vecdir = @pt_origin.vector_to @pt_target
		
	#Checking proximity based on screen coordinates
	else					
		p1 = view.screen_coords @pt_origin
		p2 = view.screen_coords @pt_origin.offset(vecref, 1)
		vref2d = p1.vector_to p2
		p3 = view.screen_coords pt
		pproj = p3.project_to_line [p1, vref2d]
		return false unless @vecdir_forced || p3.distance(pproj) <= @precision
		ray = view.pickray pproj.x, pproj.y
		lpt = Geom.closest_points [@pt_origin, vecref], ray
		@pt_target = lpt[0]
		@vecdir = vecref
	end	
	
	#Computing tooltip and color
	code = @code unless code
	stype = @@hsh_types[code]
	if stype
		@code = code.upcase
		@color = stype.color
		@tooltip = stype.tooltip
		@tooltip += ' (' + @axes_ttip + ')' if @axes_custom && @axes_ttip && ['X', 'Y', 'Z'].include?(code)
	end	
	true
end

#Draw the line between the origin and target
def draw2d(view, ref_width=nil, stipple=nil)
	draw_23d true, view, ref_width, stipple
end
def draw(view, ref_width=nil, stipple=nil)
	draw_23d false, view, ref_width, stipple
end

def draw_23d(flag_2d, view, ref_width=nil, stipple=nil)
	return if @width == 0
	return unless @pt_origin && @pt_target
	
	#Drawing the line between origin and target
	view.drawing_color = @color
	view.line_stipple = (stipple) ? stipple : @stipple
	width = (ref_width) ? ref_width : @width
	view.line_width = (@vecdir_forced) ? 2 * width : width
	if flag_2d
		view.draw2d GL_LINE_STRIP, view.screen_coords(@pt_origin), view.screen_coords(@pt_target)
	else
		view.draw GL_LINE_STRIP, @pt_origin, @pt_target
	end	
	
	#Drawing the reference perpendicular if required
	if @code == "PP"
		vpp = @lst_para.find { |v| (@vecdir % v).abs <= 0.001 }
		if vpp
			p1 = view.screen_coords @pt_origin
			p2 = view.screen_coords @pt_origin.offset(vpp, 10)
			v2d = p1.vector_to p2
			pa = p1.offset v2d, 30
			pb = p1.offset v2d, -30
			view.line_stipple = ""
			view.line_width = 4
			view.drawing_color = @color
			view.draw2d GL_LINE_STRIP, pa, pb
		end	
	end
end

end	#class VecInference

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
	return color unless face && face.valid?
	view = Sketchup.active_model.active_view
	material = (view.camera.direction % face.normal <= 0) ? face.material : face.back_material
	return color unless material
	Couleur.revert_color color, material.color
end

def Couleur.revert_color(color, face_color)	
	color = Sketchup::Color.new(color) unless color.kind_of?(Sketchup::Color)
	face_color = Sketchup::Color.new(face_color) unless face_color.kind_of?(Sketchup::Color)
	return color if Couleur.contrasted_enough?(color.to_a, face_color.to_a)
	Sketchup::Color.new(255 - color.red, 255 - color.green, 255 - color.blue)
end

def Couleur.contrasted_enough?(rgb1, rgb2)
	sum = 0
	for i in 0..2
		sum += [rgb1[i], rgb2[i]].max - [rgb1[i], rgb2[i]].min
	end
	sum > 400
end

end	# class Couleur

#--------------------------------------------------------------------------------------------------------------
# Class ContextMenu: management of contextual menu
#--------------------------------------------------------------------------------------------------------------			 				   

class ContextMenu

#Initialize the Contextual menu
def initialize
	@list_cmd = []
end

#Indicate separator to contextual menu
def add_sepa
	@list_cmd.push nil
end

#Indicate a function key contribution to contextual menu
def add_fkey(fkey, flag)
	@list_cmd.push fkey.create_cmd(flag) if condition
end

#Indicate a Sketchup command to contextual menu
def add_cmd(cmd)
	@list_cmd.push cmd
end

def add_item(text, shortcut=nil, status=nil, &proc)
	text = Traductor.encode_menu text, shortcut, status
	#####add_cmd UI::Command.new(text) { proc.call }
	add_cmd [text, proc] if proc
end

#Show the contextual menu
def show(menu)
	return if @list_cmd.length == 0
	sepa = nil
	@list_cmd.pop until @list_cmd.last || @list_cmd.length == 0
	@list_cmd.each do |cmd|
		if cmd
			#####menu.add_item cmd
			menu.add_item(cmd[0]) { cmd[1].call }
		elsif sepa
			menu.add_separator
		end
		sepa = cmd
	end
end

end	#class ContextMenu

#========================================================================================
#========================================================================================
# Please Wait tool
#========================================================================================
#========================================================================================

class PleaseWaitTool

def initialize(ruby, color=nil)
	@ruby = ruby
	@started = false
	
	@model = Sketchup.active_model
	@view = @model.active_view
	w = @view.vpwidth
	h = 16
	@rect = []
	@rect.push Geom::Point3d.new(0, 0)
	@rect.push Geom::Point3d.new(0, h)
	@rect.push Geom::Point3d.new(w, h)
	@rect.push Geom::Point3d.new(w, 0)
	@pt_text = Geom::Point3d.new 10, 0, 0
	@color = color
	@color = "yellow" unless color	
end

#Display a message
def message(message, color=nil)
	return unless defined?(Sketchup.active_model.active_view.refresh)
	@message = message
	@color = color
	unless @started
		Sketchup.active_model.tools.push_tool self
		@started = true
	end	
	@view.refresh
end

def exit
	return unless @started
	Sketchup.active_model.tools.pop_tool
	@started = nil
end

def activate
	LibFredo6.register_ruby @ruby if @ruby
	@view.refresh
end

def deactivate(view)
	@message = nil
	@view.refresh
end

def draw(view)
	return unless @message
	view.line_width = 1
	view.line_stipple = ""
	view.drawing_color = 'blue'
	view.draw GL_LINE_LOOP, @rect
	view.drawing_color = @color
	view.draw2d GL_POLYGON, @rect
	view.draw_text @pt_text, @message
end

end	#class PleaseWaitTool

#========================================================================================
#========================================================================================
# Class HourGlass: HourGlass management
#========================================================================================
#========================================================================================

class HourGlass

@@hourglass = nil

#Built-in Hourclass
def HourGlass.start(delay=0.2) ; @@hourglass = HourGlass.new :red unless @@hourglass ; @@hourglass.start delay ; end
def HourGlass.stop ; @@hourglass.stop if @@hourglass ; end
def HourGlass.check? ; (@@hourglass) ? @@hourglass.check? : false ; end


#Instance Initialization
def initialize(symb_color=nil, message=nil)
	@message = (message) ? message : T6[:T_STR_PleaseWait]
	compute_cursor symb_color
	@symb_color = symb_color
	@active = false
end

def compute_cursor(symb_color)
	case symb_color
	when :red
		@id_cursor_red = Traductor.create_cursor "Cursor_HourGlass_Red", 16, 16 unless @id_cursor_red
		@id_cursor = @id_cursor_red
	when :blue
		@id_cursor_blue = Traductor.create_cursor "Cursor_HourGlass_Blue", 16, 16 unless @id_cursor_blue
		@id_cursor = @id_cursor_blue
	else
		@id_cursor_green = Traductor.create_cursor "Cursor_HourGlass_Green", 16, 16 unless @id_cursor_green
		@id_cursor = @id_cursor_green
	end	
end

def start(delay=0.2)
	@time_start = Time.now
	@delay = delay
	@active = false
end

def check?
	if !@active && Time.now - @time_start > @delay
		@active = true
		UI.set_cursor @id_cursor
		Sketchup.set_status_text @message if @message
	end
	@active
end

def stop
	@time_start = Time.now
	@active = false
	Sketchup.set_status_text "" if @message
	UI.set_cursor 0
end

end	#class HourGlass

end #Module Traductor

