=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Jan. 2011 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6XTable.rb
# Original Date	:  31 Jan 2011
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library to assist Javascript Extendable Table
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

T6[:TIP_XTable_ExpandAll] = "Expand All"
T6[:TIP_Xtable_ShrinkAll] = "Skrink All"
T6[:TIP_Xtable_ExpandAt] = "Expand / Skrink at level %1"
T6[:TIP_XTable_Expand] = "Expand (Shift+Click to Expand All below)"
T6[:TIP_XTable_Shrink] = "Skrink (Shift+Click to shrink All below)"

#--------------------------------------------------------------------------------------------------------------------------
# Expandable table
#--------------------------------------------------------------------------------------------------------------------------

class HTML_Xtable

def initialize(table_id, html, wdlg)
	@table_id = table_id
	@html = html
	@wdlg = wdlg
	build_default_options
	init_images
	@wdlg.register_xtable self, table_id
end

#Initialize image information
def init_images
	hsh = HTML_Xtable.images_information
	
	@img_plus = hsh[:img_plus]
	@img_minus = hsh[:img_minus]
	@tip_img_plus = hsh[:tip_img_plus]
	@tip_img_minus = hsh[:tip_img_minus]
	@img_plus_plus = hsh[:img_plus_plus]
	@img_minus_minus = hsh[:img_minus_minus]
end

#Return a hash table with information about XTable images
def HTML_Xtable.images_information
	img_plus = HTML.image_file MYPLUGIN.picture_get("Img_Xtable_plus")
	img_minus = HTML.image_file MYPLUGIN.picture_get("Img_Xtable_minus")
	tip_img_plus = T6[:TIP_XTable_Expand]
	tip_img_minus = T6[:TIP_XTable_Shrink]
	img_plus_plus = HTML.image_file MYPLUGIN.picture_get("Img_Xtable_plus_plus")
	img_minus_minus = HTML.image_file MYPLUGIN.picture_get("Img_Xtable_minus_minus")
	
	hsh = { :img_plus => img_plus, :img_minus => img_minus, :img_plus_plus => img_plus_plus, :img_minus_minus => img_minus_minus,
	        :tip_img_plus => tip_img_plus, :tip_img_minus => tip_img_minus }
	
	hsh
end

#Default options
def build_default_options
	@hoptions_def = { 
		:table_border_style => "",
		:body_height => '350px',
		:frame_border_style => "2px solid green" 	#border of the overall frame
	}
end

def parse_hargs(*hargs)
	hoptions = @hoptions_def.clone
	return hoptions unless hargs
	hargs.each do |hopt|
		hopt.each { |key, val| hoptions[key] = val } if hopt
	end
	hoptions
end

#Handle the events (update main table) and notify of clients
def notify_event(event, type, svalue)
	case type
	when /expand/i
		lval = svalue.split ';'
		lval.each do |info| 
			ilevel = info.to_i.abs
			sign = (info =~ /\+/) ? + 1 : -1
			@ltable[ilevel][0] = sign * @ltable[ilevel][0].abs
		end	
		@notify_proc.call @table_id, type, lval if @notify_proc
	end	
end

