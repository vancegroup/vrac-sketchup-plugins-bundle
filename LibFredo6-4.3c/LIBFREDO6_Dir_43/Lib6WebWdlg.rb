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

#--------------------------------------------------------------------------------------------------------------
# Class Wdlg: Manage web dialogs
#--------------------------------------------------------------------------------------------------------------			 

class Wdlg

@@hsh_unique = {}

def initialize(title, hkey=nil, resizable=true, scrollable=false)
	@title = title
	@suwdlg = nil
	@scrollable = scrollable
	@resizable = resizable
	@auto_resize = true
	@xleft = 100
	@ytop = 200
	@width = 400
	@height = 300
	@manual_pos = RUN_ON_MAC
	@hkey = hkey
	@xleft, @ytop = Registry.wposition_load @hkey if @hkey && @manual_pos
	@proc_close = nil
	@nb_callback = -1
	@asynchronous = (RUN_ON_MAC) ? true : false
	@wbottom_margin = (RUN_ON_MAC) ? 30 : 55
	@wbottom_margin += 15 if SU_MAJOR_VERSION == 7
	@last_field_focus = nil
	@hsh_xtable = {}
end

#Associate a unique key to the web dialog so that only one instance of it is displayed at a given time
def set_unique_key(key)
	@unique_key = key
end

def no_auto_resize
	@auto_resize = false
end

#Associate a XTABLE to the dialog
def register_xtable(xtable, id)
	@hsh_xtable[id] = xtable
end

#Print the dlalog box
def print
	execute_script "window.print() ;"
end

def get_last_field_focus
	@last_field_focus
end

#Check if the web dialog box has already an instance visible, based on the unique key
#Return the instance if so or nil
def Wdlg.check_instance_displayed(key, bring_to_front=true)
	return nil unless key
	wdlg = @@hsh_unique[key]
	wdlg.bring_to_front if wdlg && bring_to_front
	wdlg
end

#Set or change the size of the dialog
def set_size(width, height, height_max=nil)
	@width = width
	@height = height
	@height_max = height_max
	@suwdlg.set_size @width, @height if @suwldg
end	

#Set the optional procedure to be called when the dialog box is closed
def set_on_close(&proc_cmd)
	@proc_close = proc_cmd
end

def set_position(xleft, ytop)
	@xleft = xleft
	@ytop = ytop
	@suwdlg.set_position @xleft, @ytop if @wldg	
end	

def visible?()
	(@suwdlg && @suwdlg.visible?) ? true : false
end

def bring_to_front()
	@suwdlg.bring_to_front if @suwdlg && @suwdlg.visible?
end

def set_background_color(color)
	@bgcolor = HTML.color color
end

def set_callback(hmethod)
	@hmethod = hmethod
end

def set_html_text(text_html)
	@text_html = text_html
	transfer_html
	#@suwdlg.set_html @text_html if @suwdlg
end

#specify the HTML structure to construct the page
def set_html(html)
	@text_html = assemble_html html
	transfer_html
end	
	
#Transfer HTML to web dialog. On Mac, need to use set_file as of Safari 5.0.6	
def transfer_html
	return unless @suwdlg && @text_html
	if RUN_ON_MAC
		delete_temp_file
		@tmpfile = File.join LibFredo6.tmpdir, "LibFredo_webdialog #{Time.now.to_f}.html"
		File.open(@tmpfile, "w") { |f| f.puts @text_html }
		@suwdlg.set_file @tmpfile if @suwdlg
	else
		@suwdlg.set_html @text_html if @suwdlg
	end	
end
	
def create_dialog
	@suwdlg = UI::WebDialog.new @title, @scrollable, @hkey, @xleft, @ytop, @width, @height, @resizable
	@suwdlg.set_size @width, @height
	@suwdlg.set_position @xleft, @ytop if @manual_pos
	@suwdlg.set_background_color @bgcolor if @bgcolor
	transfer_html
	@suwdlg.set_on_close { j_onclose }
	@suwdlg.add_action_callback("Unique") { |d, p| self.j_dispatch(p) }
	@closing = false
