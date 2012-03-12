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
# Name			:   A_PaletteOnSurface.rb
# Original Date	:   14 Jul 2009 - version 1.5
# Description	:   Manage the palette and contextual menus for all tools on Surface
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module SUToolsOnSurface

#Constants for Palette management (do not translate)
T6[:MNU_Exit] = "Exit Tool"
T6[:MNU_Finish] = "Finish"
T6[:MNU_Done] = "Done and Exit (RETURN)"
T6[:MNU_Redo] = "Redo operation with %1 (Double Click)"
T6[:MNU_UndoLast] = "Undo Last input (ESC)"

T6[:MNU_Option_LineMode] = "Line mode"
T6[:MNU_Option_ClickMode] = "Point and click mode (TAB)"
T6[:MNU_Option_InfLock] = "Lock Inference mode (SHIFT)"
T6[:MNU_Option_CPoint] = "Construction Points at vertices"
T6[:MNU_Option_Group] = "Generate in a Common Group"
T6[:NAM_Option_Group] = "Name: TOS__Group"
T6[:TIP_Option_Group] = "Change group name to create a new group"
T6[:MNU_Option_Protractor] = "Protractor"
T6[:MNU_Option_GenCurves] = "Generate contour as Curves"
T6[:MNU_Option_GenFaces] = "Generate Faces"
T6[:MNU_Option_Simplify] = "Simplify contour"
T6[:MNU_Option_Alone] = "Treat as Alone contour"
T6[:MNU_Option_Contours] = "Contour Selection"
T6[:MNU_Option_Trigo] = "Sector drawn Clock-wise"
T6[:MNU_Option_Diameter] = "Circle by Diameter"
T6[:MNU_Option_Axes] = "Input Axes"
T6[:MNU_NbSeg] = "Number of segments on 360 deg. - Type number followed by s in VCB"

T6[:MNU_Contour_Outer] = "Outer only"
T6[:MNU_Contour_Inner] = "Inner only"
T6[:MNU_Contour_All] = "All"

T6[:MSG_Error] = "Error:"
				
T6[:VCB_Line] = "Plain Lines"
T6[:VCB_CLine] = "Construction Lines"
T6[:VCB_Option_CPoint] = "C-POINT"
T6[:VCB_Option_Group] = "GROUP"
T6[:VCB_Option_GenFaces] = "FACES"
T6[:VCB_Option_GenCurves] = "CURVES"
T6[:VCB_Option_NoSimplify] = "NO SIMPLIFY"
T6[:VCB_Option_Alone] = "ALONE"
T6[:VCB_Option_Diameter] = "DIAMETER"
	
T6[:VCB_Length] = "Length"
T6[:VCB_Distance] = "Distance"
T6[:VCB_Offset] = "Offset"
T6[:VCB_Angle] = "Angle"
T6[:VCB_LengAngle] = "Length, Angle"
T6[:VCB_Edges] = "Edges"
T6[:VCB_Pixel] = "Sampling in pixel"
T6[:TIP_Pixel] = "VCB: integer"

T6[:PAL_Precision] = "Pixels"
T6[:PAL_Contours] = "Contour Sel."
T6[:PAL_Contour_Tit] = "Contour for implicit selection"
T6[:PAL_Contour_Outer] = "Outer contours only (ignore holes)"
T6[:PAL_Contour_Inner] = "Inner contours only (just holes)"
T6[:PAL_Contour_All] = "Both outer and Inner contours"
T6[:PAL_Rings] = "RINGS"

T6[:DLG_RingNew] = "New Rings to be added:"
T6[:DLG_RingOthers] = "Currently defined Rings:"
T6[:TIP_RingInfo] = "You can also enter Rings in VCB: length followed by x"
T6[:TIP_RingAdd] = "Add new Rings"
T6[:TIP_RingEdit] = "Edit existing Rings"
T6[:TIP_RingClearAll] = "Clear All Rings (VCB: type 0x)"
T6[:TIP_RingUndo] = "Undo last change of Rings"
	
#--------------------------------------------------------------------------------------------------------------
# Top Calling functions: create the classes and launch the tools
#--------------------------------------------------------------------------------------------------------------			 				   

#Actual launching of menus	
def SUToolsOnSurface.action__mapping(action_code, param=nil)
	case action_code
	when :line, :offset, :eraser, :freehand
		PaletteManager.launch_generic action_code.to_s
	when :shape
		SUToolsOnSurface.launch_shape param.to_s if param
	when :edit_selection
		SUToolsOnSurface.launch_polyline Sketchup.active_model.selection
	when :edit
		SUToolsOnSurface.launch_polyline
	when :void_triangle
		VoidTriangle.proceed_repair
	when :make_face
		MakeFace.proceed Sketchup.active_model.selection
	else
		PaletteManager.launch_generic nil, true
	end	
end
	
#--------------------------------------------------------------------------------------------------------------
# Class PaletteManager
#--------------------------------------------------------------------------------------------------------------			 				   

class PaletteManager

attr_reader :linemode, :option_cpoint, :option_gencurves, :option_genfaces, :option_protractor,
            :option_group, :clickmode, :inference_lock, :inference_on, :option_protractor_sector,
			:option_simplify, :option_contours, :option_alone, :option_diameter, :option_trigo, :numseg,
			:param_axe1, :param_axe2, :px_precision, :lst_rings

@@persistence = nil

#Managing the generic launcher
@@generic_tool = nil
@@generic_running = false
	
def PaletteManager.launch_generic(code=nil, generic=false, linemode=true)
	#Managing the generic launcher
	if generic
		@@generic_tool = 'line' unless @@generic_tool
		code = @@generic_tool unless code
		@@generic_tool = code
		@@generic_running = true
	else
		@@generic_running = false
	end
	
	#Launching the tool
	case code
	when /polyline/i
		SUToolsOnSurface.launch_polyline
	when /line/i
		SUToolsOnSurface.launch_line linemode
	when /offset/i	
		SUToolsOnSurface.launch_offset linemode
	when /freehand/i	
		SUToolsOnSurface.launch_freehand linemode
	when /eraser/i
		SUToolsOnSurface.launch_eraser
	else	
		SUToolsOnSurface.launch_shape code, linemode
	end
end

# Initialization of the palette manager
def initialize(itself, tool_type, *args, &refresh_proc)
	@itself = itself
	@tool_type = tool_type

	@model = Sketchup.active_model
	@view = @model.active_view
	
	#parsing the arguments
	args.each do |arg|	
		arg.each { |key, value|  parse_palette_args(key, value) } if arg.class == Hash
	end
	
	@refresh_proc = refresh_proc
	@hsh_options = {}
	@lst_options.each { |opt| @hsh_options[opt] = true }
	@tit_onsurface = T6[:TIT_OnSurface]
	
	#Restoring the option parameters
	#persistence_restore
	
	#Initialization of the palette
	#init_text
	#init_palette
	#itself.set_palette @palette
end

#Assign the individual propert for the palette manager
def parse_palette_args(key, value)
	skey = key.to_s
	case skey
	when /finish_proc_gray/i
		@finish_proc_gray = value
	when /finish_proc_exec/i
		@finish_proc_exec = value
	when /notify_proc/i
		@notify_proc = value
	when /linemode/i
		@linemode = value
		@linemode = true if @linemode == nil
	when /list_options/i
		@lst_options = value
	when /title/i
		@title = value
	when /linepicker/i
		@linepicker = value
	when /refresh_proc/i
		@refresh_proc = value
	when /shape/i
		@shape = value
	end	
end

#Notify the palette manager of termination (for saving parameters)
def initiate
	#Restoring the option parameters
	persistence_restore
	
	#Initialization of the palette
	init_text
	init_palette
	@itself.set_palette @palette
end

#Notify the palette manager of termination (for saving parameters)
def terminate
	persistence_save
end

#Initialize all texts
def init_text
	@mnu_exit = T6[:MNU_Exit]
	@mnu_finish = T6[:MNU_Finish]
	@mnu_undo_last = T6[:MNU_UndoLast]
	@mnu_done = T6[:MNU_Done]
	@mnu_option_linemode = T6[:MNU_Option_LineMode]
	@mnu_option_cpoint = T6[:MNU_Option_CPoint]
	@mnu_option_group = T6[:MNU_Option_Group]
	@tip_option_group = @mnu_option_group + " (#{MYDEFPARAM[:DEFAULT_Key_Group]})\n" + T6[:NAM_Option_Group] + 
	                    "\n" + T6[:TIP_Option_Group]
	@mnu_option_protractor = T6[:MNU_Option_Protractor]
	@mnu_option_gencurves = T6[:MNU_Option_GenCurves]
	@mnu_option_genfaces = T6[:MNU_Option_GenFaces]
	@mnu_option_contours = T6[:MNU_Option_Contours]
	@mnu_option_simplify = T6[:MNU_Option_Simplify]
	@mnu_option_alone = T6[:MNU_Option_Alone]
	@mnu_click_mode = T6[:MNU_Option_ClickMode]
	@mnu_inflock = T6[:MNU_Option_InfLock]
	@mnu_option_trigo = T6[:MNU_Option_Trigo]
	@mnu_option_diameter = T6[:MNU_Option_Diameter]
	@mnu_option_axes = T6[:MNU_Option_Axes]
	@mnu_nbseg = T6[:MNU_NbSeg]
	@tip_pixel = T6[:TIP_Pixel]
	
	@choice_contour = { 'O' => T6[:MNU_Contour_Outer], 'I' => T6[:MNU_Contour_Inner],
                        'A' => T6[:MNU_Contour_All] }

	@msg_error = T6[:MSG_Error] = "Error:"

	@vcb_edges = T6[:VCB_Edges]
	@vcb_pixel = T6[:VCB_Pixel]
	@vcb_length = T6[:VCB_Length]
	@vcb_offset = T6[:VCB_Offset]
	@vcb_angle = T6[:VCB_Angle]
	@vcb_lengangle = T6[:VCB_LengAngle]
	
	@vcb_line = T6[:VCB_Line]
	@vcb_cline = T6[:VCB_CLine]
	@vcb_cpoint = T6[:VCB_Option_CPoint]
	@vcb_group = T6[:VCB_Option_Group]
	@vcb_genfaces = T6[:VCB_Option_GenFaces]
	@vcb_gencurves = T6[:VCB_Option_GenCurves]
	@vcb_nosimplify = T6[:VCB_Option_NoSimplify]
	@vcb_alone = T6[:VCB_Option_Alone]
	@vcb_diameter = T6[:VCB_Option_Diameter]

	@tit_onsurface = T6[:TIT_OnSurface]
	
	@msg_dlg_ring_new = T6[:DLG_RingNew]
	@msg_dlg_ring_others = T6[:DLG_RingOthers]
	@txt_pal_ring = T6[:PAL_Rings]
	@tip_ring_info = T6[:TIP_RingInfo]
	@tip_ring_add = T6[:TIP_RingAdd]
	@tip_ring_edit = T6[:TIP_RingEdit]
	@tip_ring_clear_all = T6[:TIP_RingClearAll]
	@tip_ring_undo = T6[:TIP_RingUndo]
	
