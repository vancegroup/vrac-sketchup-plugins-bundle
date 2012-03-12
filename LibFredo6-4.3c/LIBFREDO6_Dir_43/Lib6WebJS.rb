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
# Name			:  Lib6WebJS.rb
# Original Date	:  10 Dec 2008 - version 3.0
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library to assist web dialog design (javascript part).
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

class Wdlg

def built_in_script_js()

	text = "<SCRIPT>"
	text += "var $run_on_mac = #{RUN_ON_MAC} ;"
	
	text += %Q~

// **********************************************************************
// Javascript code going along with LibFredo6
// **********************************************************************

// -----------------------------------------------------------------------------------------
// Global Variables
// -----------------------------------------------------------------------------------------
	var $id_field_focus ;
	var $border_default ;
	
// -----------------------------------------------------------------------------------------
// Window screen position and size
// -----------------------------------------------------------------------------------------

function browser_info() { 
	if (screen.availWidth) 
		txt = navigator.userAgent + ';;' + screen.availWidth + ';;' + screen.availHeight ; 
	else
		txt = navigator.userAgent + ';;' + screen.width + ';;' + screen.height ;
	SUCallback ("Action", "browser_info", "", "", massage(txt)) ;
}

function wposition() {
	if (window.screenX)
		txt = window.screenX + ';' + window.screenY + ';' + window.outerWidth + ';' + window.outerHeight ;
	else
		txt = (window.screenLeft-3) + ';' + (window.screenTop-22) + ';' + (document.documentElement.offsetWidth+6) + ';' + (document.documentElement.offsetHeight+25) ;
	SUCallback ("Action", "wposition", "", "", massage(txt)) ;
}	

// -----------------------------------------------------------------------------------------
// Tracking the mouse movements
// -----------------------------------------------------------------------------------------
function j6_mouse_position (e) { 
	$mouse_x = event.x + document.body.scrollLeft; 
	$mouse_y = event.y + document.body.scrollTop + 20;
} 	
	
// -----------------------------------------------------------------------------------------
// Tracking the mouse movements
// -----------------------------------------------------------------------------------------
$tt = null ;

function tooltip_show(ttId) {
	$tt = document.getElementById (ttId) ; 
	if ($tt == null) return ;
	setTimeout (function() { $tt.style.top = $mouse_y ; $tt.style.left = $mouse_x ; $tt.style.visibility = 'visible' }, 500) ; 
}

function tooltip_hide(ttId) { 
	if ($tt == null) return ;
	$tt.style.visibility = 'hidden' ; 
}

// -----------------------------------------------------------------------------------------
// Manage Javascript to Sketchup Ruby communications
// Implementation differes on Mac and on Windows
// -----------------------------------------------------------------------------------------
function SUCallback() {
	text = "" ;
	n = SUCallback.arguments.length - 1 ;
	fcallback = SUCallback.arguments[0].toString() ;
	for (i = 1 ; i < n ; i++) {
		s = SUCallback.arguments[i] ;
		if (s == null) s = "" ;
		text += s.toString() + ";;;;" ; 
	}
	text += SUCallback.arguments[n] ;
	
	$NUM_Callback += 1 ;
	msg = "!CbK!" + $NUM_Callback.toString() + "!ArG!" + fcallback + "!ArG!" + text ;
	if ($Asynchronous) {
		obj = document.getElementById ('HH_SCRIPT_HH') ;
		obj.value += msg ;
	}	
	window.location = 'skp:Unique@' + msg ;
}

function j6_clean_callback(nbsup) {
	obj = document.getElementById ('HH_SCRIPT_HH') ;
	lstnext = [] ;
	lstcur = obj.value.split ("!CbK!") ;
	n = lstcur.length ;
	for (i = 1 ; i < n ; i++) {
		ls = lstcur[i].split ("!ArG!") ;
		rank = parseInt (ls[0]) ;
		if (rank > nbsup) lstnext.push(lstcur[i]) ;
	}	
	obj.value = (lstnext.length == 0) ? "" : "!CbK!" + lstnext.join ("!CbK!") ;
}

function Action(event, obj) { 
	if (obj) SUCallback ("Action", event, obj.type, obj.id, massage(obj.value)) ; 
}

function Action_checkbox(event, obj) { 
	if (obj) {
		ck = (obj.checked) ? "true" : "false"
		SUCallback ("Action", "onclick", obj.type, obj.id, massage(ck)) ; 
	}	
}

