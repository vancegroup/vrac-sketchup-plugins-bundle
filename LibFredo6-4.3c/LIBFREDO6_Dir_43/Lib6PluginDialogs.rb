=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright © 2011 Fredo6 - Designed and written August 2011 by Fredo6
#
# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Plugin.rb
# Original Date	:  10 Dec 2008 - version 3.0
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library about Plugin Configuration for LibFredo6-compliant scripts.
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

T6[:TIP_rbFiles] = "Time to read and load Ruby files"
T6[:TIP_toolbar] = "Time to create menus and toolbar icons"
T6[:TXT_Phase2] = "Phase 2"
T6[:TIP_Phase2] = "Some plugins load few files at Sketchup startup and then load most of the remaining files at first utilization"
T6[:TXT_AtSUStartup] = "At Startup of Sketchup"
T6[:MSG_AllInMs] = "All time values are in milliseconds"
T6[:TXT_AverageLast] = "Average on last %1 SU startups"

T6[:TXT_LogMessage] = "Trace Message (source code line as tooltip)"
T6[:TXT_LogSession] = "Sketchup Session:"
T6[:TXT_LogCurrentSession] = "Current Session:"

T6[:MSG_AboutToDelete] = "You are about to delete %1 files or folders"
T6[:MSG_NothingToDelete] = "No file or folder to delete"
T6[:T_MSG_DeleteDirectory] = "Delete Directory %1?"

T6[:TIP_GenerationMasked] = "All directory names are masked in the export file"
T6[:TIP_GenerationExportTxt] = "Export File as Text"
T6[:MSG_GenerationExport] = "Export File generated: %1"
T6[:MSG_GenerationExport_Error] = "Error in generation of TXT file: %1"
T6[:MSG_ViewViaEditor] = "Click to view the file in the Text editor"

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Dialog box for Purge Obsolete files
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

class PurgeObsoleteDialog

@@top_dialog = nil

#Invoke the purge Obsolete Dialog
def PurgeObsoleteDialog.invoke
	unique_key = "Traductor_PurgeObsolete_DLG"
	@@top_dialog = PurgeObsoleteDialog.new(unique_key) unless Traductor::Wdlg.check_instance_displayed(unique_key)
end	

#initialization of the dialog box 
def initialize(unique_key)
	#Creating the dialog box
	@wdlg = create_dialog_top unique_key
end

#--------------------------------------------------------------------------------------------------------------
# Dialog box configuration
#--------------------------------------------------------------------------------------------------------------			 

#Create the dialog box
def create_dialog_top(unique_key)
	init_dialog_top
	wdlg_key = unique_key
	title = T6[:T_HELP_MenuPurgeObsolete]
	@wdlg = Traductor::Wdlg.new title, wdlg_key, false
	@wdlg.set_unique_key unique_key
	@wdlg.set_size @wid_total, @hgt_total
	@wdlg.set_background_color 'lightyellow'
	@wdlg.set_callback self.method('topdialog_callback') 
	@wdlg.set_on_close { on_close_top() }
	refresh_dialog_top
	@wdlg.show
	@wdlg
end

#Initialize parameters of the dialog box
def init_dialog_top
	#Column width and Heights
	@hgt_table = 300
	@wid_extra = (RUN_ON_MAC) ? 40 : 80
	@wid_col_file = 250
	@wid_col_dir = 300
	@wid_col_sel = 50
	@wid_total = @wid_col_file + @wid_col_dir + @wid_col_sel + @wid_extra
	@hgt_total = @hgt_table + 200	
end

#Refresh the dialog box
def refresh_dialog_top
	@wdlg.set_html format_html_top(@wdlg)
end

#Notification of window closure
def on_close_top
	@@top_dialog = nil
end

#Close the dialog box
def close_dialog_top
	@wdlg.close
end

#Call back for Statistics Dialog
def topdialog_callback(event, type, id, svalue)
	case event
		
	#Command buttons
	when /onclick/i
		case id
		when 'ButtonDone'
			@wdlg.close
		when 'ButtonPrint'
			@wdlg.print
		when /ButtonDelete/
			delete_selected_files(id =~ /All\Z/i)
			@hsh_files = nil
			refresh_dialog_top
		when 'ID_SEL'
			select_unselect_all true
		when 'ID_UNSEL'
			select_unselect_all false
		end

	when /onchange/i
		case id
		when /Sel__(.+)__(\d+)\Z/i
			@hsh_selected_files[id][1] = svalue
		end
		
	when /onKeyUp/i	#Escape and Return key
		@wdlg.close if svalue =~ /\A27\*/
		
	end
	true
end

