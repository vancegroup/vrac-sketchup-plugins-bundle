=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright © 2011 Fredo6 - Designed and written June 2011 by Fredo6
#
# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   Lib6VCB.rb
# Original Date	:   13 June 2011
# Description	:   Manage VCB inputs
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# VCB Input management
#--------------------------------------------------------------------------------------------------------------			 				   
#--------------------------------------------------------------------------------------------------------------	
  
class VCB

InputFormat = Struct.new :symb, :letter, :typenum, :suffixes, :pattern, :validate_proc, :description

#--------------------------------------------------------------------------------------------------------------
# Initialization
#--------------------------------------------------------------------------------------------------------------			 				   

#Initialization	
def initialize
	@lst_inputs = []
end

#Declare an input format. Conventions for specs is are <typenum>_<letter>_<suffixes> (or a list of specs)
def declare_input_format(symb, format_specs, description=nil, &validate_proc)
	format_specs = [format_specs] unless format_specs.class == Array
	format_specs.each do |specs|
		declare_single_format symb, specs, description, validate_proc
	end
end

#Declare an input format. Conventions are <typenum>_<letter>_<suffixes>
def declare_single_format(symb, specs, description, validate_proc)
	#Getting the specs
	typenum, letter, suffixes = specs.strip.split '_'
	typenum = (typenum && typenum != '') ? typenum.downcase.intern : nil
	
	#Letter, with special cases
	lpat = ""
	if letter && letter != ""
		letter.split('').each do |c|
			case c
			when '/', '*', '?', '+', '-'
				lpat += "\\" + c
			else
				lpat += "#{c.downcase}"
			end	
		end
	end
	
	#Creating the regular pattern
	numpat = ".*[0-9)]"
	totalpat = "\\A"	
	if typenum == :a
		totalpat += "(#{numpat}[dgr\\%])"
	elsif typenum == :aa
		totalpat += "(#{numpat}(dd|gg|rr|\\%\\%))"
	elsif typenum
		totalpat += "(#{numpat})#{lpat}"
	else	
		totalpat += "()#{lpat}"
	end			
	sfpat = (suffixes) ? "([#{suffixes.downcase}]?)" : ""	
	totalpat += sfpat + "\\Z"
	
	#Creating the structure
	input = InputFormat.new
	input.symb = symb
	input.validate_proc = validate_proc
	input.description = description
	input.typenum = typenum
	input.letter = letter
	input.suffixes = suffixes
	input.pattern = Regexp.new totalpat, Regexp::IGNORECASE
	@lst_inputs.push input
	
	input
end

#Go through the results. Each items has 3 parameters
#   - <symb>: the symbol of the variable
#   - <val>: the value
#   - <suffix>: the optional suffix, if any
def each_result
	@lst_results.each { |a| yield *a }
end

#Go through the errors. Each items has 2 parameters
#   - <symb>: the symbol of the variable or nil if the error is in the parsing
#   - <s>: the faulty string item
def each_error
	@lst_errors.each { |a| yield *a }
end

#Process the parsing of the VCB text
#Return the number of errors
def process_parsing(text)
	@lst_results = []
	@lst_errors = []
	@text = text
	return unless text
	litems = text.strip.split(/\s*;+\s*|\s+/)	
	litems.each { |s| check_item s unless s.empty? }
	@lst_errors.length
end
 
#Check an item of the VCB string 
def check_item(s)
	@lst_inputs.each do |input|
		symb = input.symb
		if s =~ input.pattern
			suffix = $2
			if $1 == ""
				val = nil
			else	
				val = validation_value(symb, input.typenum, $1, input.validate_proc)
				if val == nil
					@lst_errors.push [symb, s]
					return
				end
			end	
			@lst_results.push [symb, val, suffix]
			return
		end
	end	
	@lst_errors.push [nil, s]
end
 
#Validate individual values and convert them to their right type
def validation_value(symb, typenum, val, validate_proc)
	case typenum
	when :l
		val = Traductor.string_to_length_formula val
	when :f
		val = Traductor.string_to_float_formula val
	when :i
		val = Traductor.string_to_integer_formula val
	when :aa
		val = Traductor.string_to_angle_degree_formula val[0..-2]
	when :a
		val = Traductor.string_to_angle_degree_formula val
	end		
	val = validate_proc.call(val) if val && validate_proc
	val
end
 
end	#class VCB

end	#End Module Traductor