#Generate the HTML for the table
def format_table(ltable, *hargs)
	#Storage of specifications
	@ltable = ltable
	@hoptions = parse_hargs *hargs
	@notify_proc = @hoptions[:notify_proc]
	
	#Main Options
	lheaders = @hoptions[:headers]
	lfooters = @hoptions[:footers]
	frame_border_style = @hoptions[:frame_border_style]
	table_header_style = @hoptions[:table_header_style]
	table_footer_style = @hoptions[:table_footer_style]
	table_border_style = @hoptions[:table_border_style]
	main_div_height = @hoptions[:body_height]
	expand_buttons = @hoptions[:expand_buttons]
	
	#Initialization
	text = ""
	ntable = @ltable.length - 1
	pad_left = 16
	pad_right = 6
	pad_mid = 6
	extra_pad0 = (RUN_ON_MAC) ? 10 : 0
	cellpadding = 3

	#Styling for screen and printing
	text += "<style type='text/css' media='screen'>"
	text += ".XTABLE_DIV_Style {position: relative; height: #{main_div_height}; overflow-y: auto; overflow-x: hidden; }"
	text += "</style>"
	
	#Column width and style
	lcolumns = @hoptions[:columns]
	if lcolumns
		nbcol = lcolumns.length - 1
	else
		nbcol = @ltable[0].length - 2
		lcolumns = []
	end	
	lcol_width = lcolumns.collect { |a| w = a[:width] ; ((w) ? "width='#{w}'" : "") }
	lcol_style = lcolumns.collect { |a| w = a[:style] ; ((w) ? "class='#{w}'" : "") }
	
	#Padding within columns
	lpads = []
	lpads[0] = "style padding-left: #{pad_left}px ;'"
	for i in 1..nbcol-1
		lpads[i] = "style='padding-left: #{pad_mid}px ; padding-right: #{pad_mid}px ;'"
	end
	lpads[nbcol] = "style='padding-right: #{pad_right}px ;'"
	
	#Levels style
	llevels = @hoptions[:levels]
	if llevels
		llevel_style = llevels.collect { |a| w = a[:style] ; (w) ? "class='#{w}'" : ""}
		llevel_css_style = llevels.collect { |a| w = a[:css_style] ; (w) ? "style='#{w}'" : ""}
	else
		llevel_style = []
		llevel_css_style = []
	end	

	#Images
	wid_img = 16
	hgt_img = 9
	hsize = "height='#{hgt_img}' width='#{wid_img}' border='0'"
	attr = "style='cursor:pointer'"
	action = "onClick='XTable_expand_from_mouse(\"#{@table_id}\", %1) ;'"

	img_id = "#{@table_id}-img-%1"
	txt_plus = "<a #{attr} #{action}><img id='#{img_id}' title='#{@tip_img_plus}' src='#{@img_plus}' #{hsize}/></a>"
	txt_minus = "<a #{attr} #{action}><img id='#{img_id}' title='#{@tip_img_minus}' src='#{@img_minus}' #{hsize}/></a>"
	
	#Arrangements of colum
	txt_col = ""
	for j in 0..nbcol
		wid = lcol_width[j]
		wid = "" unless wid
		txt_col += "<COL #{wid}/>"
	end	
	
	#Expand buttons
	if expand_buttons
		hbut = html_expand_buttons()
		unless hbut.empty?
			text += "<div cellspacing='0' cellpadding='0'"
			text += hbut
			text += "</div>"
		end
	end
	
	#Master Div
	text += "<div width='100%' style='border: #{frame_border_style}; padding: 0px;'>"
	
	#Creating the fixed header
	if lheaders
		txt_header = build_header_footer 'head', nbcol, lheaders, lpads
		####text += "<div class='T_NOPRINT_Style' width='100%' style='border-bottom: #{frame_border_style};'>"
		text += "<div width='100%' style='border-bottom: #{frame_border_style};'>"
		text += "<table width='100%' cellspacing='0px', cellpadding='#{cellpadding}px' #{table_header_style}>"
		text += txt_col
		text += txt_header
		text += "</table></div>"
	end
	
	#General parameters of table
		
	#Main Table
	text += "<div width='100%' class='XTABLE_DIV_Style'>"
	text += "<table id='#{@table_id}' width='100%' cellspacing='0px' cellpadding='#{cellpadding}px' #{table_border_style}>"
	text += txt_col
	
	#Header for printing
	#####text += build_header_footer('head', nbcol, lheaders, lpads, frame_border_style) if lheaders
	text += "<tbody>"
	
	#Filling the table	
	levelprev = 0
	hidlevel = 100
	hspan = {}
	for i in 0..ntable
		a = @ltable[i]
		nlevel = a[0]
		level = nlevel.abs
		
		if nlevel < 0
			hidlevel = level if level < hidlevel
		else
			hidlevel = 100 if level <= hidlevel
		end
		
		tr_style = (llevel_style[level]) ? llevel_style[level] : ""
		hcss_style = (llevel_css_style[level]) ? llevel_css_style[level] : ""
		hhid = (level > hidlevel) ? "style='display: none'" : ""
		
		#Qualifying the row with level
		pad = pad_left * (level - 1)
		b = @ltable[i+1]
		if level != 0 && b && b[0].abs > level
			himg = (nlevel > 0) ? "#{txt_minus}" : "#{txt_plus}" 
			himg = himg.gsub('%1', "#{i}")
			hexp = "!1"
		else
			himg = ""
			hexp = ""
			pad += wid_img + extra_pad0
		end	
		
		text += "<tr #{tr_style} id='#{@table_id}-lev!#{nlevel}#{hexp}' #{hhid}>"
		
		#Filling the columns
		for j in 0..nbcol
			tx, tip, hspec = a[j+1]
			htip = (tip && tip.length > 0) ? "title='#{HTML.safe_text tip}'" : ""
			if tx && tx.length > 0
				txt = HTML.safe_text tx
			else	
				tx = "&nbsp;"
			end	
			hstyle = (lcol_style[j]) ? lcol_style[j] : ""
			hstyle += " style='border-right: 0px'" if j == nbcol
			span = (hspec) ? check_span(hspec, hspan, i, j, nbcol) : ""
			cus_style = custom_style hspec
			
			#Indientation of first cell in the row
			attr = "#{htip} #{hcss_style} #{hstyle}"
			attr = attr + " style='border-top: 0px' " if i == 0
			if j == 0
				param = HTML.merge_style_class span, cus_style, attr
				text += "<td #{param}><div style='padding-left: #{pad}px'>#{himg}#{tx}</div></td>" unless hspan["#{i}-#{j}"]
			else	
				param = HTML.merge_style_class span, cus_style, attr
				text += "<td #{param}><div #{lpads[j]}>#{tx}</div></td>" unless hspan["#{i}-#{j}"]
				param = HTML.merge_style_class cus_style, attr, "style='border-left: 0px'"
				text += "<td #{param}><div>&nbsp;</div></td>" if j == nbcol
			end	
		end
		text += "</tr>"
	end
	
	text += "</tbody>"
	
	#Footer for printing
	####text += build_header_footer('foot', nbcol, lfooters, lpads, frame_border_style) if lfooters
	
	text += "</table></div>"
	
	#Creating the fixed footer
	if lfooters
		txt_footer = build_header_footer 'head', nbcol, lfooters, lpads
		####text += "<div class='T_NOPRINT_Style' width='100%' style='border-top: #{frame_border_style};'>"
		text += "<div width='100%' style='border-top: #{frame_border_style};'>"
		text += "<table width='100%' cellspacing='0px', cellpadding='#{cellpadding}px' #{table_footer_style}>"
		text += txt_col
		text += txt_footer
		text += "</table></div>"
	end
	
	text += "</div>"
	text