end

#construct the title for the start operation label
def make_title_operation(title, flinemode=true)
	txt = title + ' ' + @tit_onsurface 
	txt += ' (' + ((@linemode) ? @vcb_line : @vcb_cline) + ')' if flinemode
	txt
end

#Create the visual palette
def make_proc(&proc) ; proc ; end

def declare_fkey(symb_key, menutext, lst_names=nil, &proc)
	Traductor::FKeyOption.new(menutext, MYDEFPARAM[symb_key], lst_names, &proc)
end

def pal_separator(tsepa)
	unless tsepa
		@palette.declare_separator unless tsepa
		tsepa = true
	end	
	tsepa
end

def init_palette
	@palette = Traductor::Palette.new 
	draw_local = self.method "draw_button_opengl"
	draw_blason = self.method "draw_button_blason"
	sblason = "blason_" + @tool_type
	symb_blason = sblason.intern
	tsepa = false

	#Blason Button
	hsh = { :blason => true, :tooltip => @title + " " + @tit_onsurface, :draw_proc => draw_blason, :passive => true }
	@palette.declare_button(symb_blason, hsh)

	#Undo Last
	if @hsh_options['undo_last']
		tsepa = pal_separator(tsepa)
		hsh = { :tooltip => @mnu_undo_last, :draw_proc => :std_undo }
		@palette.declare_button(:pal_undo_last, hsh) { @itself.onCancel 0, @view}
		tsepa = false
	end
	
	#Line mode
	if @hsh_options['linemode']
		tsepa = pal_separator(tsepa)
		lk = [@vcb_cline, @vcb_line]
		@fkey_line_mode = declare_fkey(:DEFAULT_Key_LineMode, @mnu_option_linemode, lk) { toggle_option_linemode }
		proc = make_proc() { !@linemode }
		hsh = { :value_proc => proc, :fkey => @fkey_line_mode, :draw_proc => draw_local }
		@palette.declare_button(:pal_linemode, hsh) { toggle_option_linemode }
		tsepa = false
	end
	
	#Click mode for Freehand
	if @hsh_options['clickmode']
		tsepa = pal_separator(tsepa)
		@fkey_click_mode = declare_fkey(:DEFAULT_Key_ClickMode, @mnu_click_mode) { toggle_option_clickmode }
		proc = make_proc() { @clickmode }
		hsh = { :value_proc => proc, :fkey => @fkey_click_mode, :draw_proc => draw_local }
		@palette.declare_button(:pal_clickmode, hsh) { toggle_option_clickmode }
		tsepa = false
	end

	#Inference Lock mode for Freehand
	if @hsh_options['inference_lock']
		tsepa = pal_separator(tsepa)
		proc = make_proc() { @inference_lock || @inference_on}
		hsh = { :value_proc => proc, :tooltip => @mnu_inflock, :draw_proc => draw_local, :draw_refresh => true }
		@palette.declare_button(:pal_inference_lock, hsh) { toggle_option_inference_lock }
		tsepa = false
	end

	#diameter input for Circle
	if @hsh_options['diameter']
		@param_axe1 = @option_diameter
		tsepa = pal_separator(tsepa)
		@fkey_diameter = declare_fkey(:DEFAULT_Key_InputAxes, @mnu_option_diameter) { toggle_option_diameter }
		proc = make_proc() { @option_diameter}
		hsh = { :value_proc => proc, :fkey => @fkey_diameter, :draw_proc => draw_local }
		@palette.declare_button(:pal_diameter, hsh) { toggle_option_diameter }
		tsepa = false
	end
	
	#Mode for axe inputs
	if @hsh_options['axes']
		tsepa = pal_separator(tsepa)
		@fkey_axes = declare_fkey(:DEFAULT_Key_InputAxes, @mnu_option_axes) { toggle_axes }
		
		declare_buttons_for_axes false, false
		declare_buttons_for_axes true, false
		declare_buttons_for_axes true, true
		declare_buttons_for_axes false, true
		
		tsepa = false
	end
		
	#Contour selection for offset
	if @hsh_options['contours']
		tsepa = pal_separator(tsepa)
		lk = @choice_contour
		@fkey_contours = declare_fkey(:DEFAULT_Key_Contours, @mnu_option_contours, lk) { toggle_option_contours }
		vproc = make_proc() { @option_contours }
		hsh = { :type => 'multi', :radio => true, :value_proc => vproc, :text => T6[:PAL_Contours], 
		        :default_value => 'O', :tooltip => T6[:PAL_Contour_Tit] }
		@palette.declare_button(:pal_contours, hsh) { set_option_contours }
		hp = { :parent => :pal_contours, :width => 30, :draw_proc => draw_local }
		
		hsh = { :value => 'O', :tooltip => T6[:PAL_Contour_Outer]}
		@palette.declare_button(:pal_contours_O, hp, hsh)
		
		hsh = { :value => 'A', :tooltip => T6[:PAL_Contour_All]}
		@palette.declare_button(:pal_contours_A, hp, hsh)
		
		hsh = { :value => 'I', :tooltip => T6[:PAL_Contour_Inner]}
		@palette.declare_button(:pal_contours_I, hp, hsh)
		tsepa = false
	end
	
	#Simplify for Offset
	if @hsh_options['simplify']
		tsepa = pal_separator(tsepa)
		@fkey_simplify = declare_fkey(:DEFAULT_Key_Simplify, @mnu_option_simplify) { toggle_option_simplify }
		proc = make_proc() { @option_simplify }
		hsh = { :value_proc => proc, :fkey => @fkey_simplify, :draw_proc => draw_local }
		@palette.declare_button(:pal_simplify, hsh) { toggle_option_simplify }
		tsepa = false
	end
	
	#Alone for Offset
	if @hsh_options['alone']
		@fkey_alone = declare_fkey(:DEFAULT_Key_Alone, @mnu_option_alone) { toggle_option_alone }
		proc = make_proc() { @option_alone }
		hsh = { :value_proc => proc, :fkey => @fkey_alone, :draw_proc => draw_local }
		@palette.declare_button(:pal_alone, hsh) { toggle_option_alone }
		tsepa = false
	end
	
	#Trigonometric sense
	if @hsh_options['trigo']
		tsepa = pal_separator(tsepa)
		@fkey_trigo = declare_fkey(:DEFAULT_Key_InputAxes, @mnu_option_trigo) { toggle_option_trigo }
		proc = make_proc() { !@option_trigo }
		hsh = { :value_proc => proc, :fkey => @fkey_trigo, :draw_proc => draw_local }
		@palette.declare_button(:pal_trigo, hsh) { toggle_option_trigo }
		tsepa = false
	end

	#Number of segments
	if @hsh_options['numseg']
		tsepa = pal_separator(tsepa)	
		wid = 32
		hsh = { :height => 16, :width => wid, :rank => 1, :passive => true, :text => '#', :tooltip => @mnu_nbseg }
		@palette.declare_button(:pal_numseg_title, hsh)			
		text_proc = make_proc() { @shape.nbseg.to_s + 's'}
		hsh = { :height => 16, :width => wid, :text_proc => text_proc, :bk_color => 'lightgreen', :tooltip => @mnu_nbseg }
		@palette.declare_button(:pal_numseg, hsh) { @shape.ask_numseg }	
		tsepa = false
	end

	#Number of segments
	if @hsh_options['precision']
		tsepa = pal_separator(tsepa)	
		wid = 40
		hsh = { :height => 16, :width => wid, :rank => 1, :passive => true, :text => T6[:PAL_Precision], :tooltip => @vcb_pixel }
		@palette.declare_button(:pal_pixel_title, hsh)			
		text_proc = make_proc() { @px_precision.to_s}
		hsh = { :height => 16, :width => wid, :text_proc => text_proc, :bk_color => 'yellow', 
		        :tooltip => @vcb_pixel + ' - ' + @tip_pixel }
		@palette.declare_button(:pal_precision, hsh) { ask_precision }	
		tsepa = false
	end
	
	#Construction Points
	if @hsh_options['cpoint']
		tsepa = pal_separator(tsepa)
		@fkey_cpoint = declare_fkey(:DEFAULT_Key_CPoint, @mnu_option_cpoint) { toggle_option_cpoint }
		proc = make_proc() { @option_cpoint }
		hsh = { :value_proc => proc, :fkey => @fkey_cpoint, :draw_proc => draw_local, :draw_refresh => true }
		@palette.declare_button(:pal_cpoint, hsh) { toggle_option_cpoint }
		tsepa = false
	end
	
	#Group
	if @hsh_options['group']
		tsepa = pal_separator(tsepa)
		@fkey_group = declare_fkey(:DEFAULT_Key_Group, @mnu_option_group) { toggle_option_group }
		proc = make_proc() { @option_group }
		hsh = { :value_proc => proc, :fkey => @fkey_group, :tooltip => @tip_option_group, 
		        :draw_proc => :std_group,  :main_color => 'darkred' }
		@palette.declare_button(:pal_group, hsh) { toggle_option_group }
		tsepa = false
	end
	
	#Protractor
	if @hsh_options['protractor']
		tsepa = pal_separator(tsepa)
		@fkey_protractor = declare_fkey(:DEFAULT_Key_Protractor, @mnu_option_protractor) { toggle_option_protractor }
		proc = make_proc() { @option_protractor }
		hsh = { :value_proc => proc, :fkey => @fkey_protractor, :draw_proc => :std_protractor, :main_color => 'black' }
		@palette.declare_button(:pal_protractor, hsh) { toggle_option_protractor }
		tsepa = false
	end

	#Protractor sector
	if @hsh_options['protractor_sector']
		tsepa = pal_separator(tsepa)
		@fkey_protractor_sector = declare_fkey(:DEFAULT_Key_Protractor, @mnu_option_protractor) { toggle_option_protractor_sector }	
		proc = make_proc() { @option_protractor_sector }
		hsh = { :value_proc => proc, :fkey => @fkey_protractor_sector, :draw_proc => :std_protractor, :main_color => 'black' }
		@palette.declare_button(:pal_protractor, hsh) { toggle_option_protractor_sector }
		tsepa = false
	end
	
	#Gen faces
	if @hsh_options['genfaces']
		tsepa = pal_separator(tsepa)
		@fkey_genfaces = declare_fkey(:DEFAULT_Key_GenFaces, @mnu_option_genfaces) { toggle_option_genfaces }	
		proc = make_proc() { @option_genfaces }
		hsh = { :value_proc => proc, :fkey => @fkey_genfaces, :draw_proc => draw_local }
		@palette.declare_button(:pal_genfaces, hsh) { toggle_option_genfaces }
		tsepa = false
	end
	
	#Gen curves
	if @hsh_options['gencurves']
		@fkey_gencurves = declare_fkey(:DEFAULT_Key_GenCurves, @mnu_option_gencurves) { toggle_option_gencurves }	
		proc = make_proc() { @option_gencurves }
		hsh = { :value_proc => proc, :fkey => @fkey_gencurves, :draw_proc => draw_local }
		@palette.declare_button(:pal_gencurves, hsh) { toggle_option_gencurves }
		tsepa = false
	end
	
	#Exit tool
	tsepa =pal_separator(tsepa)
	hsh = { :tooltip => @mnu_exit, :draw_proc => :std_exit }
	@palette.declare_button(:pal_exit, hsh) { @model.select_tool nil }
	
	#Execute
	if @finish_proc_exec
		@finish_proc_gray = make_proc() { false } unless @finish_proc_gray
		grayed_proc = make_proc() { @lst_marks == 0 }
		hsh = { :tooltip => @mnu_finish, :draw_proc => :valid, :grayed_proc => @finish_proc_gray }
		@palette.declare_button(:pal_finish, hsh) { @finish_proc_exec.call }
	end
	
	#Declaring side palette
	bkcolor = 'palegoldenrod'
	hshb = { :sidepal => nil, :draw_proc => draw_blason, :bk_color => bkcolor, :height => 30, :width => 32}
	
	@palette.declare_button(:tool_line, hshb, { :tooltip => T6[:TOS_LINE_Tooltip] }) { switch_tool 'line' }
	@palette.declare_separator_side nil, { :bk_color => bkcolor }
	
	hsh = {}
	SUToolsOnSurface.get_list_shapes.each do |hshape| 	
		symb = hshape['Symb']
		s = 'tool_' + symb.to_s
		@palette.declare_button(s.intern, hshb, hsh, { :tooltip => T6[symb] }) { switch_tool hshape['NameConv']}
	end			
	
	@palette.declare_separator_side nil, { :bk_color => bkcolor }
	@palette.declare_button(:tool_offset, hshb, { :tooltip => T6[:TOS_OFFSET_Tooltip] }) { switch_tool 'offset' }
	@palette.declare_button(:tool_freehand, hshb, { :tooltip => T6[:TOS_FREEHAND_Tooltip] }) { switch_tool 'freehand' }

	@palette.declare_separator_side nil, { :bk_color => bkcolor }
	@palette.declare_button(:tool_polyline, hshb, { :tooltip => T6[:TOS_POLYLINE_Tooltip] }) { switch_tool 'polyline' }
	@palette.declare_button(:tool_eraser, hshb, { :tooltip => T6[:TOS_ERASER_Tooltip] }) { switch_tool 'eraser' }
	
	#Declaring Ring side palette
	ring_init_palette if @hsh_options['ring']

