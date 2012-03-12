=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright © 2008 Fredo6 - Designed and written September 2008 by Fredo6
#
# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Config.rb
# Original Date	:  10 Sep 2008 - version 3.0
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library about Plugin Configuration for LibFredo6-compliant scripts.
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

#--------------------------------------------------------------------------------------------------------------
# Class KeyList: manage simple list, a hash table, or an ordered list [[key, value], ...]
#--------------------------------------------------------------------------------------------------------------

class KeyList

#Enumerator for a KeyList
def KeyList.each(klist)
	if klist.class == Hash
		klist.each { |key, val| yield key, val }
	elsif klist[0].class == Array && klist[0].length == 2
		klist.each { |ls| yield ls[0], ls[1] }
	else
		klist.each { |a| yield a, a }
	end	
end

#Build the list of values from a KeyList
def KeyList.values(klist)
	if klist.class == Hash
		lsv = klist.values
	elsif klist[0].class == Array && klist[0].length == 2
		lsv = []
		klist.each { |kv| lsv.push kv[1] }
	else
		lsv = klist
	end	
	lsv
end

#Build the list of values from a KeyList
def KeyList.keys(klist)
	if klist.class == Hash
		lsv = klist.keys
	elsif klist[0].class == Array && klist[0].length == 2
		lsv = []
		klist.each { |kv| lsv.push kv[0] }
	else
		lsv = klist
	end	
	lsv
end

#Return the key from a KeyList
def KeyList.to_key(klist, val)
	key = val
	if klist.class == Hash
		key = klist.index val
	elsif klist[0].class == Array && klist[0].length == 2
		klist.each do |kv|
			if kv[1] == val
				key = kv[0]
				break
			end	
		end	
	end	
	key
end

#Return the value from a KeyList
def KeyList.to_value(klist, key)
	val = key
	if klist.class == Hash
		val = klist[key]
	elsif klist[0].class == Array && klist[0].length == 2
		klist.each do |kv|
			if kv[0] == key
				val = kv[1]
				break
			end	
		end	
	end	
	val
end

end	#class KeyList

#--------------------------------------------------------------------------------------------------------------
# Class PictureFamily: for declaring foledrs where images are stored
#--------------------------------------------------------------------------------------------------------------			 				   

class PictureFamily

def initialize(base_folder, prefix)
	base_folder = "" unless base_folder
	@base_folder = base_folder.strip
	prefix = "" unless prefix
	@prefix = prefix
	@list_folders = nil
	@selected_folders = []
	@dstandard = nil
end

#Return the list of folder name (by ref to Base_folder), excluding the standard one
def all_folders
	#already computed
	return @list_folders if @list_folders
	
	#Computing the list of files
	sudir = LibFredo6.sudir	
	@list_folders = []
	dstandard = nil
	Dir[File.join(sudir, @base_folder, @prefix + '*')].each do |d|
		next unless FileTest.directory?(d)
		if d =~ /standard\Z/i				
			@dstandard = File.basename(d)
		else	
			@list_folders.push File.basename(d)
		end	
	end	
	@list_folders = @list_folders.sort
end

#Compute the list of selected folders, with base related to Sketchup Plugin directory
def selected_folders(selected_folders=nil)
	image_folders unless @list_folders
	selected_folders = @selected_folders unless selected_folders
	selected_folders = [selected_folders] unless selected_folders.class == Array
	@selected_folders = selected_folders
	ldir = []
	selected_folders.each do |d|
		ldir.push File.join(@base_folder, d) if @list_folders.include?(d)
	end
	ldir += [File.join(@base_folder, @dstandard)] if @dstandard
	ldir	
end

def oldget_picture(picfile, selfolders=nil)
	ldir = selected_folders(selfolders)
end

end	#class Picture Family

#--------------------------------------------------------------------------------------------------------------
# Class DefaultParameters: Manage default parameters
#--------------------------------------------------------------------------------------------------------------			 
T6[:DEFPARAM_Title] = "Default Parameters:"
T6[:DEFPARAM_AlternateIcon] = "Folder for Alternate Icons, cursors and other images"

