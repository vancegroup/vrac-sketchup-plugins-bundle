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
#					31 Jul 2009 - version 1.5
# Type			:   Sketchup Tool
# Description	:   Offset a contour on a surface (inside and outside)
-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module SUToolsOnSurface

#Constants for OffsetOnSurface Module (do not translate)	
TOS_ICON_OFFSET = "Offset"
TOS_CURSOR_OFS_OK = "Offset_OK_Line"
TOS_CURSOR_OFS_FORBIDDEN = "Offset_NO_Line"
TOS_CURSOR_OFS_DRAG = "Offset_Drag_Line"
TOS_CURSOR_OFS_OK_C = "Offset_OK_Cline"
TOS_CURSOR_OFS_FORBIDDEN_C = "Offset_NO_Cline"
TOS_CURSOR_OFS_DRAG_C = "Offset_Drag_Cline"

#Strings (do not translate here)
T6[:TIT_Offset] = "OFFSET"
T6[:MSG_Offset_Origin] = "Select Surface to offset"
T6[:MSG_Offset_End] = "Drag selected edge of the face or type distance"
			  
#--------------------------------------------------------------------------------------------------------------
# Top Calling functions: create the class and laucnh the tool
#--------------------------------------------------------------------------------------------------------------			 				   

def SUToolsOnSurface.launch_offset(linemode)
	MYPLUGIN.check_older_scripts
	Sketchup.active_model.select_tool TOSToolOffset.new(linemode)
end

#Invoke the Offset On Surface operation from an external script.
def SUToolsOnSurface.Api_Offset(linemode, selection, distance, group=false, alone=false, genfaces=true, 
                                gencurve=true, simplify=true, cpoint=false)

	#Checking the selection
	selection = Sketchup.active_model.selection if selection == nil || selection.length == 0
	
	#testing the selection
	return OFS_ERROR_DISTANCE_ZERO if distance == 0
	ofs = OffsetAlgo.new linemode
	status = ofs.check_initial_selection(false)
	return status if status != 0

	#Generating the offset contour
	OffsetAlgo.api_call(selection, distance, group, alone, genfaces, gencurve, simplify, cpoint)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TOSToolOffset: Sketchup tool placeholder class for UI
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					
class TOSToolOffset < Traductor::PaletteSuperTool

def initialize(linemode)
	@model = Sketchup.active_model
	@view = @model.active_view
		
	#Loading cursors
	hotx = 10
	hoty = 10

	@idcursor_mainL = MYPLUGIN.create_cursor TOS_CURSOR_OFS_OK, hotx, hoty
	@idcursor_forbiddenL = MYPLUGIN.create_cursor TOS_CURSOR_OFS_FORBIDDEN, hotx, hoty
	@idcursor_dragL = MYPLUGIN.create_cursor TOS_CURSOR_OFS_DRAG, hotx, hoty
	@idcursor_mainC = MYPLUGIN.create_cursor TOS_CURSOR_OFS_OK_C, hotx, hoty
	@idcursor_forbiddenC = MYPLUGIN.create_cursor TOS_CURSOR_OFS_FORBIDDEN_C, hotx, hoty
	@idcursor_dragC = MYPLUGIN.create_cursor TOS_CURSOR_OFS_DRAG_C, hotx, hoty
	@id_cursor_arrow_exit = MYPLUGIN.create_cursor "Arrow_Exit", 0, 0	

	#Colors
	@color_normal = MYDEFPARAM[:TOS_COLOR_Normal]
	@color_group = MYDEFPARAM[:TOS_COLOR_Group]
	@color_alone = MYDEFPARAM[:TOS_COLOR_Alone]
	@color_pseudo_selection = @model.rendering_options['HighlightColor']
	
	#Loading strings
	@title = T6[:TIT_Offset]
	@msg_offset_origin = T6[:MSG_Offset_Origin]
	@msg_offset_end = T6[:MSG_Offset_End]
	@tip_exit = T6[:TIP_Exit]
	
	#initializing variables
	@ip_origin = Sketchup::InputPoint.new
	@ip_end = Sketchup::InputPoint.new
	@distance_prev = 0

	#Creating the palette manager
	@lst_options = [ "linemode", "contours", "simplify", "alone", "cpoint", "group", "genfaces", "gencurves"]
	notify_proc = self.method "notify_change_option" 
	hsh = { 'title' => @title, 'list_options' => @lst_options, 'linemode' => linemode,
            :notify_proc => notify_proc	}
	@palman = PaletteManager.new(self, 'Offset', hsh) { refresh_view }
			
	#Drawing parameters
	parameter_linemode
end

#Porcedure to refresh the view ehn options are changed
def refresh_view
	@view.invalidate
	info_show
end