end

#Create a button for Axe input
def declare_buttons_for_axes(param1, param2)
	draw_button_axes = self.method "draw_button_axes_opengl"
	ssymb = ((param1) ? '1' : '0') + ((param2) ? '1' : '0')
	sbut = ("pal_" + ssymb).intern
	proc = make_proc() { @param_axe1 == param1 && @param_axe2 == param2 }
	tooltip = @shape.tooltip_axe1(param1) + ' - ' + @shape.tooltip_axe2(param2)
	hsh = { :value_proc => proc, :tooltip => tooltip, :draw_proc => draw_button_axes, :draw_refresh => true}
	@palette.declare_button(sbut, hsh) { set_axes param1, param2 }
end

#Method to switch tool from the side palette
def switch_tool(code)
	persistence_save
	PaletteManager.launch_generic(code, @@generic_running)
end

#--------------------------------------------------------------
# Persistence of parameters
#--------------------------------------------------------------

#Saving parameters across sessions
def persistence_save
	@@persistence = {} unless @@persistence
	type = @tool_type
	typeall = 'All'

	#Common to all tools
	@@persistence[typeall] = {} unless @@persistence[typeall]
	hsh = @@persistence[typeall]

	hsh["Group"] = @option_group
	hsh["CommonGroup"] = @hshgroup 
	
	#Specific to the tool
	@@persistence[type] = {} unless @@persistence[type]
	hsh = @@persistence[type]
	
	#Parameters specific of the tool
	hsh["Linemode"] = @linemode
	hsh["Clickmode"] = @clickmode
	hsh["InfLock"] = @inference_lock
	hsh["Cpoint"] = @option_cpoint
	hsh["Gencurves"] = @option_gencurves
	hsh["Genfaces"] = @option_genfaces
	hsh["Protractor"] = @option_protractor
	hsh["Protractor_sector"] = @option_protractor_sector
	hsh["Simplify"] = @option_simplify
	hsh["Alone"] = @option_alone
	hsh["Contours"] = @option_contours
	hsh["px_precision"] = @px_precision
	if @shape
		hsh["Diameter"] = @option_diameter
		hsh["Param_axe1"] = @param_axe1
		hsh["Param_axe2"] = @param_axe2
		hsh["Trigo"] = @option_trigo
		hsh["Numseg"] = @shape.get_numseg
		hsh["Rings"] = @lst_rings
	end
	
	#Save permanently
	persistence_write hsh	
end

def symb_from_letter(letter=nil)
	letter = '0' unless letter
	symb = '_Reg_' + @tool_type + letter
	symb.intern
end

#Restoring parameters across sessions
def persistence_restore
	type = @tool_type
	typeall = 'All'
	@@persistence = {} unless @@persistence
	
	#common to all tools
	hsh = @@persistence[typeall]
	unless hsh
		hsh = @@persistence[typeall] = {}
		hsh["CommonGroup"] = {}
		hsh["Group"] = MYDEFPARAM[:TOS_DEFAULT_Group]
	end
	@option_group = hsh["Group"]
	@hshgroup = hsh["CommonGroup"]
	
	#Specific to the tool
	hsh = @@persistence[type]
	unless hsh
		hsh = @@persistence[type] = {}
		hsh["Linemode"] = (@linemode == nil) ? true : @linemode
		hsh["Clickmode"] = MYDEFPARAM[:TOS_DEFAULT_Freehand_ClickMode]
		hsh["InfLock"] = MYDEFPARAM[:TOS_DEFAULT_Freehand_InfLock]
		hsh["Cpoint"] = (@linemode) ? MYDEFPARAM[:TOS_DEFAULT_CPoint_L] : MYDEFPARAM[:TOS_DEFAULT_CPoint_C]
		hsh["Gencurves"] = MYDEFPARAM[:TOS_DEFAULT_GenCurve]
		hsh["Genfaces"] = MYDEFPARAM[:TOS_DEFAULT_GenFaces]
		hsh["Protractor"] = MYDEFPARAM[:TOS_DEFAULT_Protractor]
		hsh["Protractor_sector"] = MYDEFPARAM[:TOS_DEFAULT_Protractor_Sector]
		hsh["Simplify"] = MYDEFPARAM[:TOS_DEFAULT_Simplify]
		hsh["Alone"] = MYDEFPARAM[:TOS_DEFAULT_Alone]
		hsh["Contours"] = MYDEFPARAM[:TOS_DEFAULT_Contour_Select]
		hsh["px_precision"] = MYDEFPARAM[:TOS_DEFAULT_Freehand_Precision]
		if @shape
			hsh["Diameter"] = MYDEFPARAM[:TOS_DEFAULT_Diameter]
			hsh["Trigo"] = MYDEFPARAM[:TOS_DEFAULT_TrigoSense]
			hsh["Numseg"] = @shape.nbsegdef
			hsh["Rings"] = []
			hsh["Param_axe1"] = hsh["Param_axe2"] = (@shape && @shape.type == CODE_Circle3P)
		end	
		persistence_load
		hsh = @@persistence[type]
	end	
	
	@linemode = hsh["Linemode"]
	@clickmode = hsh["Clickmode"]
	@inference_lock = hsh["InfLock"]
	@option_cpoint = hsh["Cpoint"]
	@option_gencurves = hsh["Gencurves"]
	@option_genfaces = hsh["Genfaces"]
	@option_protractor = hsh["Protractor"]
	@option_protractor_sector = hsh["Protractor_sector"]
	@option_simplify = hsh["Simplify"]
	@option_alone = hsh["Alone"]
	@option_contours = hsh["Contours"]
	@linepicker.set_protractor_on @option_protractor if @linepicker
	@px_precision = hsh["px_precision"]
	@px_precision = 30 unless @px_precision
	if @shape
		@option_diameter = hsh["Diameter"]
		@param_axe1 = hsh["Param_axe1"]
		@param_axe2 = hsh["Param_axe2"]
		@param_axe1 = @param_axe2 = true if @shape.type == CODE_Circle3P
		@option_trigo = hsh["Trigo"]
		@numseg = hsh["Numseg"]
		@lst_rings = (hsh["Rings"]) ? hsh["Rings"].compact : []
		@shape.set_numseg @numseg
	end	
