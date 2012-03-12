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
# Name			:   ShapeOnSurface.rb
# Original Date	:   12 July 2008 - version 1.3
#					31 Jul 2009 - version 1.5
# Type			:   Sketchup Tools
# Description	:   Polygon, Ellipes and Arcs on Surface (part of the suite of Tools to draw on a surface)
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module SUToolsOnSurface
	
STATE3_ORIGIN = 0
STATE3_AXE1 = 1
STATE3_AXE2 = 2
STATE3_EXECUTION = 3

TOS_ShapeInput = Struct.new :nbseg, :ldist, :ldelta, :angle, :beep, :changed
TOS_ShapeSaver = Struct.new :time, :distance1, :distance2, :vecpar1, :vecpar2, :forced_normal,
                            :angle, :mark_origin, :param_axe1, :param_axe2, :angle_sector
TOS_ShapeRay = Struct.new :x, :y, :angle, :distance, :dfactor
TOS_ShapeDraw = Struct.new :lmk_contour, :pts_contour, :pts_vertices, :lmk_vertices, 
                           :delta, :face, :lst_hard
											
#--------------------------------------------------------------------------------------------------------------
# Top Calling functions: create the classes and launch the tools
#--------------------------------------------------------------------------------------------------------------			 				   

def SUToolsOnSurface.launch_shape(code, linemode=nil)
	MYPLUGIN.check_older_scripts
	hshape = nil
	@lst_shapes.find { |hshape| break if hshape['NameConv'] == code }
	return unless hshape
	tool = TOSShapeTool.new hshape, linemode
	Sketchup.active_model.select_tool tool
end


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TOSToolPolygon: Tool to mimic Sketchup Polygon Mesure on surface
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					
class TOSShapeTool < Traductor::PaletteSuperTool

def initialize(hshape, linemode=nil)
	@shape = TOSShape.new hshape 
	
	#Loading parameters according to type
	@name = @shape.name
	@code = hshape['NameConv']
	@title = @shape.title
	@type = @shape.type
	@nbseg = @shape.nbsegdef
	@ortho = @shape.ortho
	@single = @shape.single
	@idcursor_line = @shape.get_id_cursor false
	@idcursor_cline = @shape.get_id_cursor true
	
	#Loading strings and cursors
	@msg_shape_origin = T6[:MSG_Shape_Origin]
	@msg_shape_end = T6[:MSG_Shape_End]
	@str_clockwise = T6[:STR_Clockwise]
	@str_anti_clockwise = T6[:STR_AntiClockwise]
	@tip_segment = T6[:TIP_Segment]
	@msg_error_input = T6[:MSG_ErrorInput]
	
	#initializing variables
	@ip_origin = Sketchup::InputPoint.new
	@ip_end = Sketchup::InputPoint.new
	@ip = Sketchup::InputPoint.new
	@prev_dist = 0
	@prev_dist0 = 0
	@prev_vec = nil
	@prev_vec0 = nil
		
	#Creating the palette manager
	init_palette linemode
	
	#Line Picker initialization
	@linepicker1 = LinePicker.new
	@linepicker1.set_drawing_parameters "black", 1, "_"
	@linepicker2 = LinePicker.new
	@linepicker2.set_drawing_parameters "black", 1, "_"
	@linepicker = @linepicker2
	@shape.set_line_pickers @linepicker1, @linepicker2
end

#Creating the palette manager
def init_palette(linemode)
	lst_options = [ "linemode", "cpoint", "group", "gencurves", "ring"]
	lst_options.push "genfaces" if @shape.type != CODE_Arc
	
	if @shape.type == CODE_Sector
		lst_options.push "protractor_sector", "trigo"
	elsif [CODE_Parallelogram, CODE_Circle3P].include?(@shape.type)
		lst_options.push "protractor"
	end	
	lst_options.push "diameter" if [CODE_Polygon, CODE_Circle].include?(@shape.type)
	lst_options.push "axes" if [CODE_Rectangle, CODE_Ellipse, CODE_Parallelogram].include?(@shape.type)
	lst_options.push "numseg" unless @shape.nbfixed
	
	notify_proc = self.method "notify_change_option" 
	hsh = { :notify_proc => notify_proc, 'title' => @name, 'list_options' => lst_options, 'linemode' => linemode,
            :shape => @shape }
	@palman = PaletteManager.new(self, @code, hsh) { refresh_view }
	@shape.set_palette @palman
end

#Procedure to refresh the view ehn options are changed
def refresh_view
	@view.invalidate
	info_show
end

#Notification call back when changing option
def notify_change_option(option)
	case option.to_s
	when /protractor_sector/i
		@linepicker.set_protractor_on @palman.option_protractor_sector if @linepicker
	when /protractor/i
		@linepicker.set_protractor_on @palman.option_protractor if @linepicker
	when /axes/i
		chain_origin @view
	end
end

#Activate the tool
def activate
	@palman.initiate
	@model = Sketchup.active_model
	@view = @model.active_view
	@selection = @model.selection
	@entities = @model.active_entities
	@bb = @model.bounds
			
	@correction_possible = false
	set_state STATE3_ORIGIN
	@view.invalidate
	info_show
end

def deactivate(view)
	@palman.terminate
	view.invalidate
end
	
#Return bounding box	
def getExtents
    return @bb if @state == STATE3_ORIGIN
	@bb = @shape.get_bounds(@bb)	
	@bb
end
	
#Generate the shape in the model	
def execute_drawing
	#Preparing the context of the model
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
		grp = @entities.add_group
		#entities = @entities
		entities = grp.entities
	end
	
	if @shape.execute_all_shapes_drawing entities, @palman.linemode, @palman.option_gencurves, 
	                                     @palman.option_genfaces, @palman.option_cpoint
		grp.explode unless @palman.option_group
		@model.commit_operation
		@correction_possible = true
	else
		@model.abort_operation
	end
end
	
#Top routine to calculate polygon shape		
def execute_shape
	execute_drawing
	set_state STATE3_ORIGIN
	@time_execute = Time.now.to_f
end
	
def onCancel(flag, view)
	#User did an Undo
	case flag
	when 1, 2	#Undo or reselect the tool
		activate
		return
	when 0	#user pressed Escape
		return if (@state == STATE3_ORIGIN)
		set_state @state - 1
	end
end

#setting the right cursor
def onSetCursor
	ic = super
	return (ic != 0) if ic
	UI::set_cursor((@palman.linemode) ? @idcursor_line : @idcursor_cline)
end

#Control the states of the tool
def set_state(state)
	state = 0 if state < 0 
	@state = state
	@shape.reset_error
	
	#Other cases
	if @state == STATE3_EXECUTION || (@state == STATE3_AXE2 && @single)
		info_show
		return execute_shape
	elsif state == STATE3_ORIGIN
		@linepicker1.reset
		@linepicker2.reset
		@linepicker = @linepicker1
		@shape.reset
	elsif state == STATE3_AXE1
		unless @mark_origin
			set_state STATE3_ORIGIN
			return
		end	
		@linepicker2.reset
		@shape.set_parcours2 nil
	elsif state == STATE3_AXE2
		chain_origin
	end	
	
	#Resetting
	@linepicker = (@state < STATE3_AXE2) ? @linepicker1 : @linepicker2
	if @shape.type == CODE_Sector
		@linepicker.set_protractor_on @palman.option_protractor_sector
	else	
		@linepicker.set_protractor_on @palman.option_protractor
	end	
	info_show
end

def done_and_exit
	execute_shape 
	@model.select_tool nil
end

#Contextual menu
def getMenu(menu)
	@palman.init_menu
	if (@state >= STATE3_AXE2) || (@type == CODE_Circle && @state >= STATE3_AXE1)
		@palman.menu_add_done { done_and_exit }
	end	
	if (@shape.redo_possible?)
		@palman.menu_add_redo(@shape.redo_menu_text) { redo_geometry }
	end
	@palman.option_menu menu
	true
