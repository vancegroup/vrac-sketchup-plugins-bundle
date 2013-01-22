=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed by Fredo6 - Copyright April 2009

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   Lib6Input.rb
# Original Date	:   8 May 2009 - version 1.0
# Description	:   Manage generic Input Fields
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end


module Traductor

T6[:MSG_Invalid_Value] = "Invalid Value"
T6[:MSG_OutOfBound] = "Out of Bound"

#--------------------------------------------------------------------------------------------------------------
# InputField
#--------------------------------------------------------------------------------------------------------------			 

class InputField

@@lpat = [:symbol, :vtype, :value, :get_proc, :show_proc, :set_proc, :default_value, :title,
          :vmin, :vmax, :vincr, :vsprintf, :vvcb, :vprompt_proc, :vprompt, :vbound_proc]

attr_reader *@@lpat

#Class initialization
def initialize(*args)

	#Patterns for input parameter settings
	@std_pats = @@lpat.collect { |symb| Regexp.new("\\A" + symb.to_s, Regexp::IGNORECASE) }
	
	#parsing the arguments
	args.each do |arg|	
		arg.each { |key, value|  parse_args(key, value) } if arg.class == Hash
	end
end

#Parse the properties of an input field
def parse_args(key, value)
	skey = key.to_s
	param = @std_pats.find { |pat| skey =~ pat }
	if param
		eval "@#{param.source[2..-1]} = value"
		return
	end
	
	#Special treatment
	case skey
	when /parent/i
		
	end	
end

#Return the value
def get_value(val=nil)
	val = (@get_proc) ? (@value = @get_proc.call) : @default_value unless val
	val
end

#Return the value
def set_value(val=nil)
	val = @default_value unless val
	val = @set_proc.call(val) if @set_proc
	val
end

def get_vmin ; get_bound @vmin, :min, get_value() ; end
def get_vmax ; get_bound @vmax, :max, get_value() ; end


#Compute the min, max or increments
def get_bound(defval, code, curvalue)
	return defval unless @vbound_proc
	case @vbound_proc.arity
	when 1
		v = @vbound_proc.call code
	when 2
		v = @vbound_proc.call code, curvalue
	when 3
		v = @vbound_proc.call code, curvalue, @symbol
	else
		return defval
	end
	(v) ? v : defval
end

def increment
	oldval = val = get_value
	vincr = get_bound @vincr, :plus, val
	return unless vincr || vincr == 0
	vmax = get_bound @vmax, :max, val
	val += vincr
	val = vmax if vmax && val > vmax
	set_value val unless val == oldval
end

def decrement
	oldval = val = get_value
	vincr = get_bound @vincr, :minus, val
	return unless vincr || vincr == 0
	vmin = get_bound @vmin, :min, val
	val -= vincr
	val = vmin if vmin && val < vmin
	set_value val unless val == oldval
end

def reached_min?
	val = get_value
	vmin = get_bound @vmin, :min, val
	val && vmin && val <= vmin
end

def reached_max?
	val = get_value
	vmax = get_bound @vmax, :max, val
	val && vmax && val >= vmax
end

#Compute the display text
def compute_show_text(val=nil)
	val = get_value val

	return @show_proc.call(val) if @show_proc 
	return Sketchup.format_length(val) if val.class == Length
	
	if @vtype == :percent
		val = val * 100.0
	end
	(@vsprintf) ? sprintf(@vsprintf, val) : val.to_s
end

#Compute the display text
def compute_show_vcb(val=nil)
	val = get_value val

	return @show_proc.call(val) if @show_proc 
	return Sketchup.format_length(val) if val.class == Length
	
	if @vtype == :percent
		val = val * 100.0
	end
	(@vvcb) ? sprintf(@vvcb, val) : compute_show_text(val)
end

#Compute the adjusted text to show in a dialog box
def compute_dialog_text(val=nil)
	sval = compute_show_text val
	case @vtype.to_s
	when /int/i, /float/i
		sval = $` + $1 if sval =~ /(\d)[\D+]\Z/
	end	

	sval
end

#Encode the label part showing the min and max values
def numeric_label_boundaries
	vmin = get_vmin
	vmax = get_vmax
	return '' unless vmin || vmax
	svmin = (vmin) ? compute_show_text(vmin) : ''
	svmax = (vmax) ? compute_show_text(vmax) : ''
	"[#{svmin} ... #{svmax}]"
end

#Validate a numeric input field
def numeric_validate(sval)
	case @vtype.to_s
	when /int/i
		val = Traductor.string_to_integer_formula sval		
	when /len/i
		val = Traductor.string_to_length_formula sval
	when /percent/i
		sval = sval.chop if sval =~ /\%\Z/
		val = Traductor.string_to_float_formula sval.to_s
		val = val * 0.01 if val		
	else
		val = Traductor.string_to_float_formula sval
	end
	unless val
		UI.messagebox T6[:MSG_Invalid_Value] + " [#{sval}]"
		return nil
	end	
	
	#Checking boundaries
	vmin = get_vmin
	vmax = get_vmax
	if (vmin && val < vmin) || (vmax && val > vmax)
		UI.messagebox "#{sval} Out of bound" + " " + numeric_label_boundaries
		UI.messagebox "[#{sval}]" + T6[:MSG_OutOfBound]  + " " + numeric_label_boundaries
		return nil
	end
	
	return val
end

#Pop up a simple dialog box to request the parameter
def dialog_ask(val=nil)
	val = get_value val
	sval = compute_dialog_text val

	#Creating the dialog box
	hparams = {}
	label = (@vprompt_proc) ? @vprompt_proc.call : @vprompt
	label = "Enter value" unless label
	title = (@title) ? @title : label
	label += '  ' + numeric_label_boundaries + '  '
	
	#invoking the dialog box
	####results = [sval]
	results = [sval]
	while true
		begin
			results = UI.inputbox [label], results, [], title
		rescue
			UI.messagebox T6[:MSG_Invalid_Value]
			next
		end
		return nil unless results
		resval = numeric_validate results[0]
		break if resval
	end	

	#Transfering the parameter
	set_value resval
end

end	#class InputField

end	#module Traductor