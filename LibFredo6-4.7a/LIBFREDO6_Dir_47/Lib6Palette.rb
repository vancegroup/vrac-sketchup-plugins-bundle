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
# Name			:   Lib6Palette.rb
# Original Date	:   8 May 2009 - version 1.0
# Description	:   Interactive button palette management
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end


module Traductor

T6[:T_DLG_EdgePlain] = "Plain"
T6[:T_DLG_EdgeAll] = "ALL"

T6[:Palette_TIP_TipZone] = "Information area"
T6[:Palette_TIP_MsgZone] = "Message area"
T6[:Palette_TIP_Pos] = "Position Top or Bottom"
T6[:Palette_TIP_Shrink] = "Shrink / Expand Palette"
T6[:Palette_TIP_MsgVisible] = "Show / Hide message area"
T6[:Palette_TIP_SideLeft] = "Position Left or Right"

T6[:DEFAULT_SectionPalette] = "Palette Configuration"
T6[:DEFAULT_PalettePos] = "Palette in Top position"
T6[:DEFAULT_PaletteShrinked] = "Palette shrinked"
T6[:DEFAULT_PaletteSideLeft] = "Palettes on Left side"
T6[:DEFAULT_PaletteMessageZone] = "Show Message area"

T6[:T_TIP_Increment] = "Increment value"
T6[:T_TIP_Decrement] = "Decrement value"

T6[:T_TIP_EditionUndo] = "Undo change"
T6[:T_TIP_EditionRedo] = "Redo last action"
T6[:T_TIP_EditionReset] = "Cancel all changes"
T6[:T_TIP_EditionRestore] = "Restore all changes"

#--------------------------------------------------------------------------------------------------------------
# Button Palette
#--------------------------------------------------------------------------------------------------------------			 

class Palette

#Structure for an individual button
@@lpat = [:draw_refresh, :draw_extra_proc, 
		  :action_proc, :value_proc, :grayed_proc, :hidden_proc, :tip_proc, :text_proc, :long_click_proc, :double_click_proc,
          :row, :sepa, :width, :height, :hidden, :bk_color, :hi_color, :rank, :tooltip, :text, :sel_text, :passive,
	      :main_color, :frame_color, :type, :edge_prop, :stipple, :default_value, :blason, :fkey, :draw_scale, :justif,
		  :value, :radio, :input, :floating, :family, :tab_style]

Palette_Button6 = Struct.new :symb, :state, :tr, :tr1, :tr2, :tr_tx, :hidsepa, :composite, :bsuite,
                             :quad, :quad1, :quad2, :buttons, :draw_proc, :draw_code, :instructions,
							 :sel_instructions, :text_instructions, :text_sel_instructions,
                             :xleft, :ybot, :computed, :parent, :value, :multi, :grayed, :selected, 
							 :sidepal, :numval, :bfloating, :text_previous, :text_sel_previous,
							 *@@lpat

Palette_Floating6 = Struct.new :symb, :title, :hidden, :computed, :buttons, :but_rows, :cur_row, :quad_out, :quad_in, 
                               :quad_bd, :quad_tit, :pt_text, :line1, :line2, :line_tit, :xpos, :ypos, :empty,
							   :hidden_proc, :xpos0, :ypos0

attr_reader :top_pos, :shrinked, :side_left, :message_visi

def make_proc(&proc) ; proc ; end

@@persistence = nil

#----------------------------------------------------------------------------
# Managing default parameters
#----------------------------------------------------------------------------

#Configure Palette Default Parameters
def Palette.config_default_parameters
	MYDEFPARAM.separator :DEFAULT_SectionPalette
	MYDEFPARAM.declare :DEFAULT_PalettePos, true, 'B'
	MYDEFPARAM.declare :DEFAULT_PaletteShrinked, false, 'B'
	MYDEFPARAM.declare :DEFAULT_PaletteSideLeft, true, 'B'
	MYDEFPARAM.declare :DEFAULT_PaletteMessageZone, true, 'B'
end

#Saving parameters across sessions
def persistence_save
	@@persistence = {} unless @@persistence

	#Common to all tools
	hsh = @@persistence
	hsh["PalettePos"] = @top_pos
	hsh["PaletteShrinked"] = @shrinked	
	hsh["PaletteSideLeft"] = @side_left	
	hsh["PaletteMessageVisi"] = @message_visi	
end

#Restoring parameters across sessions
def persistence_restore
	hsh = @@persistence
	unless hsh
		hsh = @@persistence = {}
		hsh["PalettePos"] = MYDEFPARAM[:DEFAULT_PalettePos]
		hsh["PaletteShrinked"] = MYDEFPARAM[:DEFAULT_PaletteShrinked]
		hsh["PaletteSideLeft"] = MYDEFPARAM[:DEFAULT_PaletteSideLeft]
		hsh["PaletteMessageVisi"] = MYDEFPARAM[:DEFAULT_PaletteMessageZone]
	end
	@top_pos = hsh["PalettePos"]
	@shrinked = hsh["PaletteShrinked"]	
	@side_left = hsh["PaletteSideLeft"]	
	@message_visi = hsh["PaletteMessageVisi"]	
end

#----------------------------------------------------------------------------
# Initialization and declarations
#----------------------------------------------------------------------------

#Create a palette instance
def initialize(*args)
	#SU context
	@model = Sketchup.active_model
	@render = @model.rendering_options
	
	#Default value
	@height = 32
	@top_pos = true
	@message = nil
	@main_tooltip = ""
	@long_click_duration = 1
	persistence_restore

	#Patterns for button parameter settings
	@std_pats = @@lpat.collect { |symb| Regexp.new("\\A" + symb.to_s, Regexp::IGNORECASE) }
	
	#Parsing the arguments
	args.each do |arg|	
		arg.each { |key, value|  parse_palette_args(key, value) } if arg.class == Hash
	end
	
	#initialization of lists and hash tables	
	@lst_symbs = nil
	@lst_buttons = []
	@hsh_buttons = {}
	@button_blasons = []
	
	@hsh_sides = {}
	@lst_sides = []
	@default_sidepal = :__side__pal
	
	@hsh_floats = {}
	@lst_floats = []
	@auto_hide_floats = false
		
	@hsh_visible_families = {}
	@current_family = nil
	
	#Geometric transformation initialization
	@height2 = @height / 2
	@widmax_tip = 400 unless @widmax_tip
	@wid_ctrl = @height
	@lrectnum = [0, 0, 1, 1]
	@tra_basis = [1, 0, 0, 0] + [0, -1, 0, 0] + [0, 0, 1, 0] + [0, 0, 0, 1]
	@computed = false	
	@ptxy = Geom::Point3d.new 0, 0, 0
	@origin = Geom::Point3d.new 0, @height, 0
	
	#Color initialization
	@bkcolor_normal = 'lightgrey'
	@bkcolor_hilight = 'lightgrey'
	@bkcolor_selected = 'oldlace'
	@bkcolor_title1_u = 'silver'
	@bkcolor_title1_d = 'gainsboro'
	@bkcolor_down = 'oldlace'
	@bkcolor_blason = 'khaki'
	@frcolor_blason = 'gold'
	@frcolor_white = 'white'
	@frcolor_gray = 'gray'
	@frcolor_dark = 'darkgray'
	@frcolor_float = 'darkgray'
	@bkcolor_float = 'khaki'
	@bdcolor_float = 'silver'
	@titcolor_float = 'khaki'
	@hibkcolor_float = 'silver'
	@hifrcolor_float = 'red'
	
	@id_cursor_hand = MYPLUGIN.create_cursor "Cursor_Hand", 9, 2	
	@id_cursor_arrow = MYPLUGIN.create_cursor "Cursor_ArrowPal", 2, 2	
	@id_cursor_move = MYPLUGIN.create_cursor "Cursor_Move_16", 7, 7	
	
	@tooltip = ""
	@nb_sepa = 0
	
	@view = Sketchup.active_model.active_view
	
	#Open GL instance for drawing buttons
	@ogl = Traductor::OpenGL_6.new
	@standard_draw_proc = @ogl.method "draw_proc"
	
	#Create the standard buttons
	@button_shrink = create_button :_bt_shrink, { :tooltip => T6[:Palette_TIP_Shrink], :width => @height2, :rank => 1 }
	@button_pos = create_button :_bt_pos, { :tooltip => T6[:Palette_TIP_Pos], :width => @height2 }
	@button_msg_visi = create_button :_bt_msg_visi, { :tooltip => T6[:Palette_TIP_MsgVisible], :width => @height2, 
	                                 :rank => 1, :text => '--' }
	@button_sideleft = create_button :_bt_sideleft, { :tooltip => T6[:Palette_TIP_SideLeft], :width => @height2 }
	@button_tip = create_button :_bt_tip, { :tooltip => T6[:Palette_TIP_TipZone], :passive => true, :justif => 'LT' }
	@button_message = create_button :_bt_message, { :tooltip => T6[:Palette_TIP_MsgZone], :passive => true, 
	                                                :height => 16, :hidden => true, :justif => 'LT' }
	adjust_draw_standard_button
end

