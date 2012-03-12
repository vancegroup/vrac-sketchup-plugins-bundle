=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed May /July 2008 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   PolyLineOnSurface.rb
# Original Date	:   04 June 2008 - version 1.2
#					11 Jul 2008 - version 1.3
#					31 Jul 2009 - version 1.5
# Type			:   Sketchup Tools
# Description	:   Edit Contours on a surface
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module SUToolsOnSurface

#Constants for LineOnSurface Module (do not translate)	
TOS_ICON_POLYLINE = "PolyLine"
TOS_CURSOR_POLYLINE = "PolyLine"

T6[:TIT_Polyline] = "EDIT CONTOURS"
T6[:MSG_Polyline_Origin] = "Pick vertex and drag - Double-Click to erase vertex or insert a new vertex on a segment"
T6[:MNU_EraseVertex] = "Erase Vertex"
T6[:MNU_InsertVertex] = "Insert Vertex"
T6[:MNU_ReverseAnchor] = "Reverse Anchor (green / red)"
				 
#--------------------------------------------------------------------------------------------------------------
# Top Calling functions: create the classes and launch the tools
#--------------------------------------------------------------------------------------------------------------			 				   

#Launch the polyline Editor (persistent)
def SUToolsOnSurface.launch_polyline(ledge=nil)
	HELP.check_older_scripts
	@tool_polyline = TOSToolPolyLine.new
	Sketchup.active_model.select_tool @tool_polyline
	if ledge
		ledge = SUToolsOnSurface.list_of_polyline ledge
		return false unless ledge
		@tool_polyline.set_list_edge ledge
	end	
end

#Check if the selection contains a Contour on Surface
def SUToolsOnSurface.list_of_polyline(selection)
	ledge = nil
	selection.each do |e|
		next unless e.class == Sketchup::Edge
		if OFSG.get_polyline_attribute(e)
			ledge = [] unless ledge
			ledge.push e
		end	
	end
	ledge
end	

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TOSToolPolyLine: Tool to Edit Contours on a surface
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					
class TOSToolPolyLine < Traductor::PaletteSuperTool

def initialize
	@model = Sketchup.active_model
	@view = @model.active_view
	
	#Loading cursors
	@idcursor_polyline = MYPLUGIN.create_cursor TOS_CURSOR_POLYLINE, 3, 31
	@id_cursor_arrow_exit = MYPLUGIN.create_cursor "Arrow_Exit", 0, 0	

	#initializing strings
	@title = T6[:TIT_Polyline]
	@msg_origin = T6[:MSG_Polyline_Origin]
	@mnu_erase_vertex = T6[:MNU_EraseVertex]
	@mnu_insert_vertex = T6[:MNU_InsertVertex]
	@mnu_reverse_anchor = T6[:MNU_ReverseAnchor]
	@tip_exit = T6[:TIP_Exit]
	
	#initializing variables
	@ip_origin = Sketchup::InputPoint.new
	@ip_end = Sketchup::InputPoint.new
	@ip = Sketchup::InputPoint.new
	
	#Initializing polyline editor class instance and Line Picker
	@polyedit = PolyEdit.new
	@linepicker = LinePicker.new
	
	#Creating the palette manager
	lst_options = [ ]
	hsh = { 'title' => @title, 'list_options' => lst_options, 'linemode' => true }
	@palman = PaletteManager.new(self, 'Polyline', hsh) { refresh_view }
end

#Procedure to refresh the view ehn options are changed
def refresh_view
	@view.invalidate
	info_show
end

#Specify the initial list of edges selected by the user
def set_list_edge(ledge)
	@polyedit.set_list_edge(ledge, @selection)
end

#Activation of the tool - We reset everything
def activate
	@palman.initiate
	@model = Sketchup.active_model
	@selection = @model.selection
	@entities = @model.active_entities
		
	@pt_origin = nil
	@pt_end = nil
	@pts = []
	@distance = 0
	@button_down = false
	@editing = false
	
	@selection.clear
	@polyedit.reset
	
	refresh_view
end

#Deactivation of the tool
def deactivate(view)
	@palman.terminate
	@selection.clear
	view.invalidate
end