#Tool Activation
def activate
	@palman.initiate
	@selection = @model.selection
	@entities = @model.active_entities
	@bb = @model.bounds
	@noselection = nil
	@ofs = OffsetAlgo.new @palman.linemode
	
	#setting the options
	@lst_options.each { |option| notify_change_option option }
		
	#state initialization	
	@pt_origin = nil
	@pt_end = nil
	@state = STATE_ORIGIN
	@pt_target = nil

	#checking the initial selection
	case @ofs.check_initial_selection(true) 
	when OFS_ERROR_INVALID_SELECTION, OFS_ERROR_COMPLEX_SELECTION
		@selection.clear
		@noselection = true
	when OFS_ERROR_NO_SELECTION
		@noselection = true
	else
		@noselection = false
		clean_selection
	end	
		
	info_show
	Sketchup.active_model.active_view.invalidate
		
end

#Deactivate the tool and persist all parameters
def deactivate(view)
	@palman.terminate
	view.invalidate
end

#Return bounding box	
def getExtents
	@bb
end

#Build the contextual menu for the tool
def getMenu(menu)
	@palman.init_menu
	if (@state >= STATE_END)
		@palman.menu_add_done { done_and_exit }
		menu.add_separator
	end	
	@palman.menu_add_redo(@distance_prev.to_l) { call_execute 0 } if @distance_prev != 0
	
	@palman.option_menu menu
	true
end

#Change the cursor according to the state
def onSetCursor
	ic = super
	return (ic != 0) if ic
	if @outside
		UI::set_cursor @id_cursor_arrow_exit
	elsif (@selection.length > 0)
		id = @idcursor_main
		id = @idcursor_drag if (@pt_end && @idcursor_drag != 0)
		UI::set_cursor id if (id != 0)	
	else
		UI::set_cursor @idcursor_forbidden if (@idcursor_forbidden != 0)
	end
end

#Finishes the current segment and exit
def done_and_exit
	execute_offset
	@model.select_tool nil 
end

#Execute the offset
def execute_offset
	return UI.beep if @state < STATE_END
	call_execute
end

#Return key pressed
def onReturn(view)
	execute_offset
end

#Invoke the execution for the offeting
def call_execute(d=nil)
	d = compute_distance unless d
	if (d == 0)
		d = @distance_prev
	else	
		@distance_prev = d
	end	
	return UI.beep if (d == 0)
	@ofs.execute d, @palman.make_title_operation(@title)
	start_over
end

#Start over when finished offset
def start_over
	@selection.clear
	activate
end

#Execute the offset with the same distance
def onLButtonDoubleClick(flags, x, y, view)
	if @state == STATE_END
		call_execute 0
	else
		UI.beep
	end
end

#Key Down
def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false

	#Check function keys
	if @palman.check_function_key(key, rpt, flags, view)
		@control_down = false
		return
	end
	
	#Managing the CTRL down
	case key
	when COPY_MODIFIER_KEY
		@control_down = true
		@time_ctrl_down = Time.now
		return
					
	end	
	@control_down = false
	
	onMouseMove(flags, @xend, @yend, view) if (@state >= STATE_END)
	view.invalidate
	info_show
end

#Key up
def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true
	
	case key
		#Toggling between fixed and variable length
		when COPY_MODIFIER_KEY
			if @control_down
				@control_down = false
				return if (Time.now - @time_ctrl_down) > 0.5
				@palman.toggle_option_linemode
				onMouseMove(flags, @xend, @yend, view) if (@state >= STATE_END)
			end	
	end	
	
	@control_down = false
end

#Control the states of the tool
def set_state(state)
	@state = state
	if state == STATE_EXECUTION 
		return call_execute
	end	
	@pt_end = nil if @state == STATE_END
	
	info_show
end

#Return key pressed
def onReturn(view)
	if @state == STATE_ORIGIN
		exit_tool
	else
		set_state @state + 1
	end
end

def exit_tool
	@model.select_tool nil 
end

#click down
def onLButtonDown(flags, x, y, view)
	return if super
	return exit_tool if @outside
	return UI.beep unless @pt_target
	@time_mouse_down = Time.now
	set_state @state + 1
	@ofs.set_red_point(@pt_target, @facetarget, @etarget) if @state == STATE_END
end

#Mouse button release
def onLButtonUp(flags, x, y, view)
	return if super
	return unless @pt_target
	if (@state == STATE_ORIGIN)
		return unless @ip_origin.valid?
	elsif (@state == STATE_END)	
		return unless @ip_end.valid? && @pt_end && (@pt_origin != @pt_end)
		delta = Time.now - @time_mouse_down
		dist = (@xend - @xorig) * (@xend - @xorig) + (@yend - @yorig) * (@yend - @yorig)
	    return if (delta < 0.5) && (dist < 100)  
	end
	set_state @state + 1