#Assign the individual propert for the palette
def parse_palette_args(key, value)
	skey = key.to_s
	case skey
	when /top_pos/i
		@top_pos = value
	when /shrinked/i
		@shrinked = value
	when /height/i
		@height = value
	when /proc/i
		@palette_proc = value
	when /width_message_min/i
		@widmin_tip = value
	when /width_message/i
		@widmax_tip = value
	when /long_click_duration/i
		@long_click_duration = value
	when /key_registry/i
		@key_registry = value.to_s
	end	
end

#Parse the properties of a button
def parse_button_args(button, key, value)
	skey = key.to_s
	param = @std_pats.find { |pat| skey =~ pat }
	if param
		eval "button.#{param.source[2..-1]} = value"
		button.computed = false
		return
	end
	
	#Special treatment
	case skey
	when /parent/i
		button_set_parent button, value
	when /draw_proc/i
		if value.class == Symbol || value.class == Array
			button.draw_proc = @standard_draw_proc
			button.draw_code = value
		else
			button.draw_proc = value
		end	
	when /sidepal/i
		button.sidepal = (value.class == Symbol) ? value : @default_sidepal
	end
	button.computed = false
	
end

#Return the button structure from its symbol
def [](symb)
	@hsh_buttons[symb]
end

#Return the main tooltip of the palette
def get_main_tooltip
	@main_tooltip
end
	
#Get the button value state
def button_get_value(symb=nil)
	button = (symb) ? @hsh_buttons[symb] : @sel_button
	(button) ? button.value : nil
end

#Get the button value state
def button_is_grayed?(symb=nil)
	button = (symb) ? @hsh_buttons[symb] : @sel_button
	button.grayed
end

#Create a button structure
def create_button(symb, *args, &action_proc)
	button = @hsh_buttons[symb]
	button = Palette_Button6.new unless button
	button.symb = symb
	button.hidden = false
	button.grayed = false
	button.action_proc = action_proc
	button.family = @current_family
	args.each do |arg|	
		arg.each { |key, value|  parse_button_args(button, key, value) } if arg.class == Hash
	end
	@hsh_buttons[symb] = button
	button
end

#Declare the parent of a button
def button_set_parent(button, sparent)
	parent = @hsh_buttons[sparent]
	parent = create_button sparent unless parent
	parent.buttons = [] unless parent.buttons
	parent.buttons.push button unless parent.buttons.include?(button)
	button.parent = parent
end

#Set the parameters for a button as a hash table of properties
def button_set_args(symb, *args)
	button = @hsh_buttons[symb]
	return unless button
	args.each do |arg|	
		arg.each { |key, value|  parse_button_args(button, key, value) } if arg.class == Hash
	end
	button.computed = false
	@computed = false
end

def button_set_draw_proc(symb, draw_proc, main_color=nil, frame_color=nil)
	button = @hsh_buttons[symb]
	return unless button
	parse_button_args button, :draw_proc, draw_proc
	parse_button_args button, :main_color, main_color if main_color
	parse_button_args button, :frame_color, frame_color if frame_color
	button.instructions = nil
end

def adjust_draw_standard_button
	button_set_draw_proc :_bt_shrink, ((@shrinked) ? :square_P : :cross_NE2), "red"
	button_set_draw_proc :_bt_pos, ((@top_pos) ? :triangle_SP : :triangle_NP), "green"
	button_set_draw_proc :_bt_msg_visi, ((@message_visi) ? :square_1 : :square_P), "yellow"
	button_set_draw_proc :_bt_sideleft, ((@side_left) ? :triangle_EP : :triangle_WP), "green"
end

#Declare a button
def declare_button(symb, *args, &action_proc)
	button = create_button symb, *args, &action_proc
	button_input_manage button if button.input
	if button.blason
		@button_blasons.push button
	elsif button.sidepal
		add_button_to_side button
	elsif button.floating
		add_button_to_floating button
	else
		@lst_buttons.push button unless button.parent
	end	
	@computed = false

	symb
end

#Declare a separator
def declare_separator
	s = '__sepa__' + @nb_sepa.to_s
	@nb_sepa += 1
	symb = s.intern
	declare_button symb, { :sepa => true, :passive => true, :height => @height, :width => @height / 3, 
	                       :draw_proc => :separator_V }
	symb
end

#Declare a separator for a side palette
def declare_separator_side(sidepal=nil, *args)
	s = '__sepa__' + @nb_sepa.to_s
	@nb_sepa += 1
	symb = s.intern
	declare_button symb, { :sidepal => sidepal, :passive => true, :height => @height / 3, :width => @height, 
	                       :draw_proc => :separator_H }, *args
	symb
end

#Declare a separator for a side palette
def declare_separator_floating(symb_float, *args)
	s = '__sepa__' + @nb_sepa.to_s
	@nb_sepa += 1
	symb = s.intern
	declare_button symb, { :floating => symb_float, :sepa => true, :passive => true, :height => @height, :width => @height / 3, 
	                       :draw_proc => :separator_V }
	symb
end

#Utility to form a sumbol from a symbol and text to append
def concat_symb(symb, text)
	s = symb.to_s + '___' + text
	s.intern
end

#Set the current family key for the subsequent button creation
def set_current_family(family=nil)
	@current_family = family
end

#Declare the visible families
def visible_family(*lst_families)
	@hsh_visible_families = {}
	lst_families.each { |family| @hsh_visible_families[family] = true }
	@computed = false
end

#----------------------------------------------------------------------------
# Special buttons: Edge properties
#----------------------------------------------------------------------------

#Declare a button set for edge property control
def declare_edge_prop(symb, rgshow, *args, &action_proc)
	declare_button(symb, { :type => 'multi' }, *args, &action_proc)
	button = @hsh_buttons[symb]
	hp = { :parent => symb, :width => 27, :main_color => button.main_color }
	button.edge_prop = 'PSMH' unless button.edge_prop
	list = []
	list.push ['P', T6[:T_DLG_EdgePlain], :edge_prop_plain] if button.edge_prop =~ /P/i
	list.push ['S', T6[:T_DLG_EdgeSoft], :edge_prop_soft] if button.edge_prop =~ /S/i
	list.push ['M', T6[:T_DLG_EdgeSmooth], :edge_prop_smooth] if button.edge_prop =~ /M/i
	list.push ['H', T6[:T_DLG_EdgeHidden], :edge_prop_hidden] if button.edge_prop =~ /H/i
	list.each do |ll|
		code, tip, sdraw = ll
		next unless !rgshow || code =~ rgshow
		declare_button concat_symb(symb, code), hp, { :draw_proc => sdraw, :value => code, :tooltip => tip }
	end	
	symb
end

#----------------------------------------------------------------------------
# Special buttons: Edge properties
#----------------------------------------------------------------------------

