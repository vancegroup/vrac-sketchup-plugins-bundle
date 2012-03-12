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
# Name			:  Lib6Plugin.rb
# Original Date	:  10 Dec 2008 - version 3.0
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library about Plugin Configuration for LibFredo6-compliant scripts.
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

#--------------------------------------------------------------------------------------------------------------
# PLugin Management (Part II)
#--------------------------------------------------------------------------------------------------------------			 				   

T6[:T_HELP_MenuDoc] = "Documentation"	
T6[:T_HELP_MenuVideo] = "Video"	
T6[:T_HELP_MenuAbout] = "About"	
T6[:T_HELP_MenuLanguages] = "Set Preferred Languages"	
T6[:T_HELP_MenuDefParam] = "Default Parameters"	
T6[:T_HELP_MenuTraceLog] = "View Trace log files"	
T6[:T_TIP_MenuTraceLog] = "Consult the log of traces for the current and last sessions"	
T6[:T_HELP_MenuDebugLog] = "View Debug log files"	
T6[:T_TIP_MenuDebugLog] = "Consult the log of debug messages for the current and last sessions"	
T6[:T_HELP_MenuPurgeObsolete] = "Purge Obsolete files"	
T6[:T_TIP_MenuPurgeObsolete] = "Identify old files and allow to delete them"	
T6[:T_HELP_MenuPerformances] = "Performances"	
T6[:T_TIP_MenuPerformances] = "Summarize the load times for the plugins managed by LibFredo6"	
T6[:T_HELP_MenuTranslation] = "Language Translation"	
T6[:T_HELP_MenuDonation] = "Donation"
T6[:T_HELP_MenuWebInfo] = "Plugin Information"

T6[:T_HELP_Info] = "INFORMATION"
T6[:T_HELP_RootPath] = "Plugin Root Directory"
T6[:T_HELP_Subfolder] = "Plugin Subfolder"
T6[:T_HELP_PluginLoadTime] = "Time to Load Plugins"
T6[:T_HELP_LoadTime] = "Total time to load the Plugin"
T6[:T_HELP_TotalLoadTime] = "Total load time of ALL LibFredo6 registered plugins at SU startup"
T6[:T_HELP_Usage] = "Total usage"
T6[:T_HELP_PLUGIN_USE] = "PLUGIN USE"
T6[:T_HELP_LibFredo6] = "LibFredo6 version"
T6[:T_HELP_Designed] = "Designed and developed by %1 - %2"
T6[:T_HELP_Date] = "Date"
T6[:T_HELP_Credits] = "CREDITS"
T6[:T_HELP_Support] = "SUPPORT"
T6[:T_HELP_RepositoryName] = "Plugin Repository"		 
T6[:T_HELP_WebSiteName] = "Web Site"		 
T6[:T_HELP_WebSiteLink] = "Web Site Link"		 
T6[:T_HELP_WebSupportLink] = "Check for updates"		 

T6[:T_HELP_CheckOlder] = "Checking older versions of Plugin"
T6[:T_HELP_PluginFolder] = "Sketchup Plugin Folder:"
T6[:T_HELP_FileFound] = "The following files are older and can be removed"
T6[:T_HELP_DirFound] = "The following subfolders are older and can be removed"

T6[:T_HELP_LoadingModules] = "Loading all Ruby files for plugin %1"
T6[:T_HELP_LoadedModules] = "Loaded all Ruby files for plugin %1 --> %2"
T6[:T_HELP_StartupTime] = "Startup"

T6[:T_ERROR_VersionModule] = "%1: This plugin requires LibFredo6 version greater than %2.\nCurrent version is %3"
T6[:T_ERROR_VersionSketchup] = "%1: This plugin requires Sketchup version greater than %2.\nCurrent version is %3"

T6[:DONATION_1] = "%1 is a free plugin for private and commercial use." 
T6[:DONATION_2] = "So if you donate, I'll take it as a sign of reward and recognition."
T6[:DONATION_3] = "Open the Donation page [%1]"

PLUGIN_RKEY_Usage = "Usage"
	
#=====================================
#--------------------------------------------------------------------------
# Class Plugin
#Define a plugin for LibFredo6
#--------------------------------------------------------------------------
#=====================================
	
class Plugin

def eval_T6(symb, *args)
	t6 = T6Mod.handler @main_module
	t6.get(symb, *args) if t6
end

def eval_constant(symb)
	hmod = eval @main_module
	begin
		return ((hmod.class == Module) ? hmod.const_get(symb) : nil)
	rescue
		return nil
	end	
end

#--------------------------------------------------------------------------
# Menu and Action registration
#--------------------------------------------------------------------------

#Modify the name of the action call_back (default is "action_mapping".
#The method name must be passed as a string or a symbol
def set_action_callback(method_name)
	return unless method_name
	@action_call_back_name = method_name.to_s
	@action_call_back_proc = nil
end
	
#Launch an action for the plugin
#This calls the plugin call back for mapping actions	
def launch_action(*args)

	#Loading the full module if not done already
	load_second_phase_rubies
	
	#Finding the mapping call back
	unless @action_call_back_proc
		@action_call_back_name = "action__mapping" unless @action_call_back_name
		@action_call_back_proc = @hmod_main_module.method @action_call_back_name
		return unless @action_call_back_proc
	end
	
	#invoking the action
	@action_call_back_proc.call *args
end
	
#--------------------------------------------------------------------------
# Triggering commands once
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# Ancillary menus for Plugins
#--------------------------------------------------------------------------

#Retrieve or store the average plugin time
def Plugin.average_load_time(store=false)
	key = "Average_load_times"
	nmax = 10
	
	#Retrieve the current list of times
	s = Sketchup.read_default "LibFredo6", key, ""
	ls = s.split ";"
	lstime = []
	n = ls.length
	for i in 0..n-1
		a = ls[n-i-1]
		break unless a && i < nmax
		lstime.push ls[i].to_i
	end
	
	#Retrieve the Current average
	unless store
		return nil if lstime.empty?
		x = 0
		lstime.each { |t| x += t }
		return [lstime.length, x / lstime.length]
	end
	
	#Store
	lstime.shift if lstime.length >= nmax
	lstime.push AllPlugins.total_load_time
	Sketchup.write_default "LibFredo6", key, lstime.join(';')