function GetSet(val) { 
	SUCallback ("GetSet", massage(val.toString())) ; 
}
	
function massage(s) {
	if (s == null) return "" ;
	l = [] ;
	for (i=0 ; i < s.length ; i++) l.push(s.charCodeAt(i)) ;
	return l.join(';') ;
}

function j6_onload() {
	browser_info() ;
	a = document.body.clientHeight ;
	SUCallback ("Action", "wonload", "", "", massage(a.toString())) ; 
}

function j6_onunload() {
	wposition() ; 
	SUCallback ("Action", "wonunload") ; 
}

function j6_onblur() {
	wposition() ; 
}

// -----------------------------------------------------------------------------------------
// Manage Keyboard events
// -----------------------------------------------------------------------------------------

function CaptureKeyDown(e, event) { 
	CaptureKey(e, "onKeyDown") 
}

function CaptureKeyUp(e, event) {
	CaptureKey(e, "onKeyUp") 
}

function CaptureKey(e, event) {
	if (! e) e = window.event ;
	obj = (e.target) ? e.target : e.srcElement ;
	if (obj == null) return ;
	if ((obj.type == 'text') && (event == "onKeyDown") && (e.keyCode == 13)) {
		Action("onChange", obj) ;
	}
	else {
		kk = e.keyCode + '*' + e.shiftKey + '*' + e.ctrlKey + '*' + e.altKey ;
		SUCallback ("Action", event, obj.type, obj.id, massage(kk)) ;
	}	
	return true ;
}

// -----------------------------------------------------------------------------------------
// Geting and Setting Properties and Attributes to DOM objects
// -----------------------------------------------------------------------------------------

// Get node property
function j6_get_prop(id, sprop) {
	node = document.getElementById(id) ;
	a = "#nil#" ;
	if (node) p = eval("node." + sprop) ;
	if (p) a = p ;
	GetSet (a) ;
}

// Set node property
function j6_set_prop(id, sprop, sval) {
	node = document.getElementById(id) ;
	a = "#nil#" ;
	if (node) p = eval("node." + sprop + "= " + sval.toString()) ; 
	if (p) a = p ;
	GetSet (a) ;
}

// Get node attributes (custom or predefined)
function j6_get_attr(id, sattr) {
	node = document.getElementById(id) ;
	a = "#nil#" ;
	if (node) p = node.getAttribute (sattr) ; 
	if (p) a = p ;
	GetSet (a) ;
}

// Set node attributes (custom or predefined)
function j6_set_attr(id, sattr, svalue) {
	node = document.getElementById(id) ;
	a = "#nil#" ;
	if (node != null) p = node.getAttribute (sattr) ;
	if (p) a = p ;
	if (node) node.setAttribute (sattr, svalue) ;
	GetSet (a) ;
}

// Eval an expression in Javascript
function j6_eval(expression) {
	a = "#nil#" ;
	p = eval(expression) ; 
	if (p) a = p ;
	GetSet (a) ;
}

// -----------------------------------------------------------------------------------------
// Manage MouseWheel
// -----------------------------------------------------------------------------------------

function j6_mousewheel (e) {
	if (! e) e = window.event ;
	var wheelData = e.detail ? e.detail : e.wheelDelta ;
	if (wheelData < 0) s = "_down" ;
	else s = "_up" ;
	obj = (e.target) ? e.target : e.srcElement ;
	Action ("onMouseWheel" + s, obj) ;
}

// -----------------------------------------------------------------------------------------
// Manage Focus in a web dialog
// -----------------------------------------------------------------------------------------
	
//Script to manage Focus
function j6_track_focus (e) {
	if (! e) e = window.event ;
	obj = (e.target) ? e.target : e.srcElement ;
	if ($id_field_focus && (obj) && (obj.id != $id_field_focus)) 
		document.getElementById($id_field_focus).style.backgroundColor = $border_default ;
	if ((obj) && (obj.type) && (obj.id) && (obj.type.match(/text/i))) {
		$id_field_focus = obj.id ;
		$border_default = obj.style.backgroundColor ;
		obj.style.backgroundColor = '#FFFFBB' ;
	}	
	Action ("onFocus", obj) ;
}

function j6_put_focus (id, select) {
	node = document.getElementById (id) ;
	if (node) {
		node.focus() ;
		if (obj.type.match(/text/i)) {
			j6_scroll_at (id) ;
			if (select) node.select() ;
		}
	}	
}