end

#Handle Escape key and Change of tool
def onCancel(flag, view)
	#User pressed Escape
	if (flag == 0)
		@selection.clear ####if @noselection
		activate
		return
	end
	return  if (flag != 0) || (@state == STATE_ORIGIN)  #Exiting the tool
	set_state @state - 1
end

#Clean up the selection
def clean_selection()
	@selection.clear
	@ofs.hsh_faces.each { |key, f| @selection.add f }
	@selection.add @ofs.lst_edges
end

#Compute the target point
def target_point(view, pt)
	@etarget = nil
	@facetarget = nil
	dtarget = 0.cm
	vptarget = nil
	first = true
	vpt = view.screen_coords pt
	
	@ofs.lst_edges.each do |e|
		vpt1 = view.screen_coords e.start.position
		vpt2 = view.screen_coords e.end.position
		vptproj = vpt.project_to_line [vpt1, vpt2]
		inside = (vptproj == vpt1) || (vptproj == vpt2) || (vpt1.vector_to(vptproj) % vpt2.vector_to(vptproj) < 0)
		vpicked = (inside) ? vptproj : ((vpt.distance(vpt1) < vpt.distance(vpt2)) ? vpt1 : vpt2)
		d = vpt.distance vpicked
		if (first) || (d < dtarget)
			dtarget = d  
			@etarget = e
			@etarget.faces.each do |f|
				if @ofs.hsh_faces[f.to_s]
					@facetarget = f
					break
				end
			end	
			vptarget = vpicked.clone
			first = false
		end
	end
	return nil unless vptarget
	lp = Geom.closest_points view.pickray(vptarget.x, vptarget.y), @etarget.line 
	lp[1]
end

#Cursor move
def onMouseMove(flags, x, y, view)
	#Synchronize draw and move
	return if @moving
	@moving = true

	#Event for the palette
	if super
		@not_in_viewport = true
		return
	end	
	@not_in_viewport = false
	@flags = flags
	@outside = false

	case @state	
	when STATE_ORIGIN		#input Origin of Vector
		@ip_origin.pick view, x, y
		return unless @ip_origin.valid?
		if in_empty_space?(@ip_origin)
			@outside = true
			view.tooltip = @tip_exit
			view.invalidate
			info_show
			return
		end	
		@xorig = x
		@yorig = y
		view.tooltip = @ip_origin.tooltip
		@pt_origin = @ip_origin.position if @ip_origin.valid?
		if @noselection
			face = @ip_origin.face
			if face && @entities.include?(face) && @ofs.virtual_selection(face, flags > 0)
				clean_selection unless @selection.include? face
				@pt_target = target_point view, @ip_origin.position
			elsif (flags == 0)
				@selection.clear
				@ofs.reset
				@pt_target = nil
			end
		else	
			@pt_target = target_point view, @ip_origin.position
		end	
		@pt_end = nil

	when STATE_END			#input End of Vector
		@ip_end.pick view, x, y
		break unless @ip_end.valid?
		@xend = x
		@yend = y
		view.tooltip = @ip_end.tooltip
		if @ip_end != @ip_origin
			@vector = edge_perpendicular(@etarget)
			@pt_end = compute_lock(view, flags, @ip_end, @vector)
		end	
	end	
	view.invalidate
	info_show
end

def in_empty_space?(ip)
	!(ip.vertex || ip.face || ip.edge)
end

def edge_perpendicular(e)
	ed = @ofs.hsh_edges[e.to_s]
	vec = ed.normal_in
	vec = OFSG.normal_ex_to_edge(@etarget, @facetarget)
end

def compute_distance
	d = @pt_target.distance @pt_end
	vec = @pt_target.vector_to @pt_end
	ed = @ofs.hsh_edges[@etarget.to_s]
	normal = OFSG.normal_ex_to_edge(@etarget, ed.face_in)
	(vec % normal < 0) ? -d : d
end

#Projection of input point for axis lock
def compute_lock(view, flags, ip, vec)
	vdir = @pt_target.vector_to ip.position
	if (!vdir.valid? || vec.parallel?(vdir))
		return ip.position
	elsif (flags == 0) && (ip.degrees_of_freedom == 0)	#When Shift pressed, skip inference
		return ip.position.project_to_line([@pt_target, vec])
	else
		pvorig = view.screen_coords @pt_target
		pv0 = view.screen_coords @pt_target.offset(vec, 100)
		pvip = view.screen_coords ip.position
		pv1 = pvip.project_to_line [pvorig, pv0]
		a = Geom.closest_points [@pt_target, vec], view.pickray(pv1.x, pv1.y)
		return a[0]
	end	
end