#Build the HTML for Statistics Dialog
def format_html_top(wdlg)
	#Creating the HTML stream	
	html = Traductor::HTML.new
		
	#Special_scripts
	html.script_add special_scripts
	
	#style used in the dialog box
	bgcolor = 'BG: lightblue'
	space2 = "&nbsp;&nbsp;"
	
	html.create_style 'Title', nil, 'B', 'K: navy', 'F-SZ: 16', 'text-align: center'
	html.create_style 'Header', nil, 'B', 'F-SZ: 11', 'K: black', bgcolor, 'text-align: left'
	html.create_style 'Col_', nil, 'text-align: left'
	html.create_style 'Col_File', 'Col_', 'B', 'text-align: left'
	html.create_style 'Col_Dir', 'Col_', 'K: green', 'text-align: left'
	html.create_style 'Col_Sel', 'Col_', 'B', 'K: darkblue', 'text-align: left'
	html.create_style 'Level0', nil, 'B', 'F-SZ: 12', 'K: black'
	html.create_style 'Level1', nil, 'B', 'F-SZ: 11', 'K: black'
	html.create_style 'Level2', nil, 'F-SZ: 10', 'K: darkblue'
	html.create_style 'Error', nil, 'F-SZ: 10', 'K: red'
	html.create_style 'Button', nil, 'F-SZ: 10'
	html.create_style 'ButtonU', 'Button', 'BG: yellow'	

	#Creating the main table
	@xtable = Traductor::HTML_Xtable.new "XT0", html, wdlg
	hoptions = option_xtable
	@ltable = prepare_xtable
	txt_table = @xtable.format_table @ltable, hoptions
	
	#Creating the title
	title = T6[:T_HELP_MenuPurgeObsolete]
	text = ""
	text += "<div cellspacing='0px' cellpadding='0px' class='Title'>#{title}</div>"
	text += "<div style='height: 6px'>&nbsp</div>"
	html.body_add text
	
	#Header for the table
	img_select = HTML.image_file MYPLUGIN.picture_get("Button_Check.png")
	img_unselect = HTML.image_file MYPLUGIN.picture_get("Button_Clear.png")
	sx = sy = 16
	csel = HTML.format_imagelink img_select, sx, sy, "ID_SEL", "", nil, T6[:T_BUTTON_SelectAll]
	cunsel = HTML.format_imagelink img_unselect, sx, sy, "ID_UNSEL", "", nil, T6[:T_BUTTON_UnSelectAll]
	wid = @wid_col_file + @wid_col_dir + 17
	text = "<div><table width='100%' cellspacing='0' cellpadding='0'><tr>"
	text += "<td width='#{wid}px' align='left' valign='bottom'>#{@xtable.html_expand_buttons}</td>"
	text += "<td align='left' valign='bottom'>#{csel}#{cunsel}</td>"
	text += "</tr></table></div>"
	html.body_add text

	#Inserting the main table
	html.body_add "<div>", txt_table, "</div>"
	
	#Creating the dialog box button	
	butdone = HTML.format_button T6[:T_BUTTON_Done], id="ButtonDone", 'Button', nil
	butprint = HTML.format_button T6[:T_BUTTON_Print], id="ButtonPrint", 'Button', nil
	butdelete = HTML.format_button T6[:T_BUTTON_Delete], id="ButtonDelete", 'ButtonU', nil
	butdelete_all = HTML.format_button T6[:T_BUTTON_DeleteAll], id="ButtonDeleteAll", 'ButtonU', nil
	html.body_add "<table class='T_NOPRINT_Style' width='99%' cellpadding='6px'><tr>"
	html.body_add "<td width='25%' align='left'>", butprint, "</td>"
	html.body_add "<td width='50%' align='center'>", butdelete, space2, butdelete_all, "</td>"
	html.body_add "<td align='right'>", butdone, "</td>"
	html.body_add "</tr></table>"
		
	#Returning the HTML object
	html	
end

#Specific scripts for Downloading information
def special_scripts()
	text = %Q~

function obs_select_all(str_lst, val) {
	var lst = str_lst.split(";") ;
	var len = lst.length
	for (var i = 0 ; i < len ; i++) {
		obj = document.getElementById (lst[i]) ;
		obj.checked = val ;
	}	
}

~
	text
end

#Select or Unselect all
def select_unselect_all(val)
	lst = []
	@hsh_selected_files.each do |key, a|
		file, selected = a
		lst.push key if (selected && !val) || (!selected && val)
		@hsh_selected_files[key][1] = val
	end	
	@wdlg.execute_script "obs_select_all('#{lst.join(";")}', #{val})" unless lst.empty?
end

#--------------------------------------------------------------------------------------------------------------
# Managing Obsolete files
#--------------------------------------------------------------------------------------------------------------			 

#Processing the deletion of files
def delete_selected_files(flg_all)
	lsfiles = []
	@hsh_selected_files.each do |key, a|
		file, selected = a
		lsfiles.push file if flg_all || selected
	end	
	return UI.messagebox(T6[:MSG_NothingToDelete]) if lsfiles.empty?
	
	text = T6[:MSG_AboutToDelete, "#{lsfiles.length}"] + "\n" + T6[:T_STR_PleaseConfirm]
	return if UI.messagebox(text, MB_YESNO) != 6
	
	lsfiles.each { |f| @hsh_error[f] = true }
	lsfiles.each do |f| 
		if FileTest.directory?(f)
			text = T6[:T_MSG_DeleteDirectory, File.basename(f)] + "\n" + f
			next if UI.messagebox(text, MB_YESNO) != 6
		end	
		@hsh_error.delete f if enleve_file_or_folder(f) 
	end	
end

#Delete a file or a directory
def enleve_file_or_folder(path)
	begin
		#File
		unless FileTest.directory?(path)
			status = File.delete path
			return((status == 1) ? true : false)
		end
		
		#Directory
		ls = Dir[File.join(path, "*")]
		if ls.empty?
			Dir.delete path
			return !FileTest.exist?(path)
		else	
			ls.each do |f| 
				return false unless enleve_file_or_folder(f) 
			end	
			return enleve_file_or_folder(path)
		end	
		
	rescue	
		return false
	end	
	false
end

#Options for the Xtable
def option_xtable
	#Specification for columns and headers	
	h1 = []
	h1.push({ :content => T6[:T_TXT_FileOrFolder], :style => "Header" })
	h1.push({ :content => T6[:T_TXT_RootDirectory], :style => "Header" })
	h1.push({ :content => "", :style => "Header" })
	
	c = []
	c.push({ :style => "Col_File", :width => @wid_col_file })
	c.push({ :style => "Col_Dir", :width => @wid_col_dir })
	c.push({ :style => "Col_Sel T_NOPRINT_Style2", :width => @wid_col_sel })
	
	lv0 = { :style => "Level0" }
	lv1 = { :style => "Level1", :css_style => "border-top: 2px solid steelblue" }
	lv2 = { :style => "Level2" }
	
	#Returning the Options
	hoptions = { :columns => c, :headers => h1, :levels => [lv0, lv1, lv2],
				 :body_height => "#{@hgt_table}px" }	
end

#Prepare the Xtable for Plugin obsolete files
def prepare_xtable
	@hsh_error = {} unless @hsh_error
	error_style = { :class => 'Error' }
	serror = T6[:T_TXT_Error]
	ltable = []
	@hsh_selected_files = {}
	hsh = collect_files
	cbtip = T6[:T_BUTTON_Select] + " / " + T6[:T_BUTTON_UnSelect]
	hsh.each do |key, ls|
		tip = AllPlugins.compute_tooltip key
		ltable.push [1, ["#{key} (#{ls.length})", tip, { :colspan => 3}]]
		ls.each_with_index do |a, i|
			file = File.basename a
			dir = File.dirname(a)
			sdir = File.basename dir
			dir0 = File.dirname dir
			sdir0 = File.basename dir0
			id = "SEL__#{key}__#{i}"
			@hsh_selected_files[id] = [a, false]
			cb = Traductor::HTML.format_checkbox false, "", id, "Col_Sel", nil, ""
			fitem = (@hsh_error[a]) ? [file, a + " #{serror}", error_style] : [file, a]
			ltable.push [2, fitem, [sdir0 + '/' + sdir, dir], [cb, cbtip]]
		end	
	end	
	ltable