end

def show(&proc)
	create_dialog unless @suwdlg
	if RUN_ON_MAC
		@suwdlg.navigation_buttons_enabled = false if SU_MAJOR_VERSION >= 7
		@suwdlg.show_modal  {proc.call if proc} unless @suwdlg.visible?
		bring_to_front
	else	
		@suwdlg.show {proc.call if proc} unless @suwdlg.visible?
	end	
	@@hsh_unique[@unique_key] = self if @unique_key
end

def show_modal(&proc)
	create_dialog unless @suwdlg
	@suwdlg.show_modal {proc.call if proc} unless @suwdlg.visible?
	@@hsh_unique[@unique_key] = self if @unique_key
end

def close
	return unless @suwdlg
	@closing  = true
	@suwdlg.close if @suwdlg.visible?
end

#Set the initial focus for a web dialog box
def initial_focus(id, select=false)
	@inifocus = id
	@inisel = select
end

#Set the focus on a particular element
def put_focus(id, select=true)
	@suwdlg.execute_script "j6_put_focus ('#{id}', #{(select) ? true : false}) ;" if id
	id
end

#Get the element which has the focus
def get_focus()
	@suwdlg.execute_script "j6_get_focus() ;"
	@j_passback
end

#Get the element which has the focus
def scroll_at(id)
	@suwdlg.execute_script "j6_scroll_at('#{id}') ;"
end

def set_element_enabled(id, bflag=true)
	jscript_set_prop(id, 'disabled', !bflag)
end

#Set a value according to the type
def set_element_value(id, vtype, value, flagevent=false)
	return if value == nil
	type_elt = jscript_get_prop(id, 'type')
	if vtype.class == String
		stype = vtype
		vtype = nil
	elsif vtype.class == Traductor::VTYPE
		stype = vtype.type
	else
		stype = ''
		vtype = nil
	end
	
	case stype
	when 'B'
		prop = "checked"
		val = (value) ? true : false
		#return
	when 'I', 'F', 'L', 'K', 'S', 'D'
		prop = "value"
		val = value.to_s
	when 'H'
		prop = "value"
		#val = (vtype) ? KeyList.to_value(vtype.extra, value) : value
		val = (vtype) ? KeyList.to_key(vtype.extra, value) : value
	when 'M', 'O'
		prop = "value"
		val = (value.class == Array) ? value.join(';;') : value.to_s
	else
		prop = "innerHTML"
		val = value.to_s
	end	
	a = jscript_set_prop id, prop, val
	
	#Special treatment for custom controls
	case stype 
	when /O/i
		@suwdlg.execute_script "ordered_change(\"#{id}\")"
	when /M/i
		@suwdlg.execute_script "multi_change(\"#{id}\")"	
	end
	
	#notifying the event if needed
	@hmethod.call 'OnChange', type_elt, id, val if flagevent
end

#Get a DOM property of an HTML element by Id
def jscript_get_prop(id, prop)
	@suwdlg.execute_script "j6_get_prop ('#{id}', '#{prop}') ; "
	@j_passback
end

#Set a DOM property of an HTML element by Id
def jscript_set_prop(id, prop, svalue)
	svalue = "\"'#{svalue}'\"" if svalue.class == String
	@suwdlg.execute_script "j6_set_prop ('#{id}', '#{prop}', #{svalue}) ; "
	@j_passback
end

#Get the attribute of an HTML element by Id
def jscript_get_attr(id, sattr)
	@suwdlg.execute_script "j6_get_attr ('#{id}', '#{sattr}') ; "
	@j_passback
end

#Set a n attribute of an HTML element by Id
def jscript_set_attr(id, sattr, svalue)
	svalue = "\"'#{svalue}'\"" if svalue.class == String
	@suwdlg.execute_script "j6_set_attr ('#{id}', '#{sattr}', #{svalue}) ; "
	@j_passback
end

#Evaluate a Javascript expression and return the result
def jscript_eval(expression)
	@suwdlg.execute_script "j6_eval (\"#{expression}\") ; "
	@j_passback