end

#Chain input with last entry
def chain_origin(view=nil)
	return unless @state > STATE3_AXE1
	view = @model.active_view unless view
	@shape.chain_origin view 
	view.invalidate
end
		
#Button Down - Start input of End point
def onLButtonDown(flags, x, y, view)
	return if super
	@time_mouse_down = Time.now.to_f
	@xdown = x
    @ydown = y
	if @state > STATE3_ORIGIN
		return if @linepicker.close_to_origin(x, y)
	else
		force_plane_def view, flags
	end	
	set_state @state + 1
end
	
#Button Up - execute if move has happened, otherwise ignore
def onLButtonUp(flags, x, y, view)
	return if super
	return if Time.now.to_f - @time_mouse_down < 0.2
	return if (@xdown - x).abs < 5 && (@ydown - y).abs < 5
	set_state @state + 1 if (@linepicker.mark_end && @linepicker.moved?)
end

#Enter Key
def onReturn(view)
	set_state @state + 1
end

#Key Up
def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true

	case key
		#Toggling between fixed and variable length
		when COPY_MODIFIER_KEY
			if @control_down
				@control_down = false
				return if (Time.now.to_f - @time_ctrl_down) > 0.5
				@palman.toggle_option_linemode
				onMouseMove_zero if (@state >= STATE3_AXE1)
			end	
		when CONSTRAIN_MODIFIER_KEY
			@linepicker.end_forced
			view.invalidate
	
	end	
	@control_down = false
end

#Set the default axis via arrows
def check_arrow_keys(key)
	case key
	when VK_RIGHT
		@axisdef = X_AXIS
	when VK_LEFT
		@axisdef = Y_AXIS
	when VK_UP
		@axisdef = Z_AXIS
	when VK_DOWN
		@axisdef = nil
	else
		return false
	end
	axis = @shape.set_plane_def @axisdef
	@linepicker1.set_plane_def axis
	@linepicker2.set_plane_def axis
	return true
end

#Key down
def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false

	#Check arrows or function keys
	if check_arrow_keys(key) || @palman.check_function_key(key, rpt, flags, view)
		@control_down = false
		return
	end
	
	#Option keys
	case key
		#Toggling between line and Cline mode
		when COPY_MODIFIER_KEY
			@control_down = true
			@time_ctrl_down = Time.now.to_f
			return
			
		#forcing inference	
		when CONSTRAIN_MODIFIER_KEY
			flags = CONSTRAIN_MODIFIER_MASK
			force_plane_def view, flags if @state == STATE3_ORIGIN	
			
	end	
	@control_down = false
	
	#onMouseMove(flags, @xmove, @ymove, view) if (@state >= STATE3_AXE1)
	onMouseMove_zero if (@state >= STATE3_AXE1)
end

#Double Click to repeat with same length
def onLButtonDoubleClick(flags, x, y, view)
	redo_geometry
end

#Reexecuting the shape by reusing previous parameters
def redo_geometry
	return UI.beep unless @shape.redo_possible?
	Sketchup.undo if (Time.now.to_f - @time_execute) < 0.5
	force_plane_def @view, 1, true
	@shape.redo_geometry
	execute_shape
end

#Correcting the geometry after entry in the VCB
def correct_geometry(pinput)
	unless @correction_possible && @shape.correction_valid?
		UI.beep
		return false
	end	
		
	Sketchup.undo
	@shape.correct_geometry pinput
	execute_shape
	true
end

#entry in the VCB: Distance and nb of segments
def onUserText(text, view) 
	pinput = @shape.parse_VCB text
	unless pinput
		info_show
		return UI.beep
	end	
	
	if (@state == STATE3_ORIGIN)
		if @shape.lst_savers
			correct_geometry pinput
		elsif pinput.ldelta != @palman.lst_rings
			@shape.apply_rings pinput
			view.invalidate
		end	
		return
	end
	
	finish = @shape.apply_pinput pinput
	if finish == 1
		return set_state(@state + 1)
	elsif finish == 2
		return execute_shape
	else	
		onMouseMove_zero if (@state >= STATE3_AXE1)
	end	
	view.invalidate
end

#Force default plane for shapes drawn with 'free' origin
def force_plane_def(view, flags, forced=false)
	@shape.set_forced_normal nil unless forced
	return unless @state == STATE3_ORIGIN && flags != 0
	
	return if @face_hilight
	face = @mark_origin.face
	
	normal = nil
	if face
		return unless Traductor.shift_mask?(flags)
		normal = face.normal
	elsif vertex = @mark_origin.vertex
		normal = bissector_at_vertex vertex
	elsif edge = @mark_origin.edge
		normal = edge.line[1]
	end
	return unless normal
	
	@shape.set_forced_normal normal

	@shape.force_plane_def normal
	unless @axisdef
		@linepicker1.set_plane_def normal
		@linepicker2.set_plane_def normal
	end	
	
	#Highlighting the face
	if face
		@face_hilight = face
		view.invalidate
		UI.start_timer(5) { @face_hilight = nil }
	else
		view.invalidate
	end	
end

def bissector_at_vertex(vertex)
	ledges = vertex.edges
	case ledges.length 
	when 1
		return ledges[0].line[1]
	when 2
		edge1 = ledges[0]
		edge2 = ledges[1]
		ov1 = (edge1.start == vertex) ? edge1.end : edge1.start
		ov2 = (edge2.start == vertex) ? edge2.end : edge2.start
		vec1 = ov1.position.vector_to vertex.position
		vec2 = vertex.position.vector_to ov2.position
		return vec2 if vec1.parallel?(vec2)
		Geom.linear_combination 0.5, vec1, 0.5, vec2
	else
		return nil
	end		
end

#Mouse Move method
def onMouseMove_zero
	onMouseMove(@flags, @xmove, @ymove, @view)
end

def onMouseMove(flags, x, y, view)
	#Event for the palette
	if super
		@not_in_viewport = true
		return
	end	
	@not_in_viewport = false
	@flags = flags

	@xmove = x
	@ymove = y
	@shape.set_camera view
	
	#Move the various points
	if @state == STATE3_ORIGIN
		@mark_origin = @linepicker1.onMouseMove_origin flags, x, y, view
		@shape.set_mark_origin @mark_origin
		force_plane_def view, flags
		tt = ""
	elsif @state == STATE3_AXE1
		mk = @linepicker1.onMouseMove_end flags, x, y, view
		if mk
			@mark_end1 = mk
			@shape.set_parcours1 @linepicker1.parcours
		end	
		tt = @linepicker.tooltip
	elsif @state == STATE3_AXE2 && @single == false
		@mark_end2 = @linepicker2.onMouseMove_end flags, x, y, view
		@shape.set_parcours2 @linepicker2.parcours
		tt = @linepicker.tooltip
	end
	view.tooltip = tt
	view.invalidate
	info_show
end	

#Draw method for tool
def draw(view)

	#drawing highlight faces (for setting default normal plane)
	if @face_hilight
		pts = []
		@face_hilight.outer_loop.vertices.each { |v| pts.push v.position }
		pts.push pts.first
		view.drawing_color = 'blue'
		view.line_width = 4
		view.line_stipple = ""
		view.draw GL_LINE_STRIP, pts
	end	
		
	#drawing the polygon
	if (@palman.option_group)
		color = @color_group
		width = 4
		cwidth = 2
	else
		color = @color_normal
		width = 2
		cwidth = 1
	end	
	if (@palman.linemode)
		width = width
		stipple = (@palman.option_group) ? "-.-" : ""
	else
		width = cwidth
		stipple = "_"
	end
	
	#Computing and Drawing the shape
	@shape.calculate_all_shapes
	@shape.draw_center view
	@shape.draw_shape view, width, stipple, 2, 4, @palman.option_cpoint	
	
	#Drawing the palette
	super
	
	#Drawing the axes
	unless @not_in_viewport
		if @state <= STATE3_AXE1
			@linepicker1.draw_line view, true
		else
			@linepicker1.draw_line view, false
			@linepicker2.draw_line view, true
		end
	end
	
