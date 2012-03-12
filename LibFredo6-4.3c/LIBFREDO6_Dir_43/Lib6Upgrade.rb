=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright © 2011 Fredo6 - Designed and written February 2011 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Upgrade.rb
# Original Date	:  23 Feb 2011
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library about Plugin check for upgrade for LibFredo6-compliant scripts.
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end


#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Class Upgrade: Manage check for Updates
#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------

module Traductor

T6[:UPD_HDR_InstalledLocally] = "Installed Locally"
T6[:UPD_HDR_ReleaseOnWeb] = "Released on Web"
T6[:UPD_TIP_LinkInfo] = "Open the web page related to the plugin"
T6[:UPD_TIP_LinkFile] = "Download file for installation"
T6[:UPD_TXT_OnlyRegistered] = "Show only installed plugins"
T6[:UPD_TIP_OnlyRegistered] = "This option allows seeing plugins which are published on Web but not installed locally"
T6[:UPD_TXT_LastCheck] = "Last check:"
T6[:UPD_ERR_Check1] = "ERROR in Check for Update"	
T6[:UPD_ERR_Check2] = "Please verify your Internet connection"	
T6[:UPD_ERR_FollowingURLs] = "The Following URLS could not be checked"	
T6[:UPD_MSG_CheckingInformation] = "Checking information...."
T6[:UPD_TXT_NextCheck] = "Next Check in:"

T6[:UPD_TIP_Obsolete] = "Plugin either discontinued or replaced by another one"
T6[:UPD_TIP_UpToDate] = "Up to date"
T6[:UPD_TIP_NeedUpgrade] = "Need upgrade"
T6[:UPD_TIP_Default] = "Update information NOT available online"
T6[:UPD_TIP_NextLaunchAfter] = "Next launch of Sketchup after %1"

#--------------------------------------------------------------------------------------------------------------
# Class Upgrade: classinitialization part
#--------------------------------------------------------------------------------------------------------------			 

#Class variables initialization
unless defined?(self::Upgrade)
class Upgrade
	@@top_dialog = nil
	@@only_registered = true
	@@time_last_check = nil
	@@external_check = false
end
end

class Upgrade

@@tmpdir = (RUN_ON_MAC) ? "/tmp" : ENV["TEMP"].gsub(/\\/, '/')

#--------------------------------------------------------------------------------------------------------------
# Class methods: Manage top level actions
#--------------------------------------------------------------------------------------------------------------

#Show the dialog box for Check for update.
# An optional list of plugin names can be passed
def Upgrade.top_dialog(*hoptions)
	hsh = {}
	hoptions.each { |h| h.each { |key, val| hsh[key] = val } }
	unique_key = "Traductor_Upgrade_DLG"
	@@top_dialog = Upgrade.new(unique_key, hsh) unless Traductor::Wdlg.check_instance_displayed(unique_key)
end

#Show the dialog box for Check for update.
# An optional list of plugin names can be passed
def Upgrade.time_for_check?
	tcheck = Upgrade.date_next_check
	UpgradeWarning.show if @@top_dialog == nil && tcheck < Time.now.to_f
end

#Verify if the current date will trigger a check for update
def Upgrade.date_next_check(time=nil)
	regkey = "Time_Next_Check"
	
	#Writing duration as number of seconds
	if time
		Sketchup.write_default "LibFredo6", regkey, time.to_s
		
	#Getting duration in nb days	
	else
		time = Sketchup.read_default "LibFredo6", regkey
		time = Traductor.string_to_float_formula(time)
		time = 0 unless time
	end	
	time
end

#Get or set the duration until next check
def Upgrade.duration_next_check(duration=nil)
	regkey = "Duration_Next_Check"
	
	#Writing duration in days
	if duration
		duration = 999 if duration > 999
		duration = 0 if duration < 0
		duration = Traductor.string_to_float_formula duration.to_s
		Sketchup.write_default "LibFredo6", regkey, duration.to_s if duration
		
	#Getting duration in nb days	
	else
		duration = Sketchup.read_default "LibFredo6", regkey
		duration = MYDEFPARAM[:T_DEFAULT_DurationNextCheck] unless duration
		duration = Traductor.string_to_float_formula duration.to_s
		if duration > 999
			duration = 999
			Sketchup.write_default "LibFredo6", regkey, duration.to_s
		end	
	end	
	(duration && duration >= 0) ? duration : 0
end

#Get or Set the last time of Check for Update
def Upgrade.time_last_check(time=nil)
	regkey = "Time_Last_Check"
	
	#Writing duration as number of seconds
	if time
		Sketchup.write_default "LibFredo6", regkey, time.to_s
		
	#Getting duration in nb days	
	else
		time = Sketchup.read_default "LibFredo6", regkey
		time = Traductor.string_to_float_formula(time)
		time = 0 unless time
	end	
	time