end

#Execute a Javscript command
def execute_script(script)
	@suwdlg.execute_script script
end

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Private methods to manage HTML and Call Back functions from Jscript
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#Finalize the HTML String
def assemble_html(html)
	#Top declarations
	text = ""
	text += T_HTML_DOC_TYPE + '<HTML><HEAD>' + T_HTML_SCRIPT_TYPE + T_HTML_UTF_TYPE

	#Styles used in the document
	text += html.get_html_for_all_styles
	
	#Build-in Scripts
	text += built_in_scripts
	
	#XTable Scripts
	HTML_Xtable.special_scripts html if @hsh_xtable.length > 0
	
	#Custom Scripts
	scripts = html.get_scripts
	text += "<SCRIPT>#{scripts}</SCRIPT>" unless scripts.empty?
	
	#Rest of the HEAD Section
	text += html.get_head
	text += "</HEAD>"
	
	#Body section and close of HTML page
	list_events = []
	list_events.push "onload='j6_onload() ;'"
	list_events.push "onunload='j6_onunload() ;'"
	list_events.push "onmousemove='j6_mouse_position() ;'"
	list_events.push "onkeydown='CaptureKeyDown() ;'"
	list_events.push "onkeyup='CaptureKeyUp() ;'"
	list_events.push "onfocus='j6_track_focus() ;'"
	list_events.push "onactivate='j6_track_focus() ;'"
	list_events.push "ondeactivate='j6_onblur() ;'"
	list_events.push "onblur='j6_onblur() ;'" #if RUN_ON_MAC
	list_events.push "onmousewheel='j6_mousewheel() ;'" 
	text += "<BODY #{list_events.join(' ')}>"
	
	#Add a space at the top for Mac
	if RUN_ON_MAC
		####text += "<br>" 
	end
	
	# Create a hidden field for tracking events on Mac
	if (@asynchronous)
		text += "<input id='HH_SCRIPT_HH' type='hidden' value=''></input>"
	end	
	
	# Inserting the Body part
	text += html.get_body
	
	#Ending the document
	text += "</BODY>"
	text += "</HTML>"
	
	text
end

#provide built-in scripting for the dialog boxes
def built_in_scripts
	text = ""

	text += "<SCRIPT>"
	text += "var $Asynchronous = #{@asynchronous} ;"
	text += "var $NUM_Callback = #{@nb_callback + 1} ;"
	text += "</SCRIPT>"

	text += built_in_script_js
	
	text
end

#Callback to get a values from a java script
def j_getset(p)
	p = decode_param(p.to_s)
	@j_passback = (p == "#nil#") ? nil : p
end

#Callback called on closing the dialog window
def j_onclose
	unless @closing
		@closing = true
	end	
	@proc_close.call if @proc_close
	@@hsh_unique.delete @unique_key if @unique_key
	delete_temp_file
end

def delete_temp_file
	File.unlink @tmpfile if @tmpfile
	@tmpfile = nil
end

def decode_param(s)
	return nil unless s
	l = s.split(';')
	ln = []
	l.each { |c| ln.push c.to_i }
	svalue = ln.pack("U*")
	svalue
end

#Unique callback dispatch method
def j_dispatch(p=nil)
	if @asynchronous
		val = @suwdlg.get_element_value "HH_SCRIPT_HH"
		val = p unless val && val != ""
	else
		val = p
	end	
	return unless val && val != ""
	lsv = val.split "!CbK!"
	lsv.each do |cbk|
		next if cbk == ""
		lcbk = cbk.split "!ArG!"
		cbk_index = lcbk[0].to_i
		next if (cbk_index <= @nb_callback)
		@nb_callback = cbk_index
		cbk_name = lcbk[1]
		cbk_content = lcbk[2]
		j_callback cbk_name, cbk_content
	end
	if @asynchronous
		@suwdlg.execute_script "j6_clean_callback(#{@nb_callback});"
	end	
end

