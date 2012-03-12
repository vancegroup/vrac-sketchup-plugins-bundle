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
# Name			:   LineOnSurface.rb
# Original Date	:   14 May 2008 - version 1.1
# Revisions		:	04 Jun 2008 - version 1.2
#					11 Jul 2008 - version 1.3
#					31 Jul 2009 - version 1.5
# Type			:   Sketchup Tools
# Description	:   Draw lines on a surface
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module SUToolsOnSurface

#Constants for LineOnSurface Module (do not translate here)	
T6[:TIT_Line] = "LINE"
T6[:MSG_Line_Origin] = "Click Origin"
T6[:MSG_Line_End] = "Click End Point"
				 
#--------------------------------------------------------------------------------------------------------------
# Top Calling functions: create the classes and launch the tools
#--------------------------------------------------------------------------------------------------------------			 				   

def SUToolsOnSurface.launch_line(linemode=true)
	MYPLUGIN.check_older_scripts
	Sketchup.active_model.select_tool TOSToolLine.new(linemode)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TOSToolLine: Tool to draw line (plain or construction) on a surface
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					
class TOSToolLine < Traductor::PaletteSuperTool

def initialize(linemode)
	#Initialization
	@model = Sketchup.active_model
	@view = @model.active_view
	
	#Loading strings
	@title = T6[:TIT_Line]
	@msg_Line_Origin = T6[:MSG_Line_Origin]
	@msg_Line_End = T6[:MSG_Line_End]
	
	#Loading cursors
	@idcursor_line = MYPLUGIN.create_cursor "Line", 3, 31	
	@idcursor_cline = MYPLUGIN.create_cursor "Cline", 3, 31	

	#initializing variables
	@ip_origin = Sketchup::InputPoint.new
	@ip_end = Sketchup::InputPoint.new
	@ip = Sketchup::InputPoint.new
	
	#Initializing the line picker
	@linepicker = LinePicker.new
	
	#Creating the palette manager
	lst_options = [ "linemode", "cpoint", "group", "protractor", "genfaces", "gencurves"]
	hsh = { 'title' => @title, 'list_options' => lst_options, 'linemode' => true, 'linepicker' => @linepicker }
	@palman = PaletteManager.new(self, 'Line', hsh) { refresh_view }
		
	#Other initializations	
	@prev_dist = 0
	@prev_dist0 = 0
	@prev_vec = nil
	@prev_vec0 = nil
	@angle_prev = nil
end

#Event for Activate Tool
def activate
	@palman.initiate
	@model = Sketchup.active_model
	@selection = @model.selection
	@entities = @model.active_entities
	@view = @model.active_view
	@bb = @model.bounds
	
	@enter_down = false
	@pts = []
	@distance = 0
	@parcours = []
	@edges = nil
	@moved = false
	
	set_state STATE_ORIGIN
	@view.invalidate
end

#Event for Deactivation of the tool
def deactivate(view)
	@palman.terminate
	view.invalidate
end

#Return bounding box	
def getExtents
    return @bb if @state == STATE3_ORIGIN	
	@bb = @linepicker.bounds_add @bb
    @bb
end

def onCancel(flag, view)
	#User did an Undo
	case flag
	when 1, 2	#Undo or reselect the tool
		activate
		return
	when 0	#user pressed Escape
		return  if (@state == STATE_ORIGIN)  #Exiting the tool
		set_state @state - 1
		refresh_view
	end
end

#Set the mouse cursor
def onSetCursor
	ic = super
	return (ic != 0) if ic
	UI::set_cursor((@palman.linemode) ? @idcursor_line : @idcursor_cline)
end

#Compute the path of the line, both for interactive session and final construction
def compute_path(store=false)
	parcours = @linepicker.parcours
	@linepicker.set_prev_direction parcours[-2..-1] if store && parcours
	return @pts = [] unless parcours
	@pts = []
	parcours.each { |mk| @pts.push mk.pt }
	compute_distance
	if store
		@list_coseg = []
		OFSG.compute_coseg(parcours, @list_coseg) if @palman.linemode
		@parcours = parcours 
	end	
	return @pts