#Declare a button set for extended edge property control
# - get_proc and set_proc manipulates a Hash array of property: :smooth, :soft, :hidden, :cast_shadows
def declare_edge_prop_extended(prefix, symb, get_proc, set_proc, *hargs)
	#Plain and Diagonal
	hshb = { :width => 24, :height => 16 }
	value_proc = proc { a = get_proc.call(symb) ; a[:soft] == -1 && a[:smooth] == -1 && a[:hidden] == -1 && a[:cast_shadows] == 1 }
	action_proc = proc { a = get_proc.call(symb) ; a[:soft] = a[:smooth] = a[:hidden] = -1 ; a[:cast_shadows] = 1 ; set_proc.call symb, a }
	s = "#{prefix}__EPX_Plain".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_plain, :tooltip => T6[:T_DLG_EdgePlain], :rank => 1 }
	declare_button(s, hshb, hsh, { :rank => 1 }, *hargs, &action_proc)
	
	value_proc = proc { a = get_proc.call(symb) ; a[:soft] == 0 && a[:smooth] == 0 && a[:hidden] == 0 && a[:cast_shadows] == -1 }
	action_proc = proc { a = get_proc.call(symb) ; a[:soft] = a[:smooth] = a[:hidden] = 0 ; a[:cast_shadows] = -1 ; set_proc.call symb, a }
	s = "#{prefix}__EPX_Diagonal".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_diagonal, :tooltip => T6[:T_DLG_EdgeDiagonal] }
	declare_button(s, hshb, hsh, *hargs, &action_proc)

	declare_separator
	
	#Soft
	hshb = { :width => 32, :height => 16 }
	value_proc = proc { a = get_proc.call(symb) ; a[:soft] == 1 }
	action_proc = proc { a = get_proc.call(symb) ; a[:soft] = (a[:soft] == 1) ? 0 : 1 ; set_proc.call symb, a }
	s = "#{prefix}__EPX_Soft".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_soft, :tooltip => T6[:T_DLG_EdgeSoft], :rank => 1 }
	declare_button(s, hshb, hsh, *hargs, &action_proc)
	
	value_proc = proc { a = get_proc.call(symb) ; a[:soft] == -1 }
	action_proc = proc { a = get_proc.call(symb) ; a[:soft] = (a[:soft] == -1) ? 0 : -1 ; set_proc.call symb, a }
	s = "#{prefix}__EPX_SoftNo".intern
	hsh = { :value_proc => value_proc, :draw_proc => [:edge_prop_soft, :std_negation], :tooltip => T6[:T_DLG_EdgeSoft] }
	declare_button(s, hshb, hsh, *hargs, &action_proc)

	#Smooth
	value_proc = proc { a = get_proc.call(symb) ; a[:smooth] == 1 }
	action_proc = proc { a = get_proc.call(symb) ; a[:smooth] = (a[:smooth] == 1) ? 0 : 1 ; set_proc.call symb, a }
	s = "#{prefix}__EPX_Smooth".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_smooth, :tooltip => T6[:T_DLG_EdgeSmooth], :rank => 1 }
	declare_button(s, hshb, hsh, *hargs, &action_proc)
	
	value_proc = proc { a = get_proc.call(symb) ; a[:smooth] == -1 }
	action_proc = proc { a = get_proc.call(symb) ; a[:smooth] = (a[:smooth] == -1) ? 0 : -1 ; set_proc.call symb, a }
	s = "#{prefix}__EPX_SmoothNo".intern
	hsh = { :value_proc => value_proc, :draw_proc => [:edge_prop_smooth, :std_negation], :tooltip => T6[:T_DLG_EdgeSmooth] }
	declare_button(s, hshb, hsh, *hargs, &action_proc)
	
	#Hidden
	value_proc = proc { a = get_proc.call(symb) ; a[:hidden] == 1 }
	action_proc = proc { a = get_proc.call(symb) ; a[:hidden] = (a[:hidden] == 1) ? 0 : 1 ; set_proc.call symb, a }
	s = "#{prefix}__EPX_Hidden".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_hidden, :tooltip => T6[:T_DLG_EdgeHidden], :rank => 1 }
	declare_button(s, hshb, hsh, *hargs, &action_proc)
	
	value_proc = proc { a = get_proc.call(symb) ; a[:hidden] == -1 }
	action_proc = proc { a = get_proc.call(symb) ; a[:hidden] = (a[:hidden] == -1) ? 0 : -1 ; set_proc.call symb, a }
	s = "#{prefix}__EPX_HiddenNo".intern
	hsh = { :value_proc => value_proc, :draw_proc => [:edge_prop_hidden, :std_negation], :tooltip => T6[:T_DLG_EdgeHidden] }
	declare_button(s, hshb, hsh, *hargs, &action_proc)

	#Cast Shadows
	value_proc = proc { a = get_proc.call(symb) ; a[:cast_shadows] == 1 }
	action_proc = proc { a = get_proc.call(symb) ; a[:cast_shadows] = (a[:cast_shadows] == 1) ? 0 : 1 ; set_proc.call symb, a }
	s = "#{prefix}__EPX_CastShadows".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_cast_shadows, :tooltip => T6[:T_DLG_EdgeCastShadows], :rank => 1 }
	declare_button(s, hshb, hsh, *hargs, &action_proc)
	
	value_proc = proc { a = get_proc.call(symb) ; a[:cast_shadows] == -1 }
	action_proc = proc { a = get_proc.call(symb) ; a[:cast_shadows] = (a[:cast_shadows] == -1) ? 0 : -1 ; set_proc.call symb, a }
	s = "#{prefix}__EPX_CastShadowsNo".intern
	hsh = { :value_proc => value_proc, :draw_proc => [:edge_prop_cast_shadows, :std_negation], :tooltip => T6[:T_DLG_EdgeCastShadows] }
	declare_button(s, hshb, hsh, *hargs, &action_proc)
	
	symb
end

#----------------------------------------------------------------------------
# Special buttons: Stipple properties
#----------------------------------------------------------------------------

#Declare a button set for edge property control
def declare_stipple(symb, *args, &action_proc)
	declare_button(symb, { :type => 'multi', :radio => true }, *args, &action_proc)
	button = @hsh_buttons[symb]
	hp = { :parent => symb, :width => 25, :main_color => button.main_color, :hi_color => button.hi_color }
	stipple = button.stipple
	stipple = 'DUPA' unless stipple
	list = []
	list.push ['C', T6[:T_TIP_Stipple_Continuous]] if stipple =~ /C/i
	list.push ['D', T6[:T_TIP_Stipple_Dash]] if stipple =~ /D/i
	list.push ['U', T6[:T_TIP_Stipple_Underscore]] if stipple =~ /U/i
	list.push ['P', T6[:T_TIP_Stipple_Dot]] if stipple =~ /P/i
	list.push ['A', T6[:T_TIP_Stipple_Alternate]] if stipple =~ /A/i
	list.each do |ll|
		code, tip = ll
		sdraw = "line_#{code}2".intern
		declare_button concat_symb(symb, code), hp, { :draw_proc => sdraw, :value => code, :tooltip => tip }
	end	
	symb
end

#----------------------------------------------------------------------------
# Special buttons: Input field
#----------------------------------------------------------------------------

def button_input_manage(button)
	input = button.input
	button.text_proc = make_proc() { input.compute_show_text } unless button.text_proc
	button.action_proc = make_proc() { input.dialog_ask } unless button.action_proc
	button_input_increment(button) if input.vincr || input.vbound_proc
end

def button_input_increment(button)
	#dec = 14
	dec = 13
	button.width -= 2 * dec
	button.composite = :plus_minus
	ss = button.symb.to_s
	hsh = { :height => button.height, :width => dec, :rank => button.rank, :row => button.row, 
	        :bk_color => button.bk_color, :main_color => 'gray' }
	
	symb = (ss + '___plus').intern	
	gray_proc = make_proc() { button.input.reached_max? }
	hshplus = { :draw_proc => :triangle_EP, :grayed_proc => gray_proc, :tooltip => T6[:T_TIP_Increment] }
	bplus = create_button(symb, hsh, hshplus) { button.input.increment }
	button_set_parent bplus, button.symb
	bplus.bfloating = button.bfloating
	
	symb = (ss + '___minus').intern
	gray_proc = make_proc() { button.input.reached_min? }
	hshminus = { :draw_proc => :triangle_WP, :grayed_proc => gray_proc, :tooltip => T6[:T_TIP_Decrement] }
	bminus = create_button(symb, hsh, hshminus) { button.input.decrement }
	button_set_parent bminus, button.symb
	bminus.bfloating = button.bfloating
	
	button.bsuite = [bminus, button, bplus]
end

#----------------------------------------------------------------------------
# Historical button group
#----------------------------------------------------------------------------

#Declare a button
def declare_historical(symb, *args, &action_proc)
	#Parsing the args specific to the Historical button group
	grayed_proc = nil
	tip_proc = nil
	compact = false
	title = 'Edition'
	floating = nil

	args.each do |arg|	
		next unless arg.class == Hash
		arg.each do |key, value| 
			skey = key.to_s
			case skey
			when /grayed_proc/i
				grayed_proc = value
			when /tip_proc/i
				tip_proc = value
			when /compact/i	
				compact = value
			when /title/i
				title = value
			when /floating/i
				floating = value
			end	
		end
	end
	
	#List of buttons
	lsbut = [[:undo, 1, :std_undo, 'black', T6[:T_TIP_EditionUndo], [:escape, :arrow_left]],
			 [:clear, 0, :cross_NE3, 'red', T6[:T_TIP_EditionReset], [:arrow_down]],
	         [:redo, 1, :std_redo, 'black', T6[:T_TIP_EditionRedo], [:arrow_right]],
			 [:restore, 0, :std_restore, 'green', T6[:T_TIP_EditionRestore], [:arrow_up]]]
			 
	#Creating the buttons
	libut = (compact) ? [0, 1, 2, 3] : [1, 0, 2, 3]
	wid = hgt = 16
	if !compact && title
		hsh = { :passive => true, :text => title, :height => hgt, :width => 4 * wid, :rank => 1 }
		h = args + [hsh]
		declare_button symb, *h
	end	
	libut.each do |i|		
		info = lsbut[i]
		ss = symb.to_s + info[0].to_s
		rank = (compact) ? info[1] : 0
		hsh = { :height => hgt, :width => wid, :rank => rank,
		        :draw_proc => info[2], :frame_color => info[3] }
		hsh[:grayed_proc] = make_proc() { grayed_proc.call info[0] } if grayed_proc
		hsh[:tip_proc] = make_proc() { tip_proc.call info[0] } if tip_proc
		hsh[:action_proc] = make_proc() { action_proc.call info[0] } if action_proc
		hsh[:tooltip] = Traductor.encode_tip info[4], info[5]
		h = args + [hsh]
		declare_button ss.intern, *h
	end	
end

#----------------------------------------------------------------------------
# Side Palete
#----------------------------------------------------------------------------

#Register a button in a side palette
def add_button_to_side(button)
	sidepal = button.sidepal
	lst = @hsh_sides[sidepal.to_s]
	unless lst
		lst = @hsh_sides[sidepal.to_s] = []
		@lst_sides.push lst
	end
	lst.push button
end

