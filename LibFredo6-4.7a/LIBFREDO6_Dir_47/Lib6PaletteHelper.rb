=begin
#-------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed by Fredo6 - Copyright November 2012

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   Lib6PaletteHelper.rb
# Original Date	:   14 Nov 2012
# Description	:   Built-in buttons and palette sections for palette management
#-------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end


module Traductor

T6[:T_TIP_GenMode_Title] = "Generation mode for the Contours"	
T6[:T_TIP_GenMode_NonDestructive] = "Non Destructive when possible"	
T6[:T_TIP_GenMode_EraseCreate] = "Erase Old contours, Create New contours"	
T6[:T_TIP_GenMode_Group] = "Generate in a Group"	

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Class PaletteHelper: Palette Helper Environment for defining built-in buttons
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

class PaletteHelper

#Initialization of common parameters
def initialize(palette, prefix, *hargs)
	@palette = palette
	@prefix = prefix
	@draw_common = self.method "common_opengl"	
	
	#Processing arguments
	@hsh_defaults = {}
	hargs.each do |hsh|
		hsh.each do |key, val|
			case key
			when :get_option_proc
				@get_option_proc = val
			when :set_option_proc
				@set_option_proc = val
			when :toggle_option_proc
				@toggle_option_proc = val
			when :draw_local_proc
				@draw_local_proc = val
			else
				@hsh_defaults[key] = val
			end	
		end
	end
	
	#Common attributes
	@color_but_band = 'green'
	@color_but_title = 'lightblue'
	@color_but_on = 'lightgreen'
	@color_but_value = 'lightgreen'
end

#Utility methods for getting, setting, toggling options and drawing
def get_option(symb) ; @get_option_proc.call symb ; end
def set_option(symb, val) ; @set_option_proc.call symb, val ; end
def toggle_option(symb) ; @toggle_option_proc.call symb ; end
def draw_proc(hspecs) ; (hspecs[:draw_proc] == :local) ? @draw_local_proc : hspecs[:draw_proc] ; end

#Process a list of contributions
def process_contribution(lst_contributions)
	lst_contributions.each do |hspecs|
		symb = hspecs[:symb]
		@palette.declare_separator unless hspecs[:nosepa]
		case hspecs[:type]
		when :bool
			bool symb, hspecs
		when :stipple
			stipple_style symb, hspecs
		when :integer, :float
			numeric_value symb, hspecs
		when :contour_gen_mode
			contour_generation_mode symb, hspecs
		when :powermeter
			powermeter symb, hspecs
		when :radio
			multi_radio symb, hspecs
		when :edge_prop_extended
			edge_prop_assignment symb, hspecs
		end
	end
end

#----------------------------------------------------------------------------------------
# GENMODE: Contour Generation Mode
# Values are :keep, :erase or :group
#----------------------------------------------------------------------------------------

def contour_generation_mode(symb, hspecs=nil)
	pal_symb = ("#{@prefix}_#{symb}").intern
	
	hgt = 6
	value_proc = proc { get_option symb }
	hsh = { :type => 'multi', :radio => true, :passive => true, :tooltip => T6[:T_TIP_GenMode_Title], :height => hgt,
			:bk_color => @color_but_band, :default_value => :erase, :value_proc => value_proc }
	@palette.declare_button(pal_symb, hsh) {  set_option symb, @palette.button_get_value }

	wid = hgt = 32 - hgt
	lst = [[:keep, :T_TIP_GenMode_NonDestructive, @draw_common],
	       [:erase, :T_TIP_GenMode_EraseCreate, @draw_common],
		   [:group, :T_TIP_GenMode_Group, :std_group]]
	lst.each do |ll|
		hshb = { :parent => pal_symb, :width => wid, :height => wid, :draw_proc => ll[2], :value => ll[0], 
				 :tooltip => T6[ll[1]], :hi_color => @color_but_on, :main_color => 'darkred' }
		ss = "#{pal_symb}__#{ll[0]}".intern
		@palette.declare_button ss, hshb
	end	
end

#----------------------------------------------------------------------------------------
# NUMERIC VALUE: float and integer values
#----------------------------------------------------------------------------------------