end
	
#Computing distance
def compute_distance
	return 0 if @pts.length < 2
	nb = @pts.length - 2
	@distance = 0.0.to_l
	for i in 0..nb
		@distance += @pts[i].distance @pts[i+1]
	end
end

#Finalization of the line drawing
def compute_junction
	#calculating the parcours
	compute_path true
	
	#Drawing the parcours
	execute_drawing

	#Chaining with next point
	prepare_chaining
end

#Used for Redo with imposed distance
def execute_to_distance(mark, vecdir, len)
	@parcours = Junction.to_distance mark, vecdir, len
	@pts = []
	@parcours.each { |mk| @pts.push mk.pt }
	@linepicker.set_prev_direction @parcours[-2..-1]
	
	#Drawing the parcours
	execute_drawing	
end

#Creation method for the line
def execute_drawing
	return if @pts.length < 2
	
	#Storing distance for further Redo
	push_previous @pts

	@model.start_operation @palman.make_title_operation(@title)

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
	
	#creating the new edges or construction lines
	attr = '-'
	if @palman.linemode
		@edges = []
		OFSG.commit_line(entities, @pts, attr, !@palman.option_gencurves, @list_coseg, @edges, [@pts.first, @pts.last])
		@edges[0].find_faces unless !@palman.option_genfaces
	else
		nb = @pts.length - 2
		for i in 0..nb
			cline = entities.add_cline @pts[i], @pts[i+1]
			OFSG.set_cline_attribute cline, attr
		end
	end	
	if @palman.option_cpoint
		@pts.each do |pt|
			cpoint = entities.add_cpoint pt 
			OFSG.set_cline_attribute cpoint, attr
		end
	end	
	@model.commit_operation
	
end

#Perfrom correction of distance after operation
def correct_previous(len)
	#Checking if this is applicable
	return false unless @edges
	@edges.each { |e| return false unless e.valid? }
	return false unless @parcours && @parcours.length >= 2
	
	#Computing the origin
	mark = @parcours[0]
	vecdir = mark.pt.vector_to @parcours[1].pt
		
	Sketchup.undo
	execute_to_distance mark, vecdir, len
	prepare_chaining
	true
end

#Switch the end and origin for drawing the next segment in continuity
def prepare_chaining(view=nil)
	return set_state(STATE_ORIGIN) unless @chaining
	return unless @parcours.length > 0
	view = @model.active_view unless view
	@linepicker.chain_origin view, @parcours.last
	set_state STATE_END
end

#Control the states of the tool
def set_state(state)
	@state = state
	case @state
	when STATE_EXECUTION 
		compute_junction
	when STATE_ORIGIN
		@linepicker.reset
	when STATE_END
		
	end
	info_show
end

#Event for Contextual menu
def getMenu(menu)
	@palman.init_menu
	@palman.menu_add_done { done_and_exit } if (@state >= STATE_END)
	@palman.menu_add_redo(@prev_dist0.to_l) { menu_redo } if (@prev_dist0 > 0)
	
	@palman.option_menu menu
	true
end

#Button Down - Start input of End point
def onLButtonDown(flags, x, y, view)
	return if super
	@flags = flags
	@time_mouse_down = Time.now
	@xdown = x
    @ydown = y
	if (@state == STATE_END)
		return if @linepicker.close_to_origin(x, y)
	end	
	set_state @state + 1
	@chaining = true
end

#Button Up - execute if move has happened, otherwise ignore
def onLButtonUp(flags, x, y, view)
	return if super
	@flags = flags
	return if Time.now - @time_mouse_down < 0.2
	return if (@xdown - x).abs < 2 && (@ydown - y).abs < 2
	if (@linepicker.mark_end && @linepicker.moved?)
		@chaining = false
		set_state @state + 1
	end	
end