end

#Compute the custom style and other attributes from spec
def custom_style(hspec)
	return "" unless hspec 
	bstyle = hspec[:style]
	text = ""	
	text += "style='#{bstyle}'" if bstyle
	bclass = hspec[:class]
	text += " class='#{bclass}'" if bclass
	text
end

#Build the header and footer rows
#Tag is either 'head' or 'foot'
def build_header_footer(tag, nbcol, llval, lpads, frame_border_style=nil)
	is_header = (tag == 'head')
	if frame_border_style
		dbot = (is_header) ? 'bottom' : 'top'
		topbot = "style='border-#{dbot}: #{frame_border_style}'"
		tclass = "class='T_Repeat_#{tag}er T_NOSCREEN_Style'"
	else
		topbot = ""
		tclass = "style='display: table-#{tag}er-group ;'"
		tclass = ""
	end	
	
	#Header or footer (thead or tfoot) tag
	text = ""
	text += "<t#{tag} #{tclass}>"
	
	#Managing multiple rows
	llval = [llval] unless llval[0].class == Array
	
	hspan = {}
	nrow = llval.length-1
	for irow in 0..nrow
		lval = llval[irow]
		text += "<tr>"
		for j in 0..nbcol
			hspec = lval[j]
			tx, htip, hstyle, attr = header_text_tip_class hspec
			span = check_span(hspec, hspan, irow, j, nbcol)
			rowspan = (hspec) ? hspec[:rowspan] : nil
			if topbot != "" && ((!is_header && irow == 0) || (is_header && (irow == nrow || (rowspan && (irow + rowspan) >= nrow))))
				hstyle += " #{topbot}"
			end	
			hstyle += " style='border-right: 0 ;'" if j == nbcol
			unless hspan["#{irow}-#{j}"]
				text += "<td #{attr} #{span} #{htip} #{hstyle}><div #{lpads[j]}>#{tx}</div></td>"
			end	
			text += "<td rowspan='#{nrow+1}' #{htip} #{hstyle} #{topbot} style='border-left: 0'>&nbsp;</td>" if irow == 0 && j == nbcol
		end
		text += "</tr>"
	end	
	
	#Closing tag
	text += "</t#{tag}>"
	
	text