def j_callback(cbk_name, cbk_content)	
	case cbk_name
	when /Action/i
		return j_action(cbk_content)
	when /GetSet/i
		return j_getset(cbk_content)
	end	
end

#Callback triggered when actions are executed in the web dialog
def j_action(param)
	return unless @hmethod	
	
	#getting the event, type and id of the control
	lsargs = param.split ';;;;'
	event = lsargs[0]
	type = lsargs[1]
	id = lsargs[2]
	svalue = decode_param(lsargs[3])
	onchange = false
	
	#Adjusting the event
	case event
	when /wonunload/i
	
	when /wonload/i
		h = svalue.to_i + @wbottom_margin
		@closing = false
		if @auto_resize && (h <= @height || (@height_max && h < @height_max))
			@suwdlg.set_size @width, h
			@suwdlg.set_position @xleft, @ytop if RUN_ON_MAC
		end
		put_focus(@inifocus, @inisel)
		@hmethod.call event, nil, nil, nil
		return
		
	when /onclick/i
		case type
		when /checkbox/i
			event = "OnChange"
			svalue = (svalue =~ /false/i) ? false : true
		end
		
	when /xtable/i
		xtable_forward_event event, type, id, svalue
		return
		
	when /onchange/i
		onchange = true

	when /onfocus/i		
		@last_field_focus = id if id && type =~ /text/i
			
	when /onkeydown/i

	when /onkeyup/i
	
	when /browser_info/
		store_browser_info svalue
	when /wposition/
		Registry.wposition_store @hkey, svalue if @hkey
	end		

	#calling back caller
	val = @hmethod.call event, type, id, svalue
	jscript_set_prop(id, "value", val) if onchange && val != nil
end

def xtable_forward_event(event, type, id, svalue)
	xtable = @hsh_xtable[id]
	xtable.notify_event event, type, svalue if xtable
end

#Enable or disable a button
def button_enable(id, flag=true)
	txflag = (flag) ? "" : "disabled"
	@suwdlg.execute_script "document.getElementById ('#{id}').disabled='#{txflag}'"
end

#Store the Broswer information into the Registry
def store_browser_info(param)
	ls = param.split ';;'
	user_agent, sw, sh = ls
	if user_agent =~ /MSIE\s(\d)/i
		browser = 'IE' + $1
	elsif user_agent =~ /MSIE/i
		browser = 'IE'
	elsif user_agent =~ /Safari/i
		browser = (user_agent =~ /version/i) ? browser = 'Safari3' : 'Safari2'
	elsif user_agent =~ /Mac/i
		browser = 'Safari3'
	else
		browser = ''
	end
	Registry.browser_info_store [browser, sw, sh].join(';')
end

#Retrieve browser information
def Wdlg.browser_info()
	param = Registry.browser_info_load 
	unless param
		view = Sketchup.active_model.active_view
		browser = (RUN_ON_MAC) ? "Safari" : "IE7"
		return [browser, view.vpwidth, view.vpheight]
	end
	browser, sw, sh = param
	[browser, sw.to_i, sh.to_i]	
end

end	#class Wdlg

#--------------------------------------------------------------------------------------------------------------
# Class WMsgBox: Utlities to manage Message boxbased on Web Dialog
#--------------------------------------------------------------------------------------------------------------			 

class WMsgBox

#Invoke a modal message box with all possibilities
def WMsgBox.call(message, type=nil, title=nil, lbuttons=["OK"], callback=nil, context=nil)
	wm = WMsgBox.new message, type, title, lbuttons, callback, context
	wm.invoke
end

#Create the class instance
def initialize(message, type=nil, title=nil, lbuttons=["OK"], callback=nil, context=nil)
	@type = type
	@title = title
	@title = "Message" unless @title
	@html_text = message
	@lbuttons = lbuttons
	@callback = callback
	@context = context
	@button_ok = -1
	@button_cancel = -1
end