end

#Collect all files for purge
def collect_files
	return @hsh_files if @hsh_files
	@hsh_files = {}
	AllPlugins.get_all_registered_plugins.each do |key, hsh|
		ls = AllPlugins.get_obsolete_files(key)
		@hsh_files[key] = ls unless ls.empty?
	end
	@hsh_files
end

end	#class PurgeObsoleteDialog

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Dialog box for Performance and load times
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

class PerformanceDialog

@@top_dialog = nil

#Invoke the purge Obsolete Dialog
def PerformanceDialog.invoke
	unique_key = "Traductor_Performance_DLG"
	@@top_dialog = PerformanceDialog.new(unique_key) unless Traductor::Wdlg.check_instance_displayed(unique_key)
end	

#initialization of the dialog box 
def initialize(unique_key)
	@wdlg = create_dialog_top unique_key
end

#--------------------------------------------------------------------------------------------------------------
# Dialog box configuration
#--------------------------------------------------------------------------------------------------------------			 

#Create the dialog box
def create_dialog_top(unique_key)
	init_dialog_top
	wdlg_key = unique_key
	@wdlg = Traductor::Wdlg.new @title, wdlg_key, false
	@wdlg.set_unique_key unique_key
	@wdlg.set_size @wid_total, @hgt_total
	@wdlg.set_background_color 'lightyellow'
	@wdlg.set_callback self.method('topdialog_callback') 
	@wdlg.set_on_close { on_close_top() }
	refresh_dialog_top
	@wdlg.show
	@wdlg
end

#Initialize parameters of the dialog box
def init_dialog_top
	#Column width and Heights
	@hgt_table = 300
	@wid_extra = (RUN_ON_MAC) ? 40 : 80
	@wid_col_plugin = 240
	@wid_col_time = 85
	@wid_total = @wid_col_plugin + 5 * @wid_col_time + @wid_extra + 10
	@hgt_total = @hgt_table + 230	
	@hgt_total += 30 if RUN_ON_MAC
	@title = T6[:T_HELP_PluginLoadTime]
end

#Refresh the dialog box
def refresh_dialog_top
	html = format_html_top @wdlg
	@wdlg.set_html html
end

#Notification of window closure
def on_close_top
	@@top_dialog = nil
end

#Close the dialog box
def close_dialog_top
	@wdlg.close
end

#Call back for Statistics Dialog
def topdialog_callback(event, type, id, svalue)
	case event
		
	#Command buttons
	when /onclick/i
		case id
		when 'ButtonDone'
			@wdlg.close
		when 'ButtonPrint'
			@wdlg.print
		end	

	when /onKeyUp/i	#Escape and Return key
		@wdlg.close if svalue =~ /\A27\*/
		
	end
	true
end

#Build the HTML for Statistics Dialog
def format_html_top(wdlg)
	#Creating the HTML stream	
	html = Traductor::HTML.new
			
	#style used in the dialog box
	space2 = "&nbsp;&nbsp;"
	
	html.create_style 'Title', nil, 'B', 'K: navy', 'F-SZ: 16', 'text-align: center'
	html.create_style 'Infoms', nil, 'I', 'K: slateblue', 'F-SZ: 10', 'text-align: left'
	html.create_style 'Plugin', nil, 'B', 'F-SZ: 11', 'K: black', 'text-align: left'
	html.create_style 'Average', nil, 'B', 'I', 'F-SZ: 10', 'K: purple', 'text-align: left'
	html.create_style 'PluginH', 'Plugin', 'text-align: left'
	html.create_style 'TimeBlueH', nil, 'B', 'F-SZ: 11', 'K: blue', 'BG: aquamarine', 'text-align: center'
	html.create_style 'TimeBlue', nil, 'B', 'F-SZ: 11', 'K: blue', 'BG: aquamarine', 'text-align: right'
	html.create_style 'TimeBlueR', nil, 'I', 'F-SZ: 10', 'K: blue', 'BG: aquamarine', 'text-align: right'
	html.create_style 'TimeBlueA', nil, 'B', 'F-SZ: 10', 'K: purple', 'BG: aquamarine', 'text-align: right'
	html.create_style 'Phase2', nil, 'B', 'F-SZ: 11', 'K: green', 'BG: khaki', 'text-align: right'
	html.create_style 'GrandTot', nil, 'B', 'F-SZ: 11', 'K: black', 'BG: pink', 'text-align: right'
	html.create_style 'Button', nil, 'F-SZ: 10'

	#Creating the main table
	@xtable = Traductor::HTML_Xtable.new "XT0", html, wdlg
	@ltable = prepare_xtable
	hoptions = option_xtable
	txt_table = @xtable.format_table @ltable, hoptions
	
	#Creating the title
	text = ""
	text += "<div cellspacing='0px' cellpadding='0px' class='Title'>#{@title}</div>"
	text += "<div style='height: 6px'>&nbsp</div>"
	html.body_add text
	
	#Inserting the main table
	html.body_add "<div>", txt_table, "</div>"
	
	#Creating the dialog box button	
	txms = HTML.format_span T6[:MSG_AllInMs], "", "Infoms"
	html.body_add "<table width='99%' cellpadding='6px'>"
	html.body_add "<tr>#{txms}</tr><table>"
	
	butdone = HTML.format_button T6[:T_BUTTON_Done], id="ButtonDone", 'Button', nil
	butprint = HTML.format_button T6[:T_BUTTON_Print], id="ButtonPrint", 'Button', nil
	html.body_add "<table class='T_NOPRINT_Style' width='99%' cellpadding='6px'><tr>"
	html.body_add "<td width='25%' align='left'>", butprint, "</td>"
	html.body_add "<td width='50%' align='center'>", space2, "</td>"
	html.body_add "<td align='right'>", butdone, "</td>"
	html.body_add "</tr></table>"
		
	#Returning the HTML object
	html	