end

def check_span(hspec, hspan, irow, icol, nbcol)
	return "" unless hspec
	span = ""
	colspan = hspec[:colspan]
	if colspan
		span += " colspan='#{colspan}'"
		for k in 1..colspan-1
			hspan["#{irow}-#{icol+k}"] = true
		end	
		span += " style='border-right: 0'" if (icol + colspan - 1) == nbcol
	end	
	rowspan = hspec[:rowspan]
	if rowspan
		span += " rowspan='#{rowspan}'"
		for k in 1..rowspan-1
			hspan["#{irow+k}-#{icol}"] = true
		end	
	end	
	span
end

#Build the parameters for the headers
def header_text_tip_class(hspec)
	return ["", "", "", ""] unless hspec
	if hspec
		attr = ""
		tx = hspec[:content]
		tip = hspec[:tip]		
		style = hspec[:style]
		tx = "&nbsp;" unless tx && tx.length > 0
		htip = (tip && tip.length > 0) ? "title='#{HTML.safe_text tip}'" : ""
		hstyle = (style) ? "class='#{style}'" : ""
	else
		tx = "&nbsp;"
		htip = hstyle = attr = ""
	end
	[tx, htip, hstyle, attr]
end

def html_expand_buttons(range=nil)
	#Compute max level
	level_max = 0
	@ltable.each { |a| lev = a[0].abs ; level_max = lev if lev > level_max }
	return "" if level_max <= 1
		
	#List of levels
	if range == nil
		range = 1..level_max
	elsif range.class == Integer
		range = 1..([range, level_max].min)
	elsif range.class != Array || range.class != Range
		return ""
	end	
	
	# Generating the HTML
	tbstyle = "style='border: 1px solid gray ; border-collapse: collapse'"
	txcell = "cellspacing='0px' cellpadding='0px'"
	text = "<div #{txcell}><table class='T_NOPRINT_Style' #{tbstyle} #{txcell}><tr>"
	cursor = "style='cursor:pointer'"
	font = "style='font-size: 10pt ; font-weight: bold ; color: blue'"
	for i in range
		next if i > level_max
		action = "onclick='XTable_expand_at_level(\"#{@table_id}\", #{i})'"
		if i == 1
			tip = T6[:TIP_Xtable_ShrinkAll]
			content = "<a #{action} #{cursor}><img src='#{@img_minus_minus}' height='10px' width='12px' border='0'/></a>"
		elsif i == level_max
			tip = T6[:TIP_XTable_ExpandAll]
			content = "<a #{action} #{cursor}><img src='#{@img_plus_plus}' height='10px' width='12px' border='0'/></a>"
		else
			tip = T6[:TIP_Xtable_ExpandAt, i]
			content = "<span #{action} #{cursor} #{font}> #{i}</span>"
		end	
		text += "<td width='16px' #{tbstyle} align='center' title='#{HTML.safe_text tip}'>#{content}</td>"
	end
	text += "</tr></table></div>"
	
	text
end

def cell_get_prop(irow, icol, prop)
	expr = "document.getElementById('#{@table_id}').tBodies[0].rows[#{irow}].cells[#{icol}].#{prop}"
	@wdlg.jscript_eval "#{expr}"
end

def cell_set_prop(irow, icol, prop, val)
	val = "'#{val}'" if val.class == String
	expr = "document.getElementById('#{@table_id}').tBodies[0].rows[#{irow}].cells[#{icol}].#{prop} = #{val} ;"
	@wdlg.jscript_eval "#{expr}"
end