#Double Click to repeat with same length
def onLButtonDoubleClick(flags, x, y, view)
	@flags = flags
	redo_previous
end

def push_previous(pts)
	nb = pts.length - 2
	d = 0
	if (nb >= 0)
		d = 0
		for i in 0..nb
			d += pts[i].distance pts[i+1]
		end	
	end	
	return if d == 0
	
	#swapping the stored values	
	@prev_dist = @prev_dist0
	@prev_vec = (@prev_vec0) ? @prev_vec0.clone : nil
	@prev_dist0 = d
	@prev_vec0 = pts[0].vector_to pts[1]
end

#Correction of length after operation
def redo_previous
	mark_origin = @linepicker.mark_origin
	mark_end = @linepicker.mark_end
	moved = @linepicker.moved?
	return UI.beep if mark_end
	if (moved && @prev_dist > 0)
		correct_previous @prev_dist
	elsif (!moved && @prev_vec0 && @prev_dist0 > 0)
		execute_to_distance(mark_origin, @prev_vec0, @prev_dist0)
		prepare_chaining
	else
		UI.beep
	end	
end

#Redo, when called from contextual menu
def menu_redo
	mark_origin = @linepicker.mark_origin
	mark_end = @linepicker.mark_end
	moved = @linepicker.moved?
	if (mark_end && moved && @prev_dist0 > 0)
		vecdir = @pts[0].vector_to @pts[1]
		execute_to_distance(mark_origin, vecdir, @prev_dist0)
		prepare_chaining
	elsif (mark_end == nil && @prev_vec0 && @prev_dist0 > 0)
		execute_to_distance(mark_origin, @prev_vec0, @prev_dist0)
		prepare_chaining
	else
		UI.beep
	end	
end

#Set the default axis via arrows
def check_arrow_keys(key)
	case key
	when VK_RIGHT
		axisdef = X_AXIS
	when VK_LEFT
		axisdef = Y_AXIS
	when VK_UP
		axisdef = Z_AXIS
	when VK_DOWN
		axisdef = nil
	else
		return false
	end
	@linepicker.set_forced_axis axisdef
	refresh_view
	return true
end

#Porcedure to refresh the view ehn options are changed
def refresh_view
	@linepicker.simulate_move_end @flags, @view if (@state >= STATE_END)
	@view.invalidate
	info_show
end

#Finishes the current segment and exit
def done_and_exit
	compute_junction if (@state >= STATE_END)
	@model.select_tool nil 
end

#Return key pressed
def onReturn(view)
	done_and_exit
end

#Key Up
def onKeyUp(key, rpt, flags, view)
	@flags = flags
	key = Traductor.check_key key, flags, true

	case key
		#Toggling between fixed and variable length
		when COPY_MODIFIER_KEY
			if @control_down
				@control_down = false
				return if (Time.now - @time_ctrl_down) > 0.5
				@palman.toggle_option_linemode
			end	
			
		when CONSTRAIN_MODIFIER_KEY
			@linepicker.end_forced
			view.invalidate
			
	end	
	@control_down = false
end

#Key down
def onKeyDown(key, rpt, flags, view)
	@flags = flags
	key = Traductor.check_key key, flags, false
	
	#Check arrows or function keys
	if check_arrow_keys(key) || @palman.check_function_key(key, rpt, flags, view)
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
			@flags = CONSTRAIN_MODIFIER_MASK
			
		else
			@control_down = false
			return
			
	end	
	@control_down = false
	
	refresh_view
end

#Input of length in the VCB
def onUserText(text, view) 
	@enter_down = true
	
	#Parsing the text
	ldist = []
	langle = []
	return UI.beep unless parse_VCB(text, ldist, langle)
	
	#Modifying parameters of the line
	if ldist.length == 0 && langle.length == 0			#No change
		return
	elsif ldist.length > 0 && langle.length == 0		#Change of length only
		modify_length view, ldist.last
	elsif ldist.length == 0 && langle.length > 0		#Modify direction only
		@angle_prev = langle.last
		@linepicker.set_force_angle_direction langle.last	
	else												#modify both length and angle
		@angle_prev = langle.last
		@linepicker.set_angle_direction langle.last
		modify_length view, ldist.last	
	end
	view.invalidate
	info_show