#Compute the side palettes
def compute_side_palettes
	#Computing maximum width of buttons
	@total_width_side = 0
	vpwidth = @view.vpwidth
	vpheight = @view.vpheight
	lwidmax = []
	totwid = 0
	@lst_sides.each_with_index do |lst, i|
		lst.each { |button|	lwidmax[i] = button.width unless button.hidden }
		totwid += lwidmax[i]
	end	
	
	#No visible buttons in the side palette
	@visible_sidepal = (totwid > 0)
	return unless @visible_sidepal
	
	#Dimensions and starting points
	@total_width_side = totwid	
	hpal = @total_height + 1
	xbeg = 0
	ybeg = (@top_pos) ? hpal-1 : vpheight - hpal
	
	#Computing the position of the buttons
	lhgtmax = []
	xpos = xbeg
	@lst_sides.each_with_index do |lst, i|
		lhgtmax[i] = 0
		next if lwidmax[i] == 0
		ypos = ybeg
		lst.each do |button|
			next if button.hidden
			ypos += button.height if @top_pos && button.rank == 0
			h = (@top_pos || button.rank == 0) ? 0 : button.height
			button_transfo button, xpos + button.rank * button.width, ypos + h
			ypos -= button.height if !@top_pos && button.rank == 0
			lhgtmax[i] += button.height if button.rank == 0
		end
		xpos += lwidmax[i] + 1
	end
	
	#Computing the quad for the side palettes
	@total_height_side = lhgtmax.max + 4
	@xbeg_side = xbeg
	@ybeg_side = ybeg
	xmin = xbeg
	xmax = xmin + @total_width_side
	ymin = ybeg
	ymax = ymin + @total_height_side * ((@top_pos) ? 1 : -1)
	@quad_sidepal = []
	@quad_sidepal.push Geom::Point3d.new(xmin, ymin)
	@quad_sidepal.push Geom::Point3d.new(xmax, ymin)
	@quad_sidepal.push Geom::Point3d.new(xmax, ymax)
	@quad_sidepal.push Geom::Point3d.new(xmin, ymax)
	
end

#----------------------------------------------------------------------------
# Floating palette
#----------------------------------------------------------------------------

#Declare a floating palette
def declare_floating(symb, *args)
	#Creating the data structure if not already created
	floating = @hsh_floats[symb]
	unless floating
		floating = Palette_Floating6.new
		floating.symb = symb
		floating.buttons = []
		floating.but_rows = []
		floating.cur_row = 0
		floating_initial_position floating
		@hsh_floats[symb] = floating
		@lst_floats.push floating
	end
	
	#parsing the arguments
	args.each do |arg|	
		arg.each { |key, value|  parse_floating_args(floating, key, value) } if arg.class == Hash
	end
	symb
end

#Set the auto_hide mode for floating palettes
def auto_hide_floating(on=false)
	@auto_hide_floats = on
	@hidden_floating = nil
end

def show_hide_floating(symb_float, show=true)
	floating = @hsh_floats[symb_float]
	return false if floating == nil || floating.hidden == !show
	floating.hidden = !show
	true
end

#Calculate or retrieve the initial position of the floating palette
def floating_initial_position(floating)
	xpos = ypos = nil
	if @key_registry
		ss = 'Floating_Palette_' + floating.symb.to_s
		sxypos = Sketchup.read_default @key_registry, ss
		if sxypos
			l = sxypos.split ';'
			xpos = Traductor.string_to_integer l[0]
			ypos = Traductor.string_to_integer l[1]
		end	
	end	
	floating.xpos = (xpos) ? xpos : 2000
	floating.ypos = (ypos) ? ypos : 60
	floating.xpos0 = floating.xpos
	floating.ypos0 = floating.ypos
end

#Store the floating palette position into the Sketchup registry
def floating_store_registry(floating)
	return unless @key_registry
	ss = 'Floating_Palette_' + floating.symb.to_s
	sxypos = floating.xpos.round.to_s + ';' + floating.ypos.round.to_s
	Sketchup.write_default @key_registry, ss, sxypos
end

#Check if a floating palette should be hidden
def floating_is_hidden?(floating)
	return true if floating.hidden || floating.empty || floating == @hidden_floating
	return true if floating.hidden_proc.call if floating.hidden_proc
	false
end
	
#Assign the individual property for the floating palette
def parse_floating_args(floating, key, value)
	skey = key.to_s
	case skey
	when /title/i
		floating.title = value
	when /xpos/i
		floating.xpos = value
	when /ypos/i
		floating.ypos = value
	when /hidden_proc/i
		floating.hidden_proc = value
	when /hidden/i
		floating.hidden = value
	end	
end

#Register a button in a side palette
def add_button_to_floating(button)
	#detremining the Floating palette object
	symb_float = button.floating
	floating = @hsh_floats[symb_float]
	unless floating
		declare_floating symb_float
		floating = @hsh_floats[symb_float]
	end
	button.bfloating = floating
	button.bsuite.each { |b| b.bfloating = floating } if button.bsuite
	
	#Adding the buttons to the floating palette
	unless button.parent
		floating.buttons.push button
		row = (button.row) ? button.row : floating.cur_row
		floating.cur_row = row if row
		floating.but_rows[row] = [] unless floating.but_rows[row]
		floating.but_rows[row].push button
	end	
end

#Compute the Floating palette - Position of buttons and palette
def compute_floating_palette(floating)
	#Dimension of the palette
	lxsize = []
	lysize = []
	hvsepa = 2
	sxmax = 0
	symax = 0
	lbmap = []
	floating.but_rows.each_with_index do |but_row, irow|
		no_vsepa = false
		x = sy = 0
		h = hvsepa
		cursepa = true
		xrank = 0
		curank = nil
		syprev = @height

		but_row.each do |button|
			next if button.hidden
			no_vsepa = true if button.tab_style
			if button.sepa
				if cursepa || button == but_row.last
					button.hidsepa = true
					next
				else
					button.hidsepa = false
					cursepa = true
				end
			else
				cursepa = false
			end	
			rank = button.rank
			if rank != curank #&& button.type !~ /multi/i
				h += button.height
				xrank = 0
			end	
			
			if button.type =~ /multi/i
				lbmap.push [button, irow, x + xrank, symax + h]
				xb = x
				h2 = 0
				button.buttons.each do |b|
					next if b.hidden
					h2 = b.height if h2 < b.height
					lbmap.push [b, irow, xb, symax + h + h2]
					xb += b.width
					no_vsepa = true if b.tab_style
				end
				x += button.width
				sy = h + h2 if sy < h
				h -= button.height
			elsif button.bsuite
				button.bsuite.each do |b|
					lbmap.push [b, irow, x + xrank, symax + h]
					x += b.width
					no_vsepa = true if b.tab_style
				end	
			else	
				lbmap.push [button, irow, x + xrank, symax + h]
				x += button.width if button.rank == 0
			end	
			
			sy = h if sy < h
			if rank == 0
				syprev = h - hvsepa
				h = hvsepa
				curank = nil
			else
				curank = rank
				xrank += button.width
			end	
		end	
		sxmax = x if x > sxmax
		if no_vsepa
			lysize[irow] = -(sy + ((irow == 0) ? 0 : 3))
			symax += sy + 2
		else	
			lysize[irow] = sy + hvsepa + ((irow == 0) ? 0 : 3)
			symax += sy + hvsepa + 2
		end	
	end
	
	#No buttons to display
	if lbmap.empty?
		floating.empty = true
		return
	end	
	floating.empty = false
	
	#Position of the palette
	delta = 5
	xpos = floating.xpos0
	ypos = floating.ypos0
	
	topmargin = delta
	if floating.title
		topmargin += 16
		wt = 6 * floating.title.length
		sxmax = wt if wt > sxmax
	end	
	w = sxmax + 2 * delta
	h = symax + topmargin + delta - 2
	
	#Making sure the floating palette remains within bounds
	xpos, ypos = floating_check_overlap xpos, ypos, w, h
	floating.xpos = xpos
	floating.ypos = ypos
	
	#Quads for the palette
	floating.quad_out = floating_make_quad xpos, ypos, w, h
	floating.quad_in = floating_make_quad xpos + delta, ypos + topmargin, sxmax, symax - 2
	floating.quad_bd = floating_make_quad xpos + delta, ypos + topmargin, sxmax + 1, symax - 2
	
	#Computing the row separators
	yline = ypos + topmargin 
	xbeg = xpos + delta
	xend = xpos + w - delta
	floating.line1 = []
	floating.line2 = []
	for i in 0..lysize.length-2
		next if lysize[i] < 0
		yline += lysize[i].abs
		floating.line1.push Geom::Point3d.new(xbeg, yline, 0), Geom::Point3d.new(xend, yline , 0)
		floating.line2.push Geom::Point3d.new(xbeg, yline - 1 , 0), Geom::Point3d.new(xend, yline - 1 , 0)
	end
	if floating.title
		yltext = ypos + 18
		floating.pt_text = Geom::Point3d.new xbeg, ypos, 0
		floating.line_tit = [Geom::Point3d.new(xpos, yltext, 0), Geom::Point3d.new(xpos + w, yltext , 0)]
		floating.quad_tit = floating_make_quad xpos, ypos, w, 18
	end	
		
	#Computing the final position of the buttons
	decx = xpos + delta
	decy = ypos + topmargin
	lbmap.each do |ll|
		button, irow, x, y = ll
		button_transfo button, x + decx, y + decy, true
	end		
end

#Check the position of the floating palette based on viewport and other existing palettes
def floating_check_overlap(xpos, ypos, w, h)
	vpwidth = @view.vpwidth
	vpheight = @view.vpheight

	xpos = vpwidth - w - 1 if xpos + w > vpwidth
	xpos = 0 if xpos < 0
	ypos = vpheight - h - 1 if ypos + h > vpheight
	ypos = 0 if ypos < 0

	[xpos, ypos]