def numeric_value(symb, hspecs)
	pal_symb_title = ("#{@prefix}_#{symb}_title").intern
	pal_symb_value = ("#{@prefix}_#{symb}_value").intern
	
	#Title button
	title = hspecs[:title]
	prompt = hspecs[:prompt]
	prompt = title unless prompt
	w = hspecs[:width]
	w = 80 unless w
	hsh_dim = { :height => 16, :width => w }
	color_title = hspecs[:color_title]
	color_title = @color_but_title unless color_title
	hsht = { :passive => true, :text => title, :bk_color => color_title, :tooltip => hspecs[:tooltip], :rank => 1 }
	@palette.declare_button pal_symb_title, hsh_dim, hsht
	
	#Input field
	hshi = { :vtype => hspecs[:type], :vmin => hspecs[:vmin], :vmax => hspecs[:vmax], :vincr => hspecs[:vincr], 
	         :vsprintf => hspecs[:vsprintf], :vvcb => hspecs[:vvcb], :vprompt => prompt }
	get_proc = proc { get_option symb }
	set_proc = proc { |val| set_option symb, val }
	input = Traductor::InputField.new hshi, { :get_proc => get_proc, :set_proc => set_proc }
	
	color_value = hspecs[:color_value]
	color_value = @color_but_value unless color_value
	hsh = { :bk_color => color_value, :input => input }
	@palette.declare_button pal_symb_value, hsh_dim, hsh 
end

#----------------------------------------------------------------------------------------
# STIPPLE: Stipple styles
#----------------------------------------------------------------------------------------

def stipple_style(symb, hspecs)
	pal_symb = ("#{@prefix}_#{symb}").intern

	hc = { :hi_color => @color_but_on }
	value_proc = proc { get_option symb }
	hsh = { :value_proc => value_proc, :text => hspecs[:title], :tooltip => hspecs[:tooltip], :default_value => hspecs[:default], 
	        :bk_color => @color_but_title }
	@palette.declare_stipple(pal_symb, hsh, hc) { set_option symb, @palette.button_get_value }	
end

#----------------------------------------------------------------------------------------
# BOOL: Boolean flag button (image or text)
#----------------------------------------------------------------------------------------

def bool(symb, hspecs)
	pal_symb = ("#{@prefix}_#{symb}").intern
	
	hc = { :hi_color => @color_but_on }
	value_proc = proc { get_option symb }
	hsh = { :tooltip => hspecs[:tooltip], :text => hspecs[:text], :draw_proc => draw_proc(hspecs), :value_proc => value_proc }
	@palette.declare_button(pal_symb, hsh, hc) { toggle_option symb }
end

#----------------------------------------------------------------------------------------
# MULTI RADIO: Multi Button in Radio mode
#----------------------------------------------------------------------------------------

def multi_radio(symb, hspecs)
	symb_master = ("#{@prefix}_#{symb}").intern
	buttons = hspecs[:buttons]
	text = hspecs[:text]
	value_proc = proc { get_option symb }
	hsh = { :type => 'multi', :radio => true, :passive => true, :value_proc => value_proc, :bk_color => @color_but_title, 
	        :tooltip => hspecs[:tooltip], :text => text, :height => 16, :draw_proc => draw_proc(hspecs) }
	@palette.declare_button(symb_master, hsh) { set_option symb, @palette.button_get_value }
	
	wid, = (text) ? G6.simple_text_size(text) : 0
	wid = [16, wid / buttons.length + 10].max.round
	hshp = { :parent => symb_master, :width => wid, :hi_color =>  @color_but_on }
	buttons.each do |hbut|
		val = hbut[:val]
		symb_but = "#{symb_master}__#{val}"
		hsh = { :value => val, :tooltip => hbut[:tooltip], :draw_proc => draw_proc(hbut),  }
		@palette.declare_button(symb_but, hshp, hsh)
	end
end

#----------------------------------------------------------------------------------------
# POWERMETER: Button with small squares
#----------------------------------------------------------------------------------------

#PALETTE: contribution for Powermeter fields
def powermeter(symb, hspecs)
	symb_master = ("#{@prefix}_#{symb}").intern
	
	text = hspecs[:text]
	wid, = (text) ? G6.simple_text_size(text) : 0
	n = 4
	wid = [14, wid / n + 10].max.round
	
	hc = { :hi_color => @color_but_on }
	value_proc = proc { get_option(symb) > 0 }
	hsh = { :type => 'multi_free', :tooltip => hspecs[:tooltip], :draw_proc => draw_proc(hspecs), 
	        :value_proc => value_proc, :text => text, :height => 20 }
	@palette.declare_button(symb_master, hsh, hc) { set_option symb, -get_option(symb) }  
	
	hshp = { :parent => symb_master, :width => wid, :hi_color =>  'gold', :height => 12 }
	for i in 1..n
		powermeter_marker(@palette, symb, symb_master, i, hshp)
	end		
