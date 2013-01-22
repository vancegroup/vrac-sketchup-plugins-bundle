=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed November 2012 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Error.rb
# Original Date	:  25 Nov 2012
# Description	:  Methods for Error handling
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

T6[:T_TIT_RubyError] = "Ruby Error"
T6[:T_MSG_RubyError] = "An error occured in %1"	

#--------------------------------------------------------------------------------------------------------------
# Ruby Error parsing
#--------------------------------------------------------------------------------------------------------------			 				   

def Traductor.ruby_error_backtrace_array(e)
	lst_backtrace = []
	e.backtrace.each do |s|
		if s =~ /(\d+):in\s`(.*)'/
			line = $1
			function = $2
			file = $`
			lst_backtrace.push [file, line, function]
		end	
	end	
	lst_backtrace
end

def Traductor.ruby_error_message(e, for_html=false)
	msg = e.message
	return msg unless for_html
	msg.gsub!("&", "&ampersand;")
	msg.gsub!("<", "&lt;")
	msg.gsub!(">", "&gt;")
	msg
end

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Dialog box for Displaying Ruby Error
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

class RubyErrorDialog

@@top_dialog = nil

#Invoke the Dialog box with the Exception object <e>
def RubyErrorDialog.invoke(e, plugin_name, message, *hoptions)
	unique_key = "Traductor_RubyError_DLG"
	@@top_dialog = RubyErrorDialog.new(unique_key, e, plugin_name, message, *hoptions) unless Traductor::Wdlg.check_instance_displayed(unique_key)
end	

#initialization of the dialog box 
def initialize(unique_key, e, plugin_name, title_message, *hoptions)
	@e = e
	@title_message = title_message
	@plugin_name = plugin_name
	@hoptions = hoptions
	@unique_key = unique_key
	
	#Creating the dialog box
	@wdlg = create_dialog_top
end

#--------------------------------------------------------------------------------------------------------------
# Dialog box configuration
#--------------------------------------------------------------------------------------------------------------			 

#Create the dialog box
def create_dialog_top
	UI.beep
	init_dialog_top

	@wdlg = Traductor::Wdlg.new T6[:T_TIT_RubyError], @unique_key, false
	@wdlg.set_unique_key @unique_key
	@wdlg.set_size @wid_total, @hgt_total
	@wdlg.set_background_color 'pink'
	@wdlg.set_callback self.method('topdialog_callback') 
	@wdlg.set_on_close { on_close_top() }
	refresh_dialog_top
	@wdlg.show
	@wdlg
end