end

def string_input_axes
	if @type == CODE_Sector
		return((@palman.option_trigo) ? @str_anti_clockwise : @str_clockwise)
	end
	str_axe1 = @shape.get_label_axe 1
	str_axe2 = @shape.get_label_axe 2
	(@single) ? str_axe1 : (str_axe1 + ", " + str_axe2)
end

#display information in the Sketchup status bar
def info_show
	msg = " [" + string_input_axes + "] -- "
	case @state
	when STATE3_ORIGIN
		msg += @msg_shape_origin
	when STATE3_AXE1
		msg += @msg_shape_end + " 1"
	when STATE3_AXE2
		msg += (@single) ? @title : @msg_shape_end + " 2"
	else
		msg += @title
	end	
	
	angle = nil
	if @state == STATE3_ORIGIN
		d = @last_d
		angle = @last_a
		d = 0.0 unless d
		label = @shape.get_label_origin
	elsif @single
		label = @shape.get_label_axe 1
		d = @shape.distance1 
	else
		angle = @shape.angle_sector
		if @state > STATE3_AXE1
			d = @shape.distance2 
			label = @shape.get_label_axe 2
		else
			d = @shape.distance1 
			label = @shape.get_label_axe 1
		end
	end
	@last_d = d unless d == 0.0
	if @last_d && d == 0.0
		d = @last_d
		angle = @last_a if @last_a
	end
	
	tx_error = @shape.input_error
	@palman.set_error((tx_error) ? @msg_error_input + " --> " + tx_error : nil)
	
	txvalue = d.to_l.to_s
	@last_a = angle
	txvalue += " ; " + sprintf("%3.1f ", angle.radians) + "\°" if angle
	
	@palman.info_show msg, {"angle" => angle, "length" => d, "label" => label }
end

end	#Class TOSShapeTool

#--------------------------------------------------------------------------------------------------------------
# Class TOSShape: hold logic and data for shapes on surface
#--------------------------------------------------------------------------------------------------------------			 				   
					   
class TOSShape

attr_reader :name, :title, :type, :nbsegdef, :nbseg, :ortho, :nbfixed, :single, :arc,
			:distance1, :distance2, :parcours1, :parcours2, :input_error, :lst_savers,
			:param_axe1, :param_axe2, :angle_at_origin, :angle_sector, :hshape

#Create the shape accoding to its properties	
def initialize(hshape)
	@model = Sketchup.active_model
	@hshape = hshape
	@type = hshape['Type']
	@nameconv = hshape['NameConv']
	@name = T6[hshape['Symb']]
	@title = @name + " " + T6[:TIT_OnSurface]
	@nbsegdef = hshape['NbSegDef']
	@nbsegdef = MYDEFPARAM[(type == CODE_Polygon) ? :TOS_DEFAULT_PolygonSegments : :TOS_DEFAULT_CircleSegments] unless @nbsegdef
	@nbsegmin = hshape['NbSegMin']
	@nbsegmin = 3 unless @nbsegmin
	@nbsegmax = hshape['NbSegMax']
	@nbsegmax = 150 unless @nbsegmax
	@nbseg = @nbsegdef
	@ortho = (hshape['Ortho']) ? true : false
	@nbfixed = (hshape['NbFixed']) ? true : false
	@single = (hshape['Single']) ? true : false
	@radial = (hshape['Radial']) ? true : false
	@piecemeal = (hshape['Piecemeal']) ? true : false
	@arc = (hshape['Arc']) ? true : false
	compute_axes_strings
	@default_axis = Z_AXIS
	@default_normal = Z_AXIS
	@lst_savers = []	
	@tr_id = Geom::Transformation.new
	
	@color_normal = MYDEFPARAM[:TOS_COLOR_Normal]
	@color_secondary = MYDEFPARAM[:TOS_COLOR_Secondary]
	@color_group = MYDEFPARAM[:TOS_COLOR_Group]
end

#Initialize the palette with the required options	
def set_palette(palman)
	@palman = palman
end
	
#Reset variables for shape drawing	
def reset
	@parcours1 = nil
	@parcours2 = nil
	@mkcenter = nil
	@lst_shapedraw = []
	@distance1 = 0.0
	@distance2 = 0.0
	@vecref1 = nil
	@vecref2 = nil
	@input_error = nil
	@angle_sector = nil
end
	
def get_id_cursor(cline)
	name = @hshape['NameConv'] + ((cline) ? '_Cline' : '_Line') 
	hotx = @hshape['HotX']
	hotx = 3 unless hotx
	hoty = @hshape['HotY']
	hoty = 31 unless hoty
	MYPLUGIN.create_cursor name, hotx, hoty
end

#Set the line Pickers
def set_line_pickers(linepicker1, linepicker2)
	@linepicker1 = linepicker1
	@linepicker1.set_drawing_parameters "black", 1, "_"
	@linepicker2 = linepicker2
	@linepicker2.set_drawing_parameters "black", 1, "_"
end

#Set the default axis via arrows
def set_plane_def(default_axis)
	@default_axis = (default_axis) ? default_axis : @default_normal
end

def force_plane_def(axis)
	@default_normal = axis
	set_plane_def nil
end

def set_forced_normal(normal=nil)
	@forced_normal = normal
end
	
def reset_error
	@input_error = nil
end

def get_bounds(bb)
	@lst_shapedraw.each do |sd|
		bb = bb.add sd.pts_contour
	end	
	bb = @linepicker1.bounds_add bb
	bb = @linepicker2.bounds_add bb
	bb
end

#return the current number of segments
def get_numseg
	@nbseg
end

def set_numseg(nbseg)
	@nbseg = nbseg unless @nbfixed
end

#Ask for the number of segments
def ask_numseg
	#Building and Calling the dialog box
	unless @dlgseg
		@dlgseg = Traductor::DialogBox.new @name
		@dlgseg.field_numeric "num_seg", T6[:DLG_NumSeg], @hshape['NbSegDef'], @nbsegmin, @nbsegmax
	end
		
	hparam = { 'num_seg' => @nbseg }
	return unless @dlgseg.show! hparam
	
	#Changing the parameters
	@nbseg = hparam['num_seg']
end

def compute_axes_strings
	@str_axe1 = @hshape["Axe1"]
	@str_axe2 = @hshape["Axe2"]
	@str_half_axe1 = @hshape["1/2 Axe1"]
	@str_half_axe2 = @hshape["1/2 Axe2"]
	
	@str_axe1 = T6[@str_axe1] if @str_axe1
	@str_axe2 = T6[@str_axe2] if @str_axe2
	@str_half_axe1 = T6[@str_half_axe1] if @str_half_axe1
	@str_half_axe2 = T6[@str_half_axe2] if @str_half_axe2
	
	ssaxe = T6[:STR_AXE_AXIS]
	
	@str_axe1 = ssaxe + " 1" unless @str_axe1
	@str_axe2 = ssaxe + " 2" unless @str_axe2
	@str_half_axe1 = "1/2 " + @str_axe1 unless @str_half_axe1
	@str_half_axe2 = "1/2 " + @str_axe2 unless @str_half_axe2
	
	@str_orig_center = T6[:STR_Orig_Center]
	@str_orig_bottom_mid = T6[:STR_Orig_BottomMid]
	@str_orig_bottom_left = T6[:STR_Orig_BottomLeft]
	@str_orig_left_mid = T6[:STR_Orig_LeftMid]
	
