=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Aug. 2008 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Traductor.rb
# Original Date	:  10 Sep 2008 - version 3.0
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library to assist language translation of Ruby Sketchup scripts.
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

#General constants
SU_MAJOR_VERSION_6 = (Sketchup.version.to_i > 5)	

module Traductor

LBT__DEF = Sketchup.find_support_file "LibTraductor.def", "Plugins"
load LBT__DEF if LBT__DEF

#Internal strings for validation messages - Can be TRanslated in more languages
VALID_ERROR = ["The following parameters are invalid",
               "|FR| Les param\ètres suivants ne sont pas valides"]
VALID_MIN = "%1 must be >= %2 |FR| %1 doit etre >= %2"
VALID_MAX = "%1 must be <= %2 |FR| %1 doit etre <= %2"
VALID_PATTERN = "%1 invalid: |FR| %1 invalide :"


def Traductor.s (astr, *args)

	#Computing the resulting string based on current language
	unless astr
		return "" unless args[0]
		astr = args[0]
	end	
	astr = [astr] unless astr.instance_of?(Array)
	val = astr[0]
	astr.each do |m|
		if m.strip =~ @@patlang
			val = $'
			break
		end
	end
	val =~ /\|\w\w\|/
	val = ($`) ? (($`.strip == "") ? $'.strip : $`.strip) : val.strip

	#removing the '~' for leading or trailing space preservation
	val = " " + $' if ((val =~ /\A~\s/) == 0)		# '~' followed by at least one space at beginning of string
	val = $` + " " if (val =~ /\s~\z/)				# '~' preceded by at least one space at end of string
		
	#Performing substitution
	for i in 0..args.length-1 do
		val = val.gsub "%" + (i+1).to_s, args[i].to_s
	end
	val
end

def Traductor.[] (astr, *args)
	Traductor.s astr, *args
end

def Traductor.translate(symb)
	Traductor.s symb, "#{symb}"
end

def Traductor.load_translation (hmod, pattern, curbinding, var_pattern="@msg_")
	hmod.constants.each do |a|
		Kernel::eval var_pattern + $' + '= Traductor.translate ' + a, curbinding if a =~ pattern
	end
end

def Traductor.log_error (msg, *args)
	puts Traductor[msg, *args]
end	

def Traductor.log_info (msg, *args)
	puts Traductor[msg, *args]
end	

#Conversion of string to respect special characters (from Windows dialog box or Web dialog box toward Ruby
def Traductor.encode_to_ruby(text)
	return text unless text.class == String
	begin
		return text.unpack("U*").pack("U*")
	rescue
		return text.unpack("C*").pack("U*")
	end
end 

#Format the display of the coordinates of a point
def Traductor.format_point(pt, braces='[]')
	brace1 = brace2 = ""
	brace1 = braces[0..0] if braces && braces[0..0]
	brace2 = braces[1..1] if braces && braces[1..1]
	s = brace1
	s += Sketchup.format_length(pt.x) + ','
	s += Sketchup.format_length(pt.y) + ','
	s += Sketchup.format_length(pt.z)
	s += brace2
	s
end

#Translate a string into an integer - Return nil if not a valid integer number
def Traductor.string_to_integer(s)
	(s && s.strip =~ /\A(\+|\-|\s*)(\s*)(\d+)\Z/) ? ($1.strip + $3).to_i : nil
end


#Translate a string into an integer value, accepting mathematical formulas applicable to integers
def Traductor.string_to_integer_formula(s)
	return nil if s == nil || s =~ /[^\s\+\-\*\%\/\%\(\)\d]/
	begin 
		eval "(#{s}) + 0"
	rescue Exception => detail
		nil
	end	
end

#Translate a string into a float, assumed to contain only a float - return nil if invalid
def Traductor.string_to_float(s)
	return nil unless s
	s = s.strip.upcase
	return nil if s == ''
	s = s.gsub(/,\d/) { |c| '.' + c[1..1] }
	return nil unless s =~ /\A(\+|\-|\s*)(\s*)(\d*)(\.?)(\d*)(e|E)?(\d*)\Z/
	r = $1.strip + $3
	[$4, $5, $6, $7].each { |p| r += p if p }
	r.to_f
end

#Translate a string to a float value, accepting mathematical forumal in the string - return nil of invalid
def Traductor.string_to_float_formula(s)
	return nil unless s
	s = s.strip.upcase
	lform = ["PI", "sin", "cos", "tan", "atan2", "sqrt", "log", "log10", "exp", "ceil", "floor", "round"]
	lform.each_with_index { |f, i| s = s.gsub(f.upcase, "_#{i}_") }
	s = s.gsub(/,\d/) { |c| '.' + c[1..1] }
	return nil if s =~ /[^\s\+\-\*\.\,eE_\%\/\%\(\)\d]/
	s = s.gsub(/(\A\.)\d+/) { |ss| '0' + ss }
	s = s.gsub(/(\s|\(|\+|\-)(\.)(\d+)/) { |ss| $1 + '0.' + $3 }
	s = s.gsub(',', '.').gsub(/(\d+)\.*(\d*)(e|E)?(\d*)/) { |ss| (ss =~ /\.|e|E/) ? ss : ss + '.0' }
	s = s.gsub(/_(\d+)\.\d_/) { |f| "Math::#{lform[$1.to_i]}" }
	s = s.gsub(/\s+\(/, '(')	
	begin 
		eval "0.0 + (#{s})"
	rescue Exception => detail
		nil
	end	
end

#Hold the decimal character supported by SU for length parsing
@@length_comma_or_dot = nil

#Translate a string into a Length
#The method accepts both comma and dot separator for numbers.
#return nil if invalid or the length in Inches as a Length class object)
def Traductor.string_to_length(s)
	return nil unless s
	s = s.strip
	return nil if s == ''
	
	#Checking whether Sketchup accepts the dot or the comma (tested only once)
	unless @@length_comma_or_dot
		begin
			"2.3".to_l
			@@length_comma_or_dot = '.'
		rescue Exception => detail
			@@length_comma_or_dot = ','
		end	
	end
	if @@length_comma_or_dot == '.'
		s = s.gsub(/\,\d/) { |c| '.' + c[1..1] }
	else	
		s = s.gsub(/\.\d/) { |c| ',' + c[1..1] }
	end
	
	#Notation with missing leading 0
	s = s.gsub(/(\A\.)\d+/) { |ss| '0' + ss }
	s = s.gsub(/(\s|\(|\+|\-)(\.)(\d+)/) { |ss| $1 + '0.' + $3 }
	
	#Simple float numbers or architectural dimensions
	unless s =~ /[^0-9.,\s'"\/]/
		begin
			return s.to_l
		rescue  Exception => detail
			return nil
		end	
	end	
	
	#Contains Units
	['cm', 'mm', 'km', 'm', 'inch', 'feet', 'mile'].each do |u|
		pat = Regexp.new '\s+' + u, Regexp::IGNORECASE
		s = s.gsub pat, '.' + u
		pat = Regexp.new '\d' + u, Regexp::IGNORECASE
		s = s.gsub(pat) { |c| c[0..0] + '.' + u }
	end
	
	#Evaluating the result
	s = s.gsub(/\,\d/) { |c| '.' + c[1..1] }
	begin
		return eval(s).inch
	rescue  Exception => detail
		return nil
	end	
end

#Translate a string into a Length, with formula
#The convention is that for * and /, factors are always in second position (i.e. 2cm * 4, NOT 4 * 2cm)
#Operators accepted are +, -, * and /
#return nil if invalid or the length in Inches as a Length class object)
def Traductor.string_to_length_formula(s)
	#Verifying the string and initialization
	return nil unless s
	s = s.strip
	return nil if s == ''
	s = '(' + s + ')'
	
	#Progressive parsing and transfer to string <sresult>
	plevel = []
	ffloat = false
	sresult = ""
	while s =~ /\(|\)|\*|\+|\-|\//
		sprev = $`.strip
		stoken = $&
		snext = $'
		
		#architectural units can use '/' as well
		if stoken == '/' && !ffloat && s =~ /\d+(\'+\s*|\s+)\d+\/\d+/
			stoken = nil
			sprev = $&
			snext = $'
		end
		
		#Evaluating the number, as flloat or as length
		if sprev != ''
			val = (ffloat) ? Traductor.string_to_float(sprev) : Traductor.string_to_length(sprev)
			return nil unless val
			sresult += val.to_f.to_s
		end	
		
		#Managing the parentheses and operators
		case stoken
		when '('
			plevel.push ffloat
		when ')'	
			return nil if plevel.length == 0		# No matching parenthesis
			ffloat = plevel.pop if stoken == ')'
		when '*', '/'
			ffloat = true
		when '+', '-'
			ffloat = false unless plevel.last
		end		
		sresult += stoken if stoken
		s = snext		
	end
	
	#Completing with parenthesis if missing
	sresult += ')' * plevel.length if plevel.length > 0
		
	#Evaluating the result as a length
	begin
		return eval(sresult).inch
	rescue Exception => detail
		return nil
	end	
end

#Translate a string into an angle in degree
#Angle is returned between ]-180, 180]
#Convention is suffix 'd' for degrees, 'g' for grade, '%' for slope, or, without suffix, tangent is value is <= 4, degree otherwise
#return nil if invalid
def Traductor.string_to_angle_degree(s, trick=true)
	return nil unless s
	s = s.strip.downcase
	
	#Replacing commas by decimal points
	s = s.gsub(/,\d/) { |ss| '.' + ss[1..1] }
	
	['d', '%', 'r', 'g', ''].each do |suffix|
		pat = Regexp.new '(\+{0,1}|-{0,1})(\d+)\.{0,1}(\d*)' + suffix
		next unless s =~ pat
		dec = ($3 != "") ? $3 : '0'
		sval = $1 + $2 + '.' + dec
		begin 
			val = eval "0.0 + (#{sval})"
		rescue Exception => detail
			return nil
		end	
		case suffix
		when 'd'
			deg = val
		when '%'
			deg = Math.atan2(val, 100).radians
		when 'g'
			deg = val * 0.9
		when 'r'
			deg = val.radians
		else
			if trick && val.abs <= 4.0 
				deg = Math.atan2(val, 1).radians
			else
				deg = val
			end
		end
		deg = deg.modulo(360.0)
		deg = deg - 360 if deg > 180	
		return deg
	end	
	nil
end

def Traductor.string_to_angle_degree_formula(s, trick=true)
	return nil unless s
	s = s.strip
	return nil if s == ""
	
	#Parsing the suffix
	suffix = s[-1..-1]
	if suffix =~ /[dgr\%]/i
		sval = s[0..-2]
		return nil if sval == ""
	else
		sval = s
	end
	
	#Conversion to float
	val = Traductor.string_to_float_formula(sval)
	return nil unless val
	
	case suffix
	when /d/i
		deg = val
	when '%'
		deg = Math.atan2(val, 100).radians
	when /g/i
		deg = val * 0.9
	when /r/i
		deg = val.radians
	else
		if trick && val.abs <= 4.0 
			deg = Math.atan2(val, 1).radians
		else
			deg = val
		end
	end
	deg = deg.modulo(360.0)
	deg = deg - 360 if deg > 180	
	deg
end

#Utility to format time
def Traductor.format_duration_hms(t)
	h = (t / 3600).floor
	m = ((t - h * 3600) / 60).floor
	s = t - 3600 * h - 60 * m
	"#{h}:" + sprintf('%02d', m) + ':' + sprintf('%02d', s.floor)
end

#Encode a menu from a tooltip
#If the tip contains a parenthese in last position, then it is assumed to contain the short cut
#if <tab> is passed, then the \t<tab> is appended
def Traductor.menu_from_tip(tip, tab=nil)
	mnu = tip
	if tip =~ /(.*)\((.*)\)\Z/
		mnu = $1
		tab = $2 unless tab
	end
	mnu = mnu + "\t" + tab if tab
	mnu
end

#Return the dot and comma equivalent sign for encoding numbers
@@dot = @@coma = nil
def Traductor.dot_comma(space=false)
	unless @@dot
		if Sketchup.parse_length("1,2cm")
			@@comma = (space) ? ' ' : '.'
			@@dot = ','
		else	
			@@comma = (space) ? ' ' : ','
			@@dot = '.'
		end	
	end	
	[@@dot, @@comma]
end

#Format a number with seperator every 3 digits	
def Traductor.format_number_by_3(v, decimals=0)
	srest = nil
	if v.is_a?(Integer) || decimals == 0
		smain = v.round.to_s
	else
		multiple = 10.0 ** decimals
		ia = (v * multiple).round / multiple
		smain, srest = sprintf("%3.#{decimals}f", ia).split '.'
	end
	
	dot, comma = Traductor.dot_comma
	s = smain.reverse
	new_s = ""
	for i in 0..s.length-1
		new_s += comma if i > 0 && i % 3 == 0
		new_s += s[i..i]
	end
	u = new_s.reverse
	u += dot + srest if srest
	u
end

#Format a string with a float value as short and meaningful as possible with <nsig> signative digits
def Traductor.nice_float(fval, nsig=3)
	return fval.to_s if fval == 0
	fround = fval.round
	return fround.to_s if fround == fval
	
	fval = fval.abs	
	vfloor = fval.floor
	n = vfloor.to_s.length
	return fround.to_s if n >= nsig
	nsig += 1 if vfloor == 0
	s = sprintf("%0.#{nsig-n}f", fval).sub(/0+\Z/, '')
	(s.to_f != fval) ? '~' + s : s
end

#-------------------------------------------------------------------------------------
# Encode a hash table as a string that can be later decoded as a hash
#-------------------------------------------------------------------------------------

def Traductor.hash_marshal(hash_array)
	return "" unless hash_array
	s = ""
	hash_array.each do |key, value|
		if (value.kind_of? Length)
			sval = "#{value.to_f}" + "~~~l"
		elsif (value.kind_of? Integer)	
			sval = value.to_s + "~~~i"
		elsif (value.kind_of? Float)	
			sval = "#{value.to_f}" + "~~~f"
		elsif (value.kind_of? Array)	
			sval = "#{value.join ';;;;'}" + "~~~a"
		else
			sval= value.to_s
		end	
		s += key.to_s + "\t\t" + sval.to_s + "\n\n"
	end
	s.chop.chop
end	

def Traductor.hash_unmarshal(str)
	return {} unless str
	hsh = {}
	keyvals = str.split /\n\n/
	keyvals.each do |item|
		kv = item.split /\t\t/
		if kv[1] =~ /~~~/
			case $'
			when 'l'
				kv[1] = ($`.to_f).inch
			when 'f'
				kv[1] = $`.to_f
			when 'i'
				kv[1] = $`.to_i
			when 'a'
				kv[1] = $`.split ';;;;'
			end		
		end
		hsh.store kv[0], kv[1]
	end	
	hsh
end	

def Traductor.hash_pretty(hash_array, leadstr="")
	return "" unless hash_array
	s = ""
	hash_array.each do |key, value|
		s += leadstr + key.to_s + " => " + value.to_s + "\n"
	end
	s.chop
end	

#Method to sort list by a sepcification given as a list <lspec>
#  - lspec = [3, 5] will swap the elements in 3rd and 5th position
#  - the list can be passed as a number or as a list of element which will be sorted
def Traductor.sort_specify(lspec, list=nil)
	nmax = (list.class == Array) ? list.length : list
	nmax = lspec.max unless nmax
	
	newls = []
	ibeg = 0
	for i in 0..nmax-1
		if lspec.include?(i)
			newls[i] = lspec[ibeg]
			ibeg += 1
		else
			newls[i] = i 
		end	
	end
	return newls unless list && list.class == Array
	
	newlist = []
	for i in 0..nmax-1
		newlist[i] = list[newls[i]]
	end
	newlist
end

#-----------------------------------------------------------------
# Define the utility class for managing Message boxes
#-----------------------------------------------------------------
def Traductor.messagebox(msg, button=MB_OK, title=nil)
	UI.messagebox Traductor[msg], button, Traductor[title]
end	

def Traductor.messagebox_arg(msg, button, title, *args)
	UI.messagebox Traductor[msg, *args], button, Traductor[title]
end	

#-----------------------------------------------------------------
# Define the utility class for managing Dialog boxes
#-----------------------------------------------------------------
class DialogBox
	DlgItem = Struct.new("DlgItem", :symb, :type, :label, :default, :vmin, :vmax,
									:enu_label, :enu_hash, :pattern, :msg_pattern, :flg_error) 

	attr_accessor :hash_results
	
def initialize(title, &validation_proc)
	@title = Traductor[title, "Parameters"]
	@validproc = validation_proc
	reset
end

def reset
	@list_items = []
	@prompts = []
	@values = []
	@hash_results = {}
end

def set_title title
	@title = Traductor[title, "Parameters"]
end

def set_validation_proc(&validation_proc)
	@validproc = validation_proc
end

def field_numeric(symb, label, default, vmin=nil, vmax=nil)
	
	#checking if item is new or already in the list
	item = self.get_item symb
	
	#setting up internal values
	unless (item)
		item = DlgItem.new()  
		item.symb = (symb) ? symb : @list_items.length
		item.type = 'I'
		item.vmin = nil
		item.vmax = nil	
		item.label = Traductor.s(label, symb) + '  '
		@list_items.push item
	end	
	item.label = Traductor.s(label, symb) + '  ' if label
	item.default = default if default
	item.vmin = vmin if vmin
	item.vmax = vmax if vmax
end

def field_string(symb, label, default="", pattern=nil, msg_pattern=nil)

	#checking if item is new or already in the list
	item = self.get_item symb
	
	#setting up internal values
	unless (item)
		item = DlgItem.new()  
		item.symb = (symb) ? symb : @list_items.length
		item.type = 'S'
		item.pattern = nil
		item.msg_pattern = nil
		item.label = Traductor.s(label, symb) + '  '
		@list_items.push item
	end	
	item.label = Traductor.s(label, symb) + '  ' if label
	item.default = Traductor[default] if default
	item.pattern = Regexp.new Traductor[pattern] if pattern
	item.msg_pattern = Traductor[msg_pattern] if msg_pattern
end

def field_enum(symb, label, default, enu_hash, list_order=nil)

	#checking if item is new or already in the list
	item = self.get_item symb
	
	#setting up internal values
	unless (item)
		item = DlgItem.new()  
		item.symb = (symb) ? symb : @list_items.length
		item.type = 'E'
		item.enu_hash = {}
		item.label = Traductor.s(label, symb) + '  '
		@list_items.push item
	end	
	item.label = Traductor.s(label, symb) + '  ' if label
	if (enu_hash)
		item.enu_hash = Hash.new(nil)
		enu_hash.each do |key, value| 
			item.enu_hash[key] = Traductor.s value, key
		end	
	end	
	item.default = item.enu_hash[default] if default
	if (list_order)
		l = []
		list_order.each { |code| l.push item.enu_hash[code] if item.enu_hash[code]}
	else
		l = item.enu_hash.values
	end	
	item.enu_label = l.join '|'
end

def get_item_property key, sprop
	@list_items.each do |item|
		if (item.symb.upcase == key.upcase)
			begin
				return Kernel::eval("item.#{sprop.downcase}")
			rescue
				return nil
			end
		end	
	end	
	nil
end

def show!(hash_values_and_results)
	show hash_values_and_results, hash_values_and_results
end

def show(hash_values = nil, hash_output = nil)	
	@hash_results.replace hash_values if (hash_values)
	@list_items.each {|item| item.flg_error = ""}
	
	#loop on Dialog box until valid or Cancel
	until (status = self.execute) != 0
	end
	
	#User pressed Cancel
	return false if (status < 0) 
	
	#returning the results as a Hash table
	hash_output.update hash_results if (hash_output)
	@hash_results

end

protected

def get_item key
	@list_items.each {|item| return item if item.symb == key}
	nil
end	

#-----------------------------------------------------------------------------
#Internal procedure to execute the dialog box. It returns
#   -1 if user pressed Cancel
#    0 if parameters are not valid
#    1 if parameters are valid
#-----------------------------------------------------------------------------

def execute
	prompts = []
	values = []
	enu = []
	
	#Assembling the paarmeters for the dialog boxes
	@list_items.each do |item|
		label = item.flg_error + item.label
		v = @hash_results[item.symb]
		case item.type
		when 'I'
			if (item.vmin && item.vmax)
				label += " [#{item.vmin} ... #{item.vmax}]  "
			elsif (item.vmin)
				label += " [#{item.vmin} ...]  "
			elsif (item.vmax)
				label += " [... #{item.vmax}]  "
			end
			val = (v) ? v : item.default
		when 'E'
			val = (v) ? item.enu_hash[v] : item.default
		when 'S'
			label += " [#{item.msg_pattern}]  " if (item.pattern && item.msg_pattern)
			val = (v) ? v : item.default
		end
		
		prompts.push label
		values.push val
		enu.push item.enu_label
	end

	#showing the dialog box
	values = inputbox(prompts, values, enu, @title)

	#user pressed Cancel
	return -1 unless values

	#Transfering the results into a hashtable
	i = 0
	@hash_results = {}
	@list_items.each do |item|
		#sval = Traductor.encode_to_ruby(values[i])
		#@hash_results[item.symb] = (item.type == 'E') ? item.enu_hash.index(sval) : sval
		@hash_results[item.symb] = (item.type == 'E') ? match_value(item.enu_hash, values[i]) : values[i]
		i += 1
	end	
		
	#Validation wit the user-defined validation proc - if the call does not work, we consider validation is OK
	if (@validproc)
		begin
			return (@validproc.call) ? 1 : (UI.beep ; 0)
		rescue
			return 1
		end
	end		
		
	#validation with built-in procedure
	merror = ""
	@list_items.each do |item|
		val = @hash_results[item.symb]
		item.flg_error = ""
		case item.type
		when 'I'
			if (item.vmin && val < item.vmin)
				merror += "  --  " + Traductor.s(VALID_MIN, item.label, item.vmin) + "\n"
				item.flg_error = "*"
			end	
			if (item.vmax && val > item.vmax)
				merror += "  --  " + Traductor.s(VALID_MAX, item.label, item.vmax) + "\n"
				item.flg_error = "*"
			end	
		when 'S'
			unless ((item.pattern == nil) or (val.to_s =~ item.pattern))
				merror += "  --  " + Traductor.s(VALID_PATTERN, item.label)
				merror += " (" + item.msg_pattern + ")\n" if item.msg_pattern
				item.flg_error = "*"
			end	
		end
		i += 1
	end	
	
	#Validation is OK
	return 1 if (merror == "")
	
	#There are errors - Showing the message
	merror = Traductor[VALID_ERROR] + "\n" + merror
	UI.beep
	UI.messagebox merror, MB_MULTILINE, @title
	return 0
end

#Comparison of strings. This is due to the fact that Windows and Ruby encode locales differently in strings
def match_value (hsh, value)
	vv = simplify_ascii value
	hsh.each { |key, v| return key if (simplify_ascii(v) == vv) }
	nil
end

def simplify_ascii(s)
	sres = ""
	s.each_byte { |c| sres << c if c < 128 }
	sres
end

end #Class DialogBox

#----------------------------------------------------------------------------------------------------------------------------
# Utility to manage key events on PC and Mac (onKeyDown and OnKeyUp for Tools)
#This function returns the equivalent key value on PC, whether typed on PC or on Mac
#----------------------------------------------------------------------------------------------------------------------------
def Traductor.platform_is_mac?
	(RUBY_PLATFORM =~ /darwin/i) ? true : false
end

def Traductor.check_key(key, flags, flgup)
	#on PC, just return the key
	return key unless Traductor.platform_is_mac?
		
	#Check differences on Mac (section should be completed)
	case key
		
	when 63272	#DEL key
		return 46
	when 127	#BACKSPACE key
		return 8
	end
	
	#Function keys
	if key >= 63236 && key <= 63247
		return 112 + key - 63236
	end
	
	#Numeric Keypad On
	if (flags == 2097408)
		case key
		when 48..57		#digit 0 to 9
			return 96 + key - 48
		when 42..47			#sign *, +, -, /
			return 106 + key - 42
		end	
	end
	
	#returning the  key when we did not find translation
	key
end

def Traductor.new_check_key(key, flags, flgup)		
	#Check differences on Mac (section should be completed)
	if RUN_ON_MAC
		if key == 63272	#DEL key
			return 46
		elsif key == 127	#BACKSPACE key
			return 8
		end
	end
	
	#Function keys
	if RUN_ON_MAC
		if key >= 63236 && key <= 63247
			k = 112 + key - 63236
			return "vk_F#{k}".intern
		end
	else
		if key >= 112 && key <= 123
			k = key - 111
			return "vk_F#{k}".intern
		end
	end
	
	#Arrows
	if RUN_ON_MAC
		case key
		when 63232
			return VK_UP
		when 63233
			return VK_DOWN
		when 63234
			return VK_LEFT
		when 63235
			return VK_RIGHT
		end
	end
	
	#Numeric Keypad On
	if RUN_ON_MAC
		if (flags == 2097408)
			case key
			when 48..57		#digit 0 to 9
				return 96 + key - 48
			when 42..47			#sign *, +, -, /
				return 106 + key - 42
			end	
		end
	end
	
	#returning the  key when we did not find translation
	key
end


#check if Shift key is down from flags
def Traductor.shift_mask?(flags)
	(flags & CONSTRAIN_MODIFIER_MASK == CONSTRAIN_MODIFIER_MASK)
end

#check if Ctrl  key is down from flags
def Traductor.ctrl_mask?(flags)
	(flags & COPY_MODIFIER_MASK == COPY_MODIFIER_MASK)
end

#check if Alt  key is down from flags
def Traductor.alt_mask?(flags)
	(flags & ALT_MODIFIER_MASK == ALT_MODIFIER_MASK)
end

#return the Plugin sub-directory of the Sketchup Plugins folder for the filename (usually __FILE__)
def Traductor.plugin_subdir(filename)
	filepath = File.expand_path filename
	l = filepath.split /\//
	jindex = -1
	for i in 0..l.length - 1
		if l[i] =~ /Plugins/i
			jindex = i
			break
		end
	end
	File.join l[(jindex+1)..-2]
end

#Return a constant from the Traductor package, passed either as a symbol or a string
def Traductor.own_constant(symb, default=nil)
	return default unless symb
	begin
		symb = symb.to_s.intern unless symb.class == Symbol
		return self.const_get(symb)
	rescue
		return default
	end	
end

#Return a nice text or date for a given time in seconds
def Traductor.nice_time(time=nil)
	time = Time.now unless time
	time.strftime "%d-%b-%y %H:%M:%S"
end

#Return a nice text or date for a given time in seconds
def Traductor.nice_time_from_now(time, strf_format=nil)
	return T6[:T_STR_NEVER] unless time
	
	strf_format = "%d-%b-%y %H:%M" unless strf_format
	adiff = (Time.now.to_f - time).round
	diff = adiff.abs
	if diff < 1
		return Time.at(time).strftime(strf_format)
	elsif diff < 60
		n = diff
		tx = (n < 2) ? T6[:T_TXT_Second] : T6[:T_TXT_Seconds]
	elsif diff < 3600
		n = diff / 60
		tx = (n < 2) ? T6[:T_TXT_Minute] : T6[:T_TXT_Minutes]
	elsif diff < 86400
		n = diff / 3600
		tx = (n < 2) ? T6[:T_TXT_Hour] : T6[:T_TXT_Hours]
	elsif diff < 172800
		n = nil
		tx = (adiff > 0) ? T6[:T_TXT_Yesterday] : T6[:T_TXT_Tomorrow]
		return tx
	elsif diff < 7 * 86400
		n = diff / 86400
		tx = (n < 2) ? T6[:T_TXT_Day] : T6[:T_TXT_Days]
	else	
		return Time.at(time).strftime(strf_format)
	end	
	
	(adiff > 0) ? T6[:T_TXT_Ago, "#{n} #{tx}"] : T6[:T_TXT_InFuture, "#{n} #{tx}"]
end
	
#Comprare to strings assumed to conatin version in the form like 3.2c
#Return -1, 0 or +1 like for <=>
def Traductor.compare_version(v1, v2)
	pat = /\D*\s*(\d+\.*\d*)\s*(\w*)\Z/i
	m1 = (v1 =~ pat) ? [$1.to_f, $2] : [v1.to_f, v1]
	m2 = (v2 =~ pat) ? [$1.to_f, $2] : [v2.to_f, v2]
	(m1[0] == m2[0]) ? m1[1] <=> m2[1] : m1[0] <=> m2[0]
end
	
def Traductor.text_model_or_selection
	(Sketchup.active_model.selection.empty?) ? T6[:T_TXT_WholeModel] : T6[:T_TXT_CurrentSelection]
end
	
#--------------------------------------------------------------------------------------------------------------
# Class ProgressionBar: progress bar in the Sketchup Status text area
#--------------------------------------------------------------------------------------------------------------

class ProgressionBar

#Initialization of progress bar
def initialize(nbelts, label)
	reset nbelts, label
end

#Increment the Progression Bar by <nb> steps
def countage(nb=1)
	@pb_progression += nb
	f = 100 * @pb_progression / @pb_nbelts
	percent = f.to_i
	if (percent != @pb_range)
		@pb_range = percent
		n = 1 + percent * @pb_rangemax / 100
		n1 = n.round - 1
		n2 = @pb_rangemax - n1
		if SU_MAJOR_VERSION >= 7
			s = ' |'
			if n2 == 0
				s += '-' * n1
			elsif n2 == 1
				s += '-' * (n1-1) + '>'
			else
				s += '-' * n1 + '>' + '-' * (n2-1)
			end	
		else
			s = ' ' + '|' * n1
			s += '-' * n2 if n2 > 0
		end
		new_text = s + '|  ' + @pb_label + " #{@pb_progression} / #{@pb_nbelts}"
		unless @cur_text && @cur_text == new_text
			Sketchup::set_status_text new_text
			@cur_text = new_text
		end	
	end	
	Sketchup.set_status_text @pb_label + " #{@pb_progression} / #{@pb_nbelts}", SB_VCB_LABEL
	Sketchup::set_status_text "#{@pb_range}%  -  #{sprintf "%4.2f", Time.now - @pb_time0} sec", SB_VCB_VALUE
end

def reset(nbelts=nil, label=nil)
	@pb_nbelts = nbelts if nbelts
	@pb_label = label if label
	@pb_progression = 0
	if SU_MAJOR_VERSION >= 7
		@pb_rangemax = 60
		@dash = '-'
	else	
		@pb_rangemax = 150
		@dash = '-'
	end	
	@base_text = '-' * @pb_rangemax
	@pb_range = 0
	@pb_time0 = Time.now	
	Sketchup.set_status_text ""
	Sketchup.set_status_text "", SB_VCB_LABEL
	Sketchup.set_status_text "", SB_VCB_VALUE
end

def set_label(label)
	@pb_label = label if label
end

end #class ProgressionBar

#--------------------------------------------------------------------------------------------------------------
# Class CommandFamily: for setting up menu /toolbar
#--------------------------------------------------------------------------------------------------------------			 				   

class CommandFamily

def initialize(subdir, su_menu, menu_name, toolbar_name, separator=false)
	@lst_subdir = (subdir.class == Array) ? subdir : [subdir]
	@su_menu = (su_menu.class == Sketchup::Menu) ? su_menu : UI.menu(su_menu)
	@menu_name = menu_name
	@toolbar_name = toolbar_name
	@separator = separator
	@lst_cmd = []
	
	@submenu = nil
	@tlb = nil
	@fresh = false
end

#Adding a command both in menu and toolbar
def add_command(title, tooltip, icon_name, nameconv=nil, ext=nil, &proc_cmd)
	#creating the command
	cmd = UI::Command.new(title) { proc_cmd.call }
	cmd.status_bar_text = tooltip
	
	#adding the submenu command
	menu = get_menu
	menu.add_item cmd
	@fresh = false
	
	#Finding the icons, based on naming convention
	return unless @toolbar_name && @toolbar_name.strip.length > 0
	return unless icon_name
	ext = ".png" unless ext
	nameconv = "" unless nameconv && nameconv.strip.length > 0
	
	iconpath = nameconv + icon_name + ext
	iconpath16 = nameconv + icon_name + "_16" + ext
	iconpath24 = nameconv + icon_name + "_24" + ext
	
	#Finding the icons
	lsticons = get_icons icon_name, nameconv, ext
	icon16, icon24 = lsticons
	
	#Assigning the icons
	if (icon16 && icon24)
		cmd.tooltip = tooltip
		cmd.small_icon = icon16 if icon16
		cmd.large_icon = icon24 if icon24
		@lst_cmd.push cmd
	end	
	return cmd
end

#Find icon in a directory
def find_icons(dir, iconpath, iconpath16, iconpath24)
	#Checking the directory
	path = Traductor.test_directory dir
	return nil unless path
	
	#Find the icon files
	icon = File.join path, iconpath
	icon = nil unless FileTest.exist?(icon)
	icon16 = File.join path, iconpath16
	icon16 = nil unless FileTest.exist?(icon16)
	icon24 = File.join path, iconpath24
	icon24 = nil unless FileTest.exist?(icon24)
	
	return nil unless icon || icon16 || icon24
	
	#Finding default for icons in case not all exist
	icon16 = icon unless icon16
	icon16 = icon24 unless icon16
	icon24 = icon unless icon24
	icon24 = icon16 unless icon24
	
	[icon16, icon24]
end

#Add a submenu
def add_submenu(text)
	menu = get_menu
	@fresh = false
	menu.add_submenu text
end

#Getting (and Creating it on the fly) the toolbar
def get_toolbar
	return nil unless @toolbar_name && @toolbar_name.strip.length > 0
	unless @tlb
		@tlb = UI::Toolbar.new @toolbar_name
	end
	@tlb	
end

#Creating the submenu, if it does not exist
def get_menu
	unless @submenu
		@su_menu.add_separator if @separator.class == String && @separator =~ /M/i
		@submenu = (@menu_name) ? @su_menu.add_submenu(@menu_name) : @su_menu
		@fresh = true
	end	
	@submenu
end

#Adding Separator
def add_menu_separator
	menu = get_menu
	menu.add_separator if menu && @fresh == false
end

def add_toolbar_separator
	@lst_cmd.push nil
end

def show_toolbar
	return nil unless @toolbar_name && @toolbar_name.strip.length > 0 && @lst_cmd.length > 0
	if @lst_cmd.length > 0
		@tlb = UI::Toolbar.new @toolbar_name
		@tlb.add_separator if @separator.class == String && @separator =~ /T/i
		@lst_cmd.each do |cmd|
			if cmd
				@tlb.add_item cmd
			else
				@tlb.add_separator
			end	
		end
		@lst_cmd = []
	end	
	status = @tlb.get_last_state
	if status == 1
		@tlb.restore
	elsif status == -1	
		@tlb.show if @tlb
	end	
	@tlb
end
	
#Get the icons in 16 and 24 pixels	
def get_icons(icon_name, nameconv=nil, ext=nil)	
	return [] unless icon_name
	ext = ".png" unless ext
	nameconv = "" unless nameconv && nameconv.strip.length > 0
	
	iconpath = nameconv + icon_name + ext
	iconpath16 = nameconv + icon_name + "_16" + ext
	iconpath24 = nameconv + icon_name + "_24" + ext
	
	#Finding the icons
	icon16 = icon24 = nil
	lsticons = []
	@lst_subdir.each do |d|
		lsticons = find_icons d, iconpath, iconpath16, iconpath24
		if lsticons
			icon16 = lsticons[0]
			icon24 = lsticons[1]
			break
		end	
	end
	lsticons
end

def get_tlb
	@tlb
end

end #class CommandFamily

#--------------------------------------------------------------------------------------------------------------
# Some utility about Cursors
#--------------------------------------------------------------------------------------------------------------			 				   

class CursorFamily

def initialize(subdir, nameconv=nil, ext=nil)
	subdir = "IMAGES_Standard" unless subdir
	@lst_subdir = (subdir.class == Array) ? subdir : [subdir]
	@nameconv = (nameconv) ? nameconv.strip : ""
	@ext = (ext) ? ext.strip : ".png"
end

def create_cursor(cursorname, hotx=0, hoty=0)
	cursorfile = @nameconv + cursorname + @ext
	cursorpath = nil
	@lst_subdir.each do |d|
		path = Traductor.test_directory d
		next unless path
		cursorpath = File.join path, cursorfile
		return UI::create_cursor(cursorpath, hotx, hoty) if FileTest.exist?(cursorpath)
	end	
	0
end

def oldcreate_cursor(cursorname, hotx=0, hoty=0)
	cursorfile = @nameconv + cursorname + @ext
	cursorpath = nil
	@lst_subdir.each do |d|
		path = Traductor.test_directory d
		next unless path
		cursorpath = File.join path, cursorfile
		break if FileTest.exist?(cursorpath)
	end	
	(cursorpath) ? UI::create_cursor(cursorpath, hotx, hoty) : 0
end

end	#class CursorFamily

#-------------------------------------------------------------------------------
# Ruby tool registration
#-------------------------------------------------------------------------------

class Ruby

@@hsh_ruby = {}
@@hsh_tools = {}
@@file_tool = nil
@@tools_id = {}

#Register a ruby when launched
def Ruby.register_ruby(ruby)
	return unless ruby
	id = Sketchup.active_model.tools.active_tool_id
	return if id == 0
	@@hsh_ruby[id] = "Ruby: " + ruby
end

#Internal method: check the active ruby tool among registered Ruby
def Ruby.active_ruby(id=nil)
	model = Sketchup.active_model
	return unless model
	id = model.tools.active_tool_id unless id
	ruby = @@hsh_ruby[id]
	(ruby) ? ruby : "Ruby #{id}"
end

#Get name from id
def Ruby.name_from_id(id)
	@@hsh_ruby[id]
end

#Compute a clean tool name - part is related to a bug on Mac
def Ruby.clean_tool_name(tool_name, tool_id=nil)
	return "undefined" if tool_name.class != String || tool_name == "" || tool_name =~ /\Atool/i
	return Ruby.active_ruby(tool_id) if tool_name =~ /\ARubyTool/i
	tool_name = Ruby.correct_name tool_name, tool_id if RUN_ON_MAC
	tool_name = $1 if tool_name =~ /(.+)Tool\Z/i
	Ruby.nicer_name tool_name
end

#Translate some tool names to be clearer
def Ruby.nicer_name(tool_name)
	case tool_name
	when /SketchCS/i
		'Axes'
	when /Sketch/i
		'Line'
	when /Extrude/i
		'FollowMe'
	when /Poly/i
		'Polygon'
	else
		tool_name
	end
end

#Correct the name of the SU tools
#Due to bug in Active_tool_name on Mac (truncated by 4 first characters)
def Ruby.correct_name(tool_name, tool_id)
	Ruby.load_tool_from_file unless @@file_tool
	v = @@hsh_tools[tool_name]
	if v
		v2 = @@tools_id[tool_id]
		return v2 if v2
		tool_name = v
	else	
		@@tools_id[tool_id] = tool_name
	end
	tool_name
end

#Load the known tools from a file
def Ruby.load_tool_from_file
	@@file_tool = File.join MYPLUGIN.plugin_dir, "SUTools_list.txt" unless @@file_tool
	lines = (FileTest.exist? @@file_tool) ? IO.readlines(@@file_tool) : []
	lines.each do |line|
		s = line.strip
		next if s.length == 0
		@@hsh_tools[s[4..-1]] = s
	end	
	@@hsh_tools
end

#Run or stop the Spy tool for the tools
def Ruby.spy_tool(on)
	if on
		Ruby.load_tool_from_file
		ob = Sketchup.active_model.tools.add_observer self
	elsif @@file_tool
		Sketchup.active_model.tools.remove_observer self
		lst = @@hsh_tools.values.sort { |a, b| a <=> b }
		File.open(@@file_tool, 'w') { |f| f.puts lst.join("\n") }
		@@file_tool = nil
	end
end

#Notification of tool for registration
def self.onActiveToolChanged(tools, tool_name, tool_id)
	return unless tool_name && tool_name.length > 4
	key = tool_name[4..-1]
	@@hsh_tools[key] = tool_name
end


end	#Class Ruby

#--------------------------------------------------------------------------------------------------------------
# Class Chrono6: track time
#--------------------------------------------------------------------------------------------------------------			 				   

class Chrono6
attr_reader :total, :order
attr_writer :time
@@hsh = {}
@@order = 0

def Chrono6.start(title)
	krono = @@hsh[title]
	krono = @@hsh[title] = Chrono6.new unless krono
	krono.time = Time.now.to_f
	krono
end

def initialize
	@total = 0.0
	@order = 0
end

def stop
	@total += Time.now.to_f - @time
	@@order += 1
	@order = @@order
end

def Chrono6.print
	ls = []
	@@hsh.each { |key, val| ls.push [key, val.order, val.total] }
	ls.sort! { |a, b| a[1] <=> b[1] }
	puts "CHRONO ++++++++++++++++++++++++++"
	ls.each { |a| puts "#{a[0]} --> #{a[2]}" }
	puts "CHRONO ++++++++++++++++++++++++++"
end

def Chrono6.reset
	@@hsh = {}
end

end	#class Chrono6
	
#--------------------------------------------------------------------------------------------------------------
# Class Trace6: Log information for later display
#--------------------------------------------------------------------------------------------------------------			 				   

class Tracer6

def initialize
	@text = ""
end

def puts(text)
	@text += "\n" + text
end

def print
	Kernel::puts "TRACE ============================="
	Kernel::puts @text
	Kernel::puts "TRACE ============================="
end
	
end	#class Tracer6
	
end #Module Traductor