end

def persistence_load(letter=nil)
	return unless MYDEFPARAM[:TOS_DEFAULT_Persistence]
	symb = symb_from_letter letter
	sval = MYDEFPARAM[symb]
	return unless sval
	begin
		hshload = eval sval
		hsh = @@persistence[@tool_type]
		hshload.each { |key, val| hsh[key] = val }
	rescue
	end
end

def persistence_write(hsh, letter=nil)
	return unless MYDEFPARAM[:TOS_DEFAULT_Persistence]
	symb = symb_from_letter(letter)
	@@persistence[symb] = hsh.clone
	if MYDEFPARAM[symb] != hsh.inspect
		MYDEFPARAM[symb] = hsh.inspect
		MYDEFPARAM.save_to_file
	end
end

#--------------------------------------------------------------
# Contextual menu and short cuts
#--------------------------------------------------------------

#Trap Modifier keys for extended and Keep selection
def check_function_key(key, rpt, flags, view)
	unless @list_keys
		@list_keys = []
		@list_keys.push @fkey_click_mode if @hsh_options['clickmode']
		@list_keys.push @fkey_line_mode if @hsh_options['linemode']
		@list_keys.push @fkey_cpoint if @hsh_options['cpoint']
		@list_keys.push @fkey_group if @hsh_options['group']
		@list_keys.push @fkey_protractor if @hsh_options['protractor']
		@list_keys.push @fkey_protractor_sector if @hsh_options['protractor_sector']
		@list_keys.push @fkey_genfaces if @hsh_options['genfaces']
		@list_keys.push @fkey_gencurves if @hsh_options['gencurves']
		@list_keys.push @fkey_simplify if @hsh_options['simplify']
		@list_keys.push @fkey_alone if @hsh_options['alone']
		@list_keys.push @fkey_contours if @hsh_options['contours']
		@list_keys.push @fkey_diameter if @hsh_options['diameter']
		@list_keys.push @fkey_axes if @hsh_options['axes']
		@list_keys.push @fkey_trigo if @hsh_options['trigo']
	end
	
	@list_keys.each { |fk| return true if fk.test_key(key) }

	false
end

#Initialize the Contextual menu
def init_menu
	@list_cmd = []
end

#Indicate separator to contextual menu
def add_sepa
	@list_cmd.push nil
end

#Indicate a function key contribution to contextual menu
def add_menu_fkey(condition, fkey, flag)
	@list_cmd.push fkey.create_cmd(flag) if condition == nil || @hsh_options[condition]
end

#Indicate a Sketchup command to contextual menu
def add_menu_cmd(condition, cmd)
	@list_cmd.push cmd if condition == true || @hsh_options[condition]
end

#Show the contextual menu
def show_menu(menu)
	return if @list_cmd.length == 0
	sepa = nil
	@list_cmd.pop until @list_cmd.last
	@list_cmd.each do |cmd|
		if cmd
			#menu.add_item cmd
			menu.add_item(cmd[0]) { cmd[1].call } if cmd[1]
		elsif sepa
			menu.add_separator
		end
		sepa = cmd
	end
end

#Calculate the contextual menu commands for options
def option_menu(menu)
	
	#Options for Freehand
	add_sepa
	add_menu_fkey 'clickmode', @fkey_click_mode, @clickmode
	#add_menu_cmd 'inference_lock', UI::Command.new(@mnu_inflock) { toggle_option_inference_lock }
	add_menu_cmd 'inference_lock', [@mnu_inflock, self.method('toggle_option_inference_lock')]

	#Options specific to Offset 
	add_sepa
	add_menu_fkey 'contours', @fkey_contours, @option_contours
	add_menu_fkey 'simplify', @fkey_simplify, @option_simplify
	add_menu_fkey 'alone', @fkey_alone, @option_alone

	#Axes and diameter for shape tools
	add_sepa
	add_menu_fkey 'trigo', @fkey_trigo, !@option_trigo
	add_menu_fkey 'diameter', @fkey_diameter, @option_diameter
	add_menu_fkey 'axes', @fkey_axes, @option_axes

	#Protractor options
	add_sepa
	add_menu_fkey 'protractor', @fkey_protractor, @option_protractor
	add_menu_fkey 'protractor_sector', @fkey_protractor_sector, @option_protractor_sector
	
	#Generic for most tools
	add_sepa
	add_menu_fkey 'linemode', @fkey_line_mode, !@linemode
	add_sepa
	add_menu_fkey 'cpoint', @fkey_cpoint, @option_cpoint
	add_menu_fkey 'group', @fkey_group, @option_group
	add_sepa
	add_menu_fkey 'genfaces', @fkey_genfaces, @option_genfaces
	add_menu_fkey 'gencurves', @fkey_gencurves, @option_gencurves
	
	#Showing the menu
	show_menu menu if menu
end

#Add specific menus to the contextual menu
def menu_add_done(&proc)
	#add_menu_cmd true, UI::Command.new(@mnu_done) { proc.call }
	add_menu_cmd true, [@mnu_done, proc.call]
end

def menu_add_redo(s, &proc)
	#add_menu_cmd true, UI::Command.new(T6[:MNU_Redo, s]) { proc.call }
	add_menu_cmd true, [T6[:MNU_Redo, s], proc]
end

def menu_add_undo_last(&proc)
	proc = make_proc() { @itself.onCancel 0, @view } unless proc
	#add_menu_cmd true, UI::Command.new(@mnu_undo_last) { proc.call }
	add_menu_cmd true, [@mnu_undo_last, proc]
end

#display information in the Sketchup status bar
def info_show(message, hsh_param)
	msgtit = @title + ": [" + ((@linemode) ? @vcb_line : @vcb_cline) + "] "

	msgopt = ""
	if @palette.shrinked
		msgopt += " [" + @vcb_group + "]" if @option_group
		msgopt += " [" + @vcb_gencurves + "]" if @option_gencurves
		msgopt += " [" + @vcb_genfaces + "]" if @option_genfaces
		msgopt += " [" + @vcb_cpoint + "]" if @option_cpoint
		msgopt += " [" + @vcb_nosimplify + "]" if !@option_simplify
		msgopt += " [" + @vcb_alone + "]" if @option_alone
		msgopt += " [" + @vcb_diameter + "]" if @option_diameter
	end
	
	Sketchup.set_status_text msgtit + message + msgopt 
	
	#Scanning the values
	hsh_param = {} unless hsh_param
	
	length = hsh_param['length']
	slen = Sketchup.format_length(length) if length

	offset = hsh_param['offset']
	soffset = Sketchup.format_length(offset) if offset

	angle = hsh_param['angle']
	sangle = sprintf("%3.1f ", angle.radians) + "\°" if angle
	
	nbseg = hsh_param['nbseg']
	snbseg = @vcb_edges + "=" + nbseg.to_s if nbseg
	
	precision = hsh_param['precision']
	sprecision = "px=" + precision.to_s if precision
			
	#Compute the label and VCB displayed value
	if nbseg && precision
		label = @vcb_edges
		txval = snbseg + ' ' + sprecision
		tip = @vcb_edges + " = " + nbseg.to_s + '   ' + @vcb_pixel + " = " + precision.to_s
	elsif nbseg 
		label = @vcb_edges
		txval = snbseg
		tip = @vcb_edges + " = " + nbseg.to_s
	elsif length && angle
		label = @vcb_lengangle
		txval = slen + ", " + sangle
		tip = @vcb_length + " = " + slen + "  " + @vcb_angle + " = " + sangle
	elsif length
		label = @vcb_length
		txval = slen
		tip = @vcb_length + " = " + slen 
	elsif offset
		label = @vcb_offset
		txval = soffset
		tip = @vcb_offset + " = " + soffset 
	elsif angle
		label = @vcb_angle
		txval = sangle
		tip = @vcb_angle + " = " + sangle
	else
		label = nil
		tip = ""
	end

	#Transfering text to VCB
	dlabel = hsh_param['label'] 
	label = dlabel if dlabel 
	if label
		Sketchup.set_status_text label, SB_VCB_LABEL
		Sketchup.set_status_text txval, SB_VCB_VALUE
	end	
	
	#Updating the palette information area
	splus = hsh_param['msg_comp']
	splus = (splus) ? "  --  " + splus : ""
	@palette.set_tooltip @title + splus + "\n" + tip	