end

def tooltip_axe1(param1)
	(param1) ? @str_axe1 : @str_half_axe1
end
def tooltip_axe2(param2)
	(param2) ? @str_axe2 : @str_half_axe2
end

def get_label_origin
	if @palman.param_axe1 && @palman.param_axe2
		s = @str_orig_bottom_left
	elsif !@palman.param_axe1 && @palman.param_axe2
		s = @str_orig_bottom_mid
	elsif @palman.param_axe1 && !@palman.param_axe2
		s = @str_orig_left_mid
	else
		s = @str_orig_center
	end
	s
end

def get_label_axe(nb)
	if (nb == 1)
		return((@palman.param_axe1) ? @str_axe1 : @str_half_axe1)
	else
		return((@palman.param_axe2) ? @str_axe2 : @str_half_axe2)
	end	
end

def set_camera(view)
	@vcamera = view.camera.direction
end
	
def set_mark_origin(mark_origin)
	@mark_origin = mark_origin
end
	
def set_parcours1(parcours)
	@parcours1 = parcours
	@distance1 = OFSG.compute_parcours_length parcours
	@mark_origin = (parcours) ? parcours.first : nil
	@vecpar1 = @parcours1[0].pt.vector_to @parcours1[1].pt if parcours
end

def set_parcours2(parcours)
	if (parcours && parcours.length > 1)
		@parcours2 = parcours
		@distance2 = OFSG.compute_parcours_length parcours
		@vecpar2 = @parcours2[0].pt.vector_to @parcours2[1].pt
		@angle_sector = @linepicker2.get_angle_direction
	else
		@parcours2 = nil
		@distance2 = 0.0
		@vecpar2 = nil
		@angle_sector = nil
	end	
end
	
#Compute the mark where to chain the next origin for second axis	
def mark_for_chain_origin
	if @arc
		lres = mark_within_parcours(@parcours1, @distance1 * 0.5)
		mark = lres[0]
		@vec_at_origin = lres[1]
	elsif @palman.param_axe1
		mark = @parcours1.last
		@vec_at_origin = @parcours1[-2].pt.vector_to mark.pt
	else
		mark = @parcours1.first	
		@vec_at_origin = mark.pt.vector_to @parcours1[1].pt
	end
	return mark
end
	
def chain_origin(view)
	@linepicker2.chain_origin view, mark_for_chain_origin 
	@linepicker2.impose_length @distance1 if @type == CODE_Sector
	if @ortho
		@linepicker2.set_imposed_normal @vec_at_origin
	else	
		@linepicker2.set_prev_direction @parcours1
	end	
end
	
#Save the parameters of the geometry	
def save_geometry
	saver = TOS_ShapeSaver.new
	saver.time = Time.now.to_f
	saver.mark_origin = @parcours1.first
	saver.distance1 = @distance1
	saver.param_axe1 = @palman.param_axe1
	saver.param_axe2 = @palman.param_axe2
	saver.vecpar1 = @parcours1.first.pt.vector_to @parcours1[1].pt
	saver.forced_normal = @forced_normal
	saver.angle_sector = @angle_sector
	@angle_sector_prev = @angle_sector
	if (@parcours2)
		saver.distance2 = @distance2
		saver.vecpar2 = @parcours2.first.pt.vector_to @parcours2[1].pt
		lres = mark_for_chain_origin
		saver.angle = @vec_at_origin.angle_between saver.vecpar2
	else
		saver.vecpar2 = nil
		saver.distance2 = 0.0
		saver.angle = 0		
	end	
	@lst_savers[0..-2] = [] if @lst_savers.length >= 2
	@lst_savers.push saver
end

def reinterpret_distance(current_axe, saved_axe)
	return 1.0 if saved_axe == current_axe
	return 2.0 if current_axe && !saved_axe
	return 0.5 
end

#compute the center of a Circle defined by 3 points
def compute_center_circle3P
	mk1 = @mark_origin
	mk2 = @parcours1.last
	mk3 = @parcours2.last
	
	vec12 = mk2.pt.vector_to @parcours1[-2].pt
	vec23 = mk2.pt.vector_to @parcours2[1].pt
	normalref = vec12 * vec23
	angle = vec12.angle_between vec23
	sinus = Math.sin angle
	cosinus = Math.cos angle
	return degraded_center if sinus.abs < 0.1		# Points are collinear
		
	yc = 0.5 * (@distance2 - @distance1 * cosinus) / sinus
	
	@vecref1 = nil
	vec1 = @parcours1.first.pt.vector_to @parcours1[1].pt
	parcours = Junction.to_distance mk1, vec1, @distance1 * 0.5
	mkmid = parcours.last
	v1mid = parcours[-2].pt.vector_to mkmid.pt
	normal = compute_normal_at_mark mkmid
	normal = normal.reverse unless normal % normalref < 0
	
	parcours = Junction.to_distance mkmid, v1mid * normal, -yc
	@mkcenter = parcours.last
	parcours = Junction.calculate mk1, @mkcenter
	@radius1 = OFSG.compute_parcours_length parcours
	@vecref1 = @mkcenter.pt.vector_to parcours[-2].pt
	
	@radius2 = @radius1
	parcours = Junction.calculate @mkcenter, mk2
	@vecref2 = parcours.last.pt.vector_to parcours[-2].pt
end
			
#compute the origin for an arc
def compute_center_arc()	
	#computing the radius (Credit to Stephen La Rocque)
	c = @distance1	#chord length
	s = @distance2	#sagitta length
	c2 = c * c
	y0 = (s - c2 * 0.25 / s)
	r = Math.sqrt(c2 + y0 * y0) * 0.5
	
	vec = @parcours2.last.pt.vector_to @parcours2[-2].pt
	parcours = Junction.to_distance @parcours2.last, vec, r
	@mkcenter = parcours.last
	@radius1 = @radius2 = r
	@vecref1 = parcours.last.pt.vector_to parcours[-2].pt
	@vecref2 = @parcours2[0].pt.vector_to @parcours2[1].pt
end
	
def degraded_center()
	if @palman.param_axe1 
		@radius1 = @distance1 * 0.5
		lres = mark_within_parcours @parcours1, @radius1 
		@mkcenter = lres[0]
		@vecref1 = lres[1]
	else
		@mkcenter = @parcours1[0]
		@radius1 = @distance1
		@vecref1 = @parcours1[0].pt.vector_to @parcours1[1].pt			
	end
	@radius2 = @radius1
end
	
def compute_angle_at_origin
	if @ortho || @single || @parcours2 == nil
		@angle_at_origin = nil
	else
		vec2 = @parcours2[0].pt.vector_to @parcours2[1].pt
		@angle_at_origin = @vec_at_origin.angle_between vec2
	end
end
	