end

#--------------------------------------------------------------------------------------------------------------
# Managing Perfromance lists
#--------------------------------------------------------------------------------------------------------------			 

#Options for the Xtable
def option_xtable
	#Specification for columns and headers	
	h1 = []
	h1.push({ :content => T6[:T_TXT_Plugin], :style => "Plugin", :rowspan => 2 })
	h1.push({ :content => T6[:TXT_AtSUStartup], :style => "TimeBlueH", :colspan => 3 })
	h1.push({ :content => "" })
	h1.push({ :content => "" })
	h1.push({ :content => T6[:TXT_Phase2], :tip => T6[:TIP_Phase2], :style => "Phase2", :rowspan => 2 })
	h1.push({ :content => T6[:T_TXT_GRANDTOTAL], :style => "GrandTot", :rowspan => 2 })
	
	h2 = []
	h2.push nil
	h2.push({ :content => T6[:T_TXT_RubyFiles], :tip => T6[:TIP_rbFiles], :style => "TimeBlueR" })
	h2.push({ :content => T6[:T_TXT_Menus], :tip => T6[:TIP_toolbar], :style => "TimeBlueR" })
	h2.push({ :content => T6[:T_TXT_Total], :style => "TimeBlue" })
	
	c = []
	c.push({ :style => "Plugin", :width => @wid_col_plugin })
	c.push({ :style => "TimeBlueR", :width => @wid_col_time })
	c.push({ :style => "TimeBlueR", :width => @wid_col_time })
	c.push({ :style => "TimeBlue", :width => @wid_col_time })
	c.push({ :style => "Phase2", :width => @wid_col_time })
	c.push({ :style => "GrandTot", :width => @wid_col_time })

	f1 = []
	f1.push({ :content => T6[:T_TXT_Total], :style => "Plugin" })
	f1.push({ :content => @l_total[0], :style => "TimeBlueR" })
	f1.push({ :content => @l_total[1], :style => "TimeBlueR" })
	f1.push({ :content => @l_total[2], :style => "TimeBlue" })
	f1.push({ :content => @l_total[3], :style => "Phase2" })
	f1.push({ :content => @l_total[4], :style => "GrandTot" })

	n, average = Plugin.average_load_time
	if n
		f2 = []
		f2.push({ :content => T6[:TXT_AverageLast, n], :style => "Average" })
		f2.push({ :content => "", :style => "TimeBlueR" })
		f2.push({ :content => "", :style => "TimeBlueR" })
		f2.push({ :content => "#{average}", :style => "TimeBlueA" })
		f2.push({ :content => "", :style => "Phase2" })
		f2.push({ :content => "", :style => "GrandTot" })
		footer = [f1, f2]
	else	
		footer = [f1]
	end
	
	#Returning the Options
	hoptions = { :columns => c, :headers => [h1, h2], :footers => footer, :body_height => "#{@hgt_table}px" }	
end

#Prepare the Xtable for Plugin obsolete files
def prepare_xtable
	hsh_plugins = AllPlugins.get_all_registered_plugins
	ltable = []
	tot = [0, 0, 0, 0, 0]
	lst_plugins = hsh_plugins.sort
	lst_plugins.each do |ls|
		key, hsh = ls
		a = [1, [key, AllPlugins.compute_tooltip(key)]]
		lt = AllPlugins.load_time_info key
		next unless lt.find { |x| x }
		a += lt.collect { |t| "#{t}" }
		for i in 0..4
			tot[i] += lt[i] if lt[i]
		end	
		ltable.push a
	end	
	@l_total = tot.collect { |t| "#{t}" }
	ltable
end

end	#class PerformanceDialog

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Dialog box for About Information
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

class AboutDialog

@@hsh_dialogs = {}

#Invoke the purge Obsolete Dialog
def AboutDialog.invoke(plugin)
	name = plugin.plugin_name
	unique_key = "Traductor_About_DLG_" + name
	@@hsh_dialogs[name] = AboutDialog.new(unique_key, plugin) unless Traductor::Wdlg.check_instance_displayed(unique_key)
end	

#initialization of the dialog box 
def initialize(unique_key, plugin)
	@wdlg = create_dialog_top unique_key, plugin
end

#--------------------------------------------------------------------------------------------------------------
# Dialog box configuration
#--------------------------------------------------------------------------------------------------------------			 

#Create the dialog box
def create_dialog_top(unique_key, plugin)
	@plugin = plugin
	@name = @plugin.plugin_name
	title = T6[:T_HELP_MenuAbout] + "..."
	wdlg_key = "Traductor_About_DLG"
	@wdlg = Traductor::Wdlg.new title, wdlg_key, false
	@wdlg.set_unique_key unique_key
	wid_extra = (RUN_ON_MAC) ? 40 : 80
	wid_total = 800 + wid_extra
	main_div_height = 320	
	hgt_total = main_div_height + 300	
	@wdlg.set_size wid_total, hgt_total
	@wdlg.set_background_color 'lightyellow'
	@wdlg.set_callback self.method('topdialog_callback') 
	@wdlg.set_on_close { on_close_top() }
	
	html = Traductor::HTML.new	
	@plugin.html_about(html, main_div_height)	
	@wdlg.set_html html
	
	@wdlg.show
	@wdlg
end

#Notification of window closure
def on_close_top
	@@hsh_dialogs.delete @name
end

#Close the dialog box
def close_dialog_top
	@wdlg.close
end

#Call back for Statistics Dialog
def topdialog_callback(event, type, id, svalue)
	case event
		
	#Command buttons
	when /onclick/i
		case id
		when 'ButtonDone'
			@wdlg.close
		when 'ButtonPrint'
			@wdlg.print
		when 'ButtonCheck'
			Upgrade.top_dialog({ :origin => @plugin.plugin_name })	
		when 'ButtonPerf'
			PerformanceDialog.invoke	
		when 'ButtonPurge'
			PurgeObsoleteDialog.invoke	
		when 'T_HELP_WebSiteName', 'T_HELP_WebSiteLink', 'T_HELP_MenuWebInfo'
			@plugin.open_support_link id
		end	

	when /onKeyUp/i	#Escape and Return key
		@wdlg.close if svalue =~ /\A27\*/
		
	end
	true
