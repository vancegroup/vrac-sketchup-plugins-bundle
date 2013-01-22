=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Dec. 2008 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Web.rb
# Original Date	:  10 Dec 2008 - version 3.0
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library to assist web dialog design.
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

T_HTML_DOC_TYPE = %q(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/strict.dtd">)
T_HTML_UTF_TYPE = %q(<META http-equiv='Content-Type' Content='text/html; charset=UTF-8'> )
T_HTML_SCRIPT_TYPE = %q(<META http-equiv='Content-Script-Type' content='text/javascript'>)

#--------------------------------------------------------------------------------------------------------------
# Class VTYPE: Manage validation types
#--------------------------------------------------------------------------------------------------------------			 

VTYPE_INVALID = 1
VTYPE_CONSTRAINT = 2

class VTYPE

attr_reader :strdef, :type, :vmin, :vmax, :message, :extra, :error

#Create a vtype instances from an encoded string
def initialize(strdef, extra=nil, message=nil)
	@strdef = strdef
	@message = message
	@type = nil
	@error = 0
	@extra = extra
	self.parse()
end

#Parse the Vtype definition from a string specification
def parse
	l = @strdef.split ':'
	type = l[0]
	spec = (l.length > 1) ? l[1] : ""
	
	@type = type.strip.upcase
	@vmin = nil
	@vmax = nil
	@pattern = nil
	
	case @type
	when 'B', 'H', '/', 'M', 'O'
	when 'I', 'L', 'F'
		parse_minmax(spec)
	when 'S', 'D', 'K'
		@pattern = spec.strip
	else
		@type = 'S'
	end
end

#Parse the min max value for numbers
def parse_minmax(spec)
	return unless spec
	spec = spec.strip
	
	case spec
	when /<=(.*)>/, /<=(.*)/
		@vmax = '<=' + $1.strip
	when /<(.*)>/, /<(.*)/
		@vmax = '<' + $1.strip
	end
	
	case spec
	when />=(.*)</, />=(.*)/
		@vmin = '>=' + $1.strip
	when />(.*)</, />(.*)/
		@vmin = '>' + $1.strip
	end
end

#Interpret a string as a boolean
def VTYPE.parse_as_bool(svalue)
	case svalue
	when /true/i, /yes/i, true
		return true
	when /false/i, /no/i, false
		return false
	else
		return nil
	end	
end

#Return the real typed value from an output value
def real_value(svalue)
	svalue = svalue.to_s.strip
	val = nil
	begin
		case @type
		when 'I'
			val = Traductor.string_to_integer_formula svalue
		when 'F'
			val = Traductor.string_to_float_formula svalue
		when 'L'
			val = Traductor.string_to_float_formula svalue
		when 'B'
			val = VTYPE.parse_as_bool(svalue)
			return VTYPE.parse_as_bool(svalue)
		when 'H'
			val = KeyList.to_key @extra, svalue
		when 'M', 'O'
			val = svalue
		else
			val = svalue
		end	
	rescue
		return nil
	end
	val	
end

#Return the display value as a string (possibly translated) for a real value
def display_value(value)
	svalue = value.to_s.strip
	return "" if svalue == ""
	sval = svalue
	begin
		case @type
		when 'B'
			case svalue
			when /true/i, /yes/i, true
				return 'true'
			when /false/i, /no/i, false
				return 'false'
			else
				return ''
			end	
		when 'H'
			sval = KeyList.to_value @extra, svalue
		when 'M', 'O'
			sval = KeyList.to_value @extra, svalue
		else
			sval = svalue
		end	
	rescue
		return ''
	end
	sval	
end

def as_text
	text = ""
	case @type
	when 'I'
		text = "Integer"
	when 'F'
		text = "Float"
	when 'L'
		text = "Length"
	when 'B'
		text = "Boolean"
	when 'K'
		text = "Sketchup color"
	when 'D'
		text = "Directory"
	when 'S'
		text = "String"
	when 'H'
		text = "Single selection"
	when 'M'
		text = "Multiple selection"
	when 'O'
		text = "Multiple Ordered selection"
	else
		text = "Free"
	end
	
	#additional Contsraints
	case @type
	when 'I', 'L', 'F'
		text += " #{vmin} " if @vmin
		text += " #{vmax} " if @vmax
	when 'S'
		text += " pattern -> #{@pattern}" if @pattern
	end

	text
end

#Validate a value given in a string - Return value must be tested with (val == nil) to differentiate between real value and invalid value
def validate(svalue, error_level=0)
	#check if the value if valid, according to the type
	val = real_value svalue
	if val == nil
		@error = VTYPE_INVALID
		return nil
	end	
	
	#checking if the value respect the conditions
	status = true
	case @type
	when 'I', 'L', 'F'
		if @vmin
			begin
				status = status && eval(svalue + @vmin)
			rescue
			end
		end	
		if @vmax
			begin
				status = status && eval(svalue + @vmax)
			rescue
			end
		end	
	when 'S'
		if @pattern
			rpat = Regexp.new @pattern, Regexp::IGNORECASE
			status = rpat.match svalue
		end	
	when 'D'
	
	end
	
	#returning the value
	if status
		@error = 0
	else	
		@error = VTYPE_CONSTRAINT
		val = nil
	end	
	val
end

def compare(value1, value2)
	v1 = value1.to_s.upcase
	v2 = value2.to_s.upcase
	v1 <=> v2
end

def equal(value1, value2)
	v1 = value1.to_s.upcase
	v2 = value2.to_s.upcase
	v1 == v2
end

end	#class VTYPE

#--------------------------------------------------------------------------------------------------------------
# Class HTML: Manage an HTML Stream to power web dialog boxes
#--------------------------------------------------------------------------------------------------------------			 

T6[:T_Text_Default] = "Default:"
T6[:T_Text_Type] = "Type:"

class HTML

@@browser = nil
Traductor_HTML_Style = Struct.new("Traductor_HTML_Style", :classname, :parent, :computed, :lattr, :html) 

#Create an HTML stream object
def initialize
	@head = ""
	@body = ""
	@hstyles = {}
	@scripts = ""
	include_standard_styles
end

def get_head ; @head ; end
def get_body ; @body ; end
def get_scripts ; @scripts ; end
	
#Build the HTML for all styles	
def get_html_for_all_styles
	text = ""
	
	#Special styles for Print and Screen
	text += "<style type='text/css' media='print'>"
	text += ".T_NOPRINT_Style { display: none }"
	text += ".T_Repeat_header { display: table-header-group }"
	text += ".T_Repeat_footer { display: table-footer-group }"
	text += "</style>"
	text += "<style type='text/css' media='screen'>"
	text += ".T_NOSCREEN_Style { display: none }"
	text += "</style>"
	
	#Custom styles
	if @hstyles.length > 0
		text += "<style type='text/css'>"
		text += "* { margin: 0; padding: 2px; }" if RUN_ON_MAC
		@hstyles.each do |key, style|
			compute_style style
			text += ' ' + style.html + ' '
		end	
		text += "</style>"
	end

	text
end
	
def HTML.scroll_style(style_name, height)
	text = "<style type='text/css' media='screen'>"
	text += ".#{style_name} {position: relative; height: #{height}; overflow-y: auto; overflow-x: hidden; }"
	text += "</style>"
	text
end
	
#Create a Style structure identified by its classname
def create_style(classname, parent, *args)
	return unless classname && classname.strip != ""
	
	#Creating or identifying the style
	style = @hstyles[classname]
	unless style
		style = Traductor_HTML_Style.new
		style.computed = false
		style.classname = classname
		style.parent = parent
		style.html = ""
		style.lattr = []
		@hstyles[classname] = style
	end	
	
	#Calculating the attributes
	lattr = []
	args.each { |s| lattr += s.split(';') }
	lattr.each do |s|
		case s.strip
		when /\AB\Z/i		#bold --> 'B'
			sval = 'font-weight: bold'
		when /\AI\Z/i		#Italic --> 'I'
			sval = 'font-style: italic'
		when /\AK:(.*)/i	#SU color --> 'K:<color>'
			color = HTML.color($1) 
			sval = 'color: ' + color if color 
		when /\ABG:(.*)/i	#SU color --> 'BG:<color>'
			color = HTML.color($1) 
			sval = 'background-color: ' + color if color 
		when /\AF-SZ:\s*(\d*)/i, /\AF-SZ:\s*(\d+)pt/i	#Font size in pt --> 'F-sz:<size>'
			npx = ($1 == "") ? '1' : $1
			sval = "font-size: #{npx}pt" 
		when /\AF-SZ:\s*(\d*)px/i	#Font size in pixel --> 'F-SZ:<size>' 
			npx = ($1 == "") ? '1' : $1
			sval = "font-size: #{npx}px" 
		when /\ABD:\s*(.*)/i	#Border style' 
			sval = "border-style: #{$1}" 
		when /\ABD-SZ:\s*(\d*)/i, /\ABD-SZ:(\d*)px/i	#Border size in px --> 'Bd-sz:<size>'
			npx = ($1 == "") ? '1' : $1
			sval = "border-width: #{npx}pt" 
		when /\ABD-COL:\s*(.*)/i	#SU color --> 'K:<color>'
			color = HTML.color($1) 
			sval = 'border-color: ' + color if color 
		else
			sval = s.strip
		end	
		next if sval == ""
		style.lattr += [sval]
	end	
end

#Return the CSS string for the class
def style_css(classname)
	style = @hstyles[classname]
	return nil unless style
	compute_style style
	style.html =~ /\{(.*)\}/
	$1
end

#Include the standard styles
def include_standard_styles
	#style for custom tooltips
	create_style 'T_ToolTip', nil, 'visibility: hidden;', 'position: absolute;', 
				                   'top: 0;', 'left: 0;', 'z-index: 1000;', 'display: block',
								   'font: normal 8pt sans-serif;', 'padding: 3px;',
								   'border: solid 1px;', 'BG: yellow ;'

	#style for multi list
	create_style 'T_DivMultiList', nil, 'BD-SZ: 1',
				 'Bd: solid', 'Bd-col: LightGrey', 'cellspacing: 0', 'align: center', 
				 'F-SZ: 10', 'K:Black', 'font-weight: normal'

	#styles related to vScroll
	if HTML.browser =~ /6/ || RUN_ON_MAC
		create_style 'T_DivVHeader', nil, 'margin-right: 15px'
	else	
		create_style 'T_DivVHeader', nil
	end
end

#Calculate the final HTML String for the style
def compute_style(style)
	return if style.computed
	
	#Computing recursively the parent
	lattr = style.lattr
	sparent = (style.parent) ? @hstyles[style.parent] : nil
	style.computed = true
	unless sparent == nil || sparent.computed
		compute_style sparent
	end	
	lattr = sparent.lattr + lattr if sparent
	
	#Removing duplicate attributes and computing final HTML string
	return if lattr.length == 0	
	hkey = {}
	lattr.each { |s| hkey[$`.strip.upcase] = s if (s =~ /:/) }
	style.html = ".#{style.classname} { " + hkey.values.join(' ; ') + "}" if lattr.length > 0
end

def head_add(*args)
	args.each { |html| @head += html if html }
end	

def body_add(*args)
	args.each { |html| @body += html if html }
end	

def script_add(*args)
	args.each { |js| @scripts += js if js }
end	

#=========================================================
# Class methods to help building HTML flow
#=========================================================

#Modify the string to make sure it displays in HTML
def HTML.safe_text(s)
	return s if s.class != String || s =~ /\A<.+>\Z/
	s = s.gsub("&", "&amp;") unless s =~ /&.+;/
	s = s.gsub("'", "&rsquo;")
	s = s.gsub("<", "&lt;")
	s = s.gsub(">", "&gt;")
	s
end

#Return the browser type
def HTML.browser
	#@@browser = SysInfo['BROWSER'] unless @@browser
	@@browser = '7'
	@@browser
end

#Return the offset for last column of table within a vertical scrolling DIV
def HTML.vscrolltable_extra(width)
	width += 15 unless (HTML.browser =~ /6/)
	"#{width}px"
end

#Compute an HTML color from a SU Color
def HTML.color(colorname)
	begin
		color = Sketchup::Color.new colorname
		s = ""
		s += sprintf "%02x", color.red
		s += sprintf "%02x", color.green
		s += sprintf "%02x", color.blue
		return '#' + s
	rescue
		return colorname
	end	
end

#Compute a constrating color, black or white
def HTML.contrast_color(colorname)
	begin
		color = Sketchup::Color.new colorname
		return ((color.red + color.green + color.blue) > 300) ? "#000000" : "#FFFFFF"
	rescue
		return "#000000"
	end	
end

#Combine HTML and style parameters into one string with deduplicate of class= and style=
def HTML.merge_style_class(*args)
	pat_style = /style\s*=\s*["']([^'"]*)["']/i
	pat_class = /class\s*=\s*["']([^'"]*)["']/i
	full = args.join " "
	hstyle = []
	hclass = []
	htext = ""
	
	args.each do |tx|
		tx.scan(pat_style) { |a| hstyle += a }
		tx.scan(pat_class) { |a| hclass += a }
		t1 = tx.gsub pat_style, ""
		t2 = t1.gsub pat_class, ""
		htext += " " + t2
	end
	tres = ""
	tres += htext.strip
	tres += " class='#{hclass.join(' ')}'" unless hclass.empty?
	tres += " style='#{hstyle.join(' ; ')}'" unless hstyle.empty?
	tres
end

#Format the event callbacks from a list of actions
def HTML.format_actions(lst_actions)
	lst_actions = [lst_actions] unless lst_actions.class == Array
	ls = lst_actions.uniq
	txt = ""
	ls.each do |action| 
		a = action.strip
		if a =~ /oncheck/i
			txt += " OnClick='Action_checkbox(" + '"' + "OnClick" + '"' + ", this)'" 
		else	
			txt += " #{a}='Action(" + '"' + a + '"' + ", this)'" 
		end	
	end	
	txt
end

#Format a text element as a poragraph
def HTML.format_para(text, id="", classname="", extra_actions=[], tooltip="")
	attr = HTML.format_attr id, classname, [], extra_actions, tooltip
	text = text.gsub /[\n]/, "<br>"
	"<p #{attr}>" + HTML.safe_text(text) + '</p>'
end

#Format a text element as a span
def HTML.format_span(text, id="", classname="", extra_actions=[], tooltip="")
	attr = HTML.format_attr id, classname, [], extra_actions, tooltip
	text = text.gsub /[\n]/, "<br>"
	"<span #{attr}>" + HTML.safe_text(text) + '</span>'
end

#Format a text element as a div
def HTML.format_div(text, id="", classname="", extra_actions=[], tooltip="")
	attr = HTML.format_attr id, classname, [], extra_actions, tooltip
	text = text.gsub /[\n]/, "<br>"
	"<div #{attr}>" + text + '</div>'
end

#Format a Entry field
def HTML.format_input(text, nbchar, id="", classname="", extra_actions=[], tooltip="")
	attr = HTML.format_attr id, classname, ['onChange'], extra_actions, tooltip
	bchar = ""
	if nbchar.class == Integer
		bchar = "maxlength='#{nbchar}' size='#{nbchar+1}'" if (nbchar > 0) 
	elsif nbchar.class == String
		bchar = "size='#{nbchar}'"
	end	
	focus = (RUN_ON_MAC) ? "onfocus='j6_track_focus() ;'" : ""
	"<input type='text' #{bchar} value=\"#{HTML.safe_text text}\" #{attr} #{focus}/>"
end

#Format a Push button
def HTML.format_button(text, id="", classname="", extra_actions=[], tooltip="")
	attr = HTML.format_attr id, classname, ['onClick'], extra_actions, tooltip
	"<input type='button' style='cursor:pointer' value=\"#{HTML.safe_text text}\" #{attr}/>"
end

#Format an image link
def HTML.format_imagelink(imgsrc, px, py, id="", classname="", extra_actions=[], tooltip="", href="")
	attr = HTML.format_attr id, classname, ['onClick'], extra_actions, tooltip
	hstyle = "style='cursor:pointer'"
	href = (href && href.length > 0) ? "href='#{href}'" : ""
	imgsrc = HTML.image_file imgsrc
	"<a #{href} #{hstyle}><img src='#{imgsrc}' #{hstyle} #{attr} height='#{py}' width='#{px}' border='0'/></a>"
end

#Format an image link
def HTML.format_textlink(text, id="", classname="", extra_actions=[], tooltip="", href="")
	attr = HTML.format_attr id, classname, ['onClick'], extra_actions, tooltip
	hstyle = "style='cursor:pointer ; text-decoration: underline'"
	href = (href && href.length > 0) ? "href='#{href}'" : ""
	"<a #{href} #{hstyle} #{attr}>#{HTML.safe_text text}</a>"
end

#Format a Checkbox
def HTML.format_checkbox(bool, text, id="", classname="", extra_actions=[], tooltip="")
	attr = HTML.format_attr id, classname, ['onCheck'], extra_actions, tooltip
	checked = (bool) ? "checked='checked'" : ""
	"<input type='checkbox' value=\"#{text}\" #{checked} #{attr}><span #{attr}>#{HTML.safe_text text}</span></input>"
end

#Format a table with columns of equal width
def HTML.format_table_equal_column(nbcol, paramtable, lst)
	if paramtable
		txt = "<table #{paramtable}>"
	else	
		txt = "<table width='99%' cellpadding='1px'>"
	end

	n = lst.length - 1
	m = (n / nbcol + 1) * nbcol - 1
	for i in 0..m	
		txt += "<tr>" if i.modulo(nbcol) == 0
		txt += "<td width='33%' align='left'>#{lst[i]}</td>"
		txt += "</tr>" if i.modulo(nbcol) == nbcol-1
	end
	txt += "</tr></table>"
	txt
end

#Format a Combobox
def HTML.format_combobox(value, klist, id="", classname="", extra_actions=[], tooltip="", &extraproc)
	attr = HTML.format_attr id, classname, ['onChange'], extra_actions, tooltip
	txt = "<select #{attr}>"
	KeyList.each(klist) do |code, s|
		hextras = (extraproc) ? yield(code) : nil
		next if hextras && hextras['skip']
		exattr = (hextras && hextras['attr']) ? hextras['attr'] : "" 
		text = (hextras && hextras['text']) ? hextras['text'] : s 
		tip = (hextras && hextras['tip']) ? hextras['tip'] : "" 
		htip = "title='#{tip}'" unless tip == ""
		selected = ((code == value) || (code.to_s.upcase == value.to_s.upcase)) ? 'selected' : ''
		txt += "<option #{htip} value='#{code}' #{exattr} #{selected}>#{HTML.safe_text text}</option>"
	end	
	txt += "</select>"
	txt
end

#Format a List Box
def HTML.format_listbox(value, klist, nb_item=5, id="", classname="", extra_actions=[], tooltip="", &extraproc)
	attr = HTML.format_attr id, classname, ['onChange', 'onClick'], extra_actions, tooltip
	txt = "<select size='#{nb_item}' #{attr}>"
	KeyList.each(klist) do |code, s|
		hextras = (extraproc) ? yield(code) : nil
		next if hextras && hextras['skip']
		exattr = (hextras && hextras['attr']) ? hextras['attr'] : "" 
		text = (hextras && hextras['text']) ? hextras['text'] : s 
		tip = (hextras && hextras['tip']) ? hextras['tip'] : "" 
		htip = "title='#{tip}'" unless tip == ""
		selected = ((code == value) || (code.to_s.upcase == value.to_s.upcase)) ? 'SELECTED' : ''
		txt += "<option #{htip} value='#{code}' #{exattr} #{selected}>#{HTML.safe_text text}</option>"
	end	
	txt += "</select>"
	txt
end

#Format a Combobox for Color picking
def HTML.format_SUcolorpicker(value, list, id="", classname="", extra_actions=[], tooltip="")
	attr = HTML.format_attr id, classname, ['onChange'], extra_actions, tooltip
	txt = "<select #{attr}>"
	list.each do |s|
		selected = (s.upcase == value.upcase) ? 'selected' : ''
		txcol = "style='color: #{HTML.contrast_color s} ; background-color: #{HTML.color s}'"	
		txt += "<option #{txcol} value='#{s}' #{selected}>#{s}</option>"
	end	
	txt += "</select>"
	txt
end

#Format a control area for a multi-selection non-ordered list
def HTML.format_multi_list(jsvalue, klist, id="", classname="", extra_actions=[], jsdefval=nil, hmax = nil)
	lsel = jsvalue.split(';;')
	ldef = jsdefval.split(';;')
	vlist = KeyList.values klist
	ylist = KeyList.keys klist
	
	#Creating the Div, enclosing the control
	if (vlist.length == 1)
		h = 20
	else
		hmax = 80 unless hmax
		hmax = 40 if hmax < 40
		h = vlist.length * 20
		h = hmax if h > hmax
		h = 40 if h < 40
	end	
	
	style_scroll = "Multi_SCROLL_#{h}"
	txt = ""
	txt += HTML.scroll_style(style_scroll, "#{h}px")

	txt += "<table width='99%' cellpadding='0px'><tr>"
	txt += "<td width='90%' align='left'>"
	
	txt += "<div width=99% class='#{style_scroll} T_DivMultiList'>"
	
	#Creating the value field
	txt += "<input type='hidden' value='#{jsvalue}' id='#{id}'/>"
	
	#Creating the list of options, with relevant status
	vlist.each_index do |i|
		id_option = id + "_Option____#{i}"
		checked = (lsel.include?(ylist[i])) ? "checked='checked'" : ""
		defval = (ldef.include?(ylist[i]))
		tdef = "title='#{T6[:T_Text_Default]} " + ((defval) ? 'true' : 'false') + "'"
		attr = HTML.format_attr id_option, classname, nil, nil, ""
		action = "onclick='multi_changed(\"#{id}\")'"
		txt += "<input type='checkbox' value='#{ylist[i]}' #{tdef} #{checked} #{action} #{attr}>"
		txt += "<span #{tdef}>#{vlist[i]}</span></input>"
		txt += "<br>"
	end	
	txt += "</div></td>"
	
	#Buttons clear and select all
	if vlist.length > 1
		txt += "<td width='10%' align='left' valign='top'>"
		imgall = HTML.image_file MYPLUGIN.picture_get("Button_Check.png")
		idall = "id='#{id}__All'"
		titall = "title='#{T6[:T_BUTTON_SelectAll]}'"
		actionall = "onclick='multi_select_all(\"#{id}\")'"
		noprint = "class='T_NOPRINT_Style'"

		imgclear = HTML.image_file MYPLUGIN.picture_get("Button_Clear.png")
		idclear = "id='#{id}__Clear'"
		titclear = "title='#{T6[:T_BUTTON_ClearAll]}'"
		actionclear = "onclick='multi_clear(\"#{id}\")'"
		href = "style='cursor:pointer'"
		space = "hspace='2' vspace='2' height='16' width='16' border='0'"
		txt += "<a #{href}><img src='#{imgall}' #{idall} #{titall} #{actionall} #{noprint} #{space}/></a><br>"
		txt += "<a #{href}><img src='#{imgclear}' #{idclear} #{titclear} #{actionclear} #{noprint} #{space}/></a>"
		txt += "</td>"
	end
	
	txt += "</tr></table>"

	txt
end

#Format a control area for a multi-selection ordered list
def HTML.format_ordered_list(jsvalue, klist, id="", classname="", extra_actions=[], jsdefval=nil, 
                             hmax = nil, colsel='lightcyan')
	lsel = jsvalue.split(';;')
	ldef = jsdefval.split(';;')
	vlist = KeyList.values klist
	ylist = KeyList.keys klist
	
	#Only one element in the list
	if (vlist.length == 1) 
		return HTML.format_multi_list(jsvalue, klist, id, classname, extra_actions, jsdefval, hmax)
	end
	
	#Creating the Div, enclosing the control
	hmax = 80 unless hmax
	hmax = 40 if hmax < 40
	h = vlist.length * 20
	h = hmax if h > hmax
	h = 40 if h < 40
	
	style_scroll = "Ordered_SCROLL_#{h}"
	txt = ""
	txt += HTML.scroll_style(style_scroll, "#{h}px")

	txt += "<table width='99%' cellpadding='0px'><tr>"
	txt += "<td width='90%' align='left'>"
	
	txt += "<div width=99% class='#{style_scroll} T_DivMultiList'>"
	
	#Selection color
	colsel = 'lightcyan' unless colsel && colsel.strip != ""
	hcolsel = HTML.color colsel
	
	#Creating the value field
	txt += "<input type='hidden' value='#{jsvalue}' id='#{id}'/>"
	idsel = "#{id}_Selection____"
	idcol = "#{id}_Color____"
	txt += "<input type='hidden' value='' id='#{idsel}'/>"
	txt += "<input type='hidden' value='#{hcolsel}' id='#{idcol}'/>"
	
	#creating the correspondance list for ordering
	lsorted = []
	lsel.each { |v| j = ylist.index(v) ; lsorted.push j if j }
	ylist.each_index { |i| lsorted.push i unless lsorted.include?(i) }
	
	#Creating the table for options
	id_table = id + "_Table____"
	txt += "<table id='#{id_table}' cellspacing='0' cellpadding='0' width='90%'>"
	lsorted.each_with_index do |i, k|
		id_option = id + "_Option____#{i}"
		checked = (lsel.include?(ylist[i])) ? "checked='checked'" : ""
		defval = (ldef.include?(ylist[i]))
		tdef = "title='#{T6[:T_Text_Default]} " + ((defval) ? 'true' : 'false') + "'"
		attr = HTML.format_attr id_option, classname, nil, nil, ""
		action = "onclick='ordered_changed(\"#{id}\", \"#{i}\")'"
		trid = id + "_tr____#{i}"
		tdid = id + "_td____#{i}"
		tdaction = "onclick='ordered_highlight(\"#{id}\", \"#{i}\")'"
		txt += "<tr id='#{trid}' style='cursor:pointer'>"
		txt += "<td>"
		txt += "<input type='checkbox' style='cursor:default' "
		txt += "value='#{ylist[i]}' #{tdef} #{checked} #{action} #{attr}>"
		txt += "</td>"
		txt += "<td id='#{tdid}' #{tdaction} style='cursor:pointer'>"
		txt += "<span #{tdef}>#{vlist[i]}</span></input>"
		txt += "</td></tr>"
	end	
	txt += "</table>"
	txt += "</div></td>"
	txt += "<td width='10%' align='left' valign='top'>"

	imgall = HTML.image_file MYPLUGIN.picture_get("Button_Check.png")
	idall = "id='#{id}__All'"
	titall = "title='#{T6[:T_BUTTON_SelectAll]}'"
	actionall = "onclick='ordered_select_all(\"#{id}\")'"

	imgclear = HTML.image_file MYPLUGIN.picture_get("Button_Clear.png")
	idclear = "id='#{id}__Clear'"
	titclear = "title='#{T6[:T_BUTTON_ClearAll]}'"
	actionclear = "onclick='ordered_clear(\"#{id}\")'"

	imgup = HTML.image_file MYPLUGIN.picture_get("Button_Up.png")
	idup = "id='#{id}__Up'"
	titup = "title='#{T6[:T_BUTTON_Up]}'"
	actionup = "onclick='ordered_move_row (\"#{id}\", \"up\")'"

	imgdown = HTML.image_file MYPLUGIN.picture_get("Button_Down.png")
	iddown = "id='#{id}__Down'"
	titdown = "title='#{T6[:T_BUTTON_Down]}'"
	actiondown = "onclick='ordered_move_row (\"#{id}\", \"down\")'"
	
	href = "style='cursor:pointer'"
	space = "hspace='2' vspace='2' height='16' width='16' border='0' class='T_NOPRINT_Style'"
	txt += "<a #{href}><img src='#{imgup}' #{idup} #{titup} #{actionup} #{space}/></a><br>"
	txt += "<a #{href}><img src='#{imgdown}' #{iddown} #{titdown} #{actiondown} #{space}/></a>"
	if (vlist.length > 3)
		txt += "<br>"
		txt += "<a #{href}><img src='#{imgall}' #{idall} #{titall} #{actionall} #{space}/></a><br>"
		txt += "<a #{href}><img src='#{imgclear}' #{idclear} #{titclear} #{actionclear} #{space}/></a>"
	end	
	txt += "</td></tr></table>"

	txt
end

#Utility to format Id, classname and actions
def HTML.format_attr(id, classname, default_actions, extra_actions, tooltip)
	lst_actions = ((default_actions) ? default_actions : []) + ((extra_actions) ? extra_actions : [])
	tid = ( id && id != "") ? "id='#{id}'" : ""
	actions = HTML.format_actions lst_actions
	attr = (classname && classname != "") ? "class= '#{classname}'" : ""
	ttip = ""
	if (tooltip && tooltip != "")
		tooltip = HTML.safe_text tooltip
		if tooltip =~ /\A_TT/i
			actions += " onmouseover='tooltip_show(\"#{tooltip}\");'"
			actions += " onmouseout='tooltip_hide(\"#{tooltip}\");'"
		else
			ttip = "title='#{tooltip}'"
		end	
	end	
	return "#{tid} #{ttip} #{attr} #{actions}"
end

def HTML.image_file(imgsrc)
	(RUN_ON_MAC && !(imgsrc =~ /file:\/\//i)) ? "file://" + imgsrc : imgsrc
end

end	#class HTML

end #Module Traductor