#Compute the origin of the polygon		
def compute_center()

	#Compute angle at origin
	compute_angle_at_origin
	
	#Single or double unfinished
	if (@parcours2 == nil || @parcours2.length < 2)
		degraded_center
		return
	end

	#Compute angle at drawing origin
	
	#Special Computation for arcs, circle 3Points and Sectors
	return compute_center_arc if @type == CODE_Arc
	return compute_center_circle3P if @type == CODE_Circle3P
	

	#Default vectrors for directions
	@vecref1 = @parcours1[0].pt.vector_to @parcours1[1].pt
	@vecref2 = @parcours2[0].pt.vector_to @parcours2[1].pt
	
	#Origin = Center
	if !@palman.param_axe1 && !@palman.param_axe2
		@mkcenter = @parcours1[0]
		@radius1 = @distance1
		@radius2 = @distance2
		return
	end
		
	#Grand Axe 1 and Grand Axe2
	if @palman.param_axe1 && @palman.param_axe2
		@radius1 = @distance1 * 0.5
		@radius2 = @distance2 * 0.5
		lres = mark_within_parcours @parcours1, @radius1 
		mkmid = lres[0]
		@vecref1 = lres[1]
		parcours = Junction.to_distance mkmid, @vecref2, @radius2
		@mkcenter = parcours.last
		@vecref2 = parcours[-2].pt.vector_to @mkcenter.pt
		return
	end	
	
	#!/2 Axe1 and Grand Axe2
	if !@palman.param_axe1 && @palman.param_axe2
		@radius1 = @distance1
		@radius2 = @distance2 * 0.5
		parcours = Junction.to_distance @parcours1.first, @vecref2, @radius2
		@mkcenter = parcours.last
		@vecref2 = parcours[-2].pt.vector_to @mkcenter.pt
		return
	end	

	#Grand Axe1 and 1/2 Axe2
	if @palman.param_axe1 && !@palman.param_axe2
		@radius1 = @distance1 * 0.5
		@radius2 = @distance2
		lres = mark_within_parcours @parcours1, @radius1 
		@mkcenter = lres[0]
		@vecref1 = lres[1]
		return
	end		
end
		
#Computing the center of a parcours	
def mark_within_parcours(parcours, distance)
	mkorigin = parcours[0]
	vec = mkorigin.pt.vector_to parcours[1].pt
	parc = Junction.to_distance mkorigin, vec, distance
	#vecref = parc.last.pt.vector_to parc[-2].pt
	vecref = parc[-2].pt.vector_to parc.last.pt
	[parc.last, vecref]
end

#Compute the normal direction at a Mark	
def compute_normal_at_mark(mark)
	face = mark.face
	return face.normal if face
	return @default_axis if @single || @vecpar2 == nil
	
	normal = nil
	normal = @vecpar1 * @vecpar2 if @vecref1 == nil || @vecref2 == nil || @vecref2.parallel?(@vecref1)
	#normal = @vecref1 * @vecref2 unless normal && normal.valid? 
	normal = @default_axis unless normal && normal.valid? 
	
	(normal) ? normal : @default_normal
end

def absolute_normal_at_mark(mark)	
	face = mark.face
	if face
		normal = face.normal
	elsif @single || @vecpar2 == nil
		normal = @default_axis
	else		
		normal = nil
		normal = @vecpar1 * @vecpar2 if @vecref1 == nil || @vecref2 == nil || @vecref2.parallel?(@vecref1)
		normal = @vecref1 * @vecref2 unless normal && normal.valid? 
		normal = @default_axis unless normal && normal.valid? 
	end
	
	view = Sketchup.active_model.active_view
	vcamera = view.camera.direction
	return((normal % vcamera > 0) ? normal.reverse : normal)
end

#Generate the outer contour by joining the vertices
def generate_shapedraw(lst_vert, delta, lst_hard=nil)
	#computing the contour
	lmk_contour = [lst_vert.first]
	nb = lst_vert.length - 2
	for i in 0..nb
		parcours = Junction.calculate lst_vert[i], lst_vert[i+1]
		parcours[1..-1].each { |mk| lmk_contour.push mk } if parcours.length > 1
		lmk_contour.last.signature = true
	end
	
	#computing the points in the polygon contour
	pts_contour = []
	lmk_contour.each { |mk| pts_contour.push mk.pt }
	pts_vertices = []
	lst_vert.each { |mk| pts_vertices.push mk.pt }	

	#Generating the structure
	shapedraw = TOS_ShapeDraw.new
	shapedraw.lmk_vertices = lst_vert
	shapedraw.lmk_contour = lmk_contour
	shapedraw.pts_contour = pts_contour
	shapedraw.pts_vertices = pts_vertices
	shapedraw.delta = delta
	shapedraw.face = nil
	shapedraw.lst_hard = lst_hard
	return shapedraw
end

#method to draw the center of a shape, to be called from the Tool draw() method
def draw_center(view, size=nil, color=nil, mark=nil)
	return unless @mkcenter
	color = 'red' unless color
	mark = 3 unless mark
	size = 12 unless size
	view.line_stipple = ""
	#view.draw_points @mkcenter.pt, size, mark, color
	OFSG.draw_plus view, @mkcenter.pt, 6, color
end	

#method to draw a shape, to be called from the Tool draw() method
def draw_shape(view, width, stipple, mark, size, option_cpoint)
	view.line_stipple = stipple
	color = @color_normal
	
	@lst_shapedraw.each do |shapedraw|
		view.drawing_color = color
		view.line_width = width
		
		#Drawing contour
		pts_contour = shapedraw.pts_contour
		return unless pts_contour
		pts_vertices = shapedraw.pts_vertices
		view.draw GL_LINE_STRIP, pts_contour if pts_contour.length > 1
		
		#drawing marks on main contour
		view.line_stipple = ""
		if pts_vertices && pts_vertices.length > 2
			if option_cpoint
				#view.draw_points pts_vertices, 6, 3, 'black'
				OFSG.draw_plus view, pts_vertices, 3, 'black'
			else
				#view.draw_points pts_vertices, size, mark, color
				OFSG.draw_square view, pts_vertices, 2, color
			end	
		end	
		
		#Darwing optional Construction points
		pts = []
		pts_contour.each { |pt| pts.push pt unless pts_vertices.include?(pt) }
		#view.draw_points pts, 6, 3, 'black' if option_cpoint && pts.length > 2
		OFSG.draw_plus view, pts, 3, 'black' if option_cpoint && pts.length > 2
		
		color = @color_secondary
		width = 2
		mark = 0
	end	
end

#create all shapes in the model
def execute_all_shapes_drawing(entities, linemode, option_gencurves, option_genfaces, option_cpoint)	
	#Computing the shapes
	calculate_all_shapes
	
	#drawing each shape
	@edges = []
	attr = @type + " " + ((linemode) ? 'L' : 'C') + " ---" + Time.now.to_i.to_s
	@lst_shapedraw.each do |shapedraw|	
		unless execute_single_shape_drawing shapedraw, entities, linemode, option_gencurves, option_cpoint, attr
			return false
		end	
	end
	
	#Drawing the center of the shape
	cpoint = entities.add_cpoint @mkcenter.pt		#center of the polygon
	OFSG.set_cline_attribute cpoint, attr

	#Generating faces optionally
	generate_all_faces entities if option_genfaces && linemode
	
	#Saving the geometry for future correction or redo
	save_geometry
	
	return true
end

#Create a single shape in the model
def execute_single_shape_drawing(shapedraw, entities, linemode, option_gencurves, option_cpoint, attr)
	
	#Parameters of the shape
	lmk_contour = shapedraw.lmk_contour
	pts_contour = shapedraw.pts_contour
	pts_vertices = shapedraw.pts_vertices
	return false if pts_contour.length < 2
	
	list_coseg = []
	OFSG.compute_coseg(lmk_contour, list_coseg) if linemode	
		
	#Creating the shapes
	if linemode
		lst_hard = (@piecemeal) ? pts_vertices : shapedraw.lst_hard
		edges = []
		unless native_drawing(entities, lmk_contour, pts_contour, edges, attr, pts_vertices)
			OFSG.commit_line entities, pts_contour, attr, !option_gencurves, list_coseg, edges, pts_vertices, lst_hard
		end	
		@edges += edges
				
	else
		nb = pts_contour.length - 2
		for i in 0..nb
			cline = entities.add_cline pts_contour[i], pts_contour[i+1]
			OFSG.set_cline_attribute cline, attr
		end
	end	
	if option_cpoint
		pts_contour.each do |pt| 
			cpoint = entities.add_cpoint pt 
			OFSG.set_cline_attribute cpoint, attr
		end
	end	
	
	#Operation successful
	return true
end