end

end	#Class AboutDialog

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Trace Log files
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

class TraceLog

#Compute the list of log files (from the most recent to the oldest)
def self.list_log_files(flg_all=false)
	nbmax = MYDEFPARAM[:T_DEFAULT_TraceLogNbmax]
	tmpdir = LibFredo6.tmpdir
	current_logfile = LibFredo6.log_file
	@fpat = Regexp.new LibFredo6.rootlog.sub(/\*/, "(\\d+)")
	ls = Dir[File.join(tmpdir, LibFredo6.rootlog)]
	ls.delete current_logfile
	ls.push current_logfile
	ls.reverse!
	ls = ls[0..nbmax] if !flg_all && ls.length > nbmax
	ls
end

#Build a string from the Time of the file
def self.time_from_filepath(filepath)
	fname = File.basename filepath
	return nil unless fname =~ @fpat
	t = $1.to_f / 1000
	Time.at(t).strftime "%a %d %b %Y - %Hh%M:%S"
end

#Purge the old trace files
def self.purge
	nbmax = MYDEFPARAM[:T_DEFAULT_TraceLogNbmax]
	ls = list_log_files true
	return 0 if ls.length <= nbmax+10
	ls[nbmax..-1].each { |f| File.delete f }
	ls.length - nbmax
end

end	#class TraceLog

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Dialog box for Trace Log files
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

class TraceLogDialog

@@top_dialog = nil

#Invoke the Trace log files Dialog
def TraceLogDialog.invoke
	unique_key = "Traductor_TraceLog_DLG"
	@@top_dialog = TraceLogDialog.new(unique_key) unless Traductor::Wdlg.check_instance_displayed(unique_key)
end	

#initialization of the dialog box 
def initialize(unique_key)
	@wdlg = create_dialog_top unique_key
end

#--------------------------------------------------------------------------------------------------------------
# List of Trace Log files
#--------------------------------------------------------------------------------------------------------------			 

def list_log_files
	ls = TraceLog.list_log_files
	linfo = ls.collect { |f| [f, TraceLog.time_from_filepath(f)] }
	linfo[0][1] = T6[:TXT_LogCurrentSession] + ' ' + linfo[0][1]
	@log_file = linfo[0][0]
	linfo
end

#--------------------------------------------------------------------------------------------------------------
# Dialog box configuration: Trace Log
#--------------------------------------------------------------------------------------------------------------			 

#Create the dialog box
def create_dialog_top(unique_key)
	init_dialog_top
	wdlg_key = unique_key
	@wdlg = Traductor::Wdlg.new @title, wdlg_key, false
	@wdlg.set_unique_key unique_key
	@wdlg.set_size @wid_total, @hgt_total
	@wdlg.set_background_color 'lightyellow'
	@wdlg.set_callback self.method('topdialog_callback') 
	@wdlg.set_on_close { on_close_top() }
	refresh_dialog_top
	@wdlg.show
	@wdlg
end

#Initialize parameters of the dialog box
def init_dialog_top
	#Column width and Heights
	@hgt_table = 300
	@wid_extra = (RUN_ON_MAC) ? 40 : 80
	@wid_col_time = 150
	@wid_col_message = 600
	@wid_total = @wid_col_time + @wid_col_message + @wid_extra + 10
	@hgt_total = @hgt_table + 230	
	@title = T6[:T_HELP_MenuTraceLog]
end

#Refresh the dialog box
def refresh_dialog_top
	html = format_html_top @wdlg
	@wdlg.set_html html
end

#Notification of window closure
def on_close_top
	@@top_dialog = nil
end

#Close the dialog box
def close_dialog_top
	@wdlg.close
end

#Call back for Trace Log Dialog
def topdialog_callback(event, type, id, svalue)
	case event
		
	#Command buttons
	when /onclick/i
		case id
		when 'ButtonDone'
			@wdlg.close
		when 'ButtonPrint'
			@wdlg.print
		when 'ButtonExport'
			export_as_txt
		end	
		
	when /onchange/i
		case id
		when 'Combo'
			@log_file = svalue
			refresh_dialog_top
		end
		
	when /onKeyUp/i	#Escape and Return key
		@wdlg.close if svalue =~ /\A27\*/
		
	end
	svalue
end