#Initialize parameters of the dialog box
def init_dialog_top
	#Parsing the error message and backtrace
	@msg_cause = Traductor.ruby_error_message(@e, true)	
	@lst_traces = Traductor.ruby_error_backtrace_array(@e)	

	#Column width and Heights
	nblines = [@lst_traces.length, 15].min
	@hgt_table = (nblines + 1) * 20 
	@wid_extra = (RUN_ON_MAC) ? 40 : 80
	@wid_col_file = 250
	@wid_col_line = 60
	@wid_col_method = 200
	@wid_total = @wid_col_file + @wid_col_line + @wid_col_method + @wid_extra
	@hgt_total = @hgt_table + 230
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
		when 'ButtonExport'
			export_as_txt
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
	bgcolor = 'BG: lightblue'
	space2 = "&nbsp;&nbsp;"
	
	html.create_style 'Title', nil, 'B', 'K: navy', 'F-SZ: 14', 'text-align: center'
	html.create_style 'TitleSmall', nil, 'B', 'K: black', 'F-SZ: 12', 'text-align: center'
	html.create_style 'TitleError', nil, 'B', 'I', 'K: red', 'F-SZ: 11', 'text-align: center', 'BG:white', 'border: 2px solid green'
	html.create_style 'Header', nil, 'B', 'F-SZ: 11', 'K: black', bgcolor, 'text-align: left'
	html.create_style 'Col_', nil, 'F-SZ: 11', 'text-align: left'
	html.create_style 'Col_File', 'Col_', 'B'
	html.create_style 'Col_Line', 'Col_', 'K: green'
	html.create_style 'Col_Method', 'Col_', 'B', 'K: darkblue'
	html.create_style 'Level0', nil, 'B', 'F-SZ: 12', 'K: black', 'BG: lightyellow'
	html.create_style 'Date', nil, 'F-SZ: 10', 'K: green'
	html.create_style 'Button', nil, 'F-SZ: 10'
	html.create_style 'ButtonU', 'Button', 'BG: yellow'	

	#Creating the main table
	@xtable = Traductor::HTML_Xtable.new "XT0", html, wdlg
	hoptions = option_xtable
	@ltable = prepare_xtable
	txt_table = @xtable.format_table @ltable, hoptions
	
	#Creating the title
	title = T6[:T_TIT_RubyError]
	text = ""
	ls = @title_message.split "\n"
	text += "<div cellspacing='0px' cellpadding='0px' class='Title'>#{T6[:T_MSG_RubyError, @plugin_name]}</div>"
	text += "<div style='height: 6px'>&nbsp</div>"
	text += "<div cellspacing='0px' cellpadding='0px' class='TitleSmall'>#{@title_message}</div>"
	text += "<div style='height: 6px'>&nbsp</div>"
	text += "<div cellspacing='0px' cellpadding='0px' width='100%'>"
	text += "<table width=100%><tr><td class='TitleError'>#{@msg_cause}</td></tr></table></div>"
	text += "<div style='height: 6px'>&nbsp</div>"
	html.body_add text
	
	#Inserting the main table
	html.body_add "<div>", txt_table, "</div>"
	
	#Putting a date for printing
	@now = Traductor.nice_time
	text = "<div cellspacing='0px' cellpadding='0px' class='Date'>#{@now}</div>"
	html.body_add text
	
	#Creating the dialog box button	
	butdone = HTML.format_button T6[:T_BUTTON_Done], id="ButtonDone", 'Button', nil
	butprint = HTML.format_button T6[:T_BUTTON_Print], id="ButtonPrint", 'Button', nil
	butexport = HTML.format_button T6[:T_BUTTON_ExportTXT], id="ButtonExport", 'ButtonU', nil
	html.body_add "<table class='T_NOPRINT_Style' width='99%' cellpadding='6px'><tr>"
	html.body_add "<td width='25%' align='left'>", butprint, "</td>"
	html.body_add "<td width='50%' align='center'>", butexport, "</td>"
	html.body_add "<td align='right'>", butdone, "</td>"
	html.body_add "</tr></table>"
		
	#Returning the HTML object
	html	
end

#Options for the Xtable
def option_xtable
	#Specification for columns and headers	
	h1 = []
	h1.push({ :content => T6[:T_TXT_RubyFile], :style => "Header" })
	h1.push({ :content => T6[:T_TXT_Line], :style => "Header" })
	h1.push({ :content => T6[:T_TXT_Method], :style => "Header" })
	
	c = []
	c.push({ :style => "Col_File", :width => @wid_col_file })
	c.push({ :style => "Col_Line", :width => @wid_col_line })
	c.push({ :style => "Col_Method", :width => @wid_col_method })
	
	lv0 = { :style => "Level0" }
	
	#Returning the Options
	hoptions = { :columns => c, :headers => h1, :levels => [lv0],
				 :body_height => "#{@hgt_table}px" }	
end

#Prepare the Xtable for Traces list
def prepare_xtable
	ltable = []
	@lst_traces.each do |a|
		file, line, method = a
		ltable.push [0, [File.basename(file), file], line, method]
	end	
	ltable
end

#Export the traces as txt
def export_as_txt
	#Asking for the export file
	@now = Traductor.nice_time unless @now
	name = "Ruby Error - #{@plugin_name} - #{@now}.txt"
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
		File.open(fpath, "w") do |f|
			f.puts "Date: #{@now}", "#{T6[:T_MSG_RubyError, @plugin_name]}", @title_message
			f.puts "\n#{@msg_cause}\n "
			@lst_traces.each do |a|
				file, line, method = a
				f.puts "#{File.basename(file)}: #{line} -- #{method}"
			end	
		end
		status = UI.messagebox T6[:MSG_GenerationExport, fpath] + "\n\n" + T6[:T_STR_DoYouWantOpenFile], MB_YESNO
		Traductor.openURL fpath if status == 6
	rescue
		UI.messagebox T6[:MSG_GenerationExport_Error, fpath]
	end
end

end	#class RubyErrorDialog


end	#End Module Traductor