#Input of length in the VCB
def onUserText(text, view) 
	begin
		len = Traductor.string_to_length_formula text
		return UI.beep unless len

		if @state == STATE_ORIGIN
			return if (@distance_prev == 0)
			len = (@distance_prev < 0) ? -len : len
			return info_show if @ofs.try_execute_after len
			call_execute len if @pt_target
		else
			d = compute_distance
			if len > 0
				d = (d < 0) ? -len : len
			else
				d = (d > 0) ? len : -len
			end	
			call_execute d
		end	
	rescue
		UI.beep
	end	
end

#Draw method for tool
def draw(view)
	@moving = false
	if (@state >= STATE_ORIGIN)
		if (@pt_target)
			lst_contour = []
			@ofs.lst_edges.each do |e| 
				return start_over unless e.valid?
				p1 = view.screen_coords(e.start.position)
				p2 = view.screen_coords(e.end.position)
				lst_contour.push p1, p2 
			end	
			view.drawing_color = @color_pseudo_selection
			view.line_width = 1
			view.line_stipple = "-"
			view.draw2d GL_LINES, lst_contour if lst_contour.length > 1
			#view.draw_points @pt_target, @redpoint_size, @redpoint_mark, @redpoint_color
			if @line_mode
				OFSG.draw_plus view, @pt_target, 5, @redpoint_color
			else	
				OFSG.draw_square view, @pt_target, 3, @redpoint_color
			end	
		end
	end
	
	if (@state >= STATE_END && @pt_end)
		d = compute_distance
		view.line_width = 2
		view.drawing_color = "red"
		view.line_stipple = "-"
		if d == 0
			view.draw_lines @pt_target, @pt_end
		else
			path = @ofs.path_from_red_point d
			view.draw GL_LINE_STRIP, path if path && path.length > 1
		end
		
		d = compute_distance
		if @palman.option_group
			if @palman.linemode
				view.line_stipple = "-"
				view.line_width = 3
			else
				view.line_stipple = "_"
				view.line_width = 1
			end	
			view.drawing_color = (@palman.option_alone) ? @color_alone : @color_group
		else
			if @palman.linemode
				view.line_stipple = (@palman.option_alone) ? "-" : ""
				view.line_width = 2
				view.drawing_color = @color_normal
			else
				view.line_stipple = "_"
				view.line_width = 1
				view.drawing_color = 'black'
			end	
		end
		lpt =  @ofs.get_new_contour d
		lpt.each { |l| @bb = @bb.add l }
		lpt.each { |l| view.draw GL_LINE_STRIP, l if l.length > 1 }
		view.line_stipple = ""
		#lpt.each { |l| view.draw_points l, 8, 3, 'black' if l.length > 1 } if @palman.option_cpoint
		lpt.each { |l| OFSG.draw_plus view, l, 3, 'black' if l.length > 1 } if @palman.option_cpoint
	end

	#Drawing the palette
	super	
end

#Notification call back when changing option
def notify_change_option(option)
	case option.to_s
	when /linemode/i
		parameter_linemode
		@ofs.set_option_linemode @palman.linemode
	when /group/i
		@ofs.set_group((@palman.option_group) ? @palman.current_group : nil)
	when /cpoint/i
		@ofs.set_option_cpoint @palman.option_cpoint
	when /genfaces/i
		@ofs.set_option_nofaces !@palman.option_genfaces
	when /gencurves/i
		@ofs.set_option_nocurves !@palman.option_gencurves
	when /simplify/i
		@ofs.set_option_nosimplify !@palman.option_simplify
	when /contours/i
		@ofs.set_option_contours @palman.option_contours
		clean_selection unless @noselection == nil
	when /alone/i
		@ofs.set_option_alone @palman.option_alone
	end
end
	
#set the cursor and red point depending on line mode	
def parameter_linemode	
	if @palman.linemode
		@idcursor_main = @idcursor_mainL
		@idcursor_forbidden = @idcursor_forbiddenL
		@idcursor_drag = @idcursor_dragL
		@redpoint_mark = 2
		@redpoint_size = 6
		@redpoint_color = 'red'
	else
		@idcursor_main = @idcursor_mainC
		@idcursor_forbidden = @idcursor_forbiddenC
		@idcursor_drag = @idcursor_dragC
		@redpoint_mark = 3
		@redpoint_size = 12
		@redpoint_color = 'red'
	end	
end
	
#Display message and status in the VCB
def info_show
	case @state
	when STATE_ORIGIN
		message = @msg_offset_origin
	when STATE_END
		message = @msg_offset_end
	when STATE_EXECUTION
		message = ""
	end
	
	#Computing the distance
	d = (@pt_target && @pt_end) ? @pt_target.distance(@pt_end) : @distance_prev

	#showing the message and VCB status
	@palman.info_show message, { 'offset' => d }
end
	
end #Class TOSToolOffset

end #module SUToolsOnSurface