end

#Compute the load time at SU startup of all registered plugins, including LibFredo6
def Plugin.total_load_time
	ttot = 0
	@@hsh_plugins.each do |key, plugin|
		ttot += plugin.load_time.to_f
	end
	(ttot * 1000).to_i
end

def Plugin.get_total_load_time
	"#{Plugin.total_load_time} ms"
end

#Get the load time at SU starup for the plugin
def get_load_time
	text = "#{(@load_time * 1000.0).to_i} ms"
	text += " [#{T6[:T_HELP_StartupTime]}] + #{(@load_time_second * 1000.0).to_i} ms" if @load_time_second
	text
end

#Return load time info in ms
def load_time_info
	t = []
	t[0] = @load_time - @load_time_startup
	t[1] = @load_time_startup
	t[2] = t[0] + t[1]
	t[3] = (@load_time_second) ? @load_time_second : 0
	t[4] = t[2] + t[3]
	t = t.collect { |a| (a * 1000).to_i }
	t[3] = nil if t[3] == 0
	t
end

#Register additional time for Phase 2 loading
def add_load_time_second(t)
	@load_time_second = 0.001 unless @load_time_second
	@load_time_second += t
	AllPlugins.register @plugin_name, { :load_time_second => @load_time_second }
end

#Add a credit
def add_credits(credits)
	return unless credits
	@lst_credits = [] unless @lst_credits
	credits = [credits] unless credits.class == Array
	@lst_credits += credits
end

#Add a video
def add_videos(videos)
	return unless videos
	@lst_video = [] unless @lst_video
	videos = [videos] unless videos.class == Array
	@lst_video += videos
end

#Create the menu items	for all support utilities				
def populate_support_menu(cmdfamily, submenu=nil, plugin_title_symb=nil)
	@plugin_title_symb = plugin_title_symb if plugin_title_symb 

	#Specific to LibFredo6
	if @plugin_name =~ /LibFredo6/i
		text = T6[:T_HELP_MenuLanguages] + "..."
		cmdfamily.add_command(text, text, nil, nil, nil) { T6Mod.dialog_preferred_languages }
		
		if SU_MAJOR_VERSION >= 6
			cmdfamily.add_menu_separator
			text = T6[:T_BUTTON_CheckForUpdate] + "..."
			tooltip = @web_support_link
			hoptions = { :origin_plugin => @plugin_name }
			cmdfamily.add_command(text, tooltip, nil, nil, nil) { Upgrade.top_dialog hoptions }
			
			cmdfamily.add_menu_separator
			text = T6[:T_HELP_MenuPurgeObsolete] + "..."
			tooltip = T6[:T_TIP_MenuPurgeObsolete]
			cmdfamily.add_command(text, tooltip, nil, nil, nil) { PurgeObsoleteDialog.invoke }
			
			text = T6[:T_HELP_MenuPerformances] + "..."
			tooltip = T6[:T_TIP_MenuPerformances]
			cmdfamily.add_command(text, tooltip, nil, nil, nil) { PerformanceDialog.invoke }
			
			cmdfamily.add_menu_separator
			text = T6[:T_HELP_MenuTraceLog] + "..."
			tooltip = T6[:T_TIP_MenuTraceLog]
			cmdfamily.add_command(text, tooltip, nil, nil, nil) { TraceLogDialog.invoke }
			
			if MYDEFPARAM[:T_DEFAULT_DebugShowMenu]
				text = T6[:T_HELP_MenuDebugLog] + "..."
				tooltip = T6[:T_TIP_MenuDebugLog]
				cmdfamily.add_command(text, tooltip, nil, nil, nil) { DebugLogDialog.invoke }
			end	
		end	
		cmdfamily.add_menu_separator
	end
	
	#About dialog box
	cmdfamily.add_menu_separator
	text = "#{T6[:T_HELP_MenuAbout]} #{@name} ..."
	cmdfamily.add_command(text, text, nil, nil, nil) { self.show_about }

	
	#In Sketchup 5, this is the only thing we can do
	return unless SU_MAJOR_VERSION >= 6 
	
	#Documentation
	supath = File.join @plugin_dir, "*.pdf"
	lf = []
	n = 0
	Dir[supath].each { |f| lf.push [File.basename(f), f] if FileTest.exist?(f) }
	if lf.length > 0
		text = T6[:T_HELP_MenuDoc] + "..."
		menudoc = cmdfamily.add_submenu(text)
		lf.each { |l| menudoc.add_item(l[0]) { Traductor.openURL l[1] } }
	end

	#Videos
	video_menu cmdfamily if @lst_video.length > 0
	
	#Web Site and Support Links
	cmdfamily.add_menu_separator if @web_site_link || @web_support_link
	
	if @web_repository_link 
		repository = (@web_repository) ? " [#{@web_repository}]" : ""
		text = T6[:T_HELP_RepositoryName] + repository + "..."
		tooltip = @web_repository_link
		cmdfamily.add_command(text, tooltip, nil, nil, nil) { open_URL @web_repository_link }
	end
	
	#Check for updates
	if @web_support_link && @web_support_link.strip != ""
		forum = (@web_site_name) ? " [#{@web_site_name}]" : ""
		text = T6[:T_HELP_MenuWebInfo] + forum + "..."
		tooltip = @web_support_link
		cmdfamily.add_command(text, tooltip, nil, nil, nil) { open_URL @web_support_link }
		unless @plugin_name =~ /LibFredo6/i
			text = T6[:T_BUTTON_CheckForUpdate] + "..."
			hoptions = { :origin_plugin => @plugin_name }
			cmdfamily.add_command(text, tooltip, nil, nil, nil) { Upgrade.top_dialog hoptions }
		end	
		
	elsif @web_site_link && @web_site_link.strip != ""
		forum = (@web_site_name) ? " [#{@web_site_name}]" : ""
		text = T6[:T_HELP_WebSiteName] + forum + "..."
		tooltip = @web_site_link
		cmdfamily.add_command(text, tooltip, nil, nil, nil) { open_URL @web_site_link }
	end
	
	#Donation
	if @donation
		donation_menu cmdfamily
	end
		
	#Default Parameters and Translation
	cmdfamily.add_menu_separator
	text = T6[:T_HELP_MenuDefParam] + "..."
	cmdfamily.add_command(text, text, nil, nil, nil) do
		load_second_phase_rubies
		@defparam.visual_edition eval_T6(@plugin_title_symb)
	end	

	text = T6[:T_HELP_MenuTranslation] + "..."
	cmdfamily.add_command(text, text, nil, nil, nil) do
		load_second_phase_rubies
		T6Mod.visual_edition @rootname
	end	