end

#Set an error
def set_error(message=nil)
	message = @msg_error + ' ' + message if message
	@palette.set_message message, 'E'
	@view.invalidate
end

#Set an error
def set_message(message=nil, code='I')
	message = message if message
	@palette.set_message message, code
	@view.invalidate
end

#--------------------------------------------------------------
# Modify options
#--------------------------------------------------------------

def notify_back(option)
	@notify_proc.call(option) if @notify_proc	
	@itself.onSetCursor
	@refresh_proc.call if @refresh_proc	
end

def set_linemode(linemode)
	@linemode = linemode
	@itself.onSetCursor
end

def toggle_option_linemode
	@linemode = !@linemode
	notify_back 'linemode'	
end

def toggle_option_clickmode
	@clickmode = !@clickmode
	notify_back 'clickmode'	
end

def set_inference_on(inf_on)
	@inference_on = inf_on
	notify_back 'inference_on'	
end
	
def toggle_option_inference_lock
	@inference_lock = !@inference_lock
	notify_back 'inference_lock'	
end

def toggle_option_cpoint
	@option_cpoint = !@option_cpoint
	notify_back 'cpoint'	
end

def toggle_option_protractor
	@option_protractor = !@option_protractor
	@linepicker.set_protractor_on @option_protractor if @linepicker
	notify_back 'protractor'	
end

def toggle_option_protractor_sector
	@option_protractor_sector = !@option_protractor_sector
	notify_back 'protractor_sector'	
end
	
def toggle_option_gencurves
	@option_gencurves = !@option_gencurves
	notify_back 'gencurves'	
end

def toggle_option_genfaces
	@option_genfaces = !@option_genfaces
	notify_back 'genfaces'	
end

def toggle_option_group
	@option_group = !@option_group
	notify_back 'group'	
end

def toggle_option_alone
	@option_alone = !@option_alone
	notify_back 'alone'	
end

def toggle_option_simplify
	@option_simplify = !@option_simplify
	notify_back 'simplify'	
end

def toggle_option_diameter
	@option_diameter = !@option_diameter
	@param_axe1 = @option_diameter
	notify_back 'diameter'	
end

#Change the input mode for input of full or 1/2 axis
#Return true if full axis 2, or false if 1/2 axis2
def toggle_axes
	#Single polygon
	if @shape.single
		@param_axe1 = !@param_axe1
	
	#multiple polygon
	else
		if !@param_axe1 && !@param_axe2
			@param_axe1 = true
		elsif @param_axe1 && !@param_axe2	
			@param_axe2 = true
		elsif @param_axe1 && @param_axe2	
			@param_axe1 = false
		else	
			@param_axe1 = false
			@param_axe2 = false
		end
	end
	notify_back 'axes'	
end

def set_axes(param1, param2)
	@param_axe1 = param1
	@param_axe2 = param2
	notify_back 'axes'	
end

def toggle_option_trigo
	@option_trigo = !@option_trigo
	notify_back 'trigo'	
end

def toggle_option_contours
	case @option_contours 
	when 'O'
		@option_contours = 'A'
	when 'A'
		@option_contours = 'I'
	else
		@option_contours = 'O'
	end	
	notify_back 'contours'	
end

def set_option_contours
	@option_contours = @palette.button_get_value(:pal_contours)
	notify_back 'contours'	
end

#Get the current group common to all tools in the current model (create it if not existing)
def current_group
	#checking if the group exists and is correct
	ents = @model.active_entities
	grp = @hshgroup[ents.object_id]
	return grp if grp && grp.valid? && grp.name =~ /^TOS___Group/
	
	#creating the group
	grp = ents.add_group
	grp.name = "TOS___Group"
	@hshgroup[ents.object_id] = grp
	grp
end

#Ask for the pixel precisoon (freehand)
def ask_precision
	#Building and Calling the dialog box
	unless @dlgpx
		@dlgpx = Traductor::DialogBox.new @title
		@dlgpx.field_numeric "px", T6[:VCB_Pixel], 30, 5, 200
	end
		
	hparam = { 'px' => @px_precision }
	return unless @dlgpx.show! hparam
	
	#Changing the parameters
	@px_precision = hparam['px']
end

#set the precision for Freehand
def set_precision(px_precision)
	@px_precision = px_precision
end

#--------------------------------------------------------------
# Ring Management
#--------------------------------------------------------------

#Initialize the Ring side palette
def ring_init_palette
	@ring_bkcolor = 'gold'
	bkcolor2 = 'yellow'
	
	#Initialization of the ring environment
	@lst_rings = [] unless @lst_rings
	@nb_ring_max = 10
	@lst_ring_buttons_val = []
	@lst_ring_buttons_clear = []
	@lst_ring_buttons_sepa = []
	draw_local = self.method "draw_button_opengl"
	
	#Declaring the Top buttons
	symb_side = :ringside
	nq = 8
	ndep = nq - 4
	height = 16
	wid = 16
	totwid = wid * nq
	hshb = { :sidepal => symb_side, :bk_color => bkcolor2, :height => height }
	
	#Creating the top rank
	@palette.declare_button(:ring_top, hshb, { :text => @txt_pal_ring, :tooltip => @tip_ring_info, 
	                                           :width => ndep * wid, :rank => 0, :passive => true	})
	
	vproc = make_proc() { @lst_rings_old == nil }
  	@palette.declare_button(:ring_undo, hshb, { :grayed_proc => vproc, :tooltip => @tip_ring_undo, :width => wid, :rank => ndep,
                                                :draw_proc => :std_undo, :main_color => 'black' }) { ring_restore }
											   
	vproc = make_proc() { @lst_rings.length >= @nb_ring_max }
  	@palette.declare_button(:ring_add, hshb, { :grayed_proc => vproc, :tooltip => @tip_ring_add, :width => wid, :rank => ndep+1,
                                               :draw_proc => :cross_2, :main_color => 'blue' }) { ring_dialog }
											   
	vproc = make_proc() { @lst_rings.length == 0 }
 	@palette.declare_button(:ring_edit, hshb, { :grayed_proc => vproc, :draw_proc => draw_local, :tooltip => @tip_ring_edit, 
	                                            :width => wid, :rank => ndep+2 }) { ring_dialog -1 }
	
	vproc = make_proc() { @lst_rings.length == 0 }
 	@palette.declare_button(:ring_clear, hshb, { :grayed_proc => vproc, :tooltip => @tip_ring_clear_all, :width => wid, 
	                                             :rank => ndep+3,
                                                 :draw_proc => :cross_NE3, :main_color => 'red' }) { ring_clear }
												 
	@palette.declare_separator_side symb_side, { :bk_color => 'yellow', :width => totwid }
	
	#creating all other buttons
	h = 16
	hshb_val = { :bk_color => @ring_bkcolor, :height => h, :width => (nq-1) * wid, :hidden => false }
	hshb_clear = { :bk_color => @ring_bkcolor, :height => h, :width => wid, :rank => nq-1, 
	               :draw_proc => :cross_NE3, :frame_color => 'red', :hidden => false }
	hshb_sepa = { :bk_color => @ring_bkcolor, :width => totwid, :hidden => false }
	
	ll = []
	for j in 0..@nb_ring_max-1
		ll[j] = j
	end	
	ring_clear_proc = self.method "ring_clear"
	ring_edit_proc = self.method "ring_dialog"
	#[0, 1, 2, 3, 4, 5, 6, 7, 8, 9].each do |i|
	ll.each do |i|
		symb = "ring_val_#{i}".intern
		@lst_ring_buttons_val[i] = symb
		@palette.declare_button(symb, hshb, hshb_val) { ring_edit_proc.call i }
		
		symb = "ring_clear_#{i}".intern
		@lst_ring_buttons_clear[i] = symb
		@palette.declare_button(symb, hshb, hshb_clear) { ring_clear_proc.call i }
		
		@lst_ring_buttons_sepa[i] = @palette.declare_separator_side symb_side, { :bk_color => @ring_bkcolor, :width => totwid }
	end
	
	ring_refresh
end

#Modify the list of rings
def ring_refresh
	#Hidding all buttons
	for i in 0..@nb_ring_max-1
		@palette.button_set_args @lst_ring_buttons_val[i], { :hidden => true }
		@palette.button_set_args @lst_ring_buttons_clear[i], { :hidden => true }
		@palette.button_set_args @lst_ring_buttons_sepa[i], { :hidden => true }
	end
	
	#Populating the buttons
	n = @lst_rings.length - 1
	ipositiv = 0
	for i in 0..n
		if @lst_rings[i] > 0
			ipositiv = i-1
			break
		end
	end

	for i in 0..n
		delta = @lst_rings[i]
		sdelta = Sketchup.format_length delta
		@palette.button_set_args @lst_ring_buttons_val[i], { :hidden => false, :text => sdelta }
		@palette.button_set_args @lst_ring_buttons_clear[i], { :hidden => false }
		@palette.button_set_args @lst_ring_buttons_sepa[i], { :hidden => false, :bk_color => @ring_bkcolor }
		@palette.button_set_args @lst_ring_buttons_sepa[i], { :bk_color => 'orange' } if i == ipositiv
	end
	@palette.compute_all
end

#Verify the value of rings
def ring_verify(lst_rings)
	lst_rings = lst_rings.sort { |a, b| a <=> b }
	lst = []
	for i in 0..lst_rings.length-1
		next if close_to_float(lst_rings[i], 0)
		next if i > 0 && close_to_float(lst_rings[i], lst_rings[i-1])
		lst.push lst_rings[i]
	end
	lst
end

#Check equality and proximity of ring values
def close_to_float(a, b)
	((a - b) / a).abs < 0.001