class DefaultParameters

Traductor_DefParam = Struct.new("Traductor_DefParam", :symb, :value, :defvalue, :editvalue, :vtype, :description, 
                                                      :hidden, :banner, :wdefvalue) 
													  
public

#Declare a default parameter - <symb> must be a symbol, not a string
def declare(symb, defvalue, type, extra=nil, description=nil)
	ssymb = symb.to_s
	dp = @hparam[ssymb]
	unless dp
		dp = Traductor_DefParam.new
		@hparam[ssymb] = dp
		@lparam.push dp
		dp.value = defvalue
	end
	
	#Loading the type
	type = type.strip
	dp.hidden = false
	if type =~ /\A\^/
		dp.hidden = true
		type = $'
	end	
	
	#Hack for matching color names exactly
	if type =~/\AK/i && defvalue
		defvalue = defvalue.strip
		col = Sketchup::Color.names.find { |name| name.upcase == defvalue.upcase }
		defvalue = col if col
	end
	
	#Storing parameters
	dp.symb = ssymb
	dp.defvalue = defvalue
	dp.vtype = VTYPE.new type, extra
	dp.description = (description) ? description : symb
	
	dp
end

#add a callback for notification of changes
def add_notify_proc(proc)
	@lst_notify_proc = [] unless @lst_notify_proc
	@lst_notify_proc.push proc if proc
end

#Declare a separator section
def separator(symb, options=nil, description=nil)
	declare symb, nil, '/' + ((options) ? ':' + options : ''), nil, description
end

def declare_edge_prop_PSMH(symb, default)
	declare symb, default, 'M', [['P', T6[:T_DLG_EdgePlain]], ['S', T6[:T_DLG_EdgeSoft]], 
	                             ['M', T6[:T_DLG_EdgeSmooth]], ['H', T6[:T_DLG_EdgeHidden]]]
end

def declare_edge_prop_SMH(symb, default)
	declare symb, default, 'M', [['S', T6[:T_DLG_EdgeSoft]], ['M', T6[:T_DLG_EdgeSmooth]], ['H', T6[:T_DLG_EdgeHidden]]]
end

def declare_edge_prop_SM(symb, default)
	declare symb, default, 'M', [['S', T6[:T_DLG_EdgeSoft]], ['M', T6[:T_DLG_EdgeSmooth]]]
end

#Declare an alternative list of folders for images
def alternate_icon_dir(symb, deflist, list_folder)
	declare symb, deflist, 'O', list_folder, T6[:DEFPARAM_AlternateIcon]
end

def get_description_string(dp)
	symb = dp.description
	return symb unless symb.class == Symbol
	begin
		s = @hmod.module_eval "T6[:#{symb}]"
	rescue
		s = symb.to_s
	end
	s
end

#Get a default parameter
def [](symb, default=nil)
	get_value symb, default
end

def get_value(symb, default=nil)
	if @hmod != Traductor && symb.class == Symbol && (symb.id2name =~ /\AT_/ || symb.id2name =~ /\AT6_/)
		val = Traductor::MYDEFPARAM[symb]
		return val if val
	end	
	#dp = @hparam[symb.to_s] 
	dp = which_dp symb
	(dp) ? dp.value : default		
end

#Set a default parameter
def []=(symb, value)
	set_value symb, value
end

def set_value(symb, value)
	dp = which_dp symb
	(dp) ? (dp.value = value) : nil
end

def which_dp(symb)
	ssymb = symb.to_s
	dp = @hparam[ssymb] 
	unless dp
		return nil unless ssymb =~ /_Reg_/i
		dp = declare symb, "", '^S'
	end
	dp
end

#Edit the Default Parameters via a Web dialog table
def visual_edition(title=nil)
	return @wdlg.bring_to_front if @wdlg && @wdlg.visible?
	load_file
	compute_dialog(title)
	@wdlg.show if @wdlg
end