#Draw native SU objects (Circle, Arc, Polygon) when there is no surface
def native_drawing(entities, lmk_contour, pts_contour, edges, attr, pts_vertices)
	#Only apply to Circle and Polygon
	return nil unless [CODE_Circle, CODE_Polygon, CODE_Circle3P].include?(@type)
	face = lmk_contour[0].face 
	if face
		return nil if lmk_contour.find { |mk| mk.face != face }
	else
		return nil if lmk_contour.find { |mk| mk.face }
	end	
	
	#Computing the circle and polygon parameters
	center = @mkcenter.pt
	pt1 = pts_contour[0]
	pt2 = pts_contour[1]
	radius = center.distance pt1
	vec1 = center.vector_to(pt1)
	normal = vec1 * center.vector_to(pt2)
	grp = entities.add_group
	if @type == CODE_Polygon
		ledges = grp.entities.add_ngon center, normal, radius, pts_contour.length-1
	else	
		ledges = grp.entities.add_circle center, normal, radius, pts_contour.length-1
	end	
	
	#Because SU API does not allow to specify the exact location of points, adjustment by rotation is needed
	pte = ledges.last.end.position
	ve = center.vector_to(pte)
	angle = ve.angle_between vec1
	vrot = ve * vec1
	tr = (vrot.valid?) ? Geom::Transformation.rotation(center, vrot, angle) : @tr_id
	entities.transform_entities tr, [grp]
	ledges = grp.explode.find_all { |e| e.class == Sketchup::Edge }
	curve = ledges[0].curve
	if curve
		pts_contour.clear
		curve.vertices.each { |v| pts_contour.push v.position }
	end

	#Setting the attributes for Edition
	OFSG.set_polyline_attribute ledges, attr, pts_contour
	edges += ledges
end

#Manage generation of faces for shapes
def generate_all_faces(entities)
	#Arcs have no face
	return if @type == CODE_Arc
	
	#Generate the faces
	@lst_shapedraw.each do |sd|
		begin
			sd.face = entities.add_face sd.pts_contour
			####sd.face.material = sd.face.back_material = @model.materials.current
		rescue
			sd.face = nil
		end
	end
	
	#For sectors, Shapes are already built. 
	return if @type == CODE_Sector
	####return
	
	#For others, need to eliminate some faces to manage rings
	nb = @lst_shapedraw.length - 1
	return if nb == 0
	lsd = @lst_shapedraw.sort { |s1, s2| -s1.delta <=> -s2.delta }
	i = 1
	while (i <= nb)
		face = lsd[i].face
		entities.erase_entities face if face
		i += 2
	end	
end

#Initialize a structure for getting input parameters
def init_pinput
	pinput = TOS_ShapeInput.new
	pinput.nbseg = @nbseg
	pinput.ldist = []
	pinput.ldelta = []
	pinput.angle = nil
	@palman.lst_rings.each { |d| pinput.ldelta.push d }
	pinput.beep = 0
	return pinput
end

def apply_rings(pinput)
	lst_rings = []
	pinput.ldelta.each do |r| 
		if r == 0.0
			lst_rings = []
		else	
			lst_rings.push r
		end	
	end	
	@palman.ring_set_values lst_rings
end

#Apply passively the new parameters to the shape
def apply_pinput(pinput)
	finish = 0
	
	#Modifying number of segments
	if pinput.nbseg != @nbseg
		@nbseg = pinput.nbseg
	end

	#modifying rings
	if pinput.ldelta != @palman.lst_rings
		apply_rings pinput
	end
	
	#Modifying angle
	if pinput.angle
		finish = (@type == CODE_Sector) ? 1 : 1
	end
	
	#Modifying length
	ldist = pinput.ldist
	nb = ldist.length
	if nb > 0
		if @single
			@distance1 = ldist.last
			finish = 2
		elsif @vecpar2 == nil	
			@distance1 = ldist.last
			finish = 1
		elsif nb == 1 
			@distance2 = ldist.last
			finish = 2
		else 
			@distance1 = ldist[-2]
			@distance2 = ldist.last
			finish = 2
		end
		if @type == CODE_Sector		#sector
			@distance1 = @distance2 = ldist.last
		end			
		#reconstruct_geometry(pinput)
		#@linepicker1.set_parcours @parcours1 if (finish == 1)
	end
	if finish > 0
		reconstruct_geometry(pinput)
		@linepicker1.set_parcours @parcours1 if (finish == 1)
		if pinput.angle && finish == 1
			@linepicker2.set_angle_direction pinput.angle
			#@linepicker2.set_parcours @parcours2
		end	
	end	
	return finish
end

def reconstruct_geometry(pinput)
	@parcours1 = Junction.to_distance @mark_origin, @vecpar1, @distance1
	mark = mark_for_chain_origin
	unless @single || @vecpar2 == nil
		if pinput.angle
			@angle_sector = pinput.angle
			@vecpar2 = OFSG.rotate_vector @mark_origin, @vecpar1, pinput.angle, @default_normal
		end	
		@parcours2 = Junction.to_distance mark, @vecpar2, @distance2
	end	
end

#Check if correction can be done
def correction_valid?
	return false unless @edges
	@edges.each { |e| return false unless e.valid? }
	true
end

#Correct geometry after execution, based on VCB inputs
def correct_geometry(pinput=nil)
	return false unless @lst_savers.length > 0
	saver = @lst_savers.last
	@mark_origin = saver.mark_origin
	@distance1 = saver.distance1
	@distance2 = saver.distance2
	@vecpar1 = saver.vecpar1
	@vecpar2 = saver.vecpar2
	@angle_sector = saver.angle_sector
	apply_pinput pinput if pinput
	reconstruct_geometry(pinput)
	true
end

#check if a Redo is possible
def redo_possible?
	@lst_savers.length > 0
end

#Compute text for redoing
def redo_menu_text
	return nil unless @lst_savers.length > 0
	saver = @lst_savers.last
	s1 = get_label_axe 1
	text = "#{s1} = #{saver.distance1.to_l}"
	unless @single
		s2 = get_label_axe 2
		text += ", #{s2} = #{saver.distance2.to_l}"
	end
	text	
end

#Reset shape for redoing, based on last savings
def redo_geometry
	#Retrieving the right saver (because of double-click)
	saverlast = @lst_savers.last
	recent = (Time.now.to_f - saverlast.time) < 0.5
	saverfirst = (recent) ? @lst_savers.first : saverlast
	if (recent && !@single)
		factor1 = reinterpret_distance(@palman.param_axe1, saverlast.param_axe1)
		@distance1 = saverlast.distance1 * factor1
	else
		factor1 = reinterpret_distance(@palman.param_axe1, saverfirst.param_axe1)
		@distance1 = saverfirst.distance1 * factor1
	end
	
	if (@parcours1)
		@vecpar1 = @parcours1.first.pt.vector_to @parcours1[1].pt
	else
		@vecpar1 = saverlast.vecpar1
	end	
	
	#Corecting the vector if perpendicular to edge
	if @forced_normal
		v1 = vector_project_to_plane @vecpar1, @forced_normal, saverlast.forced_normal
		@vecpar1 = v1 if v1
	end
	
	#Computing the first axis
	@parcours1 = Junction.to_distance @mark_origin, @vecpar1, @distance1
	return if @single
	
	#recomputing the second vector
	factor2 = reinterpret_distance(@palman.param_axe2, saverfirst.param_axe2)
	@distance2 = saverfirst.distance2 * factor2
	mark2 = mark_for_chain_origin
	if @parcours2
		@vecpar2 = @parcours2.first.pt.vector_to parcours2[1].pt
		@parcours2 = Junction.to_distance mark2, @vecpar2, @distance2
		return
	end	
	
	angle = (@ortho) ? Math::PI * 0.5 : saverlast.angle
	normal = compute_normal_at_mark mark2
	t = Geom::Transformation.rotation mark2.pt, normal, angle
	@vecpar2 = @vecpar1.transform t
	@parcours2 = Junction.to_distance mark2, @vecpar2, @distance2
	@angle_sector = (@ortho) ? nil : angle