#Build the HTML for Trace Log Dialog
def format_html_top(wdlg)
	#Creating the HTML stream	
	html = Traductor::HTML.new
			
	#style used in the dialog box
	space2 = "&nbsp;&nbsp;"
	@style_error = 'background-color: mistyrose ; color: red'
	@style_warning = 'background-color: yellow ; color: green'
	
	html.create_style 'Title', nil, 'B', 'K: navy', 'F-SZ: 16', 'text-align: center'
	html.create_style 'Header', nil, 'B', 'F-SZ: 11', 'BG: khaki', 'text-align: left'
	html.create_style 'ComboT', nil, 'B', 'F-SZ: 12', 'K: green'
	html.create_style 'HTime', 'Header', 'K: navy'
	html.create_style 'HMessage', 'Header', 'K: black'
	html.create_style 'Time', nil, 'B', 'F-SZ: 11', 'K: navy', 'text-align: left'
	html.create_style 'TimeS', nil, 'B', 'F-SZ: 10', 'K: gray', 'text-align: left'
	html.create_style 'Message', nil, 'F-SZ: 10', 'K: black', 'text-align: left'
	html.create_style 'Highlight1', 'Message', 'B', 'K: blue'
	html.create_style 'Highlight2', 'Message', 'B', 'K: royalblue'
	html.create_style 'Highlight3', 'Message', 'B', 'K: red'
	html.create_style 'Highlight4', 'Message', 'B', 'K: green'
	html.create_style 'Error', nil, 'B', 'F-SZ: 10', 'K: red'
	html.create_style 'Warning', nil, 'B', 'F-SZ: 10', 'K: green'
	
	
	html.create_style 'Button', nil, 'F-SZ: 10'
	html.create_style 'ButtonR', nil, 'F-SZ: 10', 'BG: yellow'

	#Creating the main table
	@xtable = Traductor::HTML_Xtable.new "XT0", html, wdlg
	@ltable = prepare_xtable
	hoptions = option_xtable
	txt_table = @xtable.format_table @ltable, hoptions
	
	#Creating the title
	text = ""
	text += "<div cellspacing='0px' cellpadding='0px' class='Title'>#{@title}</div>"
	text += "<div style='height: 6px'>&nbsp</div>"
	html.body_add text
	
	#Creating the combo box
	span = HTML.format_span T6[:TXT_LogSession], "", "ComboT"
	combo = HTML.format_combobox @log_file, @logfile_info, "Combo", "ComboT", nil, nil
	html.body_add "<table width='99%' cellpadding='6px'><tr>"
	html.body_add "<td width='25%' align='center'>", span, space2, combo, "</td>"
	html.body_add "</tr></table>"
	
	error_msg = "" 
	error_msg += HTML.format_span("ERROR(S): #{@nb_errors}", '', "Error") if @nb_errors > 0 
	error_msg += space2 
	error_msg += HTML.format_span("WARNING(S): #{@nb_warnings}", '', "Warning") if @nb_warnings > 0 
	html.body_add "<div><table width='100%' cellspacing='0' cellpadding='0'><tr>"
	html.body_add "<td width='#{@wid_col_time}px' align='left' valign='bottom'>#{@xtable.html_expand_buttons}</td>"
	html.body_add "<td align='left' valign='bottom'>#{error_msg}</td>"
	html.body_add "</tr></table></div>"

	#Inserting the main table
	html.body_add "<div>", txt_table, "</div>"
	
	#Creating the dialog box button	
	butdone = HTML.format_button T6[:T_BUTTON_Done], id="ButtonDone", 'Button', nil
	tipexport = T6[:TIP_GenerationExportTxt] + ' - ' + T6[:TIP_GenerationMasked]
	butexport = HTML.format_button T6[:T_BUTTON_ExportTXT], id="ButtonExport", 'ButtonR', nil, tipexport
	butprint = HTML.format_button T6[:T_BUTTON_Print], id="ButtonPrint", 'Button', nil
	html.body_add "<table class='T_NOPRINT_Style' width='99%' cellpadding='6px'><tr>"
	html.body_add "<td width='33%' align='left'>", butprint, "</td>"
	html.body_add "<td width='33%' align='center'>", butexport, "</td>"
	html.body_add "<td align='right'>", butdone, "</td>"
	html.body_add "</tr></table>"
		
	#Returning the HTML object
	html	
end

#--------------------------------------------------------------------------------------------------------------
# Managing Trace Log display
#--------------------------------------------------------------------------------------------------------------			 

#Options for the Xtable
def option_xtable
	#Specification for columns and headers	
	h1 = []
	h1.push({ :content => T6[:T_TXT_Time], :style => "HTime" })
	h1.push({ :content => T6[:TXT_LogMessage], :style => "HMessage" })
	
	c = []
	c.push({ :style => "Time", :width => @wid_col_time })
	c.push({ :style => "Message", :width => @wid_col_message })

	lv0 = { :css_style => "border-top: 2px solid steelblue" }
	lv1 = { :css_style => "border-top: 2px solid steelblue" }
	lv2 = { :css_style => "border-top: 1px solid steelblue" }
	lv3 = { :css_style => "border-top: 1px dashed steelblue" }
	lv4 = { :css_style => "border-top: 1px dashed gray" }
	
	#Returning the Options
	hoptions = { :columns => c, :headers => h1, :levels => [lv0, lv1, lv2, lv3, lv4], :body_height => "#{@hgt_table}px" }	
end

#Prepare the Xtable for Plugin Trace Log
# /\A?/ --> Error, /\A!/ --> Warning, /***+\Z/ --> indent +1, /***-\Z/ --> indent -1
def prepare_xtable
	@nb_errors = 0
	@nb_warnings = 0
	endcode = "$$$$END$$$$"
	space4 = "&nbsp;&nbsp;&nbsp;&nbsp;"
	hstyle_error = { :style => "#{@style_error}" }
	hstyle_warning = { :style => "#{@style_warning}" }
	hstyle_indent2 = { :class => "TimeS" }

	@logfile_info = list_log_files unless @logfile_info
	lines = IO.readlines @log_file
	lines.push endcode
	ltable = []
	decal = 0
	indent = 1
	time_orig = nil
	source_code = false
	time = tiptime = lmessage = ref = hstyle = t_prev = nil
	tip_orig = tip_last = ""
	lines.each do |line|
		line = line.strip
		if line =~ /\A>>>>/ || line == endcode
			if time
				time = "" if indent > 2
				tstyle = (indent == 2) ? hstyle_indent2 : nil
				lmessage.push space4 * (indent-1) + "SOURCE CODE: #{ref}" if source_code
				ltable.push [-indent, [time, tiptime, tstyle], [lmessage.join("<br>"), ref, hstyle]]
			end	
			break if line == endcode
			ls = $'.split ';'
			t = ls[0].to_f
			td = Time.at(t)
			ms = ((t - t.to_i) * 1000).to_i
			time = td.strftime "%Hh%M:%S.#{sprintf("%03d", ms)}"
			tiptime = td.strftime("%a %d %b %Y")
			if time_orig
				tip_last = "#{((t - t_prev) * 1000).to_i} ms since previous"
				tip_orig = " - #{((t - time_orig) * 1000).to_i} ms since startup"
				tiptime = tip_last + tip_orig + "\n" + tiptime
			else
				time_orig = t
			end	
			t_prev = t
			ref = ls[1]
			lmessage = []
			hstyle = nil
			indent += decal
			indent == 1 if indent > 1
			decal = 0
			source_code = false
		elsif line != ""	
			if (line[0..0] == '?')
				hstyle = hstyle_error
				line = line[1..-1]
				@nb_errors += 1
				source_code = true
			elsif (line[0..0] == '!')
				hstyle = hstyle_warning
				line = line[1..-1]
				@nb_warnings += 1
				source_code = true
			end	
			if line =~ /\*\*\*\+\Z/
				decal = 1
				line = $`
			elsif line =~ /\*\*\*\-\Z/
				indent -= 1 if indent > 1
				line = $`
			end	
			if line =~ /:\s/
				len = $`.length
				st = "Highlight#{indent}"
				line = "#{HTML.format_span($`, '', st)}: #{$'}" if len > 5 && len < 50
			end	
			line = space4 * (indent-1) + line
			lmessage.push line
		end
	end	
	ltable
