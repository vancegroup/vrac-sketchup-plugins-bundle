#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Dec. 2007 by Fredo6

# This software is provided as an example of using the Ruby interface to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name		:   LibTraductor.rb
# Type		:  Script library (cannot be used used in standalone)
# Description	:   A utility library to assit language translation of Ruby Sketchup scripts.
# Menu Item	:   none
# Context Menu	:   none
# Usage		:   See Tutorial on Traductor
# Date		:   10 Dec 2007
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
#PC_OR_MAC = (RUBY_PLATFORM =~ /darwin/i) ? "MAC" : "PC"

module Traductor
LBT__DEF = File.join File.dirname(__FILE__), "LibTraductor.def"
load LBT__DEF if FileTest.exist?(LBT__DEF)

#Internal strings for validation messages - Can be TRanslated in more languages
VALID_ERROR = ["The following parameters are invalid",
               "|FR| Les parametres suivants ne sont pas valides",
			   "|ES| Los siguientes Par\ámetros son inv\álidos"]
VALID_MIN = "%1 must be >= %2 |FR| %1 doit etre >= %2 |ES| %1 DEBE SER >= %2"
VALID_MAX = "%1 must be <= %2 |FR| %1 doit etre <= %2 |ES| %1 DEBE SER <= %2"
VALID_PATTERN = "%1 invalid: |FR| %1 invalide : |ES| %1 INV\ÁLIDO :"

#computing the current language
@@langdef = (defined?(TRADUCTOR_DEFAULT) && TRADUCTOR_DEFAULT.strip =~ /^\w\w$/) ? $&.upcase : Sketchup.get_locale[0..1]
@@lang = @@langdef
#@@lang = 'ES'
#@@langdef = 'ES'
@@patlang = Regexp.new '\|' + @@lang + '\|', Regexp::IGNORECASE

def Traductor.get_language 
	@@lang
end	

def Traductor.set_language(lang=nil) 
	@@lang = (lang && lang.strip != "") ? lang[0..1]: @@langdef
	@@patlang = Regexp.new '\|' + @@lang + '\|', Regexp::IGNORECASE
end	

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
	val = $` + " " if (val =~ /\s~\z/)			# '~' preceded by at least one space at end of string
		
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
	puts "old traductor"
	puts Traductor[msg, *args]
end	

def Traductor.log_info (msg, *args)
	puts Traductor[msg, *args]
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
			sval = "#{value.to_f}" + "~~~a"
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
				kv[1] = $`.to_a
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
	
def initialize title, validation_proc=nil, context=nil
	@title = Traductor[title, "Paremeters"]
	@valproc = validation_proc
	@context = context
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

def set_validation_proc validation_proc=nil, context=nil
	@valproc = validation_proc
	@context = context
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
		item.label = Traductor.s label, symb
		@list_items.push item
	end	
	item.label = Traductor.s label, symb if label
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
		item.label = Traductor.s label, symb
		@list_items.push item
	end	
	item.label = Traductor.s label, symb if label
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
		item.label = Traductor.s label, symb
		@list_items.push item
	end	
	item.label = Traductor.s label, symb if label
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
	
#	hash_values.each {|key, value| @hash_results[key] = value} if (hash_values)
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
		#@hash_results[item.symb] = (item.type == 'E') ? item.enu_hash.index(values[i]) : values[i]
		@hash_results[item.symb] = (item.type == 'E') ? match_value(item.enu_hash, values[i]) : values[i]
		i += 1
	end	
		
	#Validation wit the user-defined validation proc - if the call does not work, we consider validation is OK
	if (@valproc)
		begin
			return (Kernel::eval "#{@valproc} self, @context", binding) ? 1 : 0
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
	return key if Traductor.platform_is_mac?
	
	#Check differences on Mac (section should be completed)
	case key
	when 63232	#UP Arrow
		return 38
	when 63235	#RIGHT Arrow
		return 39
	when 63233	#DOWN Arrow
		return 40
	when 63234	#LEFT Arrow
		return 37
		
	when 131072	#Shift alone
		return 16
	when 262144	#Ctrl alone
		return 17
		
	when 63272	#DEL key
		return 46
	when 127	#DEL key
		return 8
	end
	
	#Function keys
	if ((key >= 49 && key <= 60) && ((flgup && flags == 256) || (! flgup && flags == 0)))
		return 113 + key - 50
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

end #Module Traductor