end

#generic routine to build a quad
def floating_make_quad(x, y, width, height)
	pt1 = Geom::Point3d.new x, y, 0
	pt2 = Geom::Point3d.new x + width, y, 0
	pt3 = Geom::Point3d.new x + width, y + height, 0
	pt4 = Geom::Point3d.new x, y + height, 0
	[pt1, pt2, pt3, pt4]
end

#Draw the floating palette background and title
def draw_floating_background(view, floating)
	#return if floating.hidden || floating.empty || floating == @hidden_floating
	return if floating_is_hidden?(floating)

	if floating == @mouse_floating && @origin_floating
		bkcolor = @hibkcolor_float
		frcolor = @hifrcolor_float
		wid = 2
	else
		bkcolor = @bkcolor_float
		frcolor = @frcolor_float
		wid = 1
	end
	stipple = (@origin_floating) ? '-' : ''
	
	view.drawing_color = bkcolor
	view.line_width = wid
	view.line_stipple = stipple
	view.draw2d GL_QUADS, floating.quad_out
	if floating.title
		view.drawing_color = @titcolor_float
		view.draw2d GL_QUADS, floating.quad_tit
	end	
	view.drawing_color = @bkcolor_normal
	view.draw2d GL_QUADS, floating.quad_in
	view.drawing_color = frcolor
	view.draw2d GL_LINE_LOOP, floating.quad_out
	view.drawing_color = @bdcolor_float
	view.line_width = 1
	view.draw2d GL_LINE_LOOP, floating.quad_bd
	if floating.title
		view.line_stipple = ''
		G6.view_draw_text view, floating.pt_text, floating.title
		view.drawing_color = @frcolor_dark
		view.draw2d GL_LINES, floating.line_tit
		view.drawing_color = @frcolor_white
		view.draw2d GL_LINES, floating.line1 unless floating.line1.empty?
		view.drawing_color = @frcolor_dark
		view.draw2d GL_LINES, floating.line2 unless floating.line2.empty?	
	end	
end

#Locate the floating frame where the mouse is
def locate_floating_frame(ptxy)
	@lst_floats.each do |floating|
		next if floating_is_hidden?(floating)
		if Geom.point_in_polygon_2D(ptxy, floating.quad_out, true)
			if @mouse_floating != floating
				@mouse_floating_frame = !Geom.point_in_polygon_2D(ptxy, floating.quad_in, false)
				@mouse_floating = floating
				@view.invalidate
			end	
			return true
		end	
	end	
	@mouse_floating = nil
	false
end

#Locate the floating frame where the mouse is
def test_auto_hide_floating(x, y)
	return false unless @auto_hide_floats
	ptxy = Geom::Point3d.new x, y, 0
	@hidden_floating = nil
	@lst_floats.each do |floating|
		next if floating_is_hidden?(floating)
		if Geom.point_in_polygon_2D(ptxy, floating.quad_out, true)
			@hidden_floating = floating
			return true
		end	
	end	
	false
end

#Move a palette to a new origin
def move_floating(floating, x, y)
	return if floating.xpos == x && floating.ypos == y
	floating.xpos = floating.xpos0 = x
	floating.ypos = floating.ypos0 = y
	compute_floating_palette floating
	@view.invalidate
end

#Move current highlighted palette
def move_current_floating(x, y)
	floating = @mouse_floating
	x += @origin_floating[0]
	y += @origin_floating[1]
	move_floating floating, x, y 
end

#Terminate the move of the floating palette
def end_move_floating
	floating_store_registry @mouse_floating if @mouse_floating
end

#----------------------------------------------------------------------------
# Computation methods for button and Palette
#----------------------------------------------------------------------------

#Compute a button
def compute_button(button, forced=false)
	return if button.computed && !forced
	return compute_multi(button, forced) if button.type =~ /multi/i
	return if button.parent && button.parent.type =~ /multi/i
	button.rank = 0 unless button.rank
	button.width = button.height unless button.width
	button.width = @height unless button.width
	button.height = button.width unless button.height
	button_make_quads button
	
	if button.composite && button.buttons
		button.buttons.each { |b| compute_button b, true }
	end
	
	button.computed = true
end

#Compute a multi-set of buttons
def compute_multi(button, forced=false)
	return if button.computed && !forced
	w = 0
	button.height = @height2 unless button.height
	button.buttons.each do |b|
		b.rank = 0
		b.height = button.height unless b.height
		b.computed = false
		b.floating = button.floating
		b.bfloating = button.bfloating
		compute_button b
		w += b.width unless b.hidden
		button_make_quads b
		b.computed = true
	end
	button.width = w
	button.rank = 1
	button_make_quads button
	####button.multi = true
	button.multi = true if button.type =~ /\Amulti\Z/i
	button.computed = true
end

def button_make_quads(button)
	button.quad = make_quad button.width, button.height
	button.quad1 = make_quad button.width, button.height, 1
	button.quad2 = make_quad button.width, button.height, 2
end

def check_multi_state(button)
	sval = button.value_proc.call if button.value_proc
	button.value = sval
	if button.radio
		lv = [sval]
	elsif sval.is_a? String
		lv = (sval) ? sval.split(';;') : nil
	else
		lv = sval
	end
	button.buttons.each do |b|
		if b.value
			b.selected = (lv && !lv.include?(b.value)) ? false : true
		else
			b.selected = false
		end	
	end	
end

#Calculate the button tooltip
def button_compute_tooltip(button)
	tip = nil
	if button.tip_proc
		tip = button.tip_proc.call
	end
	unless tip
		if button.tooltip
			tip = button.tooltip
		elsif button.fkey && button.value_proc
			tip = button.fkey.build_text button.value_proc.call, true
		end
	end	
	(tip) ? tip : ""
end

def button_in_family?(button)
	button.family == nil || @hsh_visible_families.length == 0 || @hsh_visible_families[button.family]
end

def compute_button_state(button)
	if button.multi
		check_multi_state button
	elsif button.value_proc
		button.selected = button.value_proc.call
	end	
end

#Recompute the whole set of palettes
def compute_all
	@hsh_buttons.each { |symb, button|	compute_button button } unless @computed
	
	#List of buttons
	lst_buttons = @lst_buttons.find_all { |button| button_in_family?(button) }
	
	#Checking button state
	#@hsh_buttons.each do |key, button|
	#lst_buttons.each do |button|
	@hsh_buttons.each do |key, button|
		compute_button_state button unless button.hidden || !button_in_family?(button)
	end
	
	#Already computed and viewport did not change size
	return if @computed && @vpwidth == @view.vpwidth && @vpheight == @view.vpheight
	
	t0 = Time.now.to_f
	
	#Reference viewport width and position for buttons
	@vpwidth = @view.vpwidth
	@vpheight = @view.vpheight
	vpwid = @view.vpwidth
	@yref = (@top_pos) ? @height + 1 : @view.vpheight + 1
	
	#compute the width for the buttons
	widbut = 0
	lst_buttons.each do |button|
		widbut += button.width if (!(button.type =~ /multi/i) && button.rank == 0) || button.type =~ /multi/i
	end
	widblason = 0
	@button_blasons.each do |button| 
		button.width = @height
		widblason += button.width
		button_make_quads button		
	end	

	#Show or hide the tooltip  area
	unless @message_visi
		@button_tip.hidden = true
		wid_tip = 0
	else	
		@button_tip.hidden = false
		wid_tip = @widmax_tip
	end	
	
	#Button position reference
	@xstart_button = wid_tip + @wid_ctrl + widblason
	
	#Computing the position of the control buttons
	lbt = [@button_shrink, @button_pos, @button_msg_visi, @button_sideleft]
	lx = [0, 0, @height2, @height2]
	ly = [@height2, 0, @height2, 0]
	for i in 0..3
		b = lbt[i]
		x = lx[i]
		y = @yref - ((@top_pos) ? ly[i] : ly[3-i])
		button_transfo b, x, y
	end
	
	#Blason buttons
	w = 0
	@button_blasons.each do |button| 
		button_transfo button, @wid_ctrl + w, @yref
		w += button.width 
	end	
	
	#Computing the other buttons
	ls_buttons = []
	lst_transfo = []
	#@lst_buttons.each { |button| ls_buttons += (button.bsuite) ? button.bsuite : [button] }
	lst_buttons.each { |button| ls_buttons += (button.bsuite) ? button.bsuite : [button] }
	
	cursepa = false
	xpos = @xstart_button
	xrank = 0
	curank = nil
	ls_buttons.each do |button|
		next if button.hidden
		
		#Multi button	
		if button.type =~ /multi/i
			#lst_transfo.push [button, xpos, @yref - button.rank * button.height]
			lst_transfo.push [button, xpos, @yref - button.rank * button.buttons[0].height]
			x = xpos
			button.buttons.each do |b|
				next if b.hidden
				lst_transfo.push [b, x, @yref]
				x += b.width
			end
			xpos += button.width
			cursepa = false
			
		#other buttons
		else
			rank = button.rank
			if button.sepa
				if cursepa
					button.hidsepa = true
					next
				else
					button.hidsepa = false
					cursepa = true
				end
			else
				cursepa = false
			end			
			if rank != curank
				xrank = 0
			end	
			lst_transfo.push [button, xpos + xrank, @yref - rank * button.height]
			if rank == 0
				xpos += button.width
				curank = nil
				xrank = 0
			else
				xrank += button.width
				curank = rank
			end	
			
		end	
	end
	term = 2
	@total_width = xpos + term
	@total_height = @height + 3
	
	#Adjusting the tip area if the button zone is too large
	w = vpwid - @total_width
	w = term if w > 0
	@total_width += w
	@button_tip.width = wid_tip + w
	button_make_quads @button_tip
	button_transfo @button_tip, @wid_ctrl + widblason, @yref
	
	#Computing the transformation of all buttons
	lst_transfo.each { |ll| button_transfo ll[0], ll[1] + w, ll[2] }
		
	#Compute the side palettes
	compute_side_palettes
	
	#Compute the floating palettes
	@lst_floats.each { |floating| compute_floating_palette floating }
	
	#Compute the Message band
	@button_message.width = @total_width
	button_make_quads @button_message
	message_transfo @total_width_side
	
	#Compute the background
	compute_quad_background
	
	#Computing the list of buttons
	ls_buttons = @hsh_buttons.values.find_all { |button| button_in_family?(button) }
	@lst_visible_buttons = ls_buttons.sort! { |b1, b2| sort_by_clickable(b1, b2) }
	
	#Declaring computing OK
	@computed = true