end

def powermeter_marker(palette, symb, prefix, i, hshp)
	psymb = ("#{prefix}_P#{i}").intern
	value_proc = proc { get_option(symb).abs >= i }
	hsh = { :tooltip => "Force #{i}", :value_proc => value_proc }
	@palette.declare_button(psymb, hsh, hshp) { set_option symb, i }
end

#----------------------------------------------------------------------------------------
# EDGE PROPERTIES EXTENDED: Stipple styles
# based on Hash array of property: 
#    - :smooth, :soft, :hidden, :cast_shadows
#    - with value 0 (unchanged), 1 (set), -1 (unset)
#----------------------------------------------------------------------------------------

#Declare a button set for extended edge property control
def edge_prop_assignment(symb, hspecs)
	prefix = ("#{@prefix}_#{symb}").intern
	hsha = { :hi_color =>  @color_but_on }

	#Plain and Diagonal
	hshb = { :width => 24, :height => 16 }
	value_proc = proc { a = get_option(symb) ; a[:soft] == -1 && a[:smooth] == -1 && a[:hidden] == -1 && a[:cast_shadows] == 1 }
	action_proc = proc { a = get_option(symb) ; a[:soft] = a[:smooth] = a[:hidden] = -1 ; a[:cast_shadows] = 1 ; set_option symb, a }
	s = "#{prefix}__EPX_Plain".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_plain, :tooltip => T6[:T_DLG_EdgePlain], :rank => 1 }
	@palette.declare_button(s, hshb, hsh, { :rank => 1 }, hsha, &action_proc)
	
	value_proc = proc { a = get_option(symb) ; a[:soft] == 0 && a[:smooth] == 0 && a[:hidden] == 0 && a[:cast_shadows] == -1 }
	action_proc = proc { a = get_option(symb) ; a[:soft] = a[:smooth] = a[:hidden] = 0 ; a[:cast_shadows] = -1 ; set_option symb, a }
	s = "#{prefix}__EPX_Diagonal".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_diagonal, :tooltip => T6[:T_DLG_EdgeDiagonal] }
	@palette.declare_button(s, hshb, hsh, hsha, &action_proc)

	@palette.declare_separator
	
	#Soft
	hshb = { :width => 32, :height => 16 }
	value_proc = proc { a = get_option(symb) ; a[:soft] == 1 }
	action_proc = proc { a = get_option(symb) ; a[:soft] = (a[:soft] == 1) ? 0 : 1 ; set_option symb, a }
	s = "#{prefix}__EPX_Soft".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_soft, :tooltip => T6[:T_DLG_EdgeSoft], :rank => 1 }
	@palette.declare_button(s, hshb, hsh, hsha, &action_proc)
	
	value_proc = proc { a = get_option(symb) ; a[:soft] == -1 }
	action_proc = proc { a = get_option(symb) ; a[:soft] = (a[:soft] == -1) ? 0 : -1 ; set_option symb, a }
	s = "#{prefix}__EPX_SoftNo".intern
	hsh = { :value_proc => value_proc, :draw_proc => [:edge_prop_soft, :std_negation], :tooltip => T6[:T_DLG_EdgeSoft] }
	@palette.declare_button(s, hshb, hsh, hsha, &action_proc)

	#Smooth
	value_proc = proc { a = get_option(symb) ; a[:smooth] == 1 }
	action_proc = proc { a = get_option(symb) ; a[:smooth] = (a[:smooth] == 1) ? 0 : 1 ; set_option symb, a }
	s = "#{prefix}__EPX_Smooth".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_smooth, :tooltip => T6[:T_DLG_EdgeSmooth], :rank => 1 }
	@palette.declare_button(s, hshb, hsh, hsha, &action_proc)
	
	value_proc = proc { a = get_option(symb) ; a[:smooth] == -1 }
	action_proc = proc { a = get_option(symb) ; a[:smooth] = (a[:smooth] == -1) ? 0 : -1 ; set_option symb, a }
	s = "#{prefix}__EPX_SmoothNo".intern
	hsh = { :value_proc => value_proc, :draw_proc => [:edge_prop_smooth, :std_negation], :tooltip => T6[:T_DLG_EdgeSmooth] }
	@palette.declare_button(s, hshb, hsh, hsha, &action_proc)
	
	#Hidden
	value_proc = proc { a = get_option(symb) ; a[:hidden] == 1 }
	action_proc = proc { a = get_option(symb) ; a[:hidden] = (a[:hidden] == 1) ? 0 : 1 ; set_option symb, a }
	s = "#{prefix}__EPX_Hidden".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_hidden, :tooltip => T6[:T_DLG_EdgeHidden], :rank => 1 }
	@palette.declare_button(s, hshb, hsh, hsha, &action_proc)
	
	value_proc = proc { a = get_option(symb) ; a[:hidden] == -1 }
	action_proc = proc { a = get_option(symb) ; a[:hidden] = (a[:hidden] == -1) ? 0 : -1 ; set_option symb, a }
	s = "#{prefix}__EPX_HiddenNo".intern
	hsh = { :value_proc => value_proc, :draw_proc => [:edge_prop_hidden, :std_negation], :tooltip => T6[:T_DLG_EdgeHidden] }
	@palette.declare_button(s, hshb, hsh, hsha, &action_proc)

	#Cast Shadows
	value_proc = proc { a = get_option(symb) ; a[:cast_shadows] == 1 }
	action_proc = proc { a = get_option(symb) ; a[:cast_shadows] = (a[:cast_shadows] == 1) ? 0 : 1 ; set_option symb, a }
	s = "#{prefix}__EPX_CastShadows".intern
	hsh = { :value_proc => value_proc, :draw_proc => :edge_prop_cast_shadows, :tooltip => T6[:T_DLG_EdgeCastShadows], :rank => 1 }
	@palette.declare_button(s, hshb, hsh, hsha, &action_proc)
	
	value_proc = proc { a = get_option(symb) ; a[:cast_shadows] == -1 }
	action_proc = proc { a = get_option(symb) ; a[:cast_shadows] = (a[:cast_shadows] == -1) ? 0 : -1 ; set_option symb, a }
	s = "#{prefix}__EPX_CastShadowsNo".intern
	hsh = { :value_proc => value_proc, :draw_proc => [:edge_prop_cast_shadows, :std_negation], :tooltip => T6[:T_DLG_EdgeCastShadows] }
	@palette.declare_button(s, hshb, hsh, hsha, &action_proc)
	
	symb