function j6_get_focus () {
	a = "#nil#" ;
	if ($id_field_focus) a = $id_field_focus ;
	GetSet (a) ;
}
	
function j6_scroll_at (id) {
	if (!id) return ;
	var obj = document.getElementById(id) ;
	if (!obj) return ;
	var curleft = curtop = 0 ;
	var parent = obj.offsetParent ;
	while (parent) {
		curleft += parent.offsetLeft ; 
		curtop += parent.offsetTop ;
		//alert ('id = ' + id + ' curtop = ' + curtop + ' parent = ' + parent.tagName + ' pid = ' + parent.id + ' over = ' + parent.currentStyle.overflow) ;
		var scroll = parent.currentStyle.overflow ;
		var scrolly = parent.currentStyle.overflowY ;
		if ((scroll && (scroll.match (/scroll/i) || scroll.match (/auto/i))) || (scrolly && (scrolly.match (/scroll/i) || scrolly.match (/auto/i)))) {
			//alert ("scroll " + curtop + ' h = ' + parent.currentStyle.height) ;
			parent.scrollTop = curtop - parseInt(parent.currentStyle.height) / 2 ;
			break ;
		}	
		parent = parent.offsetParent ;
	}	
}
	
// -----------------------------------------------------------------------------------------
// Manage Ordered multi-lists
// -----------------------------------------------------------------------------------------

//Click on the check box
function ordered_changed(id, isel) {
	ls = [] ; target = -1 ; origin = -1 ; checked = false ;
	table = document.getElementById(id + "_Table____") ;
	idsel = id + "_Option____" + isel ;
	li = table.getElementsByTagName ("input") ;
	for (j = 0 ; j < li.length ; j++) {
		opt = li[j] ;
		if (opt.id == idsel) { origin = j ; optsel = opt ; checked = opt.checked ; }
		if (opt.checked) {
			ls.push(opt.value) ; 
			if (origin != j) target = j ; 
		}	
	}
	if ((checked) || (target == origin -1)) target += 1 ;
	if (target >= 0) table.tBodies[0].moveRow (origin, target) ;
	optsel.checked = checked ;
	if (checked) { ordered_focus(id, optsel, -1) ; ordered_highlight(id, isel) ; }
	else ordered_highlight(id, "") ;
	obj = document.getElementById(id) ;
	obj.value = ls.join (";;") ;
	Action("onChange", obj)
	return true ;
}	

//Select all rows
function ordered_select_all(id) {
	ls = [] ; i = 0 ;
	tb = document.getElementById(id + "_Table____") ;
	li = tb.getElementsByTagName ("input") ;
	for (j = 0 ; j < li.length ; j++) { opt = li[j] ; ls.push(opt.value) ; }	
	obj = document.getElementById(id) ;
	obj.value = ls.join (';;') ; 
	if (multi_change(id) > 0) Action("onChange", obj) ;
}

//move rows
function ordered_move_row(id, updown) {
	nsel = -1 ;
	obsel = document.getElementById (id + "_Selection____") ;
	isel = obsel.value
	if (isel == "") return ;
	table = document.getElementById(id + "_Table____") ;
	li = table.getElementsByTagName ("input") ;
	origin = -1 ;
	opt = document.getElementById (id + "_Option____" + isel) ;
	for (j = 0 ; j < li.length ; j++) { 
		if (opt == li[j]) origin = j ; 
		if ((nsel == -1) && (li[j].checked == false)) nsel = j - 1 ;
	}
	if (nsel == -1) nsel = li.length - 1 ;
	if (origin < 0) return ;
	if (updown == 'up') {
		target = origin - 1 ;
		if (target < 0) return ;
		sense = -1 ;
	}
	else {
		target = origin + 1 ;
		if (target > nsel) return ;
		sense = +1 ;
	}
	tbody = table.tBodies[0] ;
	tbody.moveRow (origin, target) ;
	opt.checked = true ;
	ordered_focus(id, opt, sense)
	li = table.getElementsByTagName ("input") ;
	ls = [] ;
	for (j = 0 ; j < li.length ; j++) {
		opt = li[j] ;
		if (opt.checked) ls.push (opt.value) ;	
	}
	obj = document.getElementById(id) ;
	obj.value = ls.join (";;") ;
	Action("onChange", obj)
}