end

#Set the Ring values
def ring_set_values(lst_rings)
	ring_save
	@lst_rings = ring_verify lst_rings
	ring_refresh
end

#Clear one or all rings
def ring_clear(i=nil)
	ring_save
	if i
		@lst_rings.delete_at i
	else
		@lst_rings = []
	end	
	ring_refresh
end

#Save the last rings
def ring_save
	@lst_rings_old = @lst_rings.clone
end

#Restore the last change
def ring_restore
	return unless @lst_rings_old
	lold = @lst_rings.clone
	@lst_rings = @lst_rings_old.clone
	@lst_rings_old = lold
	ring_refresh
end

#Manage the dialog box for input of Ring
def ring_dialog(ibut=nil)
	#Add rings
	if ibut == nil
		lst_new = []
		lst_others = @lst_rings.clone
		lst_edit = []
		lst_new2 = nil
	
	#edit all rings
	elsif ibut < 0	
		lst_new = nil
		lst_edit = @lst_rings.clone
		lst_others = []
		lst_new2 = []
		
	#Edit Ring i	
	else
		lst_new = nil
		lst_edit = [@lst_rings[ibut]]
		lst_others = @lst_rings.clone
		lst_others.delete_at ibut
		lst_new2 = nil
	end	
	
	#Creating the dialog box
	dlg = Traductor::DialogBox.new @title
	dlg.field_string "new", @msg_dlg_ring_new, "" if lst_new
	dlg.field_string "edit", @msg_dlg_ring_others, "" if lst_edit.length > 0
	dlg.field_string "other", @msg_dlg_ring_others, "" if lst_others.length > 0
	dlg.field_string "new2", @msg_dlg_ring_new, "" if lst_new2

	hparam = {}
	hparam['new'] = "" if lst_new
	hparam['edit'] = ring_pack lst_edit if lst_edit.length > 0
	hparam['other'] = ring_pack lst_others if lst_others.length > 0
	hparam['new2'] = "" if lst_new
	
	#Invoking the dialog box
	return unless dlg.show! hparam

	#Parsing the result and updating the lsit of rings
	lst_out = ring_unpack(hparam['new']) + ring_unpack(hparam['edit']) + ring_unpack(hparam['other']) +
	          ring_unpack(hparam['new2'])
	ring_set_values lst_out if lst_out
end

#Pack the list of rings value into a string for edition
def ring_pack(lst)
	lst = lst.collect { |a| Sketchup.format_length a }
	lst.join '  '
end

#Unpack the list of rings value from a string to a valid list
def ring_unpack(text)
	return [] unless text
	text = text.strip
	return [] if text.length == 0
	
	lst_rings = []
	ls = text.split ' '	
	ls.each do |s|
		v = Traductor.string_to_length_formula s
		lst_rings.push v if v
	end
	lst_rings[0..@nb_ring_max-1]
end
#--------------------------------------------------------------
# Custom drawing for palette buttons
#--------------------------------------------------------------

#Custom drawing of buttons
def draw_button_opengl(symb, dx, dy)
	code = symb.to_s
	lst_gl = []
	xmid = dx / 2

	case code
	
	#Line mode
	when /pal_linemode/i
		dec = 3
		dx1 = dy1 = dec
		dx2 = dx - dec
		dy2 = dy - dec
		pt1 = Geom::Point3d.new(dx1, dy1, 0)
		pt2 = Geom::Point3d.new(dx2, dy2, 0)
		lst_gl.push [GL_LINE_STRIP, [pt1, pt2], 'black', 2, '-']

	#Click mode for Freehand
	when /pal_clickmode/i
		pts = []
		pts.push Geom::Point3d.new(4, 2)
		pts.push Geom::Point3d.new(dx/3, dy-5)
		pts.push Geom::Point3d.new(2*dx/3, 5)
		pts.push Geom::Point3d.new(dx-2, dy-2)
		lst_gl.push [GL_LINE_STRIP, pts, 'blue', 2, '']
		
	#Construction Points
	when /pal_cpoint/i
		stipple = (@linemode) ? '' : '-'
		dec = 5
		dx1 = dy1 = dec
		dx2 = dx - dx1
		dy2 = dy - dy1
		pt1 = Geom::Point3d.new(dx1, dy1, 0)
		pt2 = Geom::Point3d.new(dx2, dy2, 0)
		lst_gl.push [GL_LINE_STRIP, [pt1, pt2], 'darkgray', 2, stipple]
		dec -= 1
		pts = []
		pts.push Geom::Point3d.new(dx1, dy1 - dec, 0)
		pts.push Geom::Point3d.new(dx1, dy1 + dec, 0)
		pts.push Geom::Point3d.new(dx1 - dec, dy1, 0)
		pts.push Geom::Point3d.new(dx1 + dec, dy1, 0)
		pts.push Geom::Point3d.new(dx2, dy2 - dec, 0)
		pts.push Geom::Point3d.new(dx2, dy2 + dec, 0)
		pts.push Geom::Point3d.new(dx2 - dec, dy2, 0)
		pts.push Geom::Point3d.new(dx2 + dec, dy2, 0)
		lst_gl.push [GL_LINES, pts, 'black', 2, '']

	#Trigo sense
	when /pal_trigo/i
		color = 'darkgray'
		color2 = 'red'
		xmid = dx/2
		ymid = dy/2
		radius = 12
		xmin = xmid - radius
		xmax = xmid + radius
		pts = pts_circle xmid, ymid, radius
		lst_gl.push [GL_LINE_STRIP, pts, color, 1, '']
		pts1 = []
		pts1.push Geom::Point3d.new(xmid + radius, ymid)
		pts1.push Geom::Point3d.new(xmid, ymid)
		pts1.push pts[1]
		lst_gl.push [GL_LINE_STRIP, pts1, 'black', 2, '']
		lst_gl.push [GL_LINE_STRIP, pts[3..7], 'red', 2, '']
		pt = pts[6]
		pts1 = []
		pts1.push Geom::Point3d.new(pt.x, pt.y + 4)
		pts1.push Geom::Point3d.new(pt.x - 4, pt.y)
		pts1.push Geom::Point3d.new(pt.x, pt.y - 4)
		lst_gl.push [GL_POLYGON, pts1, 'red']
		

	#Diameter
	when /pal_diameter/i
		color = 'darkgray'
		color2 = 'red'
		xmid = dx/2
		ymid = dy/2
		radius = 12
		xmin = xmid - radius
		xmax = xmid + radius
		pts = pts_circle xmid, ymid, radius
		lst_gl.push [GL_LINE_STRIP, pts, color, 1, '']
		
		pts = []
		pts.push Geom::Point3d.new(xmin, ymid)
		pts.push Geom::Point3d.new(xmax, ymid)
		lst_gl.push [GL_LINE_STRIP, pts, color2, 2, '']
		
		dec = 5
		pts = []
		pts.push Geom::Point3d.new(xmin+dec, ymid+dec)
		pts.push Geom::Point3d.new(xmin, ymid)
		pts.push Geom::Point3d.new(xmin+dec, ymid-dec-1)
		lst_gl.push [GL_POLYGON, pts, color2, 2, '']
		
		pts = []
		pts.push Geom::Point3d.new(xmax-dec, ymid+dec)
		pts.push Geom::Point3d.new(xmax, ymid)
		pts.push Geom::Point3d.new(xmax-dec, ymid-dec-1)
		lst_gl.push [GL_POLYGON, pts, color2, 2, '']
		
		
	#Generate faces
	when /pal_genfaces/i
		color = 'black'
		dec = 5
		pts = []
		pts.push Geom::Point3d.new(dec, dec, 0)
		pts.push Geom::Point3d.new(dx-1, dy/2, 0)
		pts.push Geom::Point3d.new(dx/2, dy-2, 0)
		lst_gl.push [GL_LINE_STRIP, pts + [pts[0]], color, 2, '']
		lst_gl.push [GL_POLYGON, pts, 'lightblue']
	
	#Generate curves
	when /pal_gencurves/i
		color = 'blue'
		dec = 4
		dx14 = dx / 4
		dx34 = 3 * dx14
		dy14 = dy / 4
		dy34 = 3 * dy14
		pts = []
		pts.push Geom::Point3d.new(dec, dy34, 0)
		pts.push Geom::Point3d.new(dx/2, dec, 0)
		pts.push Geom::Point3d.new(dx/2, dy-dec, 0)
		pts.push Geom::Point3d.new(dx-dec, dec, 0)
		lst_gl.push [GL_LINES, pts, 'black', 1, '-']
		
		pts = []
		pt1 = Geom::Point3d.new(dec, dec, 0)
		pt2 = Geom::Point3d.new(dx-dec, dy-dec, 0)
		lst_gl.push [GL_LINE_STRIP, [pt1, pt2], 'blue', 3, '']

	#Simplify contour
	when /pal_simplify/i
		color = 'blue'
		dec = 8
		xmid = dx / 2
		ymid = dy / 2
		ptmid = Geom::Point3d.new(xmid, ymid)
		
		t = Geom::Transformation.rotation ptmid, Z_AXIS, Math::PI / 6
		
		pts = []
		pts.push Geom::Point3d.new(xmid-dec, ymid-dec)
		pts.push ptmid
		pts.push Geom::Point3d.new(xmid-dec, ymid+dec)
		pts = pts.collect { |pt| t * pt }
		lst_gl.push [GL_LINE_STRIP, pts, 'blue', 2, '']
		
		pts = []
		pts.push Geom::Point3d.new(xmid+dec, ymid-dec)
		pts.push ptmid
		pts.push Geom::Point3d.new(xmid+dec, ymid+dec)
		pts = pts.collect { |pt| t * pt }
		lst_gl.push [GL_LINE_STRIP, pts + [pts[0]], 'darkgray', 1, '']

	#Contour selection for Offset
	when /pal_contours_(A|I|O)/i
		colorH = 'yellow'
		colorB = 'lightgrey'
		fcolor = 'blue'
		code = $1
		case $1
			when 'A'
				icolor = colorB
				ocolor = colorH
			when 'I'	
				icolor = colorH
				ocolor = colorB
			when 'O'	
				icolor = colorH
				ocolor = colorH
		end
		
		decx = 2
		decy = 0
		pts1 = []
		pts1.push Geom::Point3d.new(decx, decy)
		pts1.push Geom::Point3d.new(dx-decx, decy)
		pts1.push Geom::Point3d.new(dx-decx, dy-decy)
		pts1.push Geom::Point3d.new(decx, dy-decy)
		lst_gl.push [GL_POLYGON, pts1, ocolor]
		lst_gl.push [GL_LINE_STRIP, pts1 + [pts1[0]], fcolor, 1, ''] 

		decx = 6
		decy = 2
		pts1 = []
		pts1.push Geom::Point3d.new(decx, decy+1)
		pts1.push Geom::Point3d.new(dx-decx, decy+1)
		pts1.push Geom::Point3d.new(dx-decx, dy-decy-1)
		pts1.push Geom::Point3d.new(decx, dy-decy-1)
		if code != 'O'
			lst_gl.push [GL_POLYGON, pts1, icolor]
			lst_gl.push [GL_LINE_STRIP, pts1 + [pts1[0]], fcolor, 1, ''] if code != 'O'
		end
		
	#Alone contour
	when /pal_alone/i
		color = 'blue'
		dec = 6
		len = 10
		off = 6
		
		pts1 = []
		pts1.push Geom::Point3d.new(dec, off)
		pts1.push Geom::Point3d.new(dec, off+len)
		pts1.push Geom::Point3d.new(dec+len, off+len)
		pts1.push Geom::Point3d.new(dec+len, off)
		lst_gl.push [GL_LINE_STRIP, pts1 + [pts1[0]], 'blue', 1, '']

		bias = 7
		pts2 = []
		pts2.push pts1[2]
		pts2.push Geom::Point3d.new(dec+len+bias, off+len+bias)
		pts2.push Geom::Point3d.new(dec+len+bias, off+bias)
		pts2.push pts1[3]
		lst_gl.push [GL_LINE_STRIP, pts2, 'blue', 1, '']

		pts3 = []
		pts3.push pts1[1]
		pts3.push Geom::Point3d.new(dec+bias, off+len+bias-1)
		pts3.push pts2[1]
		lst_gl.push [GL_LINE_STRIP, pts3, 'blue', 1, '']

		pts4 = []
		pts4.push Geom::Point3d.new(0, off+len-2)
		pts4.push Geom::Point3d.new(dx-9, off+len-2)
		pts4.push Geom::Point3d.new(dx, dy-3)
		pts4.push Geom::Point3d.new(9, dy-3)
		lst_gl.push [GL_LINE_STRIP, pts4 + [pts4[0]], 'red', 2, '']
		
	#Generate curves
	when /pal_inference_lock/i
		if @inference_on
			color1 = "blue"
			colorcad = 'gray'
		else	
			color1 = 'green'
			colorcad = 'darkred'
		end	
		stipple = ''
		color2 = 'red'
		
		h = 6
		dec = 6
		pts = []
		pts.push Geom::Point3d.new(dec, dec, 0)
		pts.push Geom::Point3d.new(dec+h, dec, 0)
		pts.push Geom::Point3d.new(dec+h, dec+h, 0)
		pts.push Geom::Point3d.new(dec, dec+h, 0)
		lst_gl.push [GL_POLYGON, pts, color1]
		
		dec = 20
		pts = []
		pts.push Geom::Point3d.new(dec, dec, 0)
		pts.push Geom::Point3d.new(dec+h, dec, 0)
		pts.push Geom::Point3d.new(dec+h, dec+h, 0)
		pts.push Geom::Point3d.new(dec, dec+h, 0)
		lst_gl.push [GL_POLYGON, pts, color2]

		xdep = 16
		dec = 10
		pts = []
		pts.push Geom::Point3d.new(xdep, 1, 0)
		pts.push Geom::Point3d.new(dx-1, 1, 0)
		pts.push Geom::Point3d.new(dx-1, dec, 0)
		pts.push Geom::Point3d.new(xdep, dec, 0)
		lst_gl.push [GL_POLYGON, pts, 'yellow']
		lst_gl.push [GL_LINE_STRIP, pts + [pts[0]], colorcad, 2, stipple]
		h = 4
		pts1 = []
		pts1.push pts[3]
		pts1.push Geom::Point3d.new(xdep, dec + h, 0)
		pts1.push Geom::Point3d.new(xdep + h, dec + h + 2, 0)
		pts1.push Geom::Point3d.new(dx - 1 - h, dec + h + 2, 0)
		pts1.push Geom::Point3d.new(dx - 1, dec + h, 0)
		pts1.push pts[2]
		lst_gl.push [GL_LINE_STRIP, pts1, colorcad, 2, stipple]

		pts1 = []
		pts1.push Geom::Point3d.new(xdep + dec/2, 4, 0)
		pts1.push Geom::Point3d.new(xdep + dec/2, 8, 0)
		lst_gl.push [GL_LINE_STRIP, pts1, colorcad, 2, stipple]
	
	when /ring_edit/i	
		color = (@lst_rings.length > 0) ? 'blue' : 'lightgrey'
		dec = 2
		xmid = dx / 2
		ymid = dy / 2
		
		pts = []
		pts.push Geom::Point3d.new(dec, ymid-dec)
		pts.push Geom::Point3d.new(dx-dec, ymid-dec)
		pts.push Geom::Point3d.new(dec, ymid+dec)
		pts.push Geom::Point3d.new(dx-dec, ymid+dec)
		pts.push Geom::Point3d.new(xmid-dec, ymid-3*dec)
		pts.push Geom::Point3d.new(xmid+dec, ymid+3*dec)
		lst_gl.push [GL_LINES, pts, color, 2, '']
		
	end
	
	lst_gl