#------------------------------------------------------------------------------------------
# JAVASCRIPT part
#------------------------------------------------------------------------------------------

#Specific scripts for XTable
def HTML_Xtable.special_scripts(html)

#Image information
	hsh = HTML_Xtable.images_information	
	img_plus = hsh[:img_plus]
	img_minus = hsh[:img_minus]
	tip_img_plus = hsh[:tip_img_plus]
	tip_img_minus = hsh[:tip_img_minus]

#Main functions for Expand and Shrink
	text = %Q~

function XTable_expand_from_mouse(table_id, irow) { 
	e = window.event ;
	var pict = (e.target) ? e.target : e.srcElement ;
	var shift = e.shiftKey ;
	XTable_shrink_expand(table_id, irow, shift) ;
}

function XTable_shrink_expand(table_id, irow, all) { 
	var lchange = [] ;
	table = document.getElementById (table_id) ;
	var rows = table.tBodies[0].rows ;
	nrows = rows.length ;
	var toprow = rows[irow] ;
	nlevel = -parseInt(toprow.id.split('!')[1]) ;
	XTable_show_hide_img (table_id, rows, irow, nlevel, lchange) ;
	
	level = Math.abs(nlevel) ;
	var hidshow = new Array ;
	hidshow[level] = nlevel ;
	for (var i = irow+1 ; i < nrows ; i++) {
		if (XTable_process_expand(table_id, rows, i, nlevel, hidshow, all, lchange)) break ;
	}
	SUCallback ("Action", "XTABLE", "Expand", table_id, massage(lchange.join(';'))) ; 
}

function XTable_expand_at_level(table_id, level) { 
	var lchange = [] ;
	table = document.getElementById (table_id) ;
	var rows = table.tBodies[0].rows ;
	nrows = rows.length ;

	for (var i = 0 ; i < nrows ; i++) {
		var row = rows[i] ;
		info = row.id.split('!') ;
		curlevel = parseInt(info[1]) ;
		acurlevel = Math.abs(curlevel) ;
		if (acurlevel > level) 
			newval = "none" ; 
		else
			newval = "" ; 
		if (acurlevel < level)
			nl = acurlevel ;
		else
			nl = -acurlevel ;
		XTable_show_hide_img (table_id, rows, i, nl, lchange) ;
		row.style.display = newval ;
	}
	
	SUCallback ("Action", "XTABLE", "Expand_at" + level, table_id, massage(lchange.join(';'))) ; 
}

function XTable_process_expand(table_id, rows, irow, nlevel, hidshow, all, lchange) { 
	level = Math.abs(nlevel) ;
	row = rows[irow] ;
	info = row.id.split('!') ;
	curlevel = parseInt(info[1]) ;
	if (curlevel == 0) return false ;
	acurlevel = Math.abs(curlevel) ;
	hierar = info[2] ;
	if (acurlevel <= level) return true ;
	hidshow[acurlevel] = curlevel ;
	if ((nlevel < 0) || ((hidshow[acurlevel-1] < 0) && (!all)))
		newval = "none" ;
	else
		newval = "" ;
	if ((all) && (hierar)) {
		nl = (newval == "") ? acurlevel : -acurlevel ;
		XTable_show_hide_img (table_id, rows, irow, nl, lchange) ;
	}	
	row.style.display = newval ;
	return false ;
}

function XTable_show_hide_img(table_id, rows, irow, nlevel, lchange) { 
	pict = document.getElementById (table_id + '-img-' + irow) ;
	if (!pict) return ;
	var row = rows[irow] ;
	if (nlevel < 0)
		{ Toggle_plus(pict) ; c = '-' ; }
	else
		{ Toggle_minus(pict) ; c = '+' ; }
	lchange.push (c + irow.toString()) ;
	row.id = table_id + '!' + nlevel.toString() + '!1'  ;
}

~

	#Toggle buttons
	text += "function Toggle_plus(pict) { pict.src = '#{img_plus}' ; pict.title = '#{tip_img_plus}' ; }"
	text += "function Toggle_minus(pict) { pict.src = '#{img_minus}' ; pict.title = '#{tip_img_minus}' ;  }"
	
	html.script_add text
end

end	#class HTML_Xtable

end #Module Traductor
