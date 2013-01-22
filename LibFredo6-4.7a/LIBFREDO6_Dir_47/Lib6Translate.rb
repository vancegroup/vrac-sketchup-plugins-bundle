=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright © 2008 Fredo6 - Designed and written December 2008 by Fredo6
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

T6[:TIP_Triangle_Left_Bar] = "Go to First string"	
T6[:TIP_Triangle_Left] = "Go to Previous non-translated string"	
T6[:TIP_Triangle_Right] = "Go to Next non-translated string"	
T6[:TIP_Triangle_Right_Bar] = "Go to Last string"	


#--------------------------------------------------------------------------------------------------------------
# T6 New Language Translation Management (top routines in Lib6Core.rb)
#--------------------------------------------------------------------------------------------------------------			 				   

class T6Mod

def T6Mod.all_supported_languages
	llg = []
	@@hsh_t6.each { |mod, t6| llg += t6.supported_languages }
	llg.uniq
end

#Return the list of supported language (alphabetic order)
def supported_languages
	ls = []
	@hlng.each do |code, val| 
		next if val == 1
		ls.push code 
	end	
	ls.sort { |a, b | a <=> b }
end

#Enumeration method for all symbolic string in alphabetic order --> usage: <t6>.each.symb { |symb, hsh| .... }
def each_symb(alpha_order=true)
	ls = (alpha_order) ? @hstrings.sort { |a, b| a[0] <=> b[0] } : @hstring.to_a
	ls.each do |lsymb|
		yield lsymb[0], lsymb[1]
	end	
end

#Purge unused strings (symbol defined, but no value in default language, i.e. program)
def purge_unused
	#Loop on Modules
	@hstrings.each do |symb, hsh|
		@hstrings.delete symb unless hsh[T6MOD_LNG_DEFAULT]
	end	
	nil
end

#Return the load status for a given language
def is_loaded?(lng)
	@hloaded[lng]
end

#Set the load status for all or some languages
def set_loaded(status, lst_lng=nil)
	lst_lng = @@langpref unless lst_lng
	lst_lng.each do |lng|
		@hloaded[lng] = status 
	end	
	@loaded = status
end

#Make sure all language files are loaded according to the environment @@langpref
def check_loaded
	return if @loaded
	
	#Loading the translation files for the preferred languages
	@@langpref = [Sketchup.get_locale[0..1]] unless @@langpref
	@@langpref.each do |lang|
		T6Mod.load_file @rootname, lang unless @hloaded[lang]
	end
end

#Generate the file for a given language
def write_to_file (file, lng, purge=false)
	return 0 unless @hlng[lng]
	nstrings = 0
	file.puts "__Module = #{@modname}"
	each_symb do |symb, hsh|
		if purge && !hsh[T6MOD_LNG_DEFAULT]
			hsh.delete lng
			next
		end	
		val = hsh[lng]
		if val
			val = val.gsub /[\n]/, "\\n"
			file.puts "#{symb} = \"#{UTF.flatten(val)}\""
			nstrings += 1
		end	
	end	
	return nstrings
end

#Save a translation to file in a given language - if lang == nil, then all supported language)
def T6Mod.save_to_file(rootname, lang=nil, purge=false)
	hroot = @@hsh_root[rootname]
	return 0 unless hroot
	
	#checking if language supported
	if (lang)
		lst_lng = [lang]
	else
		lst_lng = []
		hroot.hsh_t6.each do |key, t6| 
			lst_lng += t6.supported_languages
		end	
		return 0 if lst_lng.length == 0
		lst_lng = lst_lng.uniq
		lst_lng.delete T6MOD_LNG_DEFAULT
	end	
	
	#Writing to file
	nstrings = 0
	lst_lng.each do |lng|
		file = File.join hroot.path, rootname + "_#{lng}.lang"
		File.open(file, "w") do |f| 
			f.puts T6[:T_WARNING_File]
			hroot.hsh_t6.each { |key, t6| nstrings += t6.write_to_file(f, lng, purge) }
		end
	end	
	
	#Propagating the laoded status
	hroot = @@hsh_root[rootname]
	hroot.hsh_t6.each { |key, t6| t6.set_loaded(lst_lng, false) }

	nstrings
end