end

#Compute the points of a square centered at x, y with side 2 * dim
def pts_square(x, y, dim)
	pts = []
	pts.push Geom::Point3d.new(x-dim, y-dim)
	pts.push Geom::Point3d.new(x+dim, y-dim)
	pts.push Geom::Point3d.new(x+dim, y+dim)
	pts.push Geom::Point3d.new(x-dim, y+dim)
	pts
end

#Compute the points of a circle centered at x, y with radius
def pts_circle(x, y, radius, n=12)
	pts = []
	angle = Math::PI * 2 / n
	for i in 0..n
		a = angle * i
		pts.push Geom::Point3d.new(x + radius * Math.sin(a), y + radius * Math.cos(a))
	end	
	pts
end

#Custom drawing of buttons for tools
def draw_button_blason(symb, dx, dy)
	#code = @tool_type
	code = symb.to_s
	lst_gl = []
	xmid = dx / 2
	
	case code

	#Polyline Edition
	when /polyline/i
		dec = 5
		dx1 = dy1 = dec
		dx2 = dx - dec
		dy2 = dy - dec
		xmid = dx / 4
		ymid = dy / 2	
		pts = []
		pts.push Geom::Point3d.new(dec, dec)
		pts.push Geom::Point3d.new(xmid, dy-dec)
		pts.push Geom::Point3d.new(dx-dec, dy-dec)
		pts.push Geom::Point3d.new(dx-dec, ymid)
		lst_gl.push [GL_LINE_STRIP, pts + [pts[0]], 'brown', 2, '']

		len = 3
		pts1 = pts_square(pts[0].x, pts[0].y, 3)
		lst_gl.push [GL_QUADS, pts1, 'red']
		for i in 1..3 
			pts1 = pts_square(pts[i].x, pts[i].y, 2)
			lst_gl.push [GL_QUADS, pts1, 'green']
		end
	
	#Line mode
	when /line/i
		dec = 5
		dx1 = dy1 = dec
		dx2 = dx - dec
		dy2 = dy - dec
		pt1 = Geom::Point3d.new(dx1, dy1+2, 0)
		pt2 = Geom::Point3d.new(dx2 - 10, dy2, 0)
		lst_gl.push [GL_LINE_STRIP, [pt1, pt2], 'brown', 2, '']
		pt1 = Geom::Point3d.new(dx1 +10, dy1+2, 0)
		pt2 = Geom::Point3d.new(dx2, dy2, 0)
		lst_gl.push [GL_LINE_STRIP, [pt1, pt2], 'black', 2, '-']

	#Offset mode
	when /offset/i
		xmid = dx / 2
		ymid = dy / 2
		pts = pts_square xmid, ymid+1, xmid - 4
		lst_gl.push [GL_LINE_STRIP, pts + [pts[0]], 'blue', 2, '']
		pts = pts_square xmid, ymid+1, xmid - 9
		lst_gl.push [GL_LINE_STRIP, pts + [pts[0]], 'brown', 2, '']

	#Eraser mode
	when /Eraser/i
		dec = 5
		dx1 = dy1 = dec
		dx2 = dx - dec
		dy2 = dy - dec
		xmid = dx / 2
		ymid = dy / 2
		pts = []
		pts.push Geom::Point3d.new(dx1, dy1, 0)
		pts.push Geom::Point3d.new(xmid, dy1, 0)
		pts.push Geom::Point3d.new(xmid, ymid, 0)
		pts.push Geom::Point3d.new(dx1, ymid, 0)
		lst_gl.push [GL_POLYGON, pts, 'hotpink', 2, '']
		lst_gl.push [GL_LINE_STRIP, pts + [pts[0]], 'lightpink', 1, '']
		
		pts1 = [pts[2], pts[3]]
		pts1.push Geom::Point3d.new(xmid+3, dy-4, 0)
		pts1.push Geom::Point3d.new(dx-2, dy-4, 0)
		lst_gl.push [GL_POLYGON, pts1, 'pink', 2, '']
		lst_gl.push [GL_LINE_STRIP, pts1 + [pts1[0]], 'hotpink', 1, '']

		pts2 = [pts[1], pts[2], pts1[3]]
		pts2.push Geom::Point3d.new(dx-2, ymid+2, 0)
		lst_gl.push [GL_POLYGON, pts2, 'pink', 2, '']
		lst_gl.push [GL_LINE_STRIP, pts2 + [pts2[0]], 'hotpink', 1, '']

	#Freehand mode
	when /freehand/i
		pts = []
		pts.push Geom::Point3d.new(4, 20)
		pts.push Geom::Point3d.new(7, 16)
		pts.push Geom::Point3d.new(13, 14)
		pts.push Geom::Point3d.new(18, 15)
		pts.push Geom::Point3d.new(19, 18)
		pts.push Geom::Point3d.new(18, 22)
		pts.push Geom::Point3d.new(13, 23)
		pts.push Geom::Point3d.new(10, 22)
		pts.push Geom::Point3d.new(7, 17)
		pts.push Geom::Point3d.new(6, 13)
		pts.push Geom::Point3d.new(7, 11)
		pts.push Geom::Point3d.new(8, 9)
		pts.push Geom::Point3d.new(11, 8)
		pts.push Geom::Point3d.new(14, 8)
		pts.push Geom::Point3d.new(17, 9)
		lst_gl.push [GL_LINE_STRIP, pts, 'brown', 2, '']

	#Rectangle mode
	when /rectangle/i
		xmid = dx / 2
		ymid = dy / 2
		pts = pts_square xmid, ymid, xmid - 3
		pts.each { |pt| pt.y = ymid + (pt.y - ymid) * 0.75 }
		lst_gl.push [GL_LINE_STRIP, pts + [pts[0]], 'brown', 2, '']

	#Parallelogram mode
	when /parallelogram/i
		dec = 9
		pts = []
		pts.push Geom::Point3d.new(2, 4)
		pts.push Geom::Point3d.new(dx - dec, 4)
		pts.push Geom::Point3d.new(dx-2, dy-3)
		pts.push Geom::Point3d.new(dec, dy-3)
		lst_gl.push [GL_LINE_STRIP, pts + [pts[0]], 'brown', 2, '']

	#Polygon mode
	when /polygon/i
		dec = 3
		pts = []
		pts.push Geom::Point3d.new(8, dy-5)
		pts.push Geom::Point3d.new(dx/2, 4)
		pts.push Geom::Point3d.new(dx-2, dy/2+2)
		lst_gl.push [GL_LINE_STRIP, pts + [pts[0]], 'brown', 2, '']

	#Circle3P mode
	when /circle3P/i
		radius = dx / 3
		pts = pts_circle dx/2, dy/2, radius
		lst_gl.push [GL_LINE_STRIP, pts, 'brown', 2, '']
		pts = []
		pts.push Geom::Point3d.new(dx/2 - radius * Math.sqrt(2)/2, dy/2 - radius * Math.sqrt(2)/2)
		pts.push Geom::Point3d.new(dx/2, dy/2 + radius - 1)
		pts.push Geom::Point3d.new(dx/2 + radius, dy/2)
		lst_gl.push [GL_LINE_STRIP, pts, 'brown', 2, '']

	#Circle mode
	when /circle/i
		radius = dx / 3
		pts = pts_circle dx/2, dy/2, radius
		lst_gl.push [GL_LINE_STRIP, pts, 'brown', 2, '']
		
	#Ellipse mode
	when /ellipse/i
		radius = dx / 3 + 2
		ymid = dy / 2
		pts = pts_circle dx/2, ymid, radius, 18
		pts.each { |pt| pt.y = ymid + (pt.y - ymid) * 0.75 }
		lst_gl.push [GL_LINE_STRIP, pts, 'brown', 2, '']

	#Arc mode
	when /arc/i
		radius = dx / 3 + 2
		ymid = dy / 2
		pts = pts_circle dx/2, ymid, radius, 18
		pts = pts[15..-1] + pts[0..7]
		lst_gl.push [GL_LINE_STRIP, pts, 'brown', 2, '']

	#Sector mode
	when /sector/i
		radius = dx / 3 + 2
		ymid = dy / 2
		ptmid = Geom::Point3d.new(dx/2, ymid)
		pts = pts_circle dx/2, ymid, radius, 18
		pts = pts[0..0] + [ptmid] + pts[3..-1]
		lst_gl.push [GL_LINE_STRIP, pts, 'brown', 2, '']
		
	end
	
	lst_gl