//Select a row
function ordered_highlight(id, isel) {
	col = document.getElementById (id + "_Color____").value ;
	obcursel = document.getElementById (id + "_Selection____") ;
	icursel = obcursel.value
	if (icursel != "") {
		if (icursel == isel) return ;
		idcursel = id + "_tr____" + icursel ;
		tr = document.getElementById (idcursel) ;
		tr.style.backgroundColor = "" ;
		obcursel.value = "" ;
	}	
	if (isel == "") return ;
	idopt = id + "_Option____" + isel ;
	opt = document.getElementById (idopt) ;
	if (opt.checked == false) { opt.checked = true ; ordered_changed(id, isel) ; return ; }
	idsel = id + "_tr____" + isel ;
	tr = document.getElementById (idsel) ;
	tr.style.backgroundColor = col ;
	obcursel.value = isel ;
}

//Nice focus on a row
function ordered_focus(id, opt, sense) {
	table = document.getElementById(id + "_Table____") ;
	li = table.getElementsByTagName ("input") ;
	for (j = 0 ; j < li.length ; j++) { 
		if (opt == li[j]) origin = j ;
	}
	if (sense < 0) ; origin += sense * 2
	if ((origin >= 0) && (origin < li.length))  li[origin].focus() ;
}

//Update the fields based on a change in the value
function ordered_change(id) {
	table = document.getElementById(id + "_Table____") ;
	if (table == null) return multi_change(id) ;
	obj = document.getElementById(id) ;
	ls = obj.value.split (";;") ;
	n = 0 ; i = 0 ;
	while (opt = document.getElementById (id +"_Option____" + i)) { opt.checked = false ; i++ ; }
	ordered_highlight (id, "") ;
	tbody = table.tBodies[0] ;
	li = table.getElementsByTagName ("input") ;
	if (ls[0] == "") return ;
	for (i in ls) {
		k = 0 ;
		while (opt = document.getElementById (id +"_Option____" + k))
			{ if (opt.value == ls[i]) break ; k++ ;}
		if (opt == null) break ;	
		for (j = 0 ; j < li.length ; j++)
			if (li[j].id == opt.id) 
				{ tbody.moveRow (j, n) ; opt.checked = true ; n++ ; }
	}
	return 1 ;
}

function ordered_clear(id) {
	obj = document.getElementById(id) ;
	obj.value = "" ;
	ordered_highlight (id, "") ;
	if (multi_change(id) > 0) Action("onChange", obj) ;
}	

// -----------------------------------------------------------------------------------------
// Manage non-ordered multi-lists
// -----------------------------------------------------------------------------------------
	
function multi_changed(id) {
	i = 0 ; ls = [] ;
	while (opt = document.getElementById (id + "_Option____" + i)) {
		if (opt.checked) ls.push(opt.value) ; 
		i++ ; 
	}
	obj = document.getElementById(id) ;
	obj.value = ls.join (";;") ;
	Action("onChange", obj)
}

function multi_change(id) {
	obj = document.getElementById(id) ;
	ls = obj.value.split (";;") ;
	i = 0 ; n = 0 ;
	while (opt = document.getElementById (id +"_Option____" + i)) {
		checked = false ;
		for (j in ls) { if (ls[j] == opt.value) checked = true ; }
		if (opt.checked != checked) { opt.checked = checked ; n++ ; }
		i++ ; 
	}
	return n ;
}
function multi_clear(id) {
	obj = document.getElementById(id) ;
	obj.value = "" ;
	if (multi_change(id) > 0) Action("onChange", obj) ;
}	

function multi_select_all(id) {
	ls = [] ; i = 0 ;
	while (opt = document.getElementById (id +"_Option____" + i)) {
		ls.push(opt.value) ; 
		i++ ;
	}
	obj = document.getElementById(id) ;
	obj.value = ls.join (';;') ; 
	if (multi_change(id) > 0) Action("onChange", obj) ;
}

// -----------------------------------------------------------------------------------------
// Manage some table functions
// -----------------------------------------------------------------------------------------

function table_row_visibility(table_id, start, end, visible) {
	table = document.getElementById (table_id)
	rows = table.rows
	if (visible)
		status = "block"
	else
		status = "none"
		
	for (j = start ; j < end+1 ; j++) {
		rows[j].style.display = status
	}	
}


~

	text += "</SCRIPT>"

	return text
end	#method built_in_script_js

end	#class wdlg

end	#module Traductor