#Cancel events of the Tool
def onCancel(flag, view)
	case flag
	when 1, 2	#Undo or reselect the tool
		activate
		return
	when 0	#user pressed Escape
		if @editing
			@polyedit.edition_vertex_abort if @editing
			@editing = false
			view.invalidate
		else	
			activate
		end
	end
end

#Even to set the cursor
def onSetCursor
	ic = super
	return (ic != 0) if ic
	if @outside
		UI::set_cursor @id_cursor_arrow_exit
	else	
		UI::set_cursor @idcursor_polyline
	end	
end

#Finishes the current segment and exit
def done_and_exit
	move_edge_or_vertex
	@model.select_tool nil 
end

#contextual menu
def getMenu(menu)
	@palman.init_menu
	@palman.menu_add_done { done_and_exit }
	@palman.show_menu menu
	if @pk_vertex
		menu.add_separator
		menu.add_item(@mnu_erase_vertex) { erase_vertex }
		menu.add_item(@mnu_reverse_anchor) { reverse_anchor }
	elsif @pk_edge && @curpt
		menu.add_separator
		menu.add_item(@mnu_insert_vertex) { insert_vertex @curpt }
	end	
	true
end

#compute the path from the cursor when dragging
def compute_path_cursor
	return @pts = [] unless @mark_origin && @mark_end && @pt_origin && @pt_end && @pt_origin != @pt_end
	parcours = Junction.calculate @mark_origin, @mark_end
	@pts = []
	parcours.each { |mk| @pts.push mk.pt }
	compute_distance
	return @pts
end

#Computing distance for vertex move
def compute_distance
	return 0 if @pts.length < 2
	nb = @pts.length - 2
	@distance = 0.0.to_l
	for i in 0..nb
		@distance += @pts[i].distance @pts[i+1]
	end
end

#Return key pressed
def onReturn(view)
	exit_tool 
end

def exit_tool
	@model.select_tool nil 
end

#Key Up
def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true

	case key			
		#Toggling anchors	
		when COPY_MODIFIER_KEY
			if @editing
				start_edition false
				onMouseMove(flags, @x, @y, view)
				view.invalidate
				info_show
			end	
	end	
end

#Key down
def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false

	case key			
		#Toggling anchors
		when COPY_MODIFIER_KEY
			if @editing
				start_edition true
				onMouseMove(flags, @x, @y, view)
				view.invalidate
				info_show
			end	
	end	
end

#Just check if the edge or vertex belong to a contour on surface
def check_if_contour(edge, vertex)
	le = (vertex) ? vertex.edges : [edge]
	ledge = []
	le.each { |e| ledge.push e if OFSG.get_polyline_attribute(e) }
	(ledge.length > 0) ? set_list_edge(ledge) : false
end

#Double Click to add or delete marks
def onLButtonDoubleClick(flags, x, y, view)
	if @pk_vertex
		erase_vertex
	elsif @pk_edge
		insert_vertex @pt_origin
	end	
end

#Finish vertex edition
def onLButtonUp(flags, x, y, view)
	return if super
	
	@button_down = false
	if @pk_vertex && @moved == false && (Time.now - @time_mouse_down) > 0.3
		reverse_anchor
	else	
		move_edge_or_vertex
	end	
	view.invalidate
end

#Initiate vertex edition
def onLButtonDown(flags, x, y, view)
	return if super
	
	return exit_tool if @outside
	
	@time_mouse_down = Time.now
	@moved = false
	@xdown = x
    @ydown = y
	return unless pick_at_cursor(view, x, y)
	@button_down = true
	toggle_anchor = (flags > 1)
	select_origin view, x, y
	start_edition toggle_anchor
	view.invalidate
end

#start the edition of a vertex
def start_edition(toggle_anchor)	
	@polyedit.edition_vertex_start @pk_vertex, toggle_anchor if (@pk_vertex)
	@editing = true
end

#Check if the cursor is on a valid edge or a valid vertex
def pick_at_cursor(view, x, y)
	ph = view.pick_helper
	ph.do_pick x, y
	edge = ph.best_picked	
	@selection.add @pk_edge if @pk_edge && @pk_edge.valid?
	@pk_vertex = nil
	@pk_edge = nil
	@outside = false
	unless edge || @button_down
		@outside = true
		return false
	end	
	return false unless edge && edge.class == Sketchup::Edge
	@ip.pick view, x, y
	vertex = @ip.vertex

	#Build the list of edges part of contour
	le = (vertex) ? vertex.edges : [edge]
	@pk_ledge = []
	le.each do |e|
		@pk_ledge.push e if OFSG.get_polyline_attribute(e) 
	end	
	return false unless @pk_ledge.length > 0
	
	@pk_vertex = vertex
	@pk_edge = edge
	@pk_edge = @pk_ledge[0]
	@curpt = (@pk_edge) ? @ip.position : nil
	@selection.remove @pk_edge unless @pk_vertex		#for highlight
	return true