#Load parameter file
def load_file
	#Checking if file exists
	return false unless FileTest.exist?(@file)
	
	#reading the file
	IO.foreach(@file) do |line| 	
		case line
		when /___def___(.*)=\s*"(.*)"/
			symb = $1.strip
			svalue = $2
			flagdef = true
		when /___def___(.*)=\s*(.*)(#|\Z)/
			symb = $1.strip
			l = $2.split('"')
			svalue = l[1] if l.length > 0
			flagdef = true
		when /(.*)=\s*"(.*)"/
			symb = $1.strip
			svalue = $2
			flagdef = false
		when /(.*)=\s*(.*)(#|\Z)/
			symb = $1.strip
			l = $2.split('"')
			svalue = l[1] if l.length > 0
			flagdef = false
		else
			next
		end	
		
		#Saving the value
		dp = which_dp symb
		next unless dp		
		
		value = dp.vtype.real_value svalue
		
		if flagdef
			dp.wdefvalue = (value == nil) ? nil : value
		else
			dp.value = (value == nil || (dp.wdefvalue != dp.defvalue && !no_default_check?(symb))) ? dp.defvalue : value
		end
	end

	true
end

def add_no_default_check(*lst_symb)
	@lst_no_default_check = [] unless @lst_no_default_check
	@lst_no_default_check += lst_symb
end

def no_default_check?(symb)
	@lst_no_default_check = [] unless @lst_no_default_check
	@lst_no_default_check.include?(symb)
end

#Save default parameters to file
def save_to_file
	begin
		File.open(@file, "w") do |f| 
			f.puts T6[:T_WARNING_File]
			@lparam.each do	|dp| 
				next if dp.vtype.type == '/'
				svalue = (dp.defvalue.class == Array) ? dp.defvalue.join(';;') : dp.defvalue
				f.puts "___def___#{dp.symb} = \"#{svalue}\"" 
				svalue = (dp.value.class == Array) ? dp.value.join(';;') : dp.value
				f.puts "#{dp.symb} = \"#{svalue}\"" 
			end	
		end
		return true
	rescue
		text = "LibFredo6: Could NOT save the file for Default Parameter #{File.basename @file}"
		LibFredo6.log "?#{text}"
		UI.messagebox text
		return false
	end	
end

#%%%%%% PRIVATE SECTION
private

#Display error message with invalid values
def signal_errors
	text = T6[:T_ERROR_InvalidValue]
	@herror.each do |key, val|
		dp = @hparam[key]
		text += "\n" + get_description_string(dp) + " --> " + dp.editvalue.to_s
	end
	UI.messagebox text
	nil
end

def defparam_callback(event, type, id, svalue)
	case event
	
	#Command buttons
	when /onclick/i
		case id
		when "ButtonSave"
			if @herror.length > 0
				signal_errors
				return nil
			end
			#notify callback - build list of parameters modified
			if @lst_notify_proc
				lst_modif = []
				@hparam.each do |key, dp|
					lst_modif.push [dp.symb.intern, dp.value] if dp.value != dp.editvalue
				end	
			end	
			
			#transfering and saving
			@hparam.each { |key, dp| dp.value = dp.editvalue }
			save_to_file
			@wdlg.close
			
			#Notify back
			if @lst_notify_proc
				@lst_notify_proc.each do |proc|
					lst_modif.each { |ll| proc.call ll[0], ll[1] }
				end
			end
			
		#Closing the window
		when "ButtonCancel"
			@wdlg.close

		#Printing the window
		when "ButtonPrint"
			@wdlg.print
			
		#Resetting all parameters to default	
		when "ButtonReset"
			@hparam.each do |id, dp|
				@wdlg.set_element_value id, dp.vtype, dp.defvalue, true unless dp.editvalue == dp.defvalue
			end
		else
			if id =~ /(.*)__reset/i
				id = $1
				dp = @hparam[id]			
				@wdlg.set_element_value id, dp.vtype, dp.defvalue, true unless dp.editvalue == dp.defvalue
			end			
		end
		return nil
	
	#Reset factory default for the field
	when /onimage/i
		if id =~ /(.*)__reset/i
			id = $1
			dp = @hparam[id]			
			@wdlg.set_element_value id, dp.vtype, dp.defvalue, false #unless dp.editvalue == dp.defvalue
		end
		return nil
		 
	#Changes to fields	
	when /onchange/i
		dp = @hparam[id]
		vtype = dp.vtype
		val = dp.vtype.validate(svalue)
		trid = "#{dp.symb}__tr"
		if (val == nil)
			@wdlg.jscript_set_prop trid, "style.backgroundColor", @color_err
		elsif vtype.equal(val, dp.defvalue)
			@wdlg.jscript_set_prop trid, "style.backgroundColor", @color_def
		else
			@wdlg.jscript_set_prop trid, "style.backgroundColor", @color_mod
		end
		
		#Storing the value
		if (val == nil) 
			@herror[id] = dp.vtype.error
			dp.editvalue = svalue
			return nil
		else
			@herror.delete id
		end	
		dp.editvalue = val
		
		#Updating the field (for those with formulas)
		return (['I', 'F', 'L'].include?(vtype.type)) ? val.to_s : nil
	end
end

#Calculate the dialog box
def compute_dialog(title=nil)
	@color_def = HTML.color 'oldlace'
	@color_err = HTML.color 'lightpink'
	@color_mod = HTML.color 'yellow'
	@color_sep = HTML.color 'navy'

	header = HTML.safe_text T6[:DEFPARAM_Title]
	header += " " + "<span style='color:red'>#{title}</span>" if title
	note = T6[:T_STR_NoteChange]
	
	#Transfering the values
	@hparam.each { |key, dp| dp.editvalue = dp.value }
	
	#Creating the HTML stream	
	html = HTML.new
	
	#style used in the dialog box
	html.body_add HTML.scroll_style("D_SCROLL", '350px')
	html.create_style 'DivTable', nil, 'BD-SZ: 3',
	                  'Bd: solid', 'Bd-col: red', 'cellspacing: 0', 'align: center', 'width: 96%'
	html.create_style 'CellBorder', nil, 'border-style: solid', 'BD-SZ: 2', 'BD-COL: LightGrey', 
	                  "BG: #{@color_def}", 'B', 'F-SZ: 11', 'padding-top: 3px', 'padding-bottom: 3px'
	html.create_style 'CellInput', 'CellBorder'
	html.create_style 'CellDesc', 'CellBorder'
	html.create_style 'CellModif', 'CellBorder', 'BG: yellow', 'I', 'K: blue'
	html.create_style 'Button', nil, 'K: black', 'F-SZ: 10'
	html.create_style 'Header', nil, 'B', 'K: blue', 'F-SZ: 13', 'text-align: center', 'margin-bottom: 10px'
	html.create_style 'Note', nil, 'K: dimgray ; B ; I ; F-SZ: 10'
	html.create_style 'Separator', nil, 'K: white ; B ; I ; F-SZ: 13', 'BG: navy', 'text-align: center'
	
	#Creating the title
	html.body_add HTML.format_div(header, nil, 'Header')
	
	#Creating the tooltip for defaults
	#html.body_add "<div id='_TT_DefType' class='T_ToolTip'>"
	#html.body_add HTML.format_para("<b>default</b><br><i>Type</i>", nil, 'ID_TT_DefVal')
	#html.body_add HTML.format_para("Type", nil, 'ID_TT_DefType')
	#html.body_add "</div>"

	#Creating the table and button
	html.body_add format_table
	
	#Creating the button and footer note
	b1 = HTML.format_button(T6[:T_BUTTON_Cancel], id="ButtonCancel", 'Button', nil)
	b2 = HTML.format_button(T6[:T_BUTTON_ResetFactory], id="ButtonReset", 'Button', nil)
	b3 = HTML.format_button(T6[:T_BUTTON_Print], id="ButtonPrint", 'Button', nil)
	b4 = HTML.format_button(T6[:T_BUTTON_Save], id="ButtonSave", 'Button', nil)
	html.body_add "<table class='T_NOPRINT_Style' width='99%' cellpadding='4px'><tr>"
	html.body_add "<td width='25%' align='left'>", b1, '</td>'
	html.body_add "<td width='25%' align='center'>", b2, '</td>'
	html.body_add "<td width='25%' align='center'>", b3, '</td>'
	html.body_add "<td width='25%' align='right'>", b4, '</td></tr></table>'
	html.body_add HTML.format_div(note, nil, 'Note')
	
	#Creating the dialog box
	header = T6[:DEFPARAM_Title] + " " + title if title
	regkey = "Traductor_DefParam"
	@wdlg = Wdlg.new header, regkey
	@wdlg.set_html html
	@wdlg.set_size 750, 800
	@wdlg.set_background_color 'AliceBlue'
	@wdlg.set_callback self.method('defparam_callback') 
	
end

def check_apostroph(s)
	s = s.gsub "'", "&rsquo;" if s.class == String
	s
end

def format_table	
	#Table begins
	text = ""
	text += "<div class='D_SCROLL DivTable'>"
	text += "<table width='97%' cellspacing='0px', cellpadding='2px' frame='below'  rules='rows' >"
		
	#Building the table layout
	text += '<TBODY>'
	text += "<COLGROUP span='3'>"
	text += "<COL class='CellDesc'/>"
	text += "<COL class='CellInput' width='200px'/>"
	text += "<COL width=#{HTML.vscrolltable_extra(20)} />"
	text += '</COLGROUP>'
	
	#Building the table content
	list_color = Sketchup::Color.names
	img_factory = MYPLUGIN.picture_get "Button_Factory.png"
	
	@lparam.each do |dp|
		next if dp.hidden
		if dp.vtype.type == 'M' || dp.vtype.type == 'O'
			ls = dp.defvalue.split(';;').collect { |a| dp.vtype.display_value a }
			tip = ls.join("\n")			
		else
			tip = dp.vtype.display_value(dp.defvalue)
		end
		defval = "#{T6[:T_Text_Default]} <#{check_apostroph tip}>" +
		         "\n#{T6[:T_Text_Type]} #{dp.vtype.as_text}"
		defval = nil if dp.vtype.type == '/'
		txt1 = HTML.format_para get_description_string(dp), nil, "", nil, defval
		tdid = "id = #{dp.symb}__tr"
		
		#Section separator
		if dp.vtype.type == '/'
			text += "<tr #{tdid} class='Separator'><td colspan='3'>#{txt1}</td></tr>" 
			next
		end	
		
		#Value fields
		case dp.vtype.type
		when /B/i
			txt2 = HTML.format_checkbox dp.value, '', dp.symb, "", nil, defval
		when /K/i	
			txt2 = HTML.format_SUcolorpicker dp.value, list_color, dp.symb, "", nil, defval
		when /H/i	
			hsh = dp.vtype.extra 
			dv = KeyList.to_key hsh, dp.value
			txt2 = HTML.format_combobox dv, hsh, dp.symb, "", nil, defval if hsh
		when /O/i	
			hsh = dp.vtype.extra 
			txt2 = HTML.format_ordered_list dp.value, hsh, dp.symb, "", nil, dp.defvalue if hsh
		when /M/i	
			hsh = dp.vtype.extra 
			txt2 = HTML.format_multi_list dp.value, hsh, dp.symb, "", nil, dp.defvalue if hsh
		else	
			txt2 = HTML.format_input "#{dp.value.to_s}", nil, dp.symb, "", nil, defval
		end
		
		col = dp.vtype.equal(dp.value, dp.defvalue) ? @color_def : @color_mod
		bg = "bgcolor='#{col}'"
		txt3 = HTML.format_imagelink(img_factory, 16, 16, dp.symb + "__reset", "T_NOPRINT_Style", [], T6[:T_BUTTON_ResetFactory])
		attr = HTML.format_attr("#{dp.symb}__tr", nil, nil, nil, defval)
		text += "<tr #{attr} #{bg}><td>#{txt1}</td><td>#{txt2}</td><td>#{txt3}</td></tr>"
		
	end	#Loop on parameters
	
	text += "</TBODY></TABLE></div>"

	return text
end

end	#class DefParam

end #Module Traductor