def invoke
	parse_buttons
	@text_html = compute_html
	@suwdlg = Wdlg.new @title
	@suwdlg.set_size 500, 140, 300
	@suwdlg.set_position 200, 300
	transfer_html
	@suwdlg.set_background_color 'LightGrey'
	@suwdlg.set_on_close { onclose }
	@suwdlg.set_callback self.method('visual_callback') 
	@status = nil
	@suwdlg.show_modal
	unless @status
		@list_buttons.each_with_index do |lb, i|
			if lb[1] =~ /\^/
				@status = i
				break
			end
		end
		@status = 0 unless @status
	end	
	return @status
end

#Transfer HTML to web dialog. On Mac, need to use set_file as of Safari 5.0.6	
def transfer_html
	return unless @suwdlg && @text_html
	if RUN_ON_MAC
		delete_temp_file
		@tmpfile = File.join LibFredo6.tmpdir, "LibFredo_webdialog #{Time.now.to_f}.html"
		File.open(@tmpfile, "w") { |f| f.puts @text_html }
		@suwdlg.set_file @tmpfile if @suwdlg
	else
		@suwdlg.set_html @text_html if @suwdlg
	end	
end

#Finalize closing and delete temp file
def onclose
	File.unlink @tmpfile if @tmpfile
	@tmpfile = nil
end

def visual_callback(event, type, id, svalue)
	case event
	when /onclick/i
		if id =~ /ID__(\d*)/i
			@status = $1.to_i
			@suwdlg.close
		end	
	when /onkeydown/i
		lskey = svalue.split '*'
		case lskey[0].to_i
		when 13
			@status = @button_ok
		when 27
			@status = @button_cancel
		else
			return nil
		end
		@suwdlg.close	
	end
	
	return nil	
end

#Standard confirmation box for changes
#Return -1 to ignore changes, 0 to cancel and go back, +1 to save changes
def WMsgBox.confirm_changes(txtchanges=nil)
	html_text = T6[:T_WARNING_ActiveChange]
	html_text += "\n<b><span style='color: red ; text-align: center'>" + txtchanges + "</span></b>" if txtchanges
	html_text += "\n" + T6[:T_WARNING_WhatToDo]	
	lbuttons = [:T_BUTTON_Ignore, :T_BUTTON_DecideLater, '^', :T_BUTTON_GoBack, '~', :T_BUTTON_Save]
	title = T6[:T_STR_ConfirmChange]
	UI.beep
	status = WMsgBox.call html_text, nil, title,  T6[lbuttons]
	return ['I', 'L', 'B', 'S'][status]
end

private

def parse_buttons
	@list_buttons = []
	flag = ""
	@lbuttons.each do |b|
		next unless b
		b = b.to_s.strip
		if b =~ /\~\^|\^\~|\~|\^/
			flag += $&
			next
		end	
		@list_buttons.push [b, flag]
		flag = ""
	end	
	@list_buttons[0][1] = '~^' if @list_buttons.length == 1
end

def compute_html
	#initialization
	html = HTML.new
	
	#style used in the dialog box
	html.create_style 'CellImage', nil, 'align: center'
	html.create_style 'CellMessage', nil, 'align: left', 'F-SZ: 10'
	html.create_style 'Button', nil, 'K: black', 'F-SZ: 9'
	html.create_style 'ButtonDef', 'Button', 'border-width: 3px', 'B', 'border-color: green'
	html.create_style 'ButtonCxl', 'Button', 'I', 'B', 'border-width: 2px', 'B', 'border-color: lightpink'

	#formatting the text
	img = MYPLUGIN.picture_get "Button_Add.png"
	txt_img = HTML.format_imagelink img, 48, 48, nil, "CellImage"
	txt = ""
	txt += "<table cellpadding='0' width='100%'><tr>"
	txt += "<td width ='70px'>#{txt_img}</td>"
	txt += "<td><div>"
	txt += HTML.format_para @html_text, nil, 'CellMessage'
	txt += "</div></td></tr></table>"
	
	#formatting the buttons
	nb = @list_buttons.length - 1
	txt_wid = "width='#{(85 / (nb+1)).to_i}%'"
	txt += "<table width='100%'><tr><td width='15%'>&nbsp</td>"
	@list_buttons.each_with_index do |lb, i|
		just = 'center'
		style = "Button"
		if (nb != 0 && i == 0) 
			just = 'left'
		elsif (nb != 0 && i == nb)
			just = 'right'
		end
		if lb[1] =~ /\^/
			style = 'ButtonCxl'
			@button_cancel = i
		end	
		if lb[1] =~ /\~/
			style = 'ButtonDef'
			@button_ok = i
		end	
		txt += "<td #{txt_wid} align='#{just}'>"
		txt += HTML.format_button lb[0], id="ID__#{i}", style
		txt += "</td>"
	end
	txt += "</tr></table>"
	
	#Returning the HTML object
	html.body_add txt
	return html