end

def vector_project_to_plane(vec, plane_normal, v2_perp=nil)
	pt = Geom::Point3d.new vec.x, vec.y, vec.z
	ptproj = pt.project_to_plane [ORIGIN, plane_normal]
	return Geom::Vector3d.new(ptproj.x, ptproj.y, ptproj.z) if ptproj != ORIGIN
	return nil unless v2_perp
	
	v2 = v2_perp * vec
	v2proj = vector_project_to_plane v2, plane_normal
	return nil unless v2proj
	v2proj * plane_normal
end

#Parse the VCB text
def parse_VCB(text)
	pinput = init_pinput
	@input_error = nil
	parse_text text, pinput
	if (pinput.beep > 0) 
		@input_error = text
		return nil
	else
		return pinput
	end	
end

#Recursive method to parse input text
def parse_text(text, pinput)
	#end of text
	text = text.strip
	return if text.length == 0
	
	#Isolating blocks for Delta
	if text =~ /\(.*\)x/i || text =~ /\[.*\]x/i
		parse_text $`, pinput
		parse_delta_block $&, pinput
		parse_text $', pinput
	
	#Chunk of text separated by space or semi-column
	elsif text =~ /\s+/ || text =~ /;+/
		parse_text $`, pinput
		parse_text $', pinput

	#number of segments
	elsif text =~ /s/i
		parse_segments $`, pinput

	#Angle
	elsif text =~ /[dg\%r]/i
		parse_angle $` + $&, pinput

	#delta
	elsif text =~ /x/i
		if $` == ""
			pinput.ldelta = []
		else	
			parse_delta $`, pinput
		end	

	#Length
	else
		parse_distance text, pinput
	end
end