#Load a file in a given language
def T6Mod.load_file(rootname, lang)
	lang = lang.upcase
	hroot = @@hsh_root[rootname]
	return 0 unless hroot

	#Checking file existence
	file = File.join hroot.path, rootname + "_#{lang}.lang"
	hroot.hsh_t6.each { |hmod, t6| t6.set_loaded(true, lang) }
	return 0 unless FileTest.exist?(file)
	
	#Reading the file
	t6 = nil
	nstrings = 0
	IO.foreach(file) do |line| 	
		line = line.strip
		if line =~ /__Module\s*=\s*(.*)/i
			curmodule = $1.strip
			t6 = @@hsh_t6[curmodule]
		elsif t6 &&	line =~ /(.*)=(.*)/i
			symb = $1.strip
			sval = $2.strip
			sval = $' if sval =~ /\A\"/
			sval = $` if sval =~ /\"\Z/
			t6.store_value(lang, symb, sval)
			nstrings += 1
		end	
	end
	
	#Propagating the laoded status
	hroot.hsh_t6.each { |hmod, t6| t6.set_loaded(true, lang) }

	nstrings
end

#Edit the Language Translation via a Web dialog table
def T6Mod.visual_edition(rootname)
	hroot = @@hsh_root[rootname]
	return unless hroot
	t6edit = hroot.t6edit
	t6edit = T6ModEdit.new(hroot, rootname) unless t6edit
	t6edit.show_dialog
end

#Dialog Box for choosing Preferred Languages (limited version with traditional dialog box)
def T6Mod.dialog_preferred_languages

	#Computing the current Preferred Languages
	key_none = "None"
	hlang = {}
	Langue.each { |lng| hlang[lng] = Langue.nicer lng, true }
	llang = hlang.keys
	llpref = @@langpref & llang
	llang = [key_none] + llang.sort
	hlang[key_none] = T6[:T_STR_None]
	
	#Preparing the Dialog Box
	nl = 3
	hsh_params = {}
	dlg = Traductor::DialogBox.new T6[:T_HELP_MenuLanguages] 
	tl = T6[:T_STR_PreferredLanguages]
	for i in 0..nl-1
		lng = llpref[i]
		space = "                                ~"
		dlg.field_enum "#{i}", tl + " #{i+1}" + space, (lng) ? lng : key_none, hlang, llang
	end	
	
	#Calling the Dialog box
	hsh_params = dlg.show hsh_params
	return unless hsh_params
	
	#Parsing the new lang Pref
	lnew = []
	hsh_params.each do |key, lng|
		i = key.to_i
		lnew[i] = lng unless lng == key_none
	end
	lnew.uniq!
	
	#Setting the new preferred languages
	T6Mod.set_langpref lnew unless (lnew == llpref && @@langpref == llpref)		
end

end	#Class T6Mod

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Dialog box Editor for Language Translation
#--------------------------------------------------------------------------------------------------------------			 				   
#--------------------------------------------------------------------------------------------------------------			 				   

class T6ModEdit

def initialize(hroot, rootname)
	@sepasymb = '_!!_'
	@lst_empty = ["Left_Bar", "Left", "Right", "Right_Bar"]
	@htip_empty = {}
	@lst_empty.each { |a| @htip_empty[a] = T6["TIP_Triangle_#{a}".intern] }

	@rootname = rootname
	@hroot = hroot
	@wdlg = nil
	reset_modif()
	hroot.t6edit = self	
	@id_changes = "ID___Changes"
	@id_left = "ID___Left"
	@nb_left = 0
	@purge_unused = false
	@txt_search = ""
	@reg_search = nil
	
	llpref = T6Mod.get_langpref
	@lng_cur = (llpref && llpref.length > 0) ? llpref[0] : 'FR'
	@llng_sup = T6Mod.get_langpref.sort	
end

def reset_modif
	@hlng_edit = {}
	@hroot_modif = {}
	@hlng_modif = {}
	@str_changes = "&nbsp;"
	if @wdlg
		@wdlg.set_element_value @id_changes, nil, @str_changes
	end	
end

def make_id(modname, symb, lng)
	modname + @sepasymb + symb + @sepasymb + lng
end

def current_value(id)
	v = @hroot_modif[id]
	(v) ? v : @hroot_edit[id]
end

#Create a temporary hash table to store the values based on current language edited and supplementary languages shown
#Create a global hash table with keys made of module name, symbol and language
def prepare_data
	@hroot_edit = {} unless @hroot_edit
	Langue.load_file
	@llng_sup.delete @lng_cur
	([@lng_cur] + @llng_sup).each do |lng|
		next if @hlng_edit[lng]
		@hroot.hsh_t6.each do |modname, t6|
			T6Mod.load_file(@rootname, lng) unless t6.is_loaded?(lng)
			t6.each_symb do |symb, hsh|
				id = make_id modname, symb, lng
				s = hsh[lng]
				@hroot_edit[id] = (s) ? s.gsub(/[\n]/, "\\n") : nil
			end
		end	
		@hlng_edit[lng] = true
	end	
end

#Edit the Lnaguage Translation via a Web dialog table
def show_dialog
	#Reusing or creating the dialog box
	return @wdlg.bring_to_front if @wdlg && @wdlg.visible?
	
	#Creating the dialog box
	header = T6[:T_STR_Translation] + " " + @rootname
	Sketchup.set_status_text header
	regkey = "Traductor_T6ModEdit" 
	@wdlg = Wdlg.new header, regkey
	html = compute_html()
	@wdlg.set_html html
	@wdlg.set_size 700, 550
	@wdlg.set_background_color 'AliceBlue'
	@wdlg.set_callback self.method('visual_callback') 
	@wdlg.show
	UI.start_timer(0.8) { @wdlg.put_focus @lst_ids[0], true }
end

#Edit the Lnaguage Translation via a Web dialog table
def compute_html	
	#initialization
	@color_ok = HTML.color 'oldlace'
	@color_empty = HTML.color 'palegreen'
	@color_sep = HTML.color 'navy'
	@color_error = HTML.color 'lightpink'
	@color_fine = HTML.color 'white'
	@color_modif = HTML.color 'yellow'
	img_addlng = MYPLUGIN.picture_get "Button_Add.png"
	img_change = MYPLUGIN.picture_get "Button_Add.png"

	header = HTML.safe_text(T6[:T_STR_Translation]) + " " + "<span style='color:red'>#{@rootname}</span>"
	note = T6[:T_STR_NoteChange]
	
	#Transfering the values based on current language edited and supplementary languages shown
	prepare_data
	
	#Creating the HTML stream	
	html = HTML.new

	#Styling for screen and printing
	html.body_add HTML.scroll_style("D_SCROLL", '300px')

	html.create_style 'DivTable', nil, 'BD-SZ: 3',
	                  'Bd: solid', 'Bd-col: lightgrey', 'cellspacing: 0', 'align: center', 'width: 96%'
					  
	html.create_style 'InputField', nil, 'F-SZ: 10', 'width: 97%', 'K: red', 'B'
	html.create_style 'InputFieldModif', 'InputField', "BG: #{@color_modif}"
	html.create_style 'CellLangCur', nil, 'K:Black', 'B', 'align: left', 'F-SZ: 11', 'padding-bottom: 3px', 
	                                             'padding-top: 3px'
	html.create_style 'CellLangDef', nil, 'K: blue', 'B', 'F-SZ: 11', 'padding-bottom: 3px'
	html.create_style 'CellLangSup', nil, 'K: purple', 'I', 'F-SZ: 10', 'padding-bottom: 3px'
	
	html.create_style 'ButtonPlus', nil, 'K: black', 'B', 'F-SZ: 9'
	html.create_style 'Button', nil, 'K: black', 'F-SZ: 9'
	html.create_style 'ButtonEmpty', nil, 'B', 'K: white', 'BG: green', 'F-SZ: 10', 'width: 50px'
	html.create_style 'LangControl', nil, 'B', 'K: black', 'F-SZ: 10'
	html.create_style 'LangCur', nil, 'B', 'K: red', 'F-SZ: 9'
	html.create_style 'LangSup', nil, 'B', 'K: green', 'F-SZ: 9'
	html.create_style 'Header', nil, 'B', 'K: blue', 'F-SZ: 13', 'text-align: center'
	html.create_style 'Changes', nil, 'K: red ; B ; I ; F-SZ: 10'
	html.create_style 'Left', nil, 'K: green ; B ; I ; F-SZ: 10'
	html.create_style 'New', nil, 'K: purple ; B ; I ; F-SZ: 9'
	html.create_style 'Note', nil, 'K: dimgray ; B ; I ; F-SZ: 10'
	html.create_style 'Separator', nil, 'K: white ; B ; I ; F-SZ: 13', 'BG: navy', 'text-align: center'
	html.create_style 'ObSeparator', nil, 'K: white ; B ; I ; F-SZ: 13', 'BG: darkgray', 'text-align: center'
	html.create_style 'Obsolete', nil, 'K: purple ; B ; I ; F-SZ: 11'
	
	#Creating the title
	html.body_add HTML.format_div(header, nil, 'Header')
	
	#Creating the header for controlling languages
	tchange = T6[:T_BUTTON_Change]
	tlangcur = Langue.english_name @lng_cur
	txt = "<div width='96%'>"
	txt += "<table cellpadding='6px' cellspacing='2px' width='100%' style='padding-top: 15px'><tr>"
	txt += "<td valign=\"top\">"
	txt += HTML.format_span(T6[:T_STR_ToBeTranslated] + ' ', nil, 'LangControl')
	txt += HTML.format_span '&nbsp;&nbsp;', nil, 'LangCur', nil, Langue.pretty('ZH') 

	#Current Language
	lglist = [['NEW', T6[:T_STR_NewLanguage]]]
	Langue.each do |code|
		cur = Langue.current_name(code)
		nat = Langue.native_name(code)
		lglist.push [code, "#{code}: #{cur}" + ((cur == nat) ? "" : " - #{nat}")] 
	end		
	txt += HTML.format_combobox(@lng_cur, lglist, "ID_ComboCur", 'LangCur', nil, "list lang") do |code|
		(code == 'NEW') ? { "attr", "style = 'color: #{@color_sep}'" } : nil
	end	
	
	#Other languages to show
	lttip = @llng_sup.collect { |lng| Langue.english_name lng }
	txt += "</td><td align=\"right\" valign=\"top\">"
	txt += HTML.format_span(T6[:T_STR_Additional] + ' ', nil, 'LangControl')
	txt += HTML.format_input(@llng_sup.join(' '), nil, "ID_LangSup", 'LangSup', nil, lttip.join('; '))
	txt += "</td>"	
	txt += "</tr></table></div>"	
	html.body_add txt
		
	#Creating the table and buttons
	html.body_add format_table
	
	#Creating the button and footer note
	bempty = []
	@lst_empty.each do |a|
		img = HTML.image_file MYPLUGIN.picture_get("Button_Triangle_#{a}")
		bempty.push HTML.format_imagelink(img, 12, 12, "ID_Empty_#{a}", "", nil, @htip_empty[a])
	end	

	bsave = HTML.format_button(T6[:T_BUTTON_Save], "ButtonSave", 'Button', nil)
	bclose = HTML.format_button(T6[:T_BUTTON_Close], "ButtonClose", 'Button', nil)
	bprint = HTML.format_button(T6[:T_BUTTON_Print], "ButtonPrint", 'Button', nil)
	img = MYPLUGIN.picture_get("Button_Find_Prev")
	bprev = HTML.format_imagelink(img, 16, 16, "ButtonSearchPrev", "", nil, T6[:T_TIP_FindPrev])
	bsearch = HTML.format_input(@txt_search, nil, "ID_Search", 'LangSup', nil, T6[:T_TIP_Find])
	img = MYPLUGIN.picture_get("Button_Find_Next")
	bnext = HTML.format_imagelink(img, 16, 16, "ButtonSearchNext", "", nil, T6[:T_TIP_FindNext])
	
	twid = (RUN_ON_MAC) ? "100%" : "97%"
	html.body_add "<table class='T_NOPRINT_Style' width='#{twid}' cellpadding='0px' cellspacing='2px'><tr>"
	html.body_add "<td width='20%' align='left'>", bempty[0..1].join("&nbsp;"), "&nbsp;&nbsp;&nbsp;", bempty[2..3].join("&nbsp;"), '</td>'
	html.body_add "<td align='center'>", bprev, bsearch, bnext, '</td>'
	html.body_add "<td width='15%' align='center'>", bprint, '</td>'
	html.body_add "<td width='15%' align='right'>", bsave, '</td>'
	html.body_add "<td width='15%' align='right'>", bclose, '</td></tr></table>'
	html.body_add "<div><table width='100%' cellpadding='2px' cellspacing='0'><tr><td align='left'>"
	format_left()
	html.body_add HTML.format_span(@str_left, @id_left, 'Left')
	html.body_add "</td><td align='right'>"
	html.body_add HTML.format_span(@str_changes, @id_changes, 'Changes')
	html.body_add "</td></tr></table></div>"
	html.body_add HTML.format_div(note, nil, 'Note')
	
	#Creating the dialog box
	return html
end

def format_left
	if (@nb_tot == @nb_left)
		@str_left = "&nbsp;"
	else	
		@str_left = "#{T6[:T_STR_LeftTranslate]} #{@nb_left} / #{@nb_tot}"
	end	
end

#Format the main table
def format_table
	@hsh_valcur = {}
	@hsh_valdef = {}
	@hsh_valsup = {}
	@lst_ids = []
	
	#Table begins
	twid = (RUN_ON_MAC) ? "100%" : "97%"
	text = ""
	text += "<div id='TheDivTable' class='D_SCROLL DivTable'>"
	text += "<table width='#{twid}' align='center' cellspacing='0' cellpadding='0px'>"

	#Building the table content
	lng_def = T6MOD_LNG_DEFAULT
	tt1_def = "title='#{Langue.english_name(lng_def)}'"
	tt1_cur = "title='#{Langue.english_name(@lng_cur)}'"
	bd = "Style='border-width: 0 0 2px 0; border-style: solid; border-color: dimgray;'"
	@nb_left = 0
	@nb_tot = 0
	@list_unused = []
	
	#Loop on Modules
	@hroot.hsh_t6.each do |modname, t6| 
	
		#Loop on Symbols
		t6.each_symb do |symb, hsh|
		
			valdef = hsh[lng_def]

			#unused string
			unless valdef
				vcur = hsh[@lng_cur]
				@list_unused.push [symb, vcur] if vcur
				next
			end
			
			id = make_id modname, symb, @lng_cur
			@lst_ids.push id
			tbid = "id='#{id}__Table'"
			valcur = current_value(id)
			valcur = "" unless valcur
			valcur = valcur.gsub /[\n]/, "\\n"
			@nb_left += 1 if valcur == ""
			@nb_tot += 1
			col = (valcur == "") ? @color_empty : @color_ok
			bg = "bgcolor='#{col}'"
			tt2 = "title='#{modname + '::' + symb}'"
			
			text += "<tr><td>"		
			text += "<table #{tbid} width='100%' cellspacing='0', cellpadding='3' #{bg} #{bd} >"		
			#text += '<THEAD>'
			#text += "<COLGROUP span='2'>"
			text += "<COL width='40px'/>"
			text += "<COL />"
			text += "<COL/>"
			#text += '</THEAD>'
			#text += '</COLGROUP>'
			text += '<TBODY>'
								
			txt1 = HTML.format_para @lng_cur, nil, 'CellLangCur'
			vold = @hroot_edit[id]
			vold = "" unless vold
			stylinput = (valcur == vold) ? 'InputField' : 'InputFieldModif'
			txt2 = HTML.format_input valcur, nil, id, stylinput
			text += "<tr><td #{tt1_cur}>#{txt1}</td><td #{tt2}>#{txt2}</td></tr>"

			txt1 = HTML.format_para "--->", nil, 'CellLangDef'
			txt2 = HTML.format_para valdef, nil, 'CellLangDef'
			text += "<tr><td #{tt1_def}>#{txt1}</td><td #{tt2}>#{txt2}</td></tr>"
			
			@hsh_valcur[id] = valcur
			@hsh_valdef[id] = valdef
			
			@llng_sup.each do |lng|
				idsup = make_id modname, symb, lng
				valsup = current_value(idsup)
				next unless valsup && valsup.length > 0
				@hsh_valsup[id] = [] unless @hsh_valsup[id]
				@hsh_valsup[id].push valsup
				tt1_sup = "title='#{Langue.english_name(lng)}'"
				txt1 = HTML.format_para lng, nil, 'CellLangSup'
				txt2 = HTML.format_para valsup, nil, 'CellLangSup'
				text += "<tr><td #{tt1_sup}>#{txt1}</td><td #{tt2}> #{txt2}</td></tr>"
			end
			
			text += "</td></tr></tbody></table>"
		
		end	#Loop on symbols
	end	#Loop on parameters

	#Showing unused strings
	if @list_unused.length > 0
		tx = T6[:T_STR_PurgeUnused]
		ttip = T6[:T_TTIP_PurgeUnused]
		tcheck = HTML.format_checkbox @purge_unused, tx, "ID_PURGE_UNUSED", "", nil, ttip
		text += "<tr class='ObSeparator'><td>#{T6[:T_STR_ObsoleteStrings]}  #{tcheck}</td></tr>"
		@list_unused.each do |ls|
			symb = ls[0].to_s
			val = ls[1]
			tx = HTML.format_para val, nil, 'Obsolete', nil, symb
			text += "<tr><td>#{tx}</td></tr>"
		end	
	end
	
	#terminating the table
	text += "</TABLE></div>"

	return text
end

def visual_callback(event, type, id, svalue)
	case event
	when /wonunload/i
		exit_dialog() if @trap_exit

	when /wonload/i
		@trap_exit = true

	when /onfocus/i
		@cur_focus = id if id && type =~ /text/i && id =~ /!/
	
	when /onkeydown/i
		lskey = svalue.split '*'
		case lskey[0].to_i
		when 13
			if (id == "ID_LangSup")
				val = @wdlg.jscript_get_prop "ID_LangSup", "value"
				change_language_sup val
			end	
		when 27
			@trap_exit = false
			exit_dialog			
		end
		
	when /onchange/i
		case id
		when "ID_ComboCur"
			change_language svalue
		when "ID_LangSup"
			change_language_sup svalue
		when "ID_Search"
			search_register svalue
			search_next_prev 'right'
		when "ID_PURGE_UNUSED"
			@purge_unused = VTYPE.parse_as_bool svalue
			@hlng_modif[@lng_cur] = 0 if @purge_unused && @hlng_modif[@lng_cur] == nil
		else
			record_modif id, svalue
		end	
		
	when /onclick/i
		case id
		when /ButtonChangeCur/i
			newlng = Langue.visual_edition
			change_language(newlng)
			
		when /ButtonSave/i
			save_to_file

		when /ButtonPrint/i
			@wdlg.print

		when /ButtonClose/i
			@trap_exit = false
			exit_dialog

		when /ID_Empty_(.+)/i
			go_to_next_empty $1
		when /ButtonSearchNext/i
			search_next_prev 'right'
		when /ButtonSearchPrev/i
			search_next_prev 'left'
			
		end
	end
	
	return nil
end

#Refresh the dialog box by recomputing the HTML
def refresh_html
	id_focus = @cur_focus
	if id_focus
		a = id_focus.split @sepasymb
		a[2] = @lng_cur
		id_focus = a.join @sepasymb
	end	
	@wdlg.set_html compute_html()
	UI.start_timer(0.8) { @wdlg.put_focus id_focus, true }
end

#Go the the next empty transaltion
def go_to_next_empty (spec)
	case spec
	when /Left_Bar/i
		@wdlg.put_focus(@lst_ids[0], true)
	when /Right_Bar/i
		@wdlg.put_focus(@lst_ids[-1], true)
	else
		loop_on_fields(spec) { |id| (@hsh_valcur[id] == "") }
	end
end

#Perform a loop on each field and execute a function
#The loop stop when the function returns true
def loop_on_fields(spec, &cond_proc)
	@cur_focus = @lst_ids[0] unless @cur_focus
	lst_ids = (spec =~ /Right/i) ? @lst_ids : @lst_ids.reverse
	ibeg = lst_ids.rindex @cur_focus
	return unless ibeg
	
	n = lst_ids.length - 1	
	[ibeg+1..n, 0..ibeg-1].each do |a|
		for i in a
			id = lst_ids[i]		
			if cond_proc.call(id)
				@wdlg.put_focus id, true
				return id
			end	
		end	
	end	
	false
end

#Register the search string
def search_register(text)
	@txt_search = text
	@reg_search = (!text || text.empty?) ? nil : Regexp.new(text, Regexp::IGNORECASE)
end

#Do a search through the texts
def search_next_prev(spec)
	return @wdlg.put_focus(@cur_focus, true) unless @reg_search 
	loop_on_fields(spec) do |id| 
		(@hsh_valcur[id] =~ @reg_search || @hsh_valdef[id] =~ @reg_search)  
	end	
end
	
#Change the current language
def change_language(code)
	code = Langue.visual_edition if code == 'NEW'
	unless code && @lng_cur != code
		@wdlg.set_element_value "ID_ComboCur", 'S', @lng_cur
		return
	end	
	@lng_cur = code
	@trap_exit = false
	refresh_html
end

#Change the supplemnatry languages 
def change_language_sup(llng)
	llng = "" unless llng
	ll = llng.strip.upcase.split(/;\s*|,\s*|\s+/)
	llok = []
	ll.uniq.sort.each do |code| 
		if Langue.is_valid_code?(code.strip)
			llok.push code.strip
		else
			@wdlg.jscript_set_prop "ID_LangSup", "style.backgroundColor", @color_error
			UI.beep
			UI.start_timer(0.3) { @wdlg.put_focus "ID_LangSup", true }
			return
		end	
	end	
	llok.delete @lng_cur
	if llok == @llng_sup
		@wdlg.set_element_value "ID_LangSup", 'S', llok.join(' ')
		@wdlg.jscript_set_prop "ID_LangSup", "style.backgroundColor", @color_fine
		return 
	end	
	@llng_sup = llok
	@trap_exit = false
	refresh_html
end

#Exit Prop with verification
def exit_dialog
	nbmodif = @hroot_modif.length
	status_exit = true
	if (nbmodif > 0)
		case WMsgBox.confirm_changes @str_changes
		when /S/i
			save_to_file
		when /I/
			reset_modif
		when /B/i
			status_exit = false
		end
	end	
	if status_exit
		@wdlg.close if @wdlg.visible?
	else	
		show_dialog
		@trap_exit = true
	end	
end

#Save to files the modifications
def save_to_file
	#Transfering values
	@hroot_modif.each do |id, sval|
		l = id.split(@sepasymb)
		modname = l[0]
		symb = l[1]
		lng = l[2]
		t6 = @hroot.hsh_t6[modname]
		t6.store_value lng, symb, sval
		@hroot_edit[id] = sval
		@wdlg.jscript_set_prop "#{id}", "style.backgroundColor", @color_fine
	end
		
	#Saving to file
	@hlng_modif.each do |lng, n|
		T6Mod.save_to_file @rootname, lng, @purge_unused if n > 0 || @purge_unused
	end	
	@purge_unused = false
	
	#resetting Modif
	reset_modif()
end

def record_modif(id, svalue)
	svalue = svalue.strip if svalue
	@hlng_modif[@lng_cur] = 0 unless @hlng_modif[@lng_cur]
	
	@hsh_valcur[id] = svalue
	
	#checking the new value against the old value
	vused = @hroot_modif[id]
	vold = @hroot_edit[id]
	if vold == svalue
		@hroot_modif.delete id
		@hlng_modif[@lng_cur] -= 1 if vused
		@wdlg.jscript_set_prop "#{id}", "style.backgroundColor", @color_fine
	else
		@hroot_modif[id] = svalue
		@hlng_modif[@lng_cur] += 1 unless vused
		@wdlg.jscript_set_prop "#{id}", "style.backgroundColor", @color_modif
		n = 1
	end	
	
	#updating the field for tracking changes
	nbmodif = @hroot_modif.length
	if nbmodif != 0
		txt = T6[:T_STR_Changes]
		@hlng_modif.each { |lng, n| txt += " #{lng}(#{n})" if n > 0 }
	else
		txt = "&nbsp;"
	end	
	@str_changes = txt
	@wdlg.set_element_value @id_changes, nil, @str_changes
	
	#Updating the number of strings left to be translated
	@nb_left = compute_left_to_translate
	format_left
	@wdlg.set_element_value @id_left, nil, @str_left
	
	#Updating the color of the row
	vold = @hroot_modif[id]
	color = nil
	if svalue && svalue != ""
		color = @color_ok
	else
		color = @color_empty
	end	
	@wdlg.jscript_set_prop "#{id}__Table", "style.backgroundColor", color if color
	
end

#Compute the number of strings left to translate
def compute_left_to_translate
	nleft = 0
	@hsh_valcur.each do |key, val|
		nleft += 1 unless (val && val.length > 0)
	end
	nleft
end

end	#Class T6ModEdit

#--------------------------------------------------------------------------------------------------------------
# Class Langue: Hold Language definitions
#--------------------------------------------------------------------------------------------------------------			 

class Langue

@@hlang = {}
@@prefix = "__Langue_"
@@file = "Langues.def"
@@keepval = false

def Langue.add(code, english_name, native_name)
	return unless code && code.strip != ""
	code = code[0..1]
	@@hlang[code] = [english_name, native_name]
	symb = (@@prefix + code).intern
	T6[symb] = english_name
	T6.store_value(code, symb.to_s, native_name)
	code
end

def Langue.load_file
	file = File.join LibFredo6.path, @@file
	return unless FileTest.exist?(file)
	
	#Reading the file
	IO.foreach(file) do |line| 	
		line = line.strip
		if line =~ /\A(\w\w)\s*=\s*(.*)/
			code = $1
			ls = $2.split(';')
			english_name = UTF.real(ls[0])
			native_name = UTF.real(ls[1])
			Langue.add(code, english_name, native_name)
		end	
	end
end

def Langue.save_to_file
	file = File.join LibFredo6.path, @@file
	File.open(file, "w") do |f| 
		f.puts T6[:T_WARNING_File]
		@@hlang.each do |code, ls|
			f.puts "#{code} = #{UTF.flatten(ls[0])};#{UTF.flatten(ls[1])}"
		end	
	end
end

def Langue.list_codes
	@@hlang.keys.sort
end

#Enumeration method for all symbolic string in alphabetic order --> usage: <t6>.each.symb { |symb, hsh| .... }
def Langue.each
	Langue.list_codes.each { |code| yield code }
end

def Langue.nicer(code, native=false)
	lcur = Langue.current_name(code)
	leng = Langue.english_name(code)
	lnat = Langue.native_name(code)
	s = "#{code}: #{lcur}"
	s += " / #{leng}" if leng != lcur
	s += " / #{lnat}" if native && lnat != lcur && lnat != code && lnat != leng
	s
end

def Langue.pretty(code, native=false)
	"#{code}: #{Langue.current_name(code)}" + ((native) ? " / #{Langue.native_name(code)}" : "")
end

def Langue.list_for_display
	lg = []
	@@hlang.each { |code, ls| lg.push Langue.pretty(code, true) }
	lg.sort
end

def Langue.english_name(code)
	return '--' unless code
	ls = @@hlang[code]
	(ls && ls[0]) ? ls[0] : code
end

def Langue.native_name(code)
	return '--' unless code
	ls = @@hlang[code]
	(ls && ls[1]) ? ls[1] : Langue.english_name(code)
end

def Langue.current_name(code)
	return code unless code
	symb = (@@prefix + code[0..1]).intern
	val = T6[symb]
	(val != symb.to_s) ? val : Langue.english_name(code)
end

def Langue.compute_protected
	@@lng_built_in = "EN;FR;DE;IT;HU;ES;ZH;JA;PT;PL;NL;KO;EL;RU".split(';')
	llg = T6Mod.all_supported_languages + @@lng_built_in
	@@lng_protected = llg.uniq
end

def Langue.initial_values
	return if @@keepval
	
	#Transfering values
	Langue.load_file
	@@llang3 = []
	@@hlang.each do |code, ls|
		english_name = ls[0]
		native_name = ls[1]
		english_name = "" unless english_name
		native_name = "" unless native_name
		@@llang3.push [code, english_name, native_name]
	end
	@nbmodif = 0
	@@lg3cur = ["", "", ""]
	@@keepval = true
	@@lastchange = nil
end

#Calculate the dialog box
def Langue.visual_edition
	#Dialog already active - just give focus
	return @wdlg.bring_to_front if @wdlg && @wdlg.visible?

	#Transfering values
	Langue.initial_values
	Langue.compute_protected
	
	#Creating the dialog box
	header = T6[:T_STR_SupportedLanguages]
	regkey = (RUN_ON_MAC) ? nil : "Traductor_Langue"
	@wdlg = Wdlg.new header, regkey, false, false
	@wdlg.set_position 50, 150
	@wdlg.set_html Langue.compute_html
	@wdlg.set_size 500, 650
	@wdlg.initial_focus 'ID_CODE', true
	@wdlg.set_background_color 'AliceBlue'
	@wdlg.set_callback self.method('visual_callback') 
	@wdlg.show_modal
	@@lastchange
end

def Langue.compute_html
	#initialization	
	header = T6[:T_STR_SupportedLanguages]
	note = T6[:T_STR_NoteChange]
	@color_ok = HTML.color 'lightyellow'
	@color_error = HTML.color 'lightpink'
	@color_code = 'red'
	@color_eng = 'green'
	@color_nat = 'purple'
	
	#Creating the HTML stream	
	html = HTML.new
	
	#style used in the dialog box
	html.create_style 'DivHeader', 'T_DivVHeader', 'BD-SZ: 2',
	                  'Bd: solid', 'Bd-col: lightgrey', 'cellspacing: 0', 'align: center', 'width: 96%'
	#####html.create_style 'DivTable', nil, 'height: 250px', 'BD-SZ: 2',
	html.create_style 'DivTable', nil, 'BD-SZ: 2',
	                  'Bd: solid', 'Bd-col: lightgrey', 'cellspacing: 0', 'align: center', 'width: 96%'
	html.create_style 'InputCode', nil, "BG: #{@color_ok}", "K: #{@color_code}"
	html.create_style 'InputEng', nil, "BG: #{@color_ok}", "K: #{@color_eng}"
	html.create_style 'InputNat', nil, "BG: #{@color_ok}", "K: #{@color_nat}"
	html.create_style 'ShowEng', nil, 'B', "K: #{@color_eng}"
	html.create_style 'ShowNat', nil, 'B', "K: #{@color_nat}"
	html.create_style 'CellBase', nil, 'B', 'F-SZ: 10', 'padding-top: 2px', 'padding-bottom: 2px'
	html.create_style 'CellCode', 'CellBase', 'B', 'F-SZ: 10', "K: #{@color_code}"
	html.create_style 'CellEng', 'CellBase', 'B', 'F-SZ: 10', "K: #{@color_eng}"
	html.create_style 'CellNat', 'CellBase', 'B', 'F-SZ: 10', "K: #{@color_nat}"
	html.create_style 'HCellCode', 'CellCode', 'F-SZ: 11'
	html.create_style 'HCellEng', 'CellEng', 'F-SZ: 11'
	html.create_style 'HCellNat', 'CellNat', 'F-SZ: 11'
	html.create_style 'Button', nil, 'K: black', 'F-SZ: 10'
	html.create_style 'Header', nil, 'B', 'K: blue', 'F-SZ: 13', 'text-align: center', 'margin-bottom: 10px'
	html.create_style 'Note', nil, 'K: dimgray ; B ; I ; F-SZ: 10'
	
	#Creating the title
	html.body_add HTML.scroll_style("D_SCROLL", '250px')
	html.body_add HTML.format_div(header, nil, 'Header')
	
	#Creating the table and button
	html.body_add format_table
	
	#Creating the button and footer note
	b1 = HTML.format_button(T6[:T_BUTTON_Save], id="ButtonSave", 'Button', nil)
	b2 = HTML.format_button(T6[:T_BUTTON_Print], id="ButtonPrint", 'Button', nil)
	b3 = HTML.format_button(T6[:T_BUTTON_Cancel], id="ButtonCancel", 'Button', nil)
	html.body_add "<table class='T_NOPRINT_Style' width='99%' cellpadding='4px'><tr>"
	html.body_add "<td width='33%' align='left'>", b1, '</td>'
	html.body_add "<td width='33%' align='center'>", b2, '</td>'
	html.body_add "<td width='34%' align='right'>", b3, '</td>', '</table>'
	
	#returning the created HTML
	html
end

def Langue.format_table	

	#Table header
	bgcol = HTML.color 'oldlace'
	thead = ""
	thead += "<table width='100%' cellspacing='0', bgcolor='#{bgcol}' cellpadding='2px' frame='below'  rules='rows'>"
	thead += '<TBODY>'
	thead += "<COLGROUP span='4'>"
	thead += "<COL class='CellCode' width='30px'/>"
	thead += "<COL class='CellEng' width='110px'/>"
	thead += "<COL class='CellNat' width='110px'/>"
	thead += "<COL class='CellCode' width=#{HTML.vscrolltable_extra(40)} />"
	thead += '</COLGROUP>'
	
	img_add = MYPLUGIN.picture_get "Button_Add.png"
	img_change = MYPLUGIN.picture_get "Button_change.png"
	img_del = MYPLUGIN.picture_get "Button_Clear.png"
	img_ok = MYPLUGIN.picture_get "Button_Check.png"

	
	#Table head line and input fields
	tcode = T6[:T_STR_LgCode]
	teng = T6[:T_STR_LgEnglish]
	tnat = T6[:T_STR_LgNative]
	f1 = HTML.format_input @@lg3cur[0], 2, "ID_CODE", "InputCode", nil, T6[:T_STR_Lg2Char]
	f2 = HTML.format_input @@lg3cur[1], 20, "ID_ENG", "InputEng", nil, teng
	f3 = HTML.format_input @@lg3cur[2], 20, "ID_NAT", "InputNat", nil, tnat
	badd = HTML.format_button(" + ", id="ButtonAdd", 'Button', nil)
	text = ""
	text += "<div class='DivHeader'>" + thead
	bgcol = "bgcolor=#{HTML.color 'lightgrey'}"
	text += "<tr><td class='HCellCode' #{bgcol}>#{tcode}</td>"
	text += "<td #{bgcol} class='HCellEng'>#{teng}</td>"
	text += "<td #{bgcol} class='HCellNat'>#{tnat}</td>"
	text += "<td #{bgcol}></td></tr>"
	text += "<tr><td>#{f1}</td><td>#{f2}</td><td>#{f3}</td><td>#{badd}</td></tr>"
	text += "</tbody></table></div>"
	
	#List of existing languages
	@@llang3 = @@llang3.sort { |a, b| a[0] <=> b[0] }
	text += "<div class='DivTable D_SCROLL'>" + thead
	@@llang3.each do |l3|
		code = l3[0]
		english_name = l3[1]
		native_name = l3[2]
		english_name = "" unless english_name
		native_name = "" unless native_name
		if @@lng_built_in.include?(code)
			feng = HTML.format_para english_name, "_E_#{code}", 'ShowEng', nil, teng
			fnat = HTML.format_para native_name, "_N_#{code}", 'ShowNat', nil, teng
		else
			feng = HTML.format_input english_name, 20, "_E_#{code}", 'ShowEng', nil, teng
			fnat = HTML.format_input native_name, 20, "_N_#{code}", 'ShowNat', nil, tnat	
		end	
		text += "<tr><td>#{code}</td><td>#{feng}</td><td>#{fnat}</td>"
		bok = HTML.format_imagelink img_ok, 16, 16, "_OK_#{code}", nil, nil, T6[:T_BUTTON_Select]
		unless (@@lng_protected.include?(code))
			bdel = HTML.format_imagelink img_del, 16, 16, "_DEL_#{code}", nil, nil, T6[:T_BUTTON_Delete]
		else
			bdel = ""
		end		
		text += "<td align='right'>#{bok} #{bdel}</td></tr>"
	end	
	text += "</tbody></table></div>"

	return text
end

def Langue.visual_callback(event, type, id, svalue)
	case event
	when /wonload/i
		@trap_exit = true

	when /wonunload/i
		Langue.confirm_exit if @trap_exit && @nbmodif
	
	when /onchange/i
		record_modif id, svalue
		
	when /onclick/i
		case id
		when /ButtonAdd/i
			@trap_exit = false
			@wdlg.set_html compute_html() if Langue.add_current

		when /ButtonCancel/i
			@trap_exit = false
			@wdlg.close if Langue.confirm_exit()
			
		when /ButtonSave/i
			@trap_exit = false
			Langue.button_save
			@wdlg.close

		when /ButtonPrint/i
			@wdlg.print
			
		when /_DEL_(.*)/
			@trap_exit = false
			@wdlg.set_html compute_html() if Langue.button_delete $1
			
		when /_OK_(.*)/
			@@lastchange = $1
			@wdlg.close if Langue.confirm_exit()
		end
	end
	return nil
end

def Langue.is_valid_code?(code)
	code =~ /\A\w\w\Z/
end

def Langue.button_save
	Langue.add_current 
	@@llang3.each { |l3| Langue.add l3[0], l3[1], l3[2]	}
	Langue.save_to_file
	@@keepval = false
	@nbmodif = 0
end

def Langue.button_delete(code)
	ll = []
	@@llang3.each { |l3| ll.push l3 unless code == l3[0] }
	@@llang3 = ll
	@@lg3cur = ["", "", ""]
	@nbmodif += 1
	true
end

def Langue.add_current
	code = @@lg3cur[0]
	return UI.beep unless Langue.is_valid_code?(code)
	@@llang3.each do |l3|
		if code == l3[0]
			l3[1] = @@lg3cur[1] unless @@lg3cur[1] == ""
			l3[2] = @@lg3cur[2] unless @@lg3cur[2] == ""
			return true
		end
	end	
	@@llang3.push [code, @@lg3cur[1], @@lg3cur[2]]
	@@lg3cur = ["", "", ""]
	@@lastchange = code
	true
end

def Langue.record_modif(id, svalue)
	#Checking if the value contains special characters
	if svalue =~ /;/
		svalue = svalue.gsub(';', '')
		@wdlg.set_element_value id, 'S', svalue
	end	
	
	case id
	when /ID_CODE/i
		code = svalue.strip.upcase
		color = @color_ok
		if Langue.is_valid_code?(code)
			@@lg3cur[0] = code
			@@llang3.each do |l3|
				if code == l3[0]
					color = @color_error
					break
				end
			end	
		else
			color = @color_error
			UI.beep
			@@lg3cur[0] = code
		end	
		@wdlg.jscript_set_prop "ID_CODE", "style.backgroundColor", color
		
	when /ID_ENG/i	
		@@lg3cur[1] = svalue
		
	when /ID_NAT/i	
		@@lg3cur[2] = svalue
	
	when /_E_(.*)/
		code = $1
		@@llang3.each { |l3| (l3[1] = svalue ; break) if code == l3[0] }

	when /_N_(.*)/
		code = $1
		@@llang3.each { |l3| (l3[2] = svalue ; break) if code == l3[0] }

	else
		return
	end
	@nbmodif += 1
end

#Exit Prop with verification
def Langue.confirm_exit
	if @nbmodif > 0	
		status = WMsgBox.confirm_changes
		case status
		when 'L'
			return true
		when 'B'
			return Langue.visual_edition unless @wdlg.visible?
			@@lastchange = nil
			return false
		when 'S'
			Langue.button_save
		end
	end	
	@@keepval = false
	@nbmodif = 0
	true
end

end	#class Langue

end #Module Traductor