end

end	#class WMsgBox

#--------------------------------------------------------------------------------------------------------------
# Class SysInfo: Utlities to get some information about the system
#--------------------------------------------------------------------------------------------------------------			 

class SysInfo
@@hsh_prop = nil
@@asynchronous = (RUN_ON_MAC) ? true : false	#For Mac asynchronous bug


def SysInfo.[](prop)
	return nil unless prop && prop.strip != ""
	SysInfo.init unless @@hsh_prop
	(@@hsh_prop) ? @@hsh_prop[prop.strip.upcase] : nil
end
	
def SysInfo.init
	return if @@hsh_prop
	text = ""
	text += T_HTML_DOC_TYPE + '<HTML><HEAD>' + T_HTML_SCRIPT_TYPE
	
	txt = %Q~
	function getinfo() {
		Transfer ("UserAgent", navigator.userAgent) ;
		Transfer ("Width", screen.width) ;
		Transfer ("Height", screen.height) ;
		Transfer ("AvailWidth", screen.availWidth) ;
		Transfer ("AvailHeight", screen.availHeight) ;
		Transfer ("AvailTop", screen.availTop) ;
		Transfer ("AvailLeft", screen.availLeft) ;
		Transfer ("ScreenLeft", window.screenTop) ;
		Transfer ("ScreenLeft", window.screenLeft) ;
	}	
	function Transfer(prop, val) {
		msg = '!!' + prop + ';;;;' + val
		obj = document.getElementById ('HH_SCRIPT_HH') ;
		obj.value += msg
		window.location = 'skp:SysInfo@' + msg ;
	}
	~
	
	text += "<SCRIPT>#{txt}</SCRIPT>"	
	text += "</HEAD><BODY onload='getinfo(); '>"
	text += "<input id='HH_SCRIPT_HH' type='hidden' value=''></input>"
	text += "</BODY></HTML>"
	
	unless @@hsh_prop
		@suwdlg = UI::WebDialog.new
		@suwdlg.set_size 10, 10
		@suwdlg.set_html text
		@suwdlg.add_action_callback("SysInfo") { |d, p| SysInfo.callback p }	
		if RUN_ON_MAC
			@suwdlg.show 
			@suwdlg.close
		else
			@suwdlg.show_modal {@suwdlg.close}
		end	
	end	
end

def SysInfo.callback(param)
	if @@asynchronous
		param = @suwdlg.get_element_value "HH_SCRIPT_HH"
	end
	lsv = param.split '!!'
	lsv.each do |p|
		next if p == ""
		SysInfo.store p
	end	
end

def SysInfo.store(p)
	ls = p.split(';;;;')
	code = ls[0]
	val = ls[1]
	
	begin
		case code
		when /userAgent/i
			key = "BROWSER"
			if val =~ /MSIE\s(\d)/i
				value = 'IE' + $1
			elsif val =~ /MSIE/i
				value = 'IE'
			elsif val =~ /Safari/i
				value = (val =~ /version/i) ? value = 'Safari3' : 'Safari2'
			elsif val =~ /Mac/i
				value = 'Safari3'
			else
				value = ''
			end
		else
			key = code
			value = val.to_i
		end
	rescue
		return
	end
	
	@@hsh_prop = {} unless @@hsh_prop
	@@hsh_prop[key] = value
end

end	#class SysInfo

end #Module Traductor
