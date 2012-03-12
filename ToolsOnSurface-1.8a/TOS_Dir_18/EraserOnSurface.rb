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
# Name			:   EraserOnSurface.rb
# Original Date	:   04 June 2008 - version 1.2
#					12 Jul 2008 - version 1.3
#					31 Jul 2009 - version 1.5
# Type			:   Sketchup Tools
# Description	:   Erase lines and construction lines on a surface
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module SUToolsOnSurface

T6[:TIT_Eraser] = "ERASER"
T6[:MSG_Eraser] = "Click and drag over edges or construction lines / points"

#Constants for LineOnSurface Module (do not translate)	
TOS_ICON_ERASER = "Eraser"
TOS_CURSOR_ERASER = "Eraser_Line"
TOS_CURSOR_ERASER_NO = "Eraser_Line_NO"
TOS_CURSOR_ERASER_C = "Eraser_Cline"
TOS_CURSOR_ERASER_NO_C = "Eraser_CLine_NO"
				 
#--------------------------------------------------------------------------------------------------------------
# Top Calling functions: create the classes and launch the tools
#--------------------------------------------------------------------------------------------------------------			 				   

def SUToolsOnSurface.launch_eraser
	MYPLUGIN.check_older_scripts
	@tool_eraser = TOSToolEraser.new true
	Sketchup.active_model.select_tool @tool_eraser
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TOSToolEraser: Tool to erase lines (plain or construction) on a surface
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					
class TOSToolEraser < Traductor::PaletteSuperTool

def initialize(linemode)
	@model = Sketchup.active_model
	@view = @model.active_view
	
	#Loading strings
	@title = T6[:TIT_Eraser]
	@msg_eraser = T6[:MSG_Eraser]
	@tit_onsurface = T6[:TIT_OnSurface]
	@tip_exit = T6[:TIP_Exit]
	
	#Initializing the cursors
	hotx = 5
	hoty = 27
	@idcursor_eraser = MYPLUGIN.create_cursor TOS_CURSOR_ERASER, hotx, hoty
	@idcursor_eraser_no = MYPLUGIN.create_cursor TOS_CURSOR_ERASER_NO, hotx, hoty
	@idcursor_eraser_C = MYPLUGIN.create_cursor TOS_CURSOR_ERASER_C, hotx, hoty
	@idcursor_eraser_no_C = MYPLUGIN.create_cursor TOS_CURSOR_ERASER_NO_C, hotx, hoty
	@id_cursor_arrow_exit = MYPLUGIN.create_cursor "Arrow_Exit", 0, 0	

	#Creating the palette manager
	lst_options = [ "linemode"]
	hsh = { 'title' => @title, 'list_options' => lst_options, 'linemode' => linemode }
	@palman = PaletteManager.new(self, 'Eraser', hsh) { refresh_view }
		
	#initializing variables
	@ip = Sketchup::InputPoint.new		
end

def activate
	@palman.initiate
	@model = Sketchup.active_model
	@selection = @model.selection
	@entities = @model.active_entities
		
	reset_selection
	@button_down = false
	
	@view.invalidate
	info_show
end

def reset_selection
	@list_lines = []
	@list_valid = []
	@list_contour = []
	@selection.clear
end

def deactivate(view)
	@palman.terminate
	view.invalidate
end

#Perform the reasing of selected edges
def erase_edges
	@model.start_operation @title + " " + @tit_onsurface
	lst_erase = []
	if @palman.linemode
		@list_lines.each { |e| lst_erase.push e unless OFSG.restore_polyline_param(e) }
		lst_erase.each { |e| @entities.erase_entities e if e.valid?}
	else
		ls = @list_lines.find_all { |e| e.valid? }
		@entities.erase_entities ls
	end 
	@model.commit_operation
end

def onCancel(flag, view)
	#User did an Undo
	case flag
	when 1, 2	#Undo or reselect the tool
		activate
		return
	when 0	#user pressed Escape
		reset_selection
	end
end

def onSetCursor
	ic = super
	return (ic != 0) if ic
	if @outside
		UI::set_cursor @id_cursor_arrow_exit
	elsif @palman.linemode
		UI::set_cursor((@ok) ? @idcursor_eraser : @idcursor_eraser_no)
	else	
		UI::set_cursor((@ok) ? @idcursor_eraser_C : @idcursor_eraser_no_C)
	end	
end

def getMenu(menu)
	@palman.init_menu
	if (@list_lines.length > 0)
		@palman.menu_add_done { erase_edges }
	end	
	
	@palman.option_menu menu
	true
end

#Return key pressed
def onReturn(view)
	exit_tool 
end

def exit_tool
	@model.select_tool nil 