end

#Export the file as txt
def export_as_txt
	#Asking for the export file
	name = File.basename @log_file
	dir = Sketchup.active_model.path
	if dir.empty?
		dir = nil
	else	
		dir = File.dirname dir
	end	
	fpath = UI.savepanel T6[:T_BUTTON_ExportTXT], dir, name
	return unless fpath
	
	#Formatting the export file
	fpath = fpath.gsub(/\\/, '/')
	begin
		lines = IO.readlines @log_file
		File.open(fpath, "w") do |f|
			lines.each do |line|
				f.puts mask(line)
			end	
		end
		status = UI.messagebox T6[:MSG_GenerationExport, fpath] + "\n\n" + T6[:T_STR_DoYouWantOpenFile], MB_YESNO
		Traductor.openURL fpath if status == 6
	rescue
		UI.messagebox T6[:MSG_GenerationExport_Error, fpath]
	end
end

#Mask directories in line debug statements
def mask(s)
	(s =~ /(\.rb.*:\d+:)/) ? File.basename($`) + $1 + " " + $' : s
end

end	#Class TraceLogDialog

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Debug Log files
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

class DebugLog

#Compute the list of log files (from the most recent to the oldest)
def self.list_debug_files(flg_all=false)
	nbmax = MYDEFPARAM[:T_DEFAULT_DebugLogNbmax]
	tmpdir = LibFredo6.tmpdir
	current_logfile = LibFredo6.debug_file
	@fpat = Regexp.new LibFredo6.rootdebug.sub(/\*/, "(\\d+)")
	ls = Dir[File.join(tmpdir, LibFredo6.rootdebug)]
	ls.delete current_logfile
	ls.push current_logfile
	ls.reverse!
	ls = ls[0..nbmax] if !flg_all && ls.length > nbmax
	ls
end

#Build a string from the Time of the file
def self.time_from_filepath(filepath)
	return nil unless filepath
	fname = File.basename filepath
	return nil unless fname =~ @fpat
	$1.to_f / 1000
end

#Purge the old trace files
def self.purge
	nbmax = MYDEFPARAM[:T_DEFAULT_DebugLogNbmax]
	ls = list_debug_files true
	return 0 if ls.length <= nbmax+10
	ls[nbmax..-1].each { |f| File.delete f }
	ls.length - nbmax
end

end	#class DebugLog

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Dialog box for Debug Log files
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

class DebugLogDialog

@@top_dialog = nil

#Invoke the Trace log files Dialog
def DebugLogDialog.invoke
	unique_key = "Traductor_DebugLog_DLG"
	@@top_dialog = DebugLogDialog.new(unique_key) unless Traductor::Wdlg.check_instance_displayed(unique_key)
end	

#initialization of the dialog box 
def initialize(unique_key)
	@wdlg = create_dialog_top unique_key
end

#--------------------------------------------------------------------------------------------------------------
# List of Trace Log files
#--------------------------------------------------------------------------------------------------------------			 

def list_log_files
	ls = DebugLog.list_debug_files
	ls.collect { |f| [f, DebugLog.time_from_filepath(f)] }
end

#View the file with an text editor
def view_file(i)
	Traductor.openURL @logfile_info[i][0]
end

#--------------------------------------------------------------------------------------------------------------
# Dialog box configuration: Trace Log
#--------------------------------------------------------------------------------------------------------------			 

#Create the dialog box
def create_dialog_top(unique_key)
	init_dialog_top
	wdlg_key = unique_key
	@wdlg = Traductor::Wdlg.new @title, wdlg_key, false
	@wdlg.set_unique_key unique_key
	@wdlg.set_size @wid_total, @hgt_total
	@wdlg.set_background_color 'whitesmoke'
	@wdlg.set_callback self.method('topdialog_callback') 
	@wdlg.set_on_close { on_close_top() }
	refresh_dialog_top
	@wdlg.show
	@wdlg
end

#Initialize parameters of the dialog box
def init_dialog_top
	#Column width and Heights
	@hgt_table = 300
	@wid_extra = (RUN_ON_MAC) ? 40 : 80
	@wid_col_time = 250
	@wid_col_view = 150
	@wid_total = @wid_col_time + @wid_col_view + @wid_extra + 10
	@hgt_total = @hgt_table + 230	
	@title = T6[:T_HELP_MenuDebugLog]
end

#Refresh the dialog box
def refresh_dialog_top
	html = format_html_top @wdlg
	@wdlg.set_html html
end

#Notification of window closure
def on_close_top
	@@top_dialog = nil
end

#Close the dialog box
def close_dialog_top
	@wdlg.close
end

#Call back for Trace Log Dialog
def topdialog_callback(event, type, id, svalue)
	case event
		
	#Command buttons
	when /onclick/i
		case id
		when /ButtonView_(\d+)/i
			view_file $1.to_i
		when /ButtonExport_(\d+)/i
			export_as_txt $1.to_i
		when 'ButtonDone'
			@wdlg.close
		when 'ButtonPrint'
			@wdlg.print
		end	
		
	when /onKeyUp/i	#Escape
		@wdlg.close if svalue =~ /\A27\*/
	when /onKeyDown/i	#Return key
		@wdlg.close if svalue =~ /\A13\*/
		
	end
	true
end

#Build the HTML for Trace Log Dialog
def format_html_top(wdlg)
	#Creating the HTML stream	
	html = Traductor::HTML.new
			
	#style used in the dialog box
	space2 = "&nbsp;&nbsp;"
	@style_error = 'background-color: mistyrose ; color: red'
	@style_warning = 'background-color: yellow ; color: green'
	
	html.create_style 'Title', nil, 'B', 'K: navy', 'F-SZ: 16', 'text-align: center'
	html.create_style 'Header', nil, 'B', 'F-SZ: 11', 'BG: khaki', 'text-align: left'
	html.create_style 'HTime', 'Header', 'K: navy'
	html.create_style 'Current', nil, 'B', 'F-SZ: 11', 'K: green', 'BG: palegreen', 'text-align: left'
	html.create_style 'Time', nil, 'B', 'F-SZ: 11', 'K: navy', 'text-align: left'
	html.create_style 'View', nil, 'text-align: right'	
	
	html.create_style 'Button', nil, 'F-SZ: 10'
	html.create_style 'ButtonView', nil, 'F-SZ: 9', 'BG: lightyellow'
	html.create_style 'ButtonExport', nil, 'F-SZ: 9', 'BG: powderblue'

	#Creating the main table
	@xtable = Traductor::HTML_Xtable.new "XT0", html, wdlg
	@ltable = prepare_xtable
	hoptions = option_xtable
	txt_table = @xtable.format_table @ltable, hoptions
	
	#Creating the title
	text = ""
	text += "<div cellspacing='0px' cellpadding='0px' class='Title'>#{@title}</div>"
	text += "<div style='height: 6px'>&nbsp</div>"
	html.body_add text
	
	#Inserting the main table
	html.body_add "<div><table width='100%' cellspacing='0' cellpadding='0'><tr>"
	html.body_add "<td width='#{@wid_col_time}px' align='left' valign='bottom'>#{@xtable.html_expand_buttons}</td>"
	html.body_add "</tr></table></div>"
	html.body_add "<div>", txt_table, "</div>"
	
	#Creating the dialog box button	
	butdone = HTML.format_button T6[:T_BUTTON_Done], id="ButtonDone", 'Button', nil
	butexport = HTML.format_button T6[:T_BUTTON_ExportTXT], id="ButtonExport", 'ButtonR', nil, T6[:TIP_GenerationExportTxt]
	butprint = HTML.format_button T6[:T_BUTTON_Print], id="ButtonPrint", 'Button', nil
	html.body_add "<table class='T_NOPRINT_Style' width='99%' cellpadding='6px'><tr>"
	html.body_add "<td width='33%' align='left'>", butprint, "</td>"
	html.body_add "<td width='33%' align='center'>", "", "</td>"
	html.body_add "<td align='right'>", butdone, "</td>"
	html.body_add "</tr></table>"
		
	#Returning the HTML object
	html	
end

#--------------------------------------------------------------------------------------------------------------
# Managing Trace Log display
#--------------------------------------------------------------------------------------------------------------			 

#Options for the Xtable
def option_xtable
	#Specification for columns and headers	
	h1 = []
	h1.push({ :content => T6[:TXT_LogSession].gsub(':', ''), :style => "HTime" })
	h1.push({ :content => "", :style => "HTime" })
	
	c = []
	c.push({ :style => "Time", :width => @wid_col_time })
	c.push({ :style => "View", :width => @wid_col_view })

	lv0 = { :style => "Current", :css_style => "border-top: 2px solid steelblue" }
	lv1 = { :css_style => "border-top: 2px solid steelblue" }
	lv2 = { :css_style => "border-top: 1px solid gray" }
	
	#Returning the Options
	hoptions = { :columns => c, :headers => h1, :levels => [lv0, lv1, lv2], :body_height => "#{@hgt_table}px" }	
end

#Prepare the Xtable for Plugin Debug Log
def prepare_xtable
	#initialization
	@logfile_info = list_log_files unless @logfile_info
	return [] if @logfile_info.empty?
	ltable = []
	space4 = "&nbsp;&nbsp;&nbsp;&nbsp;"
	tipview = T6[:MSG_ViewViaEditor]
	tipexport = T6[:TIP_GenerationExportTxt]
	butview = HTML.format_button T6[:T_BUTTON_Visualize], "ButtonView_%1", "ButtonView", nil, tipview
	butexport = HTML.format_button T6[:T_BUTTON_Export], "ButtonExport_%1", "ButtonExport", nil, tipexport

	#Current Session
	info_current = @logfile_info[0]
	if info_current[0]
		hstylecur = { :class => "Current" }
		td = Time.at(info_current[1])
		tiptime = td.strftime "%a %d %b %Y - %Hh%M:%S" + "\n" + info_current[0]
		but = butexport.sub("%1", "0") + space4 + butview.sub("%1", "0")
		ltable.push [1, [T6[:TXT_LogCurrentSession].gsub(':', ''), tiptime, hstylecur], [but, nil, hstylecur]]
	end
	
	#Other Session
	t0 = Time.now.to_f
	@logfile_info[1..-1].each_with_index do |info, i|
		t = info[1]
		td = Time.at(t)
		delta = t0 - td.to_f
		time = td.strftime "%a %d %b %Y - %Hh%M:%S"
		but = butexport.sub("%1", (i+1).to_s) + space4 + butview.sub("%1", (i+1).to_s)
		ltable.push [1, [time, info[0]], [but]]
	end	
	ltable
end

#Export the file as txt
def export_as_txt(i)
	#Debug file
	log_file = @logfile_info[i][0]
	
	#Asking for the export file
	name = File.basename log_file
	dir = Sketchup.active_model.path
	if dir.empty?
		dir = nil
	else	
		dir = File.dirname dir
	end	
	fpath = UI.savepanel T6[:T_BUTTON_ExportTXT], dir, name
	return unless fpath
	
	#Formatting the export file
	fpath = fpath.gsub(/\\/, '/')
	begin
		lines = IO.readlines log_file
		File.open(fpath, "w") do |f|
			lines.each do |line|
				f.puts mask(line)
			end	
		end
		status = UI.messagebox T6[:MSG_GenerationExport, fpath] + "\n\n" + T6[:T_STR_DoYouWantOpenFile], MB_YESNO
		Traductor.openURL fpath if status == 6
	rescue
		UI.messagebox T6[:MSG_GenerationExport_Error, fpath]
	end
end

#Mask directories in line debug statements
def mask(s)
	(s =~ /(\.rb.*:\d+:)/) ? File.basename($`) + $1 + " " + $' : s
end

end	#Class DebugLogDialog

end #Module Traductor