end

#Call the default parameter dialog box
def invoke_default_parameter_dialog
	load_second_phase_rubies
	@defparam.visual_edition eval_T6(@plugin_title_symb)
end

#Manage menu entries for videos
def video_menu(cmdfamily)
	lsv = []
	@lst_video.each_with_index do |sv, i|
		next unless sv && sv.strip != ''
		titv = nil
		url = sv.strip
		if sv =~ /;/
			titv = $`.strip if $` 
			url = $'.strip
		end
		unless url =~ /\Ahttp\:\/\//i
			url = $' if url =~ /file\:\/\//i
			vfile = File.join @plugin_dir, url
			next unless FileTest.exist? vfile
			url = "file://" + vfile 
		end
		titv = "Video #{i+1}" unless titv && titv != ''
		lsv.push [Traductor[titv], url]
	end
	if lsv.length > 0
		text = T6[:T_HELP_MenuVideo] + "..."
		menuvideo = cmdfamily.add_submenu(text)
		lsv.each do |l| 
			cmd = UI::Command.new(l[0]) { Traductor.openURL l[1] }
			cmd.status_bar_text = l[1]
			menuvideo.add_item cmd 			
		end	
	end	
end

#Manage menu entries for videos
def donation_menu(cmdfamily)
	lsv = []
	@lst_donation.each_with_index do |sv, i|
		next unless sv && sv.strip != ''
		next if sv =~ /\Afredo/i
		return if sv =~ /\Anone/i
		titv = nil
		url = sv.strip
		if sv =~ /;/
			titv = $`.strip if $` 
			url = $'.strip
		end
		unless url =~ /\Ahttp\:\/\//i
			url = $' if url =~ /file\:\/\//i
			vfile = File.join @plugin_dir, url
			next unless FileTest.exist? vfile
			url = "file://" + vfile 
		end
		titv = "Donation #{i+1}" unless titv && titv != ''
		lsv.push [Traductor[titv], url]
	end
	lsv = [["Fredo6 at Paypal", @plugin_name]] if lsv.length == 0
	cmdfamily.add_menu_separator
	text = T6[:T_HELP_MenuDonation] + "..."
	menudonation = cmdfamily.add_submenu(text)
	lsv.each do |l| 
		tit, url = l
		cmd = UI::Command.new(tit) { execute_donation(url) }
		cmd.status_bar_text = T6[:DONATION_3, url]
		menudonation.add_item cmd 			
	end	
end

#Invoke the donation page
def execute_donation(url)	
	return Traductor.openURL(url) if url =~ /:\/\//
	file = File.join LibFredo6.path, "Fredo6_donation.html"
	lines = IO.readlines(file)
	t = T6[:DONATION_1, url] + "<br>" + T6[:DONATION_2]
	text = ""
	lines.each { |s| text += s.sub("!text!", t) }
	tmpfile = File.join Traductor.temp_dir, "donation.html"
	File.open(tmpfile, "w") { |f| f.puts text }
	Traductor.openURL tmpfile
end

#Get Image directory list, based on preference
def picture_all_folders
	@picturefamily = Traductor::PictureFamily.new(@folder, @picture_prefix) unless @picturefamily
	@picturefamily.all_folders
end

def picture_selected_folders(selected_folders=nil)
	@picturefamily = Traductor::PictureFamily.new(@folder, @picture_prefix) unless @picturefamily
	@picturefamily.selected_folders selected_folders
end

def declare_picture_folders_symb(symb)
	@picture_symb = symb
end

def picture_get(filename)
	return unless filename
	filename = filename.strip
	return if filename == ""
	folders = nil
	folders = @defparam[@picture_symb] if @defparam && @picture_symb
	list_dir_pictures = picture_selected_folders folders
	
	#Checking filename existence
	filename = filename + ".png" unless filename =~ /\.\w*\d*\Z/ 
	list_dir_pictures.each do |d|
		f = File.join @su_plugin_dir, d, filename
		return f if FileTest.exist?(f)
	end
	return nil	
end

#open a URL with complete and correct form
def open_URL(url)
	Traductor.openURL url
end

#Show about dialog box
def show_about
	(SU_MAJOR_VERSION >= 6) ? show_about_v6 : show_about_v5
end
	
def show_about_v6
	AboutDialog.invoke self
end
	
def get_translation(symb, alter)
	s = T6[symb]
	(s == symb) ? s : Traductor[alter]
end
	