end

#Switch mark status between red and green
def reverse_anchor
	@polyedit.edition_reverse_anchor @pk_vertex
	@polyedit.edition_vertex_abort
	@editing = false
	@pk_edge = nil
end

#Insert a new vertex on an edge
def insert_vertex(pt)
	@polyedit.edition_vertex_insert @entities, @pk_edge, pt
end

#Erase a vertex from the contour
def erase_vertex
	@polyedit.edition_vertex_erase @entities, @pk_vertex
end

#Validate the move of a vertex
def move_edge_or_vertex
	if @editing && @pk_vertex
		if @mark_end == nil || (@mark_end.pt == @mark_origin.pt)
			@polyedit.edition_vertex_abort
		else
			@polyedit.edition_vertex_commit @entities
		end	
		@pk_edge = nil
	end	
	@editing = false
end

#select origin point
def select_origin(view, x, y)
	@xorig = x
	@yorig = y
	@ip.pick view, x, y
	@ip_origin.copy! @ip
	@mark_origin = OFSG.mark_from_inputpoint view, @ip_origin, x, y
	@pt_origin = @mark_origin.pt
	@face_origin = @mark_origin.face
	@mark_end = nil
end

#select End point after move
def select_end(view, x, y)
	@xend = x
	@yend = y
	@ip.pick view, x, y
	@mark_end = @mark_origin
	@pt_end = @mark_end.pt
	@face_end = @mark_end.face
	return unless (@ip != @ip_origin) && @ip.valid?
	@ip_end.copy! @ip
	@mark_end = OFSG.mark_from_inputpoint view, @ip_end, x, y
	@pt_end = @mark_end.pt
	@face_end = @mark_end.face
end

#Mouse Move method
def onMouseMove(flags, x, y, view)
	#Event for the palette
	if super
		@not_in_viewport = true
		return
	end	
	@not_in_viewport = false
	@flags = flags

	#checking real move
	@moved = true if @button_down && ((@xdown-x).abs > 5 || (@ydown-y).abs > 5)
	@x = x
	@y = y
	
	tt = @ip.tooltip
	#End Point	
	if @button_down
		select_end view, x, y
		@polyedit.edition_vertex_move(@mark_end) if @editing && @pk_vertex	
	
	#Origin Point
	else
		if pick_at_cursor(view, x, y)
			set_list_edge @pk_ledge
			sparam = (@pk_edge) ? @pk_edge.get_attribute(TOS___Dico, TOS___ParamEdge) : nil
		elsif @outside
			tt = @tip_exit
		end
	end		
	
	view.tooltip = tt
	view.invalidate
	info_show
end	

#Draw method for Polyline tool
def draw(view)
	if @button_down && @editing && @pk_vertex
		pts = compute_path_cursor
		view.drawing_color = 'orange'
		view.line_stipple = "-"
		view.line_width = 2
		view.draw GL_LINE_STRIP, pts if pts.length > 1
	end	
	
	#@polyedit.draw_loops view
	
	if @pk_vertex
		view.line_width = 2
		view.line_stipple = ""
		#view.draw_points @pk_vertex.position, 15, 1, 'orange' if @pk_vertex.valid?
		OFSG.draw_rect view, @pk_vertex.position, 5, 'orange' if @pk_vertex.valid?
	elsif @pk_edge
		G6.draw_lines_with_offset view, [@pk_edge.start.position, @pk_edge.end.position], 'orange', 3, ""
	end
	
	@polyedit.draw_loops view
	#Watchlist.draw view

	#Drawing the palette
	super	
end

#display information in the Sketchup status bar
def info_show
	@palman.info_show @msg_origin, { 'distance' => @distance }
end

end	#End Class TOSToolPolyLine
	
end	#End Module SUToolsOnSurface