end

#-------------------------------------------------------------------------------------------
# Instance Methods for Upgrade class
#-------------------------------------------------------------------------------------------

#initialization of the Upgrade environment (single instance)
def initialize(unique_key, hoptions)	
	#Getting all external plugins if not already done
	@hsh_plugins = AllPlugins.get_all_registered_plugins
	
	#Loading update info
	@file_save_info = File.join @@tmpdir, "LibFredo6_Update_info.tmp"
	load_update_info

	#Creating the dialog box
	@wdlg = create_dialog_top unique_key, hoptions
end

def sorting_plugins_name(a, b)
	return -1 if a == "LibFredo6"
	return 1 if b == "LibFredo6"
	a <=> b
end

#Arrange the list of plugins by sorting and decoding
def organize_plugins
	#Sorting plugins by alpha order
	ls = @hsh_plugins.values.find_all { |a| a[:author] }
	@lst_plugins = ls.sort do |a, b| 
		(a[:author] == b[:author]) ? sorting_plugins_name(a[:name], b[:name]) : a[:author] <=> b[:author]
	end	
	
	#Build the counters for authors
	@hsh_authors = Hash.new 0
	@lst_plugins.each do |hsh| 
		author = hsh[:author]
		@hsh_authors[author] += 1 if author
	end	
	
	#Building the list of URLs to check
	def_website, def_url = MYPLUGIN.get_upd_info
	hsh_urls = {}
	@lst_plugins.each do |hsh|
		url = hsh[:url]
		next unless url
		website = hsh[:website]
		hsh_urls[url] = website if hsh_urls[url] == nil
	end	
	@update_urls = [[def_url, def_website]]
	hsh_urls.each do |url, website|
		next if url == def_url
		unless website
			url =~ /\/\/(.*)\//
			website = $1
		end	
		@update_urls.push [url, website]
	end	
end

#Refresh the dialog box
def refresh_dialog_top
	organize_plugins
	prepare_plugin_table
	html = format_html_top @wdlg
	@wdlg.set_html html
end

#---------------------------------------------------------------------------------------
# Update management
#---------------------------------------------------------------------------------------

#Process check for update for a given url
def invoke_update
	@iurl = 0
	@lst_errors = []
	@ierror = 0
	@hsh_update_save = {}
	@wdlg.button_enable @id_but_check, false
	invoke_update_url
end


#Process check for update for a given url
def invoke_update_url
	url = @update_urls[@iurl]
	unless url
		terminate_update
		return
	end
	@wdlg.execute_script "xfetch_get('#{@iurl}', '#{url[0]}', '#{url[1]}')"
end

#Terminate the update
def terminate_update
	@wdlg.button_enable @id_but_check, true
	
	#Manage Erros
	if @lst_errors.length > 0
		text = T6[:UPD_ERR_Check1] + "\n" + T6[:UPD_ERR_Check2]
		text += "\n" + T6[:UPD_ERR_FollowingURLs]
		@lst_errors.each { |lurl| text += "\n -- #{lurl[1]} (#{lurl[0]})" }
		UI.messagebox text
		return refresh_last_check if @lst_errors.length == @update_urls.length
	end	
	
	#Transfer and save information
	@@time_last_check = Upgrade.time_last_check(Time.now.to_f)
	store_next_check @@time_last_check
	save_update_info
	refresh_dialog_top
end

#Save the update information to a temporary file
def save_update_info
	return if @hsh_update_save.length == 0
	File.open @file_save_info, "w" do |f|
		@hsh_update_save.each do |plugin, hsh|
			lst = []
			hsh.each { |key, val| lst.push "#{key} = #{val}" }
			f.puts "#{lst.join ";"}"
		end	
	end	
end

#Save the update information to a temporary file
def load_update_info
	return unless FileTest.exist?(@file_save_info)
	IO.foreach(@file_save_info) do |line|
		process_update line, false
	end	
end

#Compute and store the next date for check
def store_next_check(now=nil)
	now = Time.now.to_f unless now
	duration = Upgrade.duration_next_check
	t = duration * 24 * 3600
	time_next = (duration > 0) ? (now + duration * 24 * 3600) : 0
	Upgrade.date_next_check time_next
	time_next
end

#Call back from the Dialog box for Update
def notify_update(event, fetch_id, sval)
	
	#Termination and Errors
	if event =~ /error/i
		@ierror += 1
	elsif event !~ /finish/i
		process_update(sval)
		return
	end	

	#Moving to next URL
	@lst_errors.push @update_urls[@iurl] if @ierror > 0
	@iurl += 1
	@ierror = 0
	invoke_update_url