def html_about(html, main_div_height)
	#Initiate the fields
	name = get_translation :PLUGIN_Name, @lst_name
	description = get_translation :PLUGIN_Description, @lst_description
	copyright = T6[:T_HELP_Designed, @creator, Traductor[@lst_copyright]]
	version = @version
	date = T6[@lst_date]
	title = "#{name} #{version} - #{date}"
	
	#style used in the dialog box
	space2 = "&nbsp;&nbsp;"
	skip = "<div style='height: 6px'>&nbsp</div>"
	
	html.create_style 'DivTable', nil, 'BD-SZ: 1', 'Bd: solid', 'Bd-col: gray', 'cellspacing: 0', 'align: center'
	html.create_style 'Title', nil, 'B', 'K: navy', 'F-SZ: 16'
	html.create_style 'Version', nil, 'K: green', 'F-SZ: 16'
	html.create_style 'Date', nil, 'K: black', 'F-SZ: 14'
	html.create_style 'Description', nil, 'B', 'K: blue', 'F-SZ: 12'
	html.create_style 'Label', nil, 'B', 'K: green', 'F-SZ: 11'
	html.create_style 'Info', nil, 'B', 'K: black', 'F-SZ: 11'
	html.create_style 'InfoS', nil, 'B', 'K: black', 'F-SZ: 10'
	html.create_style 'InfoSG', nil, 'B', 'K: green', 'F-SZ: 10'
	html.create_style 'InfoR', nil, 'B', 'K: red', 'F-SZ: 11'
	html.create_style 'Link', nil, 'B', 'K: blue', 'F-SZ: 9'
	html.create_style 'Copyright', nil, 'I', 'K: black', 'F-SZ: 11'
	html.create_style 'Section', nil, 'B', 'K: slateblue', 'BG: gold', 'F-SZ: 11'
	html.create_style 'SectionS', nil, 'B', 'K: slateblue', 'BG: gold', 'F-SZ: 10'
	html.create_style 'Credit', nil, 'K: black', 'F-SZ: 10'
	html.create_style 'CreditB', nil, 'B', 'K: darkgrey', 'F-SZ: 10'
	html.create_style 'Button', nil, 'F-SZ: 10'
	html.create_style 'ButtonG', nil, 'BG: lightgreen', 'F-SZ: 10'
	
	#Styling for screen and printing
	text = "<style type='text/css' media='screen'>"
	text += ".MAIN_DIV_Style {position: relative; height: #{main_div_height}px; overflow-y: auto; overflow-x: hidden; }"
	text += "</style>"
	html.body_add text
	
	#Creating the title
	txplug = HTML.format_span name, "", "Title"
	txversion = HTML.format_span version, "", "Version"
	txdate = HTML.format_span date, "", "Date"
	html.body_add "<div cellspacing='0px' cellpadding='0px' align='center'>", "#{txplug}&nbsp;#{txversion} - #{txdate}", "</div>"
	html.body_add skip
		
	#Description
	desc = HTML.format_span Traductor[@lst_description], "", "Description" if @lst_description
	copyright = HTML.format_span T6[:T_HELP_Designed, @creator, Traductor[@lst_copyright]], "", "Copyright" if @lst_description
	html.body_add "<table width='100%' cellpadding='3px'>"
	html.body_add "<tr><td align='center'>#{desc}</td></tr>"
	html.body_add "<tr><td align='center'>#{copyright}</td></tr>"
	html.body_add "</table>"
	html.body_add skip
		
	#Main div
	html.body_add "<div width='100%' class='MAIN_DIV_Style DivTable'>"
	html.body_add "<table width='100%' cellspacing='0px' cellpadding='0px'>"
	
	#Information
	linfo = []
	linfo.push [T6[:T_HELP_Subfolder], @folder, 'Info']
	linfo.push [T6[:T_HELP_RootPath], @su_plugin_dir, 'InfoS']
	linfo.push [T6[:T_HELP_LoadTime], get_load_time, 'Info']
	if @plugin_name != "LibFredo6"
		linfo.push [T6[:T_HELP_LibFredo6], LibFredo6.version, 'InfoR']
	else	
		linfo.push [T6[:T_HELP_TotalLoadTime], Plugin.get_total_load_time, 'Info']
	end	
		
	text = HTML.format_span T6[:T_HELP_Info], "", "Section"
	html.body_add "<table width='100%' cellpadding='0px'>"
	html.body_add "<tr><td align='left'>#{text}</td></tr>"
	linfo.each do |info|
		label = HTML.format_span info[0], "", "Label"
		value = HTML.format_span info[1], "", info[2]
		html.body_add "<tr><td>#{label} = #{value}</td></tr>"
	end
	html.body_add "</table>"
	html.body_add skip

	#Support
	if @web_site_name || @web_support_link || @web_site_link
		linfo = []
		linfo.push [:T_HELP_WebSiteName, @web_site_name, @web_site_link] if @web_site_name
		if @web_support_link
			linfo.push [:T_HELP_MenuWebInfo, @web_support_link]
		elsif @web_site_link
			linfo.push [:T_HELP_WebSiteLink, @web_site_link]
		end	
		
		if linfo.length > 0
			text = HTML.format_span T6[:T_HELP_Support], "", "Section"
			html.body_add "<table width='100%' cellpadding='0px'>"
			html.body_add "<tr><td align='left'>#{text}</td></tr>"
			linfo.each do |info|
				label = HTML.format_span T6[info[0]], "", "Label"
				value = HTML.format_textlink info[1], info[0].to_s, 'Link', nil, info[2]
				html.body_add "<tr><td>#{label} = #{value}</td></tr>"
			end
			html.body_add "</table>"
			html.body_add skip
		end	
	end	
		
	#Credit Table	
	if @lst_credits.length > 0
		text = HTML.format_span T6[:T_HELP_Credits], "", "Section"
		html.body_add "<table width='100%' cellpadding='0px'>"
		html.body_add "<tr><td colspan='2' align='left'>#{text}</td></tr>"
		
		@lst_credits.each do |credit|
			if credit =~ /:/
				text = HTML.format_span($`, "", "CreditB") + HTML.format_span($& + $', "", "Credit")
			else	
				text = HTML.format_span credit, "", "Credit"
			end	
			html.body_add "<tr><td width='10px' align='right'>-</td>"
			html.body_add "<td align='left'>#{text}</td></tr>"
		end	
		html.body_add "</table>"
	end

	#Usage
	lst_usage = usage_list
	unless lst_usage.empty?
		ntot, time_usage = usage_total
		text = HTML.format_span T6[:T_HELP_PLUGIN_USE], "", "Section"
		text += HTML.format_span " (#{time_usage})", "", "InfoS"
		html.body_add "<table cellpadding='0px'>"
		html.body_add "<tr><td colspan='3' align='left'>#{text}</td></tr>"	
		lst_usage.each do |usage|
			text_cmd = HTML.format_span usage[1], "", "InfoS"
			text_nb = HTML.format_span "#{usage[0]}", "", "InfoSG"
			html.body_add "<tr><td align='left'>-</td>"
			html.body_add "<td align='left'>#{text_cmd}</td>"
			html.body_add "<td align='left'>#{text_nb}</td>"
			html.body_add "</tr>"
		end	
		html.body_add "</table>"
	end
	
	#End of scrolling DIV
	html.body_add "</table></div>"
	
	
	#Creating the dialog box button		
	butdone = HTML.format_button T6[:T_BUTTON_Done], "ButtonDone", 'Button', nil
	butprint = HTML.format_button T6[:T_BUTTON_Print], "ButtonPrint", 'Button', nil
	butcheck = HTML.format_button T6[:T_BUTTON_CheckForUpdate], "ButtonCheck", 'ButtonG', nil
	butperf = HTML.format_button T6[:T_HELP_MenuPerformances], "ButtonPerf", 'ButtonG', nil, T6[:T_TIP_MenuPerformances]
	butpurge = HTML.format_button T6[:T_HELP_MenuPurgeObsolete], "ButtonPurge", 'ButtonG', nil, T6[:T_TIP_MenuPurgeObsolete]
	html.body_add "<table class='T_NOPRINT_Style' width='99%' cellpadding='6px'><tr>"
	html.body_add "<td width='20%' align='left'>", butprint, "</td>"
	html.body_add "<td width='60%' align='center'>", butcheck, space2, butperf, space2, butpurge, "</td>"
	html.body_add "<td align='right'>", butdone, "</td>"
	html.body_add "</tr></table>"
end
	
#Old version for SU5 which does not support Web dialog	
def show_about_v5
	text = ""
	text += Traductor[@lst_name] + " v" + @version
	text += "\n" + Traductor[@lst_description] if @lst_description
	text += "\n\n" + T6[:T_HELP_Designed, @creator, Traductor[@lst_copyright]]
	text += "\n" + T6[:T_HELP_Date] + " : " + T6[@lst_date]
	
	if @lst_credits.length > 0
		text += "\n\n" + T6[:T_HELP_Credits]
		@lst_credits.each { |w| text += "\n   - " + w }
	end	
	
	text += "\n\n" + T6[:T_HELP_Info]
	text += "\n  - " + T6[:T_HELP_RootPath] + " = " + @su_plugin_dir	
	text += "\n  - " + T6[:T_HELP_Subfolder] + " = " + @folder	
	text += "\n  - " + T6[:T_HELP_LoadTime] + " = #{get_load_time}"
	ntot, time_usage = usage_total
	text += "\n  - " + "#{T6[:T_HELP_Usage]} (#{time_usage})" + " = #{ntot}" if ntot
	if @plugin_name != "LibFredo6"
		text += "\n  - " + T6[:T_HELP_LibFredo6] + " = #{LibFredo6.folder} (#{MYPLUGIN.get_load_time})"
	else	
		text += "\n  - " + T6[:T_HELP_TotalLoadTime] + " = #{Plugin.get_total_load_time}"
	end	

	if @web_site_name || @web_support_link || @web_site_link
		text += "\n\n" + T6[:T_HELP_Support]
		text += "\n  - " + T6[:T_HELP_WebSiteName] + " --> " + @web_site_name if @web_site_name
		if @web_support_link
			text += "\n  - " + T6[:T_HELP_MenuWebInfo] + " --> " + @web_support_link
		elsif @web_site_link
			text += "\n  - " + T6[:T_HELP_WebSiteLink] + " --> " + @web_site_link
		end	
	end	
	
	UI.messagebox text, ((RUN_ON_MAC) ? MB_MULTILINE : MB_OK)
end

#Open the web page for a link
def open_support_link(ssymb)
	return unless ssymb.class == String
	case ssymb.intern
	when :T_HELP_WebSiteName, :T_HELP_WebSiteLink
		link = @web_site_link
	when :T_HELP_MenuWebInfo
		link = @web_support_link
	else
		return
	end
	Sketchup.set_status_text "Opening #{link}...."
	UI.openURL link
	Sketchup.set_status_text ""
end
	
#--------------------------------------------------------------------------------------------------------------
# Manage Old files and directories
#--------------------------------------------------------------------------------------------------------------			 

#Check older files - This method is obsolete
def check_older_scripts
end

#--------------------------------------------------------------------------------------------------------------
# Manage Configuration of a Plugin
#--------------------------------------------------------------------------------------------------------------			 

Traductor_Plugin_Command = Struct.new "Traductor_Plugin_Command", :symb, :proc, :menutext, :icon, :ttip, :valproc,
                                                                  :test_cond, :separator, :submenu, :state, :cmd

def declare_toolbar(toolbarname, list_symb_buttons)
	@toolbarname = toolbarname
	list_symb_buttons = [list_symb_buttons] if list_symb_buttons.class == String
	@list_symb_buttons = list_symb_buttons
end

def declare_topmenu(topmenusymb, list_menuperso=nil, separator=nil)
	@topmenu = (topmenusymb) ? eval_T6(topmenusymb) : nil
	list_menuperso = [list_menuperso] unless list_menuperso.class == Array
	@list_menuperso = list_menuperso
	@separator = separator
end

#Declare a command (i.e. both menu and icon in toolbar)
def declare_command(symb, iconroot=nil, &proc)
	symbtext = symb.to_s + "Menu"
	menutext = eval_T6 symbtext.intern
	symbttip = symb.to_s + "Tooltip"
	ttip = eval_T6 symbttip.intern
	ttip = menutext if ttip == symbttip
	declare_command_long symb, menutext, ttip, iconroot, &proc
end

def declare_command_long(symb, text_menu, text_tooltip, iconroot=nil, &proc)
	tpc = Traductor_Plugin_Command.new
	tpc.symb = symb
	tpc.proc = proc
	tpc.menutext = text_menu
	symbttip = symb.to_s + "Tooltip"
	tpc.ttip = text_tooltip
	tpc.ttip = tpc.menutext unless tpc.ttip
	tpc.icon = iconroot
	tpc.icon = eval_constant(symb.to_s + "Icon") unless iconroot
	tpc.state = nil
	tpc.valproc = false
	@list_commands.push tpc
	@hsh_tpc[symb] = tpc
end

#Return the Sketchup UI command for a symbol, or the full hash table if symb is nil
def get_command(symb=nil)
	(symb) ? @hsh_commands[symb] : @hsh_commands
end

#modify the tooltip of an icon (we cannot change the menu text or icon with the API!!)
def change_button_tooltip(symb, tooltip)
	cmd = @hsh_commands[symb]
	return unless cmd
	cmd.tooltip = cmd.status_bar_text = tooltip
end

#Change the state of a button (to be used with care)
def set_button_state(symb, state=nil)
	tpc = @hsh_tpc[symb]
	return nil unless tpc
	tpc.state = state
	if state && !tpc.valproc
		tpc.cmd.set_validation_proc { state_validation_proc tpc.symb }
		tpc.valproc = true
	elsif state == nil && tpc.valproc
		tpc.valproc = false
		tpc.cmd.set_validation_proc { MF_ENABLED | MF_UNCHECKED}
	end	
end

def state_validation_proc(symb)
	tpc = @hsh_tpc[symb]
	(tpc.state) ? tpc.state : (MF_ENABLED | MF_UNCHECKED)
end

#Declare a contextual menu, possibly dependent on a condition
def declare_context_handler(symb, test_condition, separator=nil, submenu=nil, &proc)
	txh = symb.to_s + "Handler"
	text_menu = eval_T6 txh.intern
	symbtext = (symb.to_s + "Menu").intern
	text_menu = eval_T6 symbtext if text_menu == txh
	symbttip = symb.to_s + "Tooltip"
	text_tooltip = eval_T6 symbttip.intern
	text_tooltip = text_menu if text_tooltip == symbttip
	declare_context_handler_long symb, text_menu, text_tooltip, test_condition, separator, submenu, &proc
end

def declare_context_handler_long(symb, text_menu, text_tooltip, test_condition, separator=nil, submenu=nil, &proc)
	tpc = Traductor_Plugin_Command.new
	tpc.symb = symb
	tpc.proc = proc
	tpc.menutext = text_menu
	tpc.ttip = text_tooltip
	tpc.ttip = tpc.menutext unless tpc.ttip
	tpc.test_cond = test_condition
	tpc.submenu = eval_T6 submenu
	tpc.separator = separator
	@list_handlers.push tpc
end

#Declare a separator for Menu, Toolbar or both
def declare_separator(mt='MT')
	return unless mt
	@list_commands.push "M" if mt =~ /M/i
	@list_commands.push "T" if mt =~ /T/i
end

def declare_menu_separator
	@list_commands.push "M"
end

def declare_toolbar_separator
	@list_commands.push "T"
end

def default_icons_visible(list_symb=nil)
	if list_symb
		list_symb = [list_symb] unless list_symb.class == Array
		@default_icons_visible |= list_symb.collect { |symb| symb.to_s }
	else
		#@default_icons_visible = []
		@default_icons_visible = nil
	end
end

def default_handlers_visible(list_symb)
	if list_symb
		list_symb = [list_symb] unless list_symb.class == Array
		@default_handlers_visible |= list_symb.collect { |symb| symb.to_s }
	else
		@default_handlers_visible = []
	end
end

#Method to process all initialization task: commands, default parameters
def go
	
	#Declaring the default param for the configuration
	build_config_defparam
	
	#Loading the configuration file
	@defparam.load_file
	
	#Configuring the toolbar and menu
	build_config_commands
	build_config_handlers
	
end

#Build the default parameters for the configuration
def build_config_defparam
	dp = @defparam
	
	#Title section
	dp.separator :T_DEFAULT_SECTION_Plugin
	
	#Alternate directory for pictures
	dp.alternate_icon_dir :__IMAGE_Dir, "", picture_all_folders
	declare_picture_folders_symb (:__IMAGE_Dir)

	#Toolbar
	dp.declare :T_DEFAULT_ToolbarName, @toolbar, 'T'
	
	#Icon shown in toolbar
	klist = []
	lsymb = []
	@list_commands.each do |tpc|
		next if tpc == 'M' || tpc == 'T'
		klist.push [tpc.symb.to_s, tpc.menutext]
		lsymb.push tpc.symb.to_s
	end
	if klist.length > 0
		lsymb = [] unless @default_icons_visible
		#lsymb = @default_icons_visible unless @default_icons_visible.empty?
		lsymb = @default_icons_visible if @default_icons_visible && @default_icons_visible.length > 0
		dp.declare :T_DEFAULT_IconVisible, lsymb.join(';;'), "M", eval_T6(klist)
	end	
	
	#Top menu
	lmenu = []
	if @list_menuperso
		@list_menuperso.each do |mp|
			symb = CustomMenu.get_menu_symb mp
			sumenu = CustomMenu.get_menu_sumenu mp
			text = CustomMenu.get_menu_name mp
			text = "" unless text
			text += " (#{sumenu})" if sumenu != ""
			lmenu.push [symb.to_s, text] if symb && text
		end	
	end	
	if lmenu.length > 1
		@defparam.declare :T_DEFAULT_TopMenu, lmenu[0][0], "H:", lmenu
	end	

	#Contextual menu
	klist = []
	lsymb = []
	@list_handlers.each do |tpc|
		next if tpc == 'M' || tpc == 'T'
		klist.push [tpc.symb.to_s, tpc.menutext]
		lsymb.push tpc.symb.to_s
	end
	if klist.length > 0
		lsymb = @default_handlers_visible unless @default_handlers_visible.empty?
		dp.declare :T_DEFAULT_HandlerVisible, lsymb.join(';;'), "M", eval_T6(klist)
	end	
	
end

#Build the commands (menus and toolbar buttons)
def build_config_commands	
	#Top menu and toolbar
	sumenu = CustomMenu.get_menu_suhandle @defparam[:T_DEFAULT_TopMenu]
	sumenu = UI.menu "Plugins" unless sumenu
	@topmenu = @plugin_name unless @topmenu
	@toolbar = @defparam[:T_DEFAULT_ToolbarName]
	@toolbar = @plugin_name unless @toolbar
	list_dir_icons = picture_selected_folders @defparam[@picture_symb].split(';;')
	@cmdfamily = Traductor::CommandFamily.new list_dir_icons, sumenu, @topmenu, @toolbar, @separator
	
	#Filtering the commands - Take only chosen icons and avoid double separators
	ltpc = []
	msep = true
	tsep = true
	lshown = @defparam[:T_DEFAULT_IconVisible]
	@list_commands.each do |tpc|
		if (tpc == 'M')
			ltpc.push tpc unless msep
			msep = true
		elsif tpc == 'T'
			ltpc.push tpc unless tsep
			tsep = true
		else
			vshow = lshown.include?(tpc.symb.to_s) && tpc.icon
			ltpc.push [vshow, tpc]
			tsep = false if vshow
			msep = false
		end	
	end	
	return if ltpc.length == 0
	ltpc.pop until ltpc.last != 'M' && ltpc.last != 'T'	#trailing separators		
	return if ltpc.length == 0
	
	#Processing the commands
	pending_tsep = false
	ltpc.each do |tpc|
		if tpc == 'M'
			@cmdfamily.add_menu_separator
		elsif tpc == 'T'
			#@cmdfamily.add_toolbar_separator
			pending_tsep = true
		else
			icon = (tpc[0]) ? tpc[1].icon : nil 
			if icon && pending_tsep
				@cmdfamily.add_toolbar_separator
				pending_tsep = false
			end	
			cmd = @cmdfamily.add_command(tpc[1].menutext, tpc[1].ttip, icon, @icon_conv, nil) do
				command_invoke tpc[1] 
			end	
			@hsh_commands[tpc[1].symb] = cmd if cmd
			tpc[1].cmd = cmd
		end	
	end
	
	#Standard support menu
	@cmdfamily.add_menu_separator
	populate_support_menu @cmdfamily, nil, nil
	
	#showing the toolbar
	@cmdfamily.show_toolbar
end

#Execute a command, and other tasks (usage log)
def command_invoke(tpc)
	usage_use tpc.symb
	tpc.proc.call
end

#Register the usage of a command of the plugin
def usage_use(symb)
	usage_get
	n = @hsh_usage[symb.to_s]
	n = 0 unless n
	@hsh_usage[symb.to_s] = n + 1
	Sketchup.write_default @plugin_name, PLUGIN_RKEY_Usage, usage_encode
end

#Get the total number of usages
def usage_total
	usage_get unless @hsh_usage
	t = @hsh_usage['_time']
	return nil unless t
	ntot = 0
	@hsh_usage.each { |key, val| ntot += val if key != '_time' }
	return nil if ntot == 0
	tc = Time.at t
	stime = tc.strftime "%a %d %b %Y - %Hh%M"
	[ntot, stime]
end

#return the total time and 
def usage_list
	usage_get unless @hsh_usage
	lst = []
	@hsh_usage.each do |key, val| 
		tpc = @hsh_tpc[key.intern]
		lst.push [val, tpc.menutext] if tpc
	end	
	lst.sort! { |a, b| a[1] <=> b[1] }
end

#Encode the string for usage to be stored in the registry
def usage_encode
	ls = []
	@hsh_usage.each do |key, value|
		ls.push "'#{key}'=>#{value}"
	end
	"{" + ls.join(',') + "}"
end

#Get the full information on usage
def usage_get
	unless @hsh_usage
		@hsh_usage = {}
		s = Sketchup.read_default @plugin_name, PLUGIN_RKEY_Usage
		begin
			eval "@hsh_usage = #{s}" if s
		rescue
			return {}
		end
		@hsh_usage = { '_time' => Time.now.to_f } unless @hsh_usage['_time']
	end		
	@hsh_usage
end

#Build the commands (menus and toolbar buttons)
def build_config_handlers
	return if @list_handlers.length == 0

	#Creating the commands once for all
	@hsh_ui_command = {}
	@list_handlers.each do |tpc|
		@hsh_ui_command[tpc.symb] = cmd = UI::Command.new(tpc.menutext) { tpc.proc.call }
		cmd.tooltip = tpc.ttip if tpc.ttip
	end
	
	UI.add_context_menu_handler do |cxmenu|
		menu = cxmenu
		
		#Reinitializing the context for new menu
		if menu != @handler_menu
			@handler_menu = menu
			@hash_handler_menu = {}
		end	
		hcond = {}
		
		#Loop on contextual menus declared
		lshown = @defparam[:T_DEFAULT_HandlerVisible]
		@list_handlers.each do |tpc|
			#not selected
			next unless lshown.include?(tpc.symb.to_s)
			
			#Evaluating the condition if any
			cond = tpc.test_cond
			if cond
				case hcond[cond.to_s]
				when 0
					next
				when nil
					res = hcond[cond.to_s] = ((cond.execute_test) ? 1 : 0)
					next if res == 0
				end	
			end
			
			#Possible submenu
			submenu = tpc.submenu
			nosep = false
			if submenu && submenu.strip != ''
				if @hash_handler_menu[submenu] == nil
					menu.add_separator if tpc.separator
					menu = menu.add_submenu submenu
					@hash_handler_menu[submenu] = true
					nosep = true
				end
			end

			#Creating the submenu
			menu.add_separator if tpc.separator && !nosep
			
			menu.add_item(@hsh_ui_command[tpc.symb])
		end	
	end 
end	

#Create a Cursor with the preferred image folders specified by Default Parameters
def create_cursor(name, hotx=0, hoty=0)
	unless @cursorfamily
		list_dir_icons = picture_selected_folders @defparam[@picture_symb].split(';;')
		@cursorfamily = Traductor::CursorFamily.new list_dir_icons, @cursor_conv
	end
	@cursorfamily.create_cursor name, hotx, hoty
end

#Compute a tooltip text with plugin name, version, date and author
def compute_tooltip
	"#{@plugin_name} v#{@version} - #{T6[@lst_date]} - #{@creator}"
end

#--------------------------------------------------------------------------------------------------------------
# Manage obsolete files
#--------------------------------------------------------------------------------------------------------------

#Register old files or directories
def register_obsolete_files(filedir)
	filedir = [filedir] unless filedir.class == Array
	@lst_obsolete_files = [] unless @lst_obsolete_files
	@lst_obsolete_files |= filedir
end

#Check the existence of obsolete files and return the list
def check_obsolete_files
	lfiles = []

	#Registered files
	$:.each do |sudir|
		@lst_obsolete_files.each do |f|
			lfiles += Dir[File.join(sudir, f)]
		end	
	end
	
	#Directory for older versions
	dd = File.basename @plugin_dir
	if dd =~ /(.+_Dir_)(\d\d)\Z/
		root = $1
		curver = $2
		$:.each do |sudir|
			Dir[File.join(sudir, "#{root}*")].each do |d|
				if d =~ /(.+_Dir_)(\d\d)\Z/
					lfiles.push d unless $2 == curver
				end
			end	
		end
	end	
	lfiles
end

end	#class Plugin

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Custom Menu:
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

ALL_SU_MENUS = ["Plugins", "Tools", "File", "Edit", "View", "Camera", "Draw", "Page", "Window", "Help"]

class CustomMenu

Traductor_Custom_Menu = Struct.new("Traductor_Custom_Menu", :symb, :menutext, :sumenu, :hmenu, :separator,
                                                            :list_hmenus) 

@@hsh_custom_menus = {}
@@hsh_custom_hmenus = {}

def CustomMenu.register(symb, menutext, sumenu, separator=false)
	hcm = @@hsh_custom_menus[symb.to_s]
	return hcm if hcm
	
	hcm = Traductor_Custom_Menu.new
	hcm.symb = symb
	hcm.menutext = (menutext) ? menutext : symb.to_s
	hcm.separator = separator
	hcm.sumenu = sumenu
	@@hsh_custom_menus[symb.to_s] = hcm
	hcm
end

#Get the SU handle to a custom menu
def CustomMenu.get_menu_suhandle(hcm)
	# SU top menu
	return UI.menu(hcm) if ALL_SU_MENUS.include?(hcm)
	
	#Custom menu
	hcm = @@hsh_custom_menus[hcm.to_s] if hcm.class == String || hcm.class == Symbol
	return nil unless hcm.class == Struct::Traductor_Custom_Menu
	return hcm.hmenu if hcm.hmenu
	
	#Creating the menu
	hmenu = get_menu_suhandle hcm.sumenu
	return nil unless hmenu
	hmenu.add_separator if hcm.separator
	hcm.hmenu = hmenu.add_submenu hcm.menutext
	@@hsh_custom_hmenus[hcm.hmenu.to_s] = hcm
	return hcm.hmenu
end

def CustomMenu.get_menu_symb(hcm)
	return nil unless hcm
	return hcm if ALL_SU_MENUS.include?(hcm)
	hcm = @@hsh_custom_menus[hcm.to_s] if hcm.class == String || hcm.class == Symbol
	return nil unless hcm.class == Struct::Traductor_Custom_Menu
	hcm.symb
end

def CustomMenu.get_menu_name(hcm)
	return nil unless hcm
	return "Sketchup - #{hcm}" if ALL_SU_MENUS.include?(hcm)
	hcm = @@hsh_custom_menus[hcm.to_s] if hcm.class == String || hcm.class == Symbol
	return nil unless hcm.class == Struct::Traductor_Custom_Menu
	hcm.menutext
end

def CustomMenu.get_menu_sumenu(hcm)
	return nil unless hcm
	return "" if ALL_SU_MENUS.include?(hcm)
	hcm = @@hsh_custom_menus[hcm.to_s] if hcm.class == String || hcm.class == Symbol
	return nil unless hcm.class == Struct::Traductor_Custom_Menu
	CustomMenu.get_menu_name hcm.sumenu
end

end	#class Custom Menu

#--------------------------------------------------------------------------------------------------------------
# Custom TestCondition: code attached to a test
#--------------------------------------------------------------------------------------------------------------			 

class TestCondition

@@hsh_symb = {}

def initialize(symb=nil, &proc)
	@@hsh_symb[symb.to_s] = self
	@proc = proc	
	@val = nil
end

def execute_test
	@val = @proc.call if @proc
	@val
end

def get_val
	@val
end

def TestCondition.get_self(symb)
	return nil unless symb
	(symb.class == Traductor::TestCondition) ? symb : @@hsh_symb[symb.to_s]
end

end	#class TestCondition


end #Module Traductor