end

#----------------------------------------------------------------------------------------
# OPENGL: Common drawing for Helpert
#----------------------------------------------------------------------------------------

#OPENGL: Custom drawing of buttons
def common_opengl(symb, dx, dy, main_color, frame_color, selected)
	code = symb.to_s
	lst_gl = []
	dx2 = dx / 2
	dy2 = dy / 2
	
	case code			
	when /__keep/
		ll = [[4,9], [7,11], [9,9], [11, 7], [13, 8], [15,10], [17, 16]]
		pts = ll.collect { |a| Geom::Point3d.new a[0], a[1] + 6 }
		lst_gl.push [GL_LINE_STRIP, pts, 'black', 1, '']
		pts = ll.collect { |a| Geom::Point3d.new a[0], a[1] - 6 }
		lst_gl.push [GL_LINE_STRIP, pts, 'magenta', 3, '']
		ll = [[dx2,dy2+4], [dx2,dy2-5], [dx2,dy2-5], [dx2-3,dy2], [dx2,dy2-5], [dx2+3,dy2]]
		pts = ll.collect { |a| Geom::Point3d.new *a }
		lst_gl.push [GL_LINES, pts, 'blue', 2, '']
	when /__erase/
		ll = [[4,9], [7,11], [9,9], [11, 7], [13, 8], [15,10], [17, 16]]
		pts = ll.collect { |a| Geom::Point3d.new a[0], a[1] + 6 }
		lst_gl.push [GL_LINE_STRIP, pts, 'black', 1, '']
		pts = ll.collect { |a| Geom::Point3d.new a[0], a[1] - 6 }
		lst_gl.push [GL_LINE_STRIP, pts, 'magenta', 3, '']
		ll = [[dx2-4, dy2], [dx2+4,dy2+9], [dx2-4, dy2+9], [dx2+4,dy2]]
		pts = ll.collect { |a| Geom::Point3d.new *a }
		lst_gl.push [GL_LINES, pts, 'red', 2, '']
	end
	lst_gl
end

end	#End class PaletteHelper

end	#module Traductor