end

#Process an update from the string read in url
def process_update(sval, save_tmp=true)
	#Parsing the string
	lchunk = sval.split(';').collect { |a| a.strip }
	hsh = {}
	hsh_orig = {}
	lchunk.each do |a| 
		a =~ /=/
		key = $`
		val = $'
		symb = symb_from_keyword key
		next unless symb && val
		hsh[symb] = T6[val.strip]
		hsh_orig[symb] = val.strip
	end	
	
	#Plugin info decoding
	new_plugin = hsh[:name]
	return unless new_plugin
	new_plugin = hsh[:name] = verify_plugin(new_plugin)
	old_hsh = @hsh_plugins[new_plugin]
	old_hsh = @hsh_plugins[new_plugin] = {} unless old_hsh
	
	#Transfering information to internal plugin hash array
	hsh.each { |key, val| old_hsh[key] = val }
	
	#Transfering information for saving to temporary file
	if save_tmp
		hsh_save = @hsh_update_save[new_plugin]
		hsh_save = @hsh_update_save[new_plugin] = {} unless hsh_save
		hsh_orig.each { |key, val| hsh_save[key] = val }
	end	
end

#Verify the plugin name in the list (match lower / upper case)
def verify_plugin(name)
	@hsh_plugins.each do |key, val|
		key = key.strip
		return key if key == name || key.downcase == name.downcase
	end
	name
end

#Parse the keyword and return corresponding symbol
def symb_from_keyword(keyword)
	return nil unless keyword
	
	case keyword.strip
	when /plugin/i, /name/i
		:name
	when /version/i
		:new_version
	when /date/i
		:new_date
	when /comment/i
		:new_comment
	when /description/i
		:new_description
	when /author/i
		:author
	when /info/i
		:link_info
	when /required/i
		:new_required
	when /download/i, /link_file/i
		:link_file
	else
		nil
	end	
end

#---------------------------------------------------------------------------------------
# Web Dialog box
#---------------------------------------------------------------------------------------

#Prepare the plugin table for display
def prepare_plugin_table	
	#Texts and Tooltips
	tip_info = T6[:UPD_TIP_LinkInfo]
	tip_file = T6[:UPD_TIP_LinkFile]
	img_file = MYPLUGIN.picture_get("button_down")
	
	border = 'border-top: 1px solid gray'
	htborder = { :style => border }
	
	hstyle2up = { :colspan => 4, :style => "#{@style_up_to_date} ; #{border}", :class => "Col_Comment" }
	hstyle2obs = { :colspan => 4, :style => "#{@style_obsolete} ; #{border}", :class => "Col_Comment" }
	lup_to_date = [T6[:T_TXT_UP_TO_DATE], nil, hstyle2up]

	#Building the table
	ltable = []
	
	author = nil
	@lst_plugins.each_with_index do |hsh, i|
		#Checking the status of the plugin
		version = hsh[:version]
		new_version = hsh[:new_version]
		
		#Skip display
		next if @@only_registered && !version
	
		#Categorize by author
		if hsh[:author] != author
			author = hsh[:author]
			ltable.push [1, [author, nil, { :colspan => 6, :class => "Level1" }]]
		end	
			
		color = ''
		up_to_date = false
		obsolete = (version) ? hsh[:obsolete] : nil
		if obsolete
			color = @style_obsolete
			next unless @filter_obsolete
		elsif !version
			color = @style_uninstalled
		elsif version && new_version 
			if Traductor.compare_version(version, new_version) >= 0
				color = @style_up_to_date
				up_to_date = true
				next unless @filter_up_to_date
			else	
				color = @style_need_upgrade
				next unless @filter_need_upgrade
			end	
		else
			color = @style_default
			next unless @filter_default
		end 	
		
		hstyle1 = { :style => "#{border}; #{color}" }
		htborder = hstyle1
		hstyle1_np = { :style => "#{border}; #{color}"}
		hstyle2 = { :style => "#{color}" }
		hstyle2c = { :colspan => 3, :style => "#{color}", :class => "Col_Comment" }
		hstyle2nc = { :colspan => 4, :style => "#{color}" }
		
		#Filling the table	
		tip_description = (hsh[:description]) ? hsh[:description] : hsh[:new_description]
		tip_description += "\n#{T6[:T_TXT_Required]} --> #{hsh[:required]}" if hsh[:required] && hsh[:required].strip != ""
		txplugin = [hsh[:name], tip_description, htborder]
		txversion = [version, nil, htborder]
		txdate = [hsh[:date], nil, htborder]
		txnew_version = [new_version, nil, hstyle1]
		txnew_date = [hsh[:new_date], nil, hstyle1]
		txrequired = [hsh[:new_required], nil, hstyle1]
		comment = hsh[:comment]
		new_comment = hsh[:new_comment]
		
		#Info link
		link_info = hsh[:link_info]
		if link_info && link_info.length > 0
			tip = tip_info + "\n#{link_info}" 
			hinfo = HTML.format_textlink 'Info', "Info-#{i}", "Cell_Info T_NOPRINT_Style", nil, tip
		else
			hinfo = ""
		end	
		txinfo = [hinfo, nil, hstyle1_np]
		
		#Download link if any
		link_file = hsh[:link_file]
		if link_file
			tip = tip_file + "\n#{link_file}" 
			lk = (RUN_ON_MAC) ? nil : link_file
			hfile = HTML.format_imagelink img_file, 16, 16, "File-#{i}", "Cell_Info", nil, tip, lk
		else
			hfile = ""
		end	
		txlinks = [hfile, nil, hstyle1]
		
		#Main row of the table and additional row for comments
		if obsolete
			empty = [nil, nil, hstyle1]
			ltx = ["#{T6[:T_TXT_OBSOLETE]}: #{obsolete}", T6[:UPD_TIP_Obsolete], hstyle2obs]
			ltable.push [2, txplugin, txversion, txdate, txinfo, ltx, empty, empty, empty]
		elsif up_to_date
			empty = [nil, nil, hstyle1]
			ltable.push [2, txplugin, txversion, txdate, txinfo, lup_to_date, empty, empty, empty]
		else
			ltable.push [2, txplugin, txversion, txdate, txinfo, txnew_version, txnew_date, txlinks, txrequired ]
		end
		
		if comment || (new_comment && !up_to_date && !obsolete)
			empty = [nil, nil, hstyle2]
			ltable.push [2, [comment, nil, hstyle2c], nil, nil, empty, [new_comment, nil, hstyle2nc], empty, empty, empty]
		end	
		
	end
	
	#Filtering the table for lonely author records
	@ltable = []
	ltable.each_with_index do |a, i|
		@ltable.push a unless a[0] == 1 && (!ltable[i+1] || ltable[i+1][0] == 1) 
	end	
end

#Create the dialog box
def create_dialog_top(unique_key, hoptions)
	init_dialog_top
	wdlg_key = unique_key
	title = T6[:T_BUTTON_CheckForUpdate]
	#@wdlg = Traductor::Wdlg.new title, wdlg_key, false
	@wdlg = Traductor::Wdlg.new title, wdlg_key, true
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
	@wid_col_name = 250
	@wid_col_version = 50
	@wid_col_date = 100
	@wid_col_info = 40
	@wid_col_required = 100
	@wid_col_links = 30
	@wid_total = @wid_col_name + 2 * @wid_col_version + 2 * @wid_col_date + @wid_col_info + @wid_col_required + @wid_col_links + @wid_extra
	@hgt_total = @hgt_table + 300
	@wid_message = 250
	@hgt_message = 100
	@xleft_message = (@wid_total - @wid_message) / 2
	@ytop_message = (@hgt_total - @hgt_message) / 2	
	@vtype_duration = Traductor::VTYPE.new 'F:>=0<=999'
	
	@style_up_to_date = 'background-color: #ccfbcc ; color: green'
	@style_need_upgrade = 'background-color: lightpink ; color: red'
	@style_default = 'background-color: #E0F8F7 ; color: royalblue'
	@style_uninstalled = 'background-color: #ffbbff ; color: #cd00cd'
	@style_obsolete = 'background-color: lightgrey ; color: dimgray'

	@filter_up_to_date = true
	@filter_need_upgrade = true
	@filter_obsolete = true
	@filter_default = true
	
	@@time_last_check = Upgrade.time_last_check
end

#Notification of window closure
def on_close_top
	@@top_dialog = nil
end

#Close the dialog box
def close_dialog_top
	@wdlg.close
end

#Build the HTML for Statistics Dialog
def format_html_top(wdlg)
	#Id for elements
	@id_but_check = "ButtonUpdate"
	
	#Creating the HTML stream	
	html = Traductor::HTML.new
	
	#Special_scripts
	html.script_add xfetch_scripts
	
	#style used in the dialog box
	bgcolor = 'BG: #F5D0A9'
	space2 = "&nbsp;&nbsp;"
	
	html.create_style 'DivChecking', nil, 'B', 'K: white', 'F-SZ: 15', 'text-align: center', 'BG: green', 
	                  "height: #{@hgt_message}px", "width: #{@wid_message}px", 'position: absolute', 
					  "left: #{@xleft_message}px", "top: #{@ytop_message}px"
	html.create_style 'Title', nil, 'B', 'K: navy', 'F-SZ: 16', 'text-align: center'
	html.create_style 'Header', nil, 'B', 'F-SZ: 11', 'K: black', bgcolor, 'text-align: center'
	html.create_style 'HeaderS', 'Header', 'I', 'F-SZ: 10'
	html.create_style 'Check', nil, 'I', 'F-SZ: 11'
	html.create_style 'NextCheck', nil, 'I', 'B', 'F-SZ: 11', 'K: blue'

	html.create_style 'WebSite', nil, 'F-SZ: 12'
	html.create_style 'Filter', nil, 'F-SZ: 9', 'B', 'text-align: center'
	html.create_style 'Check', nil, 'F-SZ: 11', 'B', 'K: #cd00cd'
	html.create_style 'Date', nil, 'F-SZ: 11', 'I', 'text-align: right', 'K: darkgrey'
	html.create_style 'Col_', nil, 'F-SZ: 10', 'text-align: left'
	html.create_style 'Col_Name', 'Col_', 'B', 'K: black'
	html.create_style 'Col_Version', 'Col_', 'B', 'K: green', 'text-align: center'
	html.create_style 'Col_Date', 'Col_', 'B', 'K: darkblue', 'text-align: center'
	html.create_style 'Col_Info', nil, 'B', 'I', 'K: blue', 'text-align: center', 'border-left: 1px solid green', 'border-right: 1px solid red'
	html.create_style 'Col_NewVersion', 'Col_Version', 'I', 'K: darkgrey'
	html.create_style 'Col_NewDate', 'Col_Date', 'I', 'K: darkgrey'
	html.create_style 'Col_Required', 'Col_Date', 'I', 'K: darkgrey'
	html.create_style 'Col_Comment', 'Col_Date', 'I', 'K: darkgrey'
	html.create_style 'Level0', nil, 'B', 'F-SZ: 13'
	html.create_style 'Level1', nil, 'B', 'F-SZ: 12', 'K: black'
	html.create_style 'Level2', nil, 'F-SZ: 10'
	html.create_style 'Cell_Info', nil, 'text-align: center'
	html.create_style 'Button', nil
	html.create_style 'ButtonU', nil, 'BG: yellow'	

	#Creating the main table
	@xtable = Traductor::HTML_Xtable.new "XT0", html, wdlg
	hoptions = option_xtable
	txt_table = @xtable.format_table @ltable, hoptions
	
	#Creating the title
	title = T6[:T_BUTTON_CheckForUpdate]
	text = ""
	text += "<div cellspacing='0px' cellpadding='0px' class='Title'>#{title}</div>"
	text += "<div style='height: 6px'>&nbsp</div>"
	html.body_add text

	#Creating the information banner
	cbox = HTML.format_checkbox @@only_registered, T6[:UPD_TXT_OnlyRegistered], "OnlyRegistered", "Check", nil, T6[:UPD_TIP_OnlyRegistered]
	cfilter = format_html_filter
	text = "<div><table width='100%' cellspacing='0' cellpadding='0'><tr>"
	text += "<td width='60px' align='left' valign='bottom'>#{@xtable.html_expand_buttons}</td>"
	text += "<td width='60px' align='center' valign='bottom'>#{cfilter}</td>"
	text += "<td width='260px' align='left' valign='bottom' class='Check'>#{cbox}</td>"
	now_date = T6[:UPD_TXT_LastCheck] + ' ' + Traductor.nice_time_from_now(@@time_last_check)
	tip_date = Time.at(@@time_last_check).strftime "%d-%b-%y %H:%M"
	text += "<td ID='ID_TIME_LAST_CHECK' align='right' valign='bottom' class='Date' title='#{tip_date}'>#{now_date}</td>"
	text += "</tr></table></div>"
	html.body_add text
	
	#Inserting the main table
	html.body_add "<div>", txt_table, "</div>"
	
	#Creating the DONE button
	duration = Upgrade.duration_next_check
	sduration = (duration.round == duration) ? duration.round : sprintf("%.1f", duration)
	tip = tip_next_date
	fld = HTML.format_span T6[:UPD_TXT_NextCheck], "", "NextCheck", nil, tip
	fld += space2
	fld += HTML.format_input sduration, '3', "ID_NextCheck", "NextCheck", nil, tip
	fld += space2
	fld += HTML.format_span T6[:T_TXT_Days], "", "NextCheck", nil, tip
	
	butdone = HTML.format_button T6[:T_BUTTON_Done], id="ButtonDone", 'Button', nil
	butprint = HTML.format_button T6[:T_BUTTON_Print], id="ButtonPrint", 'Button', nil
	butupdate = HTML.format_button T6[:T_BUTTON_CheckForUpdate], id="#{@id_but_check}", 'ButtonU', nil
	html.body_add "<table class='T_NOPRINT_Style' width='99%' cellpadding='6px'><tr>"
	html.body_add "<td width='50%' align='left' valign='center'>", fld, "</td>"
	html.body_add "<td width='15%' align='left'>", butprint, "</td>"
	html.body_add "<td width='20%' align='center'>", butupdate, "</td>"
	html.body_add "<td align='right'>", butdone, "</td>"
	html.body_add "</tr></table>"
	
	#Creating the Checking div
	tcheck = HTML.safe_text T6[:UPD_MSG_CheckingInformation]
	wsite = "Sketchucation"
	@id_msg_div = "ID_msg_div"
	@id_msg_txt = "ID_msg_txt"
	html.body_add "<div id='ID_msg_div' style='display: none' class='T_NOPRINT_Style DivChecking'>"
	html.body_add "<table width='100%' height='100%'>"
	html.body_add "<tr><td style='vertical-align:middle'>#{tcheck}</td></tr>"
	html.body_add "<tr><td id='ID_msg_txt' class='WebSite' style='vertical-align:middle'>#{wsite}</td></tr>"
	html.body_add "</table></div>"
	
	#Returning the HTML object
	html	
end

#Compute the next date for check as a string
def tip_next_date
	next_date = Time.now.to_f + Upgrade.duration_next_check * 86400
	snext_date = Time.at(next_date).strftime "%d-%b-%y %H:%M"
	T6[:UPD_TIP_NextLaunchAfter, snext_date]
end

#Options for the Xtable
def option_xtable
	#Specification for columns and headers	
	txdate = T6[:T_TXT_Date]
	txversion = T6[:T_TXT_Version] 
	txreq = T6[:T_TXT_Required] 
	h1 = []
	h1.push({ :content => T6[:T_TXT_Plugin], :style => "Header", :rowspan => 2 })
	h1.push({ :content => T6[:UPD_HDR_InstalledLocally], :style => "Header", :colspan => 2 })
	h1.push({ :content => "", :style => "Header" })
	h1.push({ :content => "", :style => "Header", :rowspan => 2 })
	#h1.push({ :content => "", :style => "Header T_NOPRINT_Style2", :rowspan => 2 })
	h1.push({ :content => T6[:UPD_HDR_ReleaseOnWeb], :style => "Header", :colspan => 4 })
	h1.push({ :content => "", :style => "Header" })
	#h1.push({ :content => "", :style => "Header T_NOPRINT_Style2" })
	h1.push({ :content => "", :style => "Header" })
	h1.push({ :content => "", :style => "Header" })

	h2 = []
	h2.push({ :content => "", :style => "Header" })
	h2.push({ :content => txversion, :style => "HeaderS" })
	h2.push({ :content => txdate, :style => "HeaderS" })
	#h2.push({ :content => "", :style => "Header T_NOPRINT_Style2" })
	h2.push({ :content => "", :style => "Header" })
	h2.push({ :content => txversion, :style => "HeaderS" })
	h2.push({ :content => txdate, :style => "HeaderS" })
	#h2.push({ :content => "", :style => "HeaderS T_NOPRINT_Style2" })
	h2.push({ :content => "", :style => "HeaderS" })
	h2.push({ :content => txreq, :style => "HeaderS" })
	
	c = []
	c.push({ :style => "Col_Name", :width => @wid_col_name })
	c.push({ :style => "Col_Version", :width => @wid_col_version })
	c.push({ :style => "Col_Date", :width => @wid_col_date })
	#c.push({ :style => "Col_Info T_NOPRINT_Style2", :width => @wid_col_info })
	c.push({ :style => "Col_Info", :width => @wid_col_info })
	c.push({ :style => "Col_NewVersion", :width => @wid_col_version })
	c.push({ :style => "Col_NewDate", :width => @wid_col_date })
	#c.push({ :style => "Col_Download T_NOPRINT_Style2", :width => @wid_col_links })
	c.push({ :style => "Col_Download", :width => @wid_col_links })
	c.push({ :style => "Col_Required", :width => @wid_col_required })
	
	lv0 = { :style => "Level0" }
	lv1 = { :style => "Level1", :css_style => "border-top: 2px solid steelblue" }
	lv2 = { :style => "Level2" }
	
	#Returning the Options
	hoptions = { :columns => c, :headers => [h1, h2], :levels => [lv0, lv1, lv2],
				 :body_height => "#{@hgt_table}px" }	
end

def format_html_filter
	hgt = 16
	wid = 3 * hgt + 8
	attr = "width='33%' #{HTML.format_actions('onclick')}"
	hand = "cursor:pointer"
	tip_up = "title='#{T6[:UPD_TIP_UpToDate]}'"
	tip_need = "title='#{T6[:UPD_TIP_NeedUpgrade]}'"
	tip_def = "title='#{T6[:UPD_TIP_Default]}'"
	tip_obs = "title='#{T6[:UPD_TIP_Obsolete]}'"
	text = ""
	text += "<table width='#{wid}' height='#{hgt}' cellspacing='0' cellpadding='0' class='Filter' border><tr>"
	
	text += "<td id='ID_FILTER_UP' #{tip_up} #{attr} style='#{@style_up_to_date} ; #{hand}'>#{(@filter_up_to_date) ? "X" : "&nbsp;"}</td>"	
	text += "<td id='ID_FILTER_NEED' #{tip_need} #{attr} style='#{@style_need_upgrade} ; #{hand}'>#{(@filter_need_upgrade) ? "X" : "&nbsp;"}</td>"
	text += "<td id='ID_FILTER_OBS' #{tip_obs} #{attr} style='#{@style_obsolete} ; #{hand}'>#{(@filter_obsolete) ? "X" : "&nbsp;"}</td>"
	text += "<td id='ID_FILTER_DEF' #{tip_def} #{attr} style='#{@style_default} ; #{hand}'>#{(@filter_default) ? "X" : "&nbsp;"}</td>"
	text += "</tr></table>"
	text
end

#Call back for Statistics Dialog
def topdialog_callback(event, type, id, svalue)
	case event
	
	#Custom events
	when /Custom/i
		notify_update type, id, svalue
		
	#Command buttons
	when /onclick/i
		case id
		when /Info-(\d+)\Z/i
			open_link_info $1.to_i
		when /File-(\d+)\Z/i
			open_link_file $1.to_i if RUN_ON_MAC
		when 'ButtonDone'
			@wdlg.close
		when 'ButtonPrint'
			@wdlg.print
		when @id_but_check
			invoke_update
		when /ID_FILTER_DEF/i
			@filter_default = !@filter_default
			refresh_dialog_top
		when /ID_FILTER_NEED/i
			@filter_need_upgrade = !@filter_need_upgrade
			refresh_dialog_top
		when /ID_FILTER_OBS/i
			@filter_obsolete = !@filter_obsolete
			refresh_dialog_top
		when /ID_FILTER_UP/i
			@filter_up_to_date = !@filter_up_to_date
			refresh_dialog_top
		end

	when /onChange/i	#Escape and Return key
		case id
		when /OnlyRegistered/i
			@@only_registered = svalue
			refresh_dialog_top
		when /ID_NextCheck/i		
			svalue = MYDEFPARAM[:T_DEFAULT_DurationNextCheck].to_s unless svalue && svalue.strip.length > 0
			duration = @vtype_duration.validate(svalue)
			unless duration
				UI.messagebox T6[:T_ERROR_NotGoodValue, svalue] 
				return svalue
			end	
			Upgrade.duration_next_check duration
			store_next_check
			@wdlg.jscript_set_prop id, "title", tip_next_date
			return svalue
		end
		
	when /onKeyUp/i	#Escape and Return key
		@wdlg.close if svalue =~ /\A27\*/
		
	end
	true
end

def open_link_info(i)
	link = @lst_plugins[i][:link_info]
	UI.openURL link
end

def open_link_file(i)
	link = @lst_plugins[i][:link_file]
	UI.openURL link
end

#Refresh the last check date
def refresh_last_check
	now_date = T6[:UPD_TXT_LastCheck] + ' ' + Traductor.nice_time_from_now(@@time_last_check)
	@wdlg.jscript_set_prop "ID_TIME_LAST_CHECK", "innerHTML", now_date
end

#Specific scripts for Downloading information
def xfetch_scripts()
	text = %Q~

var $xt = null ;
if (window.XMLHttpRequest)
	$xt = new XMLHttpRequest() ;
else if (window.ActiveXObject) 
     $xt = new ActiveXObject('MSXML2.XMLHTTP.3.0');
	
var $requestTimer = 0 ;

function xfetch_get(fetch_id, url, website) {
	if (!$xt) return ;
	div = document.getElementById ('ID_msg_div') ;
	div_txt = document.getElementById ('ID_msg_txt') ;
	div_txt.innerHTML = website ;
	div.style.display = "" ;
	$xt.open ("GET", url, true) ;
	$requestTimer = setTimeout(function() { $xt.abort(); }, 10000) ;
 	if (!$xt) return ;
	$xt.onreadystatechange = function() { xfetch_checkData(fetch_id) } ;
	$xt.send(null) ;
}

function xfetch_checkData(fetch_id)
{
	state = $xt.readyState ;
	if (state != 4) {
		clearTimeout($requestTimer) ;
		return ;
	}
	
	if ($xt.status != 200) {
		$xt.abort () ;
		div.style.display = "none" ;
		SUCallback ("Action", "Custom", "Upgrade_Error", fetch_id, "") ;
		return ;
	}
	
	var text = $xt.responseText ;
	ltext = text.split ('!!=!!') ;
	for (var i = 1 ; i < ltext.length ; i += 2) {
		var s = ltext[i] ; 
		if ((!s.match (/\s*plugin/i)) && (!s.match (/\s*name/i))) continue ;
		s = s.replace (/href\="([^"]+)"[^>]*>/ig, "> $1 <") ;
		s = s.replace (/(<([^>]+)>)/ig, ""); 
		s = s.replace (/&amp;/ig, "&"); 
		if (s.length > 1000) continue ;
		SUCallback ("Action", "Custom", "Upgrade_Fetch", fetch_id, massage(s)) ;
	}	
	div.style.display = "none" ;	
	SUCallback ("Action", "Custom", "Upgrade_Finish", fetch_id, "") ;
}

~
	text
end

end	#class Upgrade

#----------------------------------------------------------------------------------------------------------
# Class UpgradeWarning: Warning dialog box 
#----------------------------------------------------------------------------------------------------------

class UpgradeWarning

@@warning_dialog = nil

def UpgradeWarning.show
	unique_key = "Traductor_Upgrade_DLG_WARNING"
	@@warning_dialog = UpgradeWarning.new(unique_key) #unless @@warning_dialog
	nil
end

#Create the warning dialog box
def initialize(unique_key)
	#Initialization
	@unique_key = unique_key
	@wid_img = 96
	@hgt_img = @wid_img
	@wid = @wid_img + 10
	@hgt = @hgt_img + 20
	if SU_MAJOR_VERSION == 7 && !RUN_ON_MAC
		@wid += 20
		@hgt += 14
	end	
	@wish_update = false
	
	#Creating the dialog box (with shadow for focus)
	@wdlg = create_dialog
	@wdlg_shadow = create_dialog true
	@wdlg.show
	@wdlg_shadow.show
	@wdlg_shadow.close
	nil
end

#Creating the web dialog box
def create_dialog(shadow=false)		
	wdlg = Traductor::Wdlg.new "", @unique_key, false
	wdlg.set_unique_key @unique_key
	wdlg.set_position 0, 0
	wdlg.no_auto_resize
	wdlg.set_size @wid, @hgt
	wdlg.set_background_color 'lightyellow'
	unless shadow
		wdlg.set_callback self.method('dialog_callback') unless shadow
		wdlg.set_on_close { on_close() }
	end	
	wdlg.set_html prepare_html
	wdlg
end

#Build the HTML for the dialog box
def prepare_html
	tip = T6[:T_BUTTON_CheckForUpdate]
	imgsrc = HTML.image_file MYPLUGIN.picture_get("Button_CheckForUpdate")
	
	text = ""
	#text += "<div width='100%' cellspacing='0px' cellpadding='2px'>"
	text += "<table width='100%' cellspacing='0px' cellpadding='0px' style='position:absolute; left:0px; top:0px' border><tr>"
	text += "<td height='#{@hgt_img}>"
	text += HTML.format_imagelink(imgsrc, @wid_img, @hgt_img, "ID_CHECK", "", nil, tip)
	text += "</td></tr></table>"
	
	html = HTML.new
	html.body_add text
	html
end

#Notification of closure
def on_close
	@@warning_dialog = nil
	terminate
end

#Call back for Statistics Dialog
def dialog_callback(event, type, id, svalue)
	case event
	when /onclick/i
		case id
		when /ID_CHECK/i
			@wish_update = true
			@wdlg.close
		end
	end	
end	

#Terminate with either delaying check by one day or calling the upgrade box
def terminate
	#Call the top Check for Update dialog
	if @wish_update
		Upgrade.top_dialog
		
	#Delay to next day
	else
		Upgrade.date_next_check(Time.now.to_f + 84600)
	end	
end

end	#class UpgradeWarning

end #Module Traductor