end

#Porcedure to refresh the view ehn options are changed
def refresh_view
	@view.invalidate
	info_show
end

def onLButtonDown(flags, x, y, view)
	return if super
	return exit_tool if @outside
	@button_down = true
	onMouseMove(flags, x, y, view)
end

def onLButtonUp(flags, x, y, view)
	return if super
	erase_edges
	reset_selection
	@button_down = false
end

#Key Up
def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true

	case key
	#Toggling between fixed and variable length
	when COPY_MODIFIER_KEY
		@palman.toggle_option_linemode
	end	
	@control_down = false
end

#Key down
def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false

	if @palman.check_function_key(key, rpt, flags, view)
		@control_down = false
		return
	end

	case key			
	#Calling options
	when CONSTRAIN_MODIFIER_KEY
		onMouseMove 2, @x, @y, view if @button_down

	when COPY_MODIFIER_KEY
		@control_down = true
		return
		
	else
		@control_down = false
		return
	end	
	@control_down = false
	
	view.invalidate
	info_show
end

#Check if the edges are already part of the selection
def already_selected(ledge)
	status = false
	ledge.each do |e|
		if @list_lines.include?(e) 
			status = true
		elsif OFSG.get_polyline_attribute(e)
			@list_lines.push e
			@selection.add e
			status = true
		end	
	end
	status
end

#Check if edges are already known
def already_valid(ledge)
	status = false
	ledge.each do |e|
		if @list_valid.include?(e) 
			status = true
		elsif OFSG.get_polyline_attribute(e)
			@list_valid.push e
			status = true
		end	
	end
	status
end

#check if contour already known
def already_contour(ledge)
	status = false
	le = []
	ledge.each do |e|
		if @list_contour.include?(e) 
			status = true
		elsif OFSG.get_polyline_attribute(e)
			le.push e
			status = true
		end	
	end
	return status unless le.length > 0
	
	pe = PolyEdit.new
	pe.set_list_edge le, nil
	ll = pe.get_list_edge
	ll.each do |l|
		l.each do |e|
			unless @list_lines.include?(e)
				@list_lines.push e
				@selection.add e
				@list_contour.push e
			end	
		end	
	end	
	true
end

#Check and mark edge or edges at vertex for selection
def mark_edge_for_delete(edge, vertex)
	le = (vertex) ? vertex.edges : [edge]
	(@button_down) ? already_selected(le) : already_valid(le)
end

#Check and mark edge or edges at vertex for selection with full contour option
def mark_contour_for_delete(edge, vertex)
	le = (vertex) ? vertex.edges : [edge]
	return false unless already_valid(le)
	(@button_down) ? already_contour(le) : true
end

def mark_cline_for_delete(cline)
	if OFSG.get_polyline_attribute(cline) 
		if @button_down && ! @list_lines.include?(cline)
			@list_lines.push cline
			@selection.add cline
		end	
		status = true
	end	
	status
end

#Mouse Move method
def onMouseMove(flags, x, y, view)
	#Event for the palette
	return if super
	
	@x = x
	@y = y
	@ok = false
	@outside = false
	ph = view.pick_helper
	ph.do_pick x, y
	edge = ph.best_picked	
	
	#Mouse in the mepty space
	unless edge || @button_down
		@outside = true
		view.tooltip = @tip_exit
		onSetCursor
		view.invalidate
		return
	end	
	
	if @palman.linemode
		unless edge && edge.class == Sketchup::Edge
			@pk_edge = nil
		else	
			@ip.pick view, x, y
			if flags > 1
				@ok = mark_contour_for_delete edge, @ip.vertex
			else
				@ok = mark_edge_for_delete edge, @ip.vertex
			end	
			if (@ok) && edge && OFSG.get_polyline_attribute(edge)
				@pk_edge = edge
			else
				@pk_edge = nil
			end	
		end	
	else	
		return unless edge && (edge.class == Sketchup::ConstructionLine || edge.class == Sketchup::ConstructionPoint)
		@ok = mark_cline_for_delete edge
		@pk_edge = nil
	end	
	view.tooltip = ""
	onSetCursor
	view.invalidate
end	

#Draw method for Polyline tool
def draw(view)	
	if @palman.linemode && @button_down == false && @pk_edge && @pk_edge.valid?
		G6.draw_lines_with_offset view, [@pk_edge.start.position, @pk_edge.end.position], 'orange', 3, ""
	end
	
	#Drawing the palette
	super
end

#display information in the Sketchup status bar
def info_show
	@palman.info_show @msg_eraser, nil
end

end	#End Class TOSToolEraser
	
end	#End Module SUToolsOnSurface