end

#Sort method with clickable button in latest positions
def sort_by_clickable(b1, b2)
	return 1 if button_is_clickable?(b1) && !button_is_clickable?(b2)
	return -1 if button_is_clickable?(b2) && !button_is_clickable?(b1)
	-(b1.rank <=> b2.rank)
end

#Set the transformation for the button
def message_transfo(x)
	button = @button_message
	x = @vpwidth - x - button.width unless @side_left
	button.xleft = @tra_basis[12] = x
	button.ybot = @tra_basis[13] = @yref + ((@top_pos) ? button.height : -@height)
	
	@tra_basis[5] = -1
	button.tr_tx = Geom::Transformation.new @tra_basis
	@tra_basis[5] = -1
	button.tr = Geom::Transformation.new @tra_basis
	@tra_basis[12] += 1
	@tra_basis[13] -= 1
	button.tr1 = Geom::Transformation.new @tra_basis
	@tra_basis[12] += 1
	@tra_basis[13] -= 1
	button.tr2 = Geom::Transformation.new @tra_basis
end

#Set the transformation for the button
def button_transfo(button, x, y, noside=false)
	x = @vpwidth - x - button.width unless noside || @side_left
	button.xleft = @tra_basis[12] = x
	button.ybot = @tra_basis[13] = y
	@tra_basis[5] = -1
	button.tr_tx = Geom::Transformation.new @tra_basis
	@tra_basis[5] = -1
	button.tr = Geom::Transformation.new @tra_basis
	@tra_basis[12] += 1
	@tra_basis[13] -= 1
	button.tr1 = Geom::Transformation.new @tra_basis
	@tra_basis[12] += 1
	@tra_basis[13] -= 1
	button.tr2 = Geom::Transformation.new @tra_basis
end

def make_quad(w, h, incr=0)
	pt1 = Geom::Point3d.new 0, 0, 0
	pt2 = Geom::Point3d.new 0, h - incr, 0
	pt3 = Geom::Point3d.new w - incr, h - incr, 0
	pt4 = Geom::Point3d.new w - incr, 0, 0
	[pt1, pt2, pt3, pt4]
end

#Draw the background of the palette
def compute_quad_background
	xmin = 0
	xmax = @total_width
	unless @side_left
		xmin = @view.vpwidth - xmax
		xmax = @view.vpwidth
	end
	
	if @top_pos
		ymin = 0
		ymax = @height + 3
		ylinew = ymax - 1
		ylineb = ylinew + 1
		yminh = ymin
		ymaxh = ylinew
	else
		ymin = @view.vpheight - @height - 3
		ymax = @view.vpheight
		ylinew = ymin + 1
		ylineb = ylinew - 1
		yminh = ymax
		ymaxh = ylinew
	end
	@quad_background = []
	@quad_background.push Geom::Point3d.new(xmin, ymin)
	@quad_background.push Geom::Point3d.new(xmax, ymin)
	@quad_background.push Geom::Point3d.new(xmax, ymax)
	@quad_background.push Geom::Point3d.new(xmin, ymax)
	
	@line_background = []
	@line_background.push Geom::Point3d.new(xmin, ylinew)
	@line_background.push Geom::Point3d.new(xmax, ylinew)
	@line_background.push Geom::Point3d.new(xmin, ylineb)
	@line_background.push Geom::Point3d.new(xmax, ylineb)
	
	if @side_left
		@line_background.push Geom::Point3d.new(xmax-1, yminh)
		@line_background.push Geom::Point3d.new(xmax-1, ymaxh)
		@line_background.push Geom::Point3d.new(xmax, yminh)
		@line_background.push Geom::Point3d.new(xmax, ymaxh)
	else
		@line_background.push Geom::Point3d.new(xmin+1, yminh)
		@line_background.push Geom::Point3d.new(xmin+1, ymaxh)
		@line_background.push Geom::Point3d.new(xmin, yminh)
		@line_background.push Geom::Point3d.new(xmin, ymaxh)
	end
end

#----------------------------------------------------------------------------
# Drawing methods
#----------------------------------------------------------------------------

def draw_background(view)
	#draw the background to the main palette
	return if @shrinked
	compute_quad_background unless @quad_background
	view.drawing_color = @bkcolor_normal
	view.draw2d GL_QUADS, @quad_background
	
	view.line_stipple = ''
	view.line_width = 2
	view.drawing_color = @frcolor_dark
	view.draw2d GL_LINE_STRIP, @line_background[0..1]
	view.line_width = 1
	view.drawing_color = @frcolor_white
	view.draw2d GL_LINE_STRIP, @line_background[2..3]

	view.drawing_color = @frcolor_dark
	view.draw2d GL_LINE_STRIP, @line_background[4..5]
	view.drawing_color = @frcolor_white
	view.draw2d GL_LINE_STRIP, @line_background[6..7]
	
	#draw background to the side palette
	if @visible_sidepal
		#view.drawing_color = 'yellow'
		#view.draw2d GL_QUADS, @quad_sidepal
	end	
	
	#Draw background of the floating palettes
	@lst_floats.each do |floating|
		draw_floating_background view, floating
	end
end

#Draw a button in all states
def draw_button(view, button)
	return if button.hidden || button.hidsepa || button.height == 0
	return if button.bfloating && floating_is_hidden?(button.bfloating)
	compute_button button
	return unless button.quad && button.tr
	if button == @button_tip
		return if @button_tip.hidden || (@widmin_tip && @button_tip.width < @widmin_tip)
	end
	
	bt_color = button.bk_color
	bt_color = bt_color.call if bt_color.class == Proc
	bh_color = button.hi_color
	bh_color = bh_color.call if bh_color.class == Proc
	clickable = button_is_clickable?(button)

	#drawing the area
	if !clickable
		#bkcolor = @bkcolor_normal
		bkcolor = (bt_color) ? bt_color : @bkcolor_normal
		width = 1
		color1 = @frcolor_dark
		color2 = @frcolor_dark
	elsif button.selected
		bkcolor = (bh_color) ? bh_color : @bkcolor_selected
		width = 2
		color1 = @frcolor_gray
		color2 = @frcolor_white
	elsif button == @sel_button	
		bkcolor = @bkcolor_down
		width = 2
		color1 = @frcolor_gray
		color2 = @frcolor_white
	elsif button == @hi_button
		bkcolor = (bt_color) ? bt_color : @bkcolor_hilight
		width = 2
		color1 = @frcolor_white
		color2 = @frcolor_gray
	else	
		bkcolor = (bt_color) ? bt_color : @bkcolor_normal
		width = 1
		color1 = 'darkgray'
		color2 = 'darkgray'
	end	
	
	#Framing for the button
	if width == 1
		t = button.tr
		quad = button.quad
		pts = quad.collect { |pt| t * pt }
		pts1 = [pts[1], pts[2]]
		pts2 = [pts[0], pts[3]]
	else
		t = button.tr1
		quad = button.quad1
		pts = quad.collect { |pt| t * pt }
		pts1 = [pts[0], pts[1], pts[2]]
		pts2 = [pts[2], pts[3], pts[0]]
	end	

	#drawing the background
	unless button.tab_style
		view.drawing_color = bkcolor
		view.draw2d GL_QUADS, pts
		content = draw_button_content view, button
	end
	
	#Drawing the content"
	
	#drawing the border
	if button.tab_style
		draw_button_tab view, button, bt_color
	elsif width > 1
		view.line_width = width
		view.line_stipple = ""
		view.drawing_color = color1
		view.draw2d GL_LINE_STRIP, pts1
		view.drawing_color = color2
		view.draw2d GL_LINE_STRIP, pts2
	end
				
	#Compute the text
	text = button.text
	if button.text_proc
		text = button.text_proc.call
	end
	
	#Draw a border for groups
	if clickable && width == 1 && !content && button.text == nil
		view.drawing_color = 'silver'
		view.line_width = 1
		pts = button.quad2.collect { |pt| t * pt }
	end	
	
	underline = (!clickable || (!button.selected && button != @hi_button)) && !button.bk_color && button.rank > 0 && 
	   (button.text || button.text_proc) && button.draw_proc == nil && button.draw_code == nil
	   
	t = button.tr1 if underline && !button.tab_style
	
	#Draw the text if any
	if text && !button.grayed
		draw_button_text view, button, text
	end
	
	#Draw a separator for title
	if underline
		view.line_width = 1
		view.line_stipple = ""
		pts1 = [button.quad2[0], button.quad2[3]].collect { |pt| t * Geom::Point3d.new(pt.x, pt.y+1, 0) }
		pts2 = [button.quad2[0], button.quad2[3]].collect { |pt| t * pt }
		view.drawing_color = @bkcolor_title1_u
		view.draw2d GL_LINE_STRIP, pts1
		view.drawing_color = @bkcolor_title1_d
		view.draw2d GL_LINE_STRIP, pts2
	end		