#Parse a Ring block in the form [...]x
def parse_delta_block(text, pinput)
	text = text.slice(1..-3) 
	pinput.ldelta = []
	text = text.strip
	return if text == ""
	
	while true
		text = text.strip
		if text =~ /\s/ || text =~ /;/
			parse_delta $`, pinput
			text = $'
		else
			parse_delta text, pinput
			break
		end
	end	
end

#Parse a single value of ring distance
def parse_delta(text, pinput)
	f = Traductor.string_to_length_formula text
	begin
		pinput.ldelta.push f if f
	rescue
	end
end

#Parse number of segments
def parse_segments(text, pinput)
	if @nbfixed == true
		pinput.beep += 1
		return
	elsif text == ""
		nb = @nbsegdef
	else 
		#nb = text.to_i
		nb = Traductor.string_to_integer_formula text
		nb = 0 unless nb
	end
	
	if (nb < @nbsegmin || nb > @nbsegmax)
		pinput.beep += 1
	elsif nb != @nbseg	
		pinput.nbseg = nb
	end	
end

#Parse angle (for sectors and parallelograms)
def parse_angle(text, pinput)
	if @single || @ortho
		pinput.beep += 1
		return
	elsif text == ""
		pinput.angle = @angle_sector_prev if @angle_sector_prev
		return
	else 
		dangle = Traductor.string_to_angle_degree text
		angle = (dangle) ? dangle.degrees : 0.0
	end
	angle = angle.modulo(DEUX_PI)
	angle = angle + DEUX_PI if angle < 0
	if (angle == 0)
		pinput.beep += 1
	else 	
		angle = (@palman.option_trigo) ? angle : DEUX_PI - angle
		pinput.angle = angle
	end	
end

def parse_distance(text, pinput)
	begin
		f = Traductor.string_to_length_formula text
		f = 0.0 unless f
		if f <= 0.0 #|| @vecref1 == nil
			pinput.beep += 1
		else
			pinput.ldist.push f
		end
	rescue
		pinput.beep += 1
	end
end

#--------------------------------------
#Calculation of geometry
#--------------------------------------			 				   
	
#Compute all shapes to be drawn as <shaepdraw> structure
def calculate_all_shapes()
	#Initialization
	@lst_shapedraw = []
	@mkcenter = nil
	return unless @parcours1
	
	#computing the origin
	compute_center
	
	#Double polygon unfinished
	return unless @single || @parcours2
	
	case @type		
		when CODE_Rectangle, CODE_Parallelogram	#Rectnagle, Parallelogram
			quadri_calculate_shapes		
		else	#Circle, Polygon, Ellipse, Circle 3P
			radial_calculate_shapes			
	end
end


#Compute the whole shape for Quadri shapes	
def quadri_calculate_shapes()	

	#Calculating angle for parallelogram
	compute_angle_sector if @type == CODE_Parallelogram
	
	#generating all shapes in rings
	([0.0] + @palman.lst_rings).each do |delta|
		lst_vert =  quadri_calculate_single_shape delta
		next unless lst_vert
		shapedraw = generate_shapedraw(lst_vert, delta)
		@lst_shapedraw.push shapedraw
	end
end

#Compute a shape with 4 sides (Rectangle, parallelogram)
def quadri_calculate_single_shape(delta)	
	return nil if (@radius1 + delta < 0) || (@radius2 + delta < 0)
	
	angle = (@ortho) ? Math::PI * 0.5 : @angle_sector
	r1 = @radius1 + delta
	r2 = @radius2 + delta
	d1 = 2.0 * r1
	d2 = 2.0 * r2
	
	#Origin = Center
	parcours = Junction.to_distance @mkcenter, @vecref1, r1
	mkmid1 = parcours.last
	parcours = Junction.to_distance mkmid1, @vecref2.reverse, r2
	mkcorner1 = parcours.last	
		
	parcours = Junction.to_distance mkcorner1, @vecref2, d2
	mkcorner2 = parcours.last
		
	parcours = Junction.to_distance mkcorner2, @vecref1.reverse, d1
	mkcorner3 = parcours.last
		
	parcours = Junction.to_distance mkcorner3, @vecref2.reverse, d2
	mkcorner4 = parcours.last
	
	#Adjustments for forcing the input points
	return [mkcorner1, mkcorner2, mkcorner3, mkcorner4, mkcorner1]
	mkcorner1 = @parcours1.last if @palman.param_axe2
	mkcorner2 = @parcours2.last if @palman.param_axe1
	mkcorner4 = @parcours1.first if @palman.param_axe1 && @palman.param_axe2
	
	if !@palman.param_axe1
		parcours = Junction.calculate mkcorner2, @parcours2.last
		vec = parcours[-2].pt.vector_to parcours.last.pt
		parcours = Junction.to_distance @parcours2.last, vec, r1
		mkcorner3 = parcours.last
	end
		
	return [mkcorner1, mkcorner2, mkcorner3, mkcorner4, mkcorner1]
end

#Calculate all shapes with Radial pattern
def radial_calculate_shapes()
	radial_shapes_from_center()
end

def radial_list_rays(nbseg, angle_deb, angle_total, ratio)
	angle_unit = angle_total / nbseg
	lst_ray = []
	for i in 0..nbseg
		angle = angle_deb + angle_unit * i
		x = Math.cos(angle)
		y = Math.sin(angle)
		dfactor = 1.0
		if (ratio != 1.0)
			y = y * ratio
			dfactor = dfactor * Math.sqrt(x * x + y * y)
			angle = Math.atan2(y, x)
		end	
		ray = TOS_ShapeRay.new
		ray.dfactor = dfactor
		ray.angle = angle
		ray.x = x
		ray.y = y
		lst_ray.push ray
	end
	lst_ray
end

#Compute the vertice when mark is imposed
def radial_force_mark (mark, delta)
	return mark if (delta == 0.0)
	parcours = Junction.calculate @mkcenter, mark	
	vec = parcours[-2].pt.vector_to parcours.last.pt
	parcours = Junction.to_distance mark, vec, delta
	parcours.last		
end

#Substitute imposed extremities
def radial_impose_extremities(lst_vert, delta, markdeb, markend)
	forced_mkbeg = radial_force_mark markdeb, delta
	forced_mkend = radial_force_mark markend, delta
	
	mkvert = lst_vert.first
	d1 = mkvert.pt.distance forced_mkbeg.pt		
	d2 = mkvert.pt.distance forced_mkend.pt	
	mkforced = (d1 <= d2) ? forced_mkbeg : forced_mkend
	lst_vert[0..0] = [mkforced]

	mkvert = lst_vert.last
	d1 = mkvert.pt.distance forced_mkbeg.pt		
	d2 = mkvert.pt.distance forced_mkend.pt	
	mkforced = (d1 <= d2) ? forced_mkbeg : forced_mkend
	lst_vert[-1..-1] = [mkforced]
end

def compute_angle_sector
	angle_total = @angle_at_origin
	v1 = @mark_origin.pt.vector_to @parcours1.last.pt
	v2 = @mark_origin.pt.vector_to @parcours2.last.pt
	ps = (v1 * v2) % @vcamera
	angle_total = (2 * Math::PI - angle_total) if (v1 * v2) % @vcamera > 0
	@angle_sector = angle_total
end

#Compute the whole shape for Radial shapes	
def radial_shapes_from_center()	
	#drawing arcs
	case @type
	when CODE_Arc	#Arcs
		angle_total = 2.0 * Math.atan2(@distance1 * 0.5, @radius1 - @distance2)
		angle_deb = -angle_total * 0.5
		ratio = 1.0
		markdeb = @parcours1.first
		markend = @parcours1.last
		nb = @nbseg / 2
		if (@mkcenter.face && markdeb.face && markend.face) ||
		   (@mkcenter.face == nil && markdeb.face == nil && markend.face == nil)
			method_center = false
		else
			method_center = false
		end	


	when CODE_Sector	#Sectors
		#compute_angle_sector
		if (@palman.option_trigo)
			angle_total = @angle_sector
			angle_deb = 0
		else	
			angle_total = DEUX_PI - @angle_sector
			angle_deb = -angle_total
		end	
		markdeb = @parcours1.last
		markend = @parcours2.last
		ratio = 1.0
		nb = @nbseg * angle_total.abs / DEUX_PI
		nb = nb.to_i + 1
		method_center = true
		
	else	#circle by center, ellipse, polygon, circle 3P
		angle_total = 2 * Math::PI
		ratio = (@single || @distance2 == 0) ? 1.0 : (@radius2 / @radius1)
		angle_deb = 0.0
		markdeb = nil
		markend = nil
		nb = @nbseg
		method_center = true
	end	
		
	#generating all shapes in rings
	if (method_center)
		radial_special_center_OK nb, angle_deb, angle_total, markdeb, markend
	else
		lst_ray = radial_list_rays nb, angle_deb, angle_total, ratio
		radial_special_center_nil lst_ray, markdeb, markend, angle_total, nb
	end	

	#Special treatment for Sectors to join borders
	arrange_sectors if @type == CODE_Sector

	return
end

#Compute the circular shapes when center has a face	
def radial_special_center_OK(nb, angle_deb, angle_total, markdeb, markend)	

	#generating all shapes in rings
	normal = compute_normal_at_mark @mkcenter
	normal = normal.reverse if normal % @vcamera > 0
	origin = @mkcenter.pt
	distance = @radius1
	([0.0] + @palman.lst_rings).each do |delta|
		radius = distance + delta
		ratio = (@single || @distance2 == 0) ? 1.0 : ((@radius2 + delta) / (@radius1 + delta))
		next if radius <= 0.0
		lst_ray = radial_list_rays nb, angle_deb, angle_total, ratio
		lst_vert = []
		lst_ray.each do |ray|
			t = Geom::Transformation.rotation origin, normal, ray.angle
			vec = @vecref1.transform t
			parcours = Junction.to_distance @mkcenter, vec, ray.dfactor * radius
			mkvert = parcours.last
			lst_vert.push mkvert
		end	
		
		#Imposing vertices at extremities
		radial_impose_extremities lst_vert, delta, markdeb, markend if markdeb && markend
		
		#generating the Shapedraw structure
		shapedraw = generate_shapedraw lst_vert, delta
		@lst_shapedraw.push shapedraw
	end
end	

#Compute the circular shapes when center has no face	
def radial_special_center_nil(lst_ray, markdeb, markend, angle_total, nb)	
	([0.0] + @palman.lst_rings).each do |delta|
		#Computing the initial point
		radius = @radius1 + delta
		next if radius <= 0.0		#ring too small
		vecdir = @parcours2[-2].pt.vector_to @parcours2.last.pt
		if (delta != 0.0)
			parcours = Junction.to_distance @parcours2.last, vecdir, delta
			topmark = parcours.last
		else
			topmark = @parcours2.last
		end	
		
		angle_unit = angle_total / nb
		d0 = radius * angle_unit
		
		#Right quadran
		prev_mark = topmark
		prev_normal = absolute_normal_at_mark prev_mark
		prev_vec = vecdir * prev_normal
		lvert1 = []
		angledeb = angle_unit * 0.5
		nb2 = (nb / 2) - 1
		for i in 0..nb2
			t = Geom::Transformation.rotation prev_mark.pt, prev_normal, angledeb - angle_unit
			vec = prev_vec.transform t
			parcours = Junction.to_distance prev_mark, vec, d0
			prev_mark = parcours.last
			prev_normal = absolute_normal_at_mark prev_mark
			prev_vec = parcours[-2].pt.vector_to prev_mark.pt
			lvert1.push prev_mark
			angledeb = 0
		end	

		#Left quadrant
		prev_mark = topmark
		prev_normal = absolute_normal_at_mark prev_mark
		prev_vec = prev_normal * vecdir
		lvert2 = []
		angledeb = -angle_unit * 0.5
		nb2 = (nb / 2) - 1
		for i in 0..nb2
			t = Geom::Transformation.rotation prev_mark.pt, prev_normal, angledeb + angle_unit
			vec = prev_vec.transform t
			parcours = Junction.to_distance prev_mark, vec, d0
			prev_mark = parcours.last
			prev_normal = absolute_normal_at_mark prev_mark
			prev_vec = parcours[-2].pt.vector_to prev_mark.pt
			lvert2.push prev_mark
			angledeb = 0
		end	
		
		#Joining the parcours
		lst_vert = lvert2.reverse + [topmark] + lvert1
		radial_impose_extremities lst_vert, delta, markdeb, markend if delta == 0 && markdeb && markend
		
		#generating the Shapedraw structure
		shapedraw = generate_shapedraw lst_vert, delta
		@lst_shapedraw.push shapedraw
	end
end	

#Create Sectors
def arrange_sectors
	#Sorting the list of sectors
	lsd = @lst_shapedraw.sort { |s1, s2| -s1.delta <=> -s2.delta }
	
	#Joining the borders
	lsdnew = []
	nb = lsd.length - 1
	i = 0
	while (i <= nb)
		lsd1 = lsd[i].lmk_vertices
		lsd2 = (i == nb) ? [@mkcenter] : lsd[i+1].lmk_vertices
		lst_vert = lsd1 + lsd2.reverse + [lsd1.first]
		lst_hard = [lsd1.first.pt, lsd1.last.pt, lsd2.first.pt, lsd2.last.pt]
		sd = generate_shapedraw lst_vert, lsd[i].delta, lst_hard
		lsdnew.push sd
		i += 2
	end	
	@lst_shapedraw = lsdnew	
end

end	#class TOSShape

	
end	#End Module SUToolsOnSurface