end

#Custom drawing of buttons
def draw_button_axes_opengl(symb, dx, dy)
	code = symb.to_s
	code =~ /pal_(\d)(\d)/
	param1 = ($1 == '1')
	param2 = ($2 == '1')
	lst_gl = []
	xmid = dx / 2
	ymid = dy / 2 + 3
	frcolor = 'gray'
	bkcolor = 'lightcyan'
	
	pt0 = Geom::Point3d.new 0, 0, 0
	pt1 = Geom::Point3d.new 0, 0, 0
	pt2 = Geom::Point3d.new 0, 0, 0

	case @shape.type
	when 'R'
		pts = pts_square xmid, ymid, xmid - 2
		pts.each { |pt| pt.y = ymid + (pt.y - ymid) * 0.75 }
		lst_gl.push [GL_POLYGON, pts, bkcolor]
		lst_gl.push [GL_LINE_LOOP, pts, frcolor, 1, '']
		pt0.x = (param1) ? pts[0].x : xmid
		pt0.y = (param2) ? pts[0].y + 1 : ymid
		pt1.x = pts[1].x - 1
		pt2.y = pts[2].y
		pt2.x = (param1) ? pt1.x : pt0.x
		pt1.y = pt0.y
		ptm = (param1) ? pt1 : pt0
		lst_gl.push [GL_LINE_STRIP, [pt0, pt1], 'blue', 2, '']
		lst_gl.push [GL_LINE_STRIP, [ptm, pt2], 'red', 2, '']
		lst_gl.push [GL_POLYGON, pts_square(pt0.x, pt0.y, 2), 'green']

	when 'E'
		radius = dx / 3 + 4
		ptse = pts_circle dx/2, ymid, radius, 18
		ptse.each { |pt| pt.y = ymid + (pt.y - ymid) * 0.75 }
		lst_gl.push [GL_POLYGON, ptse, bkcolor, 1, '']
		lst_gl.push [GL_LINE_STRIP, ptse, frcolor, 1, '']
		pts = pts_square xmid, ymid, radius
		pts.each { |pt| pt.y = ymid + (pt.y - ymid) * 0.75 }
		pt0.x = (param1) ? pts[0].x : xmid
		pt0.y = (param2) ? pts[0].y + 1 : ymid
		pt1.x = pts[1].x - 1
		pt2.y = pts[2].y
		pt2.x = (param1) ? pt1.x : pt0.x
		pt1.y = pt0.y
		ptm = (param1) ? pt1 : pt0
		lst_gl.push [GL_LINE_STRIP, [pt0, pt1], 'blue', 2, '']
		lst_gl.push [GL_LINE_STRIP, [ptm, pt2], 'red', 2, '']
		lst_gl.push [GL_POLYGON, pts_square(pt0.x, pt0.y, 2), 'green']

	when 'P/'
		dec = 9
		pts = []
		pts.push Geom::Point3d.new(2, 4)
		pts.push Geom::Point3d.new(dx - dec, 4)
		pts.push Geom::Point3d.new(dx-2, dy-3)
		pts.push Geom::Point3d.new(dec, dy-3)
		
		pt1 = (param2) ? pts[1] : Geom.linear_combination(0.5, pts[1], 0.5, pts[2])
		pt2 = (param1) ? pts[2] : Geom.linear_combination(0.5, pts[2], 0.5, pts[3])
		if param1 && param2
			pt0 = pts[0]
		elsif !param1 && !param2
			pt0 = Geom.linear_combination(0.5, pts[0], 0.5, pts[2])
		elsif param1 && !param2	
			pt0 = Geom.linear_combination(0.5, pts[0], 0.5, pts[3])
		else
			pt0 = Geom.linear_combination(0.5, pts[0], 0.5, pts[1])
		end
		lst_gl.push [GL_POLYGON, pts, bkcolor]
		lst_gl.push [GL_LINE_LOOP, pts, frcolor, 1, '']
		lst_gl.push [GL_LINE_STRIP, [pt0, pt1], 'blue', 2, '']
		ptm = (param1) ? pt1 : pt0
		lst_gl.push [GL_LINE_STRIP, [ptm, pt2], 'red', 2, '']
		lst_gl.push [GL_POLYGON, pts_square(pt0.x, pt0.y, 2), 'green']
		
	end

	#Adding the function key indicator
	next_toggle = false
	if @param_axe1 && @param_axe2
		next_toggle = true if !param1 && param2
	elsif !@param_axe1 && @param_axe2
		next_toggle = true if !param1 && !param2
	elsif !@param_axe1 && !@param_axe2
		next_toggle = true if param1 && !param2
	elsif @param_axe1 && !@param_axe2
		next_toggle = true if param1 && param2
	end	
	lst_gl += Traductor::OpenGL_6.new.digit_instructions '5', dx, 0 if next_toggle
	
	lst_gl
end
		
end	#End Class PaletteManager

end	#End Module SUToolsOnSurface