end

#Draw Button Text
def draw_button_text(view, button, text)
	#Which text to draw	 
	text = (button.selected && text[1]) ? text[1] : text[0] if text.class == Array
	return unless text

	#Retrieving the text information
	if button.selected
		instructions = button.text_sel_instructions
		text_previous = button.text_sel_previous
	else
		instructions = button.text_instructions
		text_previous = button.text_previous
	end
	
	#Computing the instructions
	unless instructions && text == text_previous
		wid = button.width
		hgt = button.height
		y = button.height+1
		y -= 1 if button.tab_style
		x = 3
		justif = (button.justif) ? button.justif : 'MT' 
		instructions = G6.text_box_instructions(text, x, y, wid, hgt, justif)
	end
		
	#Storing the text information	
	if button.selected
		button.text_sel_instructions = instructions
		button.text_sel_previous = text_previous
	else
		button.text_instructions = instructions
		button.text_previous = text_previous
	end

	#Drawing the text
	t = button.tr_tx
	instructions.each do |lst|
		s, pt = lst
		G6.view_draw_text view, t * pt, s
	end	
end

#Draw buttons with TAB style
def draw_button_tab(view, button, bt_color)
	bkcolor = (bt_color) ? bt_color : @bkcolor_normal
	bkcolor = 'silver' if button == @hi_button
	bkcolor = @bkcolor_down if button.selected
	
	t = (button.selected) ? button.tr : button.tr
	quad = (button.selected) ? button.quad1 : button.quad2
	dec = 3
	pts = quad.collect { |pt| t * pt }
	pts[2].x -= 1
	pts[3].x -= 1
	ptc10 = Geom::Point3d.new pts[1].x, pts[1].y+dec, 0
	ptc12 = Geom::Point3d.new pts[1].x+dec, pts[1].y, 0
	ptc21 = Geom::Point3d.new pts[2].x-dec, pts[2].y, 0
	ptc23 = Geom::Point3d.new pts[3].x, pts[2].y+dec, 0
	lptw = [pts[0], ptc10, ptc12, ptc21]
	lptw = [pts[3], pts[0]] + lptw unless button.selected
	lptg = [ptc21, ptc23, pts[3]]
	
	poly = [pts[0], ptc10, ptc12, ptc21, ptc23, pts[3], pts[0]]
	view.drawing_color = bkcolor
	view.draw2d GL_POLYGON, poly
	
	draw_button_content view, button
	
	view.line_stipple = ""
	view.line_width = 1
	view.drawing_color = @frcolor_gray
	view.draw2d GL_LINE_STRIP, lptg
	if button.selected
		view.line_width = 2
		view.draw2d GL_LINE_STRIP, [ptc23, pts[3]]
	end
	view.line_width = 1
	view.drawing_color = @frcolor_white
	view.draw2d GL_LINE_STRIP, lptw
end

def draw_button_content(view, button)
	#button colors
	if button.grayed
		main_color = @frcolor_white
		frame_color = @frcolor_dark
	else
		main_color = button.main_color
		frame_color = button.frame_color
	end
		
	#Getting the instructions
	if button.selected
		instructions = button.sel_instructions
		unless instructions && !button.draw_refresh	
			instructions = []
			if button.draw_code
				codes = button.draw_code
				codes = [codes] if codes.class != Array
				codes.each do |code|
					instructions += @standard_draw_proc.call(code, button.width - 4, 
															 button.height - 4, main_color, frame_color,
															 button.draw_scale, button.draw_extra_proc, true)
				end													
			else
				#button.instructions += button.draw_proc.call(button.symb, button.width - 4, button.height - 4) if button.draw_proc
				instructions += compute_instructions(button, main_color, frame_color)
			end	
			instructions += fkey_instructions(button) if button.fkey
			button.sel_instructions = instructions
		end
	
	else
		instructions = button.instructions
		unless instructions && !button.draw_refresh	
			instructions = []
			instructions += blason_instructions(button, main_color, frame_color) if button.blason
			if button.draw_code
				codes = button.draw_code
				codes = [codes] if codes.class != Array
				codes.each do |code|
					instructions += @standard_draw_proc.call(code, button.width - 4, 
															 button.height - 4, main_color, frame_color,
															 button.draw_scale, button.draw_extra_proc, false)
				end													
			else
				instructions += compute_instructions(button, main_color, frame_color)
			end	
			instructions += fkey_instructions(button) if button.fkey
			button.instructions = instructions
		end
	end
	
	return false unless instructions
	
	#processing the instructions
	@ogl.process_draw_GL view, button.tr2, instructions
end

#Compute the instructions for the button
def compute_instructions(button, main_color, frame_color)
	draw_proc = button.draw_proc
	return [] unless draw_proc
	
	case draw_proc.arity
	when 3
		draw_proc.call(button.symb, button.width - 4, button.height - 4)
	when 4
		draw_proc.call(button.symb, button.width - 4, button.height - 4, button.selected)
	when 5
		draw_proc.call(button.symb, button.width - 4, button.height - 4, main_color, frame_color)
	when 6
		draw_proc.call(button.symb, button.width - 4, button.height - 4, main_color, frame_color, button.selected)
	end	
end

#Draw the frame for a blason
def blason_instructions(button, main_color, frame_color)
	main_color = (button.main_color) ? button.main_color : @bkcolor_blason unless main_color
	frame_color = (button.frame_color) ? button.frame_color : @frcolor_blason unless frame_color
	@standard_draw_proc.call :std_blason, button.width - 4, button.height - 4, main_color, frame_color, false
end

#Draw the frame for a blason
def fkey_instructions(button)
	main_color = 'green'
	x = button.width - 4
	y = 1
	frame_color = (button.frame_color) ? button.frame_color : @frcolor_blason unless frame_color
	@ogl.digit_instructions button.fkey.fkey, x, y, main_color
end

#Top drawing method for the palette
def draw(view)
	#List of all visible buttons
	compute_all unless @computed
	ls_buttons = list_visible
	
	#Tracking all changes since last refresh
	ls_buttons.each { |button| button_track_changes button }
	
	#Recomputing the palette if necessary
	compute_all
		
	#drawing the background for all palettes
	draw_background view
	
	#Drawing the elements
	ls_buttons.each { |button| draw_button view, button }	
	
	#Drawing the highlight button
	draw_button view, @hi_button if @hi_button && button_is_clickable?(@hi_button)
end

#----------------------------------------------------------------------------
# Change of state
#----------------------------------------------------------------------------

def button_track_changes(button)
	if button.grayed != button_check_grayed?(button)
		button.instructions = nil
	end	
	if button.hidden != button_check_hidden?(button)
		@computed = false
	end	

end

#Test the status Grayed of a button
def button_check_grayed?(button)
	if button.parent
		button.grayed = button_check_grayed?(button.parent)
	end
	button.grayed = button.grayed_proc.call if button.grayed_proc
	button.grayed
end

#Test the status Grayed of a button
def button_check_hidden?(button)
	if button.parent
		button.hidden = button_check_hidden?(button.parent)
	end
	button.hidden = button.hidden_proc.call if button.hidden_proc
	button.hidden
end
	

#----------------------------------------------------------------------------
# Message Zone
#----------------------------------------------------------------------------

#Set the tooltip
def set_tooltip(tooltip=nil, level=nil)
	text = (tooltip) ? tooltip : ""
	set_message_and_tip @button_tip, text, level
end

#Set a Message
def set_message(message=nil, level=nil)
	@shadow_bug_displayed = false
	text = (message) ? message.gsub("\n", ' - ') : nil
	set_message_and_tip @button_message, message, level
	@button_message.hidden = (text) ? false : true
end

#Utility to set Message and Tip
def set_message_and_tip(button, text=nil, level=nil)
	button.text = text
	case level
	when 'W', 'w'
		color = 'yellow'
	when 'H', 'h'
		color = 'lightyellow'
	when 'I', 'i'
		color = 'lightgreen'
	when 'E', 'e'
		color = 'lightcoral'
	when /..+/
		color = level
	else
		color = nil
	end
	button.bk_color = color
end

#----------------------------------------------------------------------------
# Palette placement
#----------------------------------------------------------------------------

#Toggle shrink or expand of palettes
def toggle_shrinked
	@shrinked = !@shrinked
	refresh_after_toggle false
end