end

#Modify length of line
def modify_length(view, len)
	mark_origin = @linepicker.mark_origin
	mark_end = @linepicker.mark_end
	unless mark_end
		UI.beep unless correct_previous len
	else
		vecdir = mark_origin.pt.vector_to mark_end.pt
		if vecdir.length > 0.0
			execute_to_distance mark_origin, vecdir, len
			prepare_chaining view
		else
			UI.beep
		end	
	end	
end

#Parse the VCB text
def parse_VCB(text, ldist, langle)
	nbeep = parse_text text, ldist, langle
	if (nbeep > 0) 
		@palman.set_error text
		return false
	end	
	true
end

#Recursive method to parse input text
def parse_text(text, ldist, langle)
	#end of text
	nbeep = 0
	text = text.strip
	return if text.length == 0
		
	#Chunk of text separated by space or semi-column
	if text =~ /\s+/ || text =~ /;+/
		nbeep += parse_text $`, ldist, langle
		nbeep += parse_text $', ldist, langle

	#Angle
	elsif text =~ /[dg\%r]/i
		nbeep += parse_angle $` + $&, langle

	#Length
	else
		nbeep += parse_distance text, ldist
	end
	nbeep
end

#Parse angle fom VCB
def parse_angle(text, langle)
	if text == ""
		langle.push @angle_prev if @angle_prev != nil
	end	
	#rangle = Traductor.string_to_float_formula text
	rangle = Traductor.string_to_angle_degree text
	return 1 unless rangle
	angle = rangle.degrees
	angle = angle.modulo(DEUX_PI)
	angle = angle + DEUX_PI if angle < 0
	langle.push angle
	return 0
end

#Parse distance from VCB
def parse_distance(text, ldist)
	begin
		d = Traductor.string_to_length_formula text
		if d 
			ldist.push d
			return 0
		end
	rescue
	end
	return 1
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
	
	#Origin Point
    if (@state == STATE_ORIGIN)
		@mark_beg = @linepicker.onMouseMove_origin flags, x, y, view
		
	#End Point	
	elsif (@state == STATE_END)
		@linepicker.onMouseMove_end flags, x, y, view, true
	end
	
	@palman.set_error
	view.tooltip = @linepicker.tooltip
	view.invalidate
	info_show
end	

#Draw method for tool
def draw(view)
	#drawing the origin and end points
	@linepicker.draw view unless @not_in_viewport
	
	#Drawing the Line contour
	if !@not_in_viewport && @state >= STATE_END
		pts = compute_path
		factor = @linepicker.inference_factor
		if @palman.linemode
			if (@palman.option_group)
				stipple = "-.-"
				width = 2 * factor
			else	
				stipple = ""
				width = 1 * factor
			end	
		else
			stipple = "_"
			width = 1 * factor
		end
		
		@linepicker.set_drawing_parameters 'black', width, stipple
		@linepicker.draw_line view, true
		view.line_stipple = ""
		#view.draw_points pts[1..-2], 10, 3, 'black' if @palman.option_cpoint && pts.length > 2
		OFSG.draw_square view, pts[1..-2], 3, 'black' if @palman.option_cpoint && pts.length > 2
	end	
	
	#Drawing the palette
	super
end

#display information in the Sketchup status bar
def info_show
	case @state
	when STATE_ORIGIN
		message = @msg_Line_Origin
	when STATE_END
		message = @msg_Line_End
	when STATE_EXECUTION
		message = @title
	end
	
	#Message in VCB status bar
	compute_distance
	@palman.info_show message, { 'length' => @distance, 'angle' => @linepicker.get_angle_direction }
end

end	#End Class TOSToolLine

end	#End Module SUToolsOnSurface