#Toggle position top or bottom of the palettes
def toggle_top_down
	@top_pos = !@top_pos
	refresh_after_toggle
end

#Toggle visibility of the message zone
def toggle_message_visible
	@message_visi = !@message_visi
	refresh_after_toggle
end

#Toggle position left or right of the palettes
def toggle_side_left
	@side_left = !@side_left
	refresh_after_toggle
end

#Refresh after changing the palette position
def refresh_after_toggle(recompute=true)
	adjust_draw_standard_button
	persistence_save
	if recompute
		@computed = false
		compute_all
	end	
	onMouseMove_zero
	@view.invalidate
end

#----------------------------------------------------------------------------
# Mouse handling
#----------------------------------------------------------------------------

#check if a button is not clickable
def button_is_clickable?(button)
	#!(button.passive || grayed?(button) || button.hidden || button.hidsepa)
	!(button.passive || button.grayed || button.hidden || button.hidsepa)
end

#Return the list of visible buttons
def list_visible
	if (@shrinked)
		ls = [@button_pos, @button_shrink, @button_msg_visi, @button_sideleft]
	else
		compute_all unless @lst_visible_buttons
		ls = @lst_visible_buttons
	end
	ls
end

#Determine if an active button is under the mouse
def locate_button(x, y)
	#Quick test if within the palette
	@mouse_button = nil
	@within_background = nil
	
	#Finding the button
	list_visible.each do |button|
		next unless button_visible?(button) && button.xleft
		if (x >= button.xleft && x <= button.xleft + button.width) && 
		   (y <= button.ybot + 2 && y >= button.ybot - button.height - 3 )
			@mouse_button = button
			break
		end	
	end
	@mouse_button
end

#check if a button is visible
def button_visible?(button)
	return false if button.hidden || button.sepa
	bfloating = button.bfloating
	return false if bfloating && floating_is_hidden?(bfloating)
	true
end

#Detrmine if the mouse if still within the bounday of the main palette
def locate_within_background?(ptxy)
	@within_background = Geom.point_in_polygon_2D(ptxy, @quad_background, true)
end

#Set the cursor
def onSetCursor
	return false unless @mouse_button || @mouse_floating || @within_background
	if @mouse_floating
		ic = (@mouse_floating_frame) ? @id_cursor_move : @id_cursor_move
	elsif @mouse_button && button_is_clickable?(@mouse_button)
		ic = @id_cursor_hand
	else
		ic = @id_cursor_arrow
	end
	UI::set_cursor ic
	ic
end

#Mouse move methods
def onMouseMove_zero
	onMouseMove -1, @ptxy.x, @ptxy.y, @view
end

def onMouseMove(flags, x, y, view)
	return false if cancel_button_down(flags) || !@ptxy || !x || !y
	@ptxy.x = x
	@ptxy.y = y
	
	#Handling moving of floating palettes
	if test_auto_hide_floating(x, y)
		@view.invalidate
		return false
	end
	
	if @origin_floating
		move_current_floating x, y
		return true
	end
	
	#Handling Button highlight
	button = locate_button x, y
	unless button || @button_down
		@hi_button = nil
		return true if locate_floating_frame(@ptxy)
		if locate_within_background?(@ptxy)
			view.invalidate
			return true 
		end	
		return false
	end	
	@mouse_floating = nil
	
	#Mouse is down
	return true if flags & 1 == 1
	
	if @button_down
		@hi_button = nil
		if button == nil || (@sel_button && button != @sel_button)
			return true
		end
	else	
		@hi_button = button
	end	
	if @hi_button
		text = button_compute_tooltip(@hi_button)
		@view.tooltip = @main_tooltip = (text) ? text.gsub("\n", ' - ') : ""
		@view.invalidate
	end	
	true
end

#Mouse enters the view port
def onMouseLeave(view)
	@hi_button = false
	@view.invalidate
end

#Mouse leaves the view port
def onMouseEnter(view)
end

#Cancel a button down event when Up event is not in the same area
def cancel_button_down(flags)
	if (flags == nil || flags >= 0) && @button_down && (flags & 1 != 1)
		@hi_button = nil
		@sel_button = nil
		@button_down = false
		@view.invalidate
	end	
	false
end	

#Button click - Means that we end the selection
def onLButtonDown(flags, x, y, view)
	@xdown = x
	@ydown = y
	@ptxy.x = x ; @ptxy.y = y
	@time_down = nil
	
	#Handling the floating palette
	if @origin_floating
		@origin_floating = nil
		@view.invalidate
		end_move_floating
		return true
	end
	
	if @mouse_floating
		@origin_floating = [@mouse_floating.xpos - x, @mouse_floating.ypos - y]
		@view.invalidate
		return true
	end
	
	#Handling button click
	button = locate_button x, y
	unless button
		return true if locate_within_background?(@ptxy)
		return false
	end	
	@button_down = true
	@view.tooltip = @main_tooltip = ""
	@sel_button = button
	@sel_button = nil unless button_is_clickable?(@sel_button)
	@time_down = Time.now.to_f if button
	@view.invalidate
	true
end

#Button click - Means that we end the selection
def onLButtonUp(flags, x, y, view)
	#Handling the floating palette
	@long_click = nil
	@ptxy.x = x ; @ptxy.y = y
	if @origin_floating 
		@origin_floating = nil if ((@xdown - x).abs > 4 || (@ydown - y).abs > 4)
		#end_move_floating if ((@xdown - x).abs > 4 || (@ydown - y).abs > 4)
		@view.invalidate
		end_move_floating unless @origin_floating
		return true
	elsif @mouse_floating
		return true
	end

	#Handling button click
	button = locate_button x, y
	
	if button && !@button_down
		@hi_button = nil
		@view.invalidate
		return true
	end
	
	#Not an event for the palette
	unless @button_down && button
		@hi_button = nil
		@sel_button = nil
		@view.invalidate
		return true if locate_within_background?(@ptxy)		
		return false
	end
	
	@button_down = false
	
	#Trapping the click if clic up is on the same button as click down
	if @sel_button && button == @sel_button 
		@long_click = Time.now.to_f - @time_down if @time_down
		execute_button @sel_button if button_is_clickable?(@sel_button)
	end

	@sel_button = nil
	@view.invalidate
	true
end

def onLButtonDoubleClick(flags, x, y, view)
	@ptxy.x = x ; @ptxy.y = y
	button = locate_button x, y
	status = false
	if button
		if button.double_click_proc
			button.double_click_proc.call
			status = true
		else
			status = onLButtonDown(flags, x, y, view)
			onLButtonUp(flags, x, y, view)
		end	
	else
		status = true if locate_within_background?(@ptxy)
	end	
	@view.invalidate
	status
end

#Test if the action was generated from a long click
def long_click?(duration=nil)
	duration = @long_click_duration unless duration
	(@long_click && @long_click > duration)
end

#----------------------------------------------------------------------------
# Execution of actions
#----------------------------------------------------------------------------

#Execution of action when clicking on button
def execute_button(button)
	return unless button && button_is_clickable?(button)
	
	symb = button.symb
	
	#Standard
	if symb == :_bt_pos
		return toggle_top_down
	elsif symb == :_bt_shrink
		return toggle_shrinked
	elsif symb == :_bt_msg_visi
		return toggle_message_visible
	elsif symb == :_bt_sideleft
		return toggle_side_left
	end
	
	#Checking multiple button
	parent = button.parent
	if parent && parent.multi
		execute_multi button, parent
		button = parent
	elsif button.multi
		button.value = button.default_value	
	end
	
	#Calling the custom proc
	if button.long_click_proc && long_click?
		button.long_click_proc.call
	elsif button.action_proc
		button.action_proc.call
	elsif @palette_proc	
		@palette_proc.call :click, button.symb, button.value
	end	
end

#Execution method parent button controlling multi-choice buttons
def execute_multi(button, parent)
	sval = parent.value
	if parent.radio
		parent.value = button.value
	else
		lv = (sval) ? sval.split(';;') : []
		if button.selected
			lv -= [button.value]
		else
			lv.push button.value unless lv.include?(button.value)
		end
		parent.value = lv.join ';;'
	end	
end
	
end	# class Palette

#--------------------------------------------------------------------------------------------------------------
# Class PaletteSuperTool: used for subclassing the Tools and provide palette management
#--------------------------------------------------------------------------------------------------------------			 				   

class PaletteSuperTool

def set_palette(palette)
	@palette = palette
end

def draw(view)
	@palette.draw view if @palette
end

def onMouseLeave(view)
	@palette.onMouseLeave(view) if @palette
end

def onMouseEnter(view)
	@palette.onMouseEnter(view) if @palette
	view.invalidate
end	

def onLButtonDown(flags, x, y, view)
	@palette.onLButtonDown(flags, x, y, view) if @palette
end

def onLButtonUp(flags, x, y, view)
	@palette.onLButtonUp(flags, x, y, view) if @palette
end

def onLButtonDoubleClick(flags, x, y, view)
	@palette.onLButtonDoubleClick(flags, x, y, view) if @palette
end

def onMouseMove(flags, x, y, view)
	@palette.onMouseMove(flags, x, y, view) if @palette
end
	
def onSetCursor
	@palette.onSetCursor if @palette
end
	
end	#End class PaletteSuperTool

end	#module Traductor

