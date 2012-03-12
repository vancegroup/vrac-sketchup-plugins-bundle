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
# GenericFamily: super class for families
#--------------------------------------------------------------------------------------------------------------			 				   
#--------------------------------------------------------------------------------------------------------------	
  
class VCB

InputInfo = Struct.new :symb, :text, :type, :validate_proc

#--------------------------------------------------------------------------------------------------------------
# Initialization
#--------------------------------------------------------------------------------------------------------------			 				   

#Initialization	
def initialize(*hargs)
	#Main instance variables
	@hsh_inputs = {}
	
	#parsing the arguments
	hargs.each do |harg|	
		harg.each { |key, value| parse_VCB_args(key, value) } if harg.class == Hash
	end
end

#Assign parameters to the VCB instance
def parse_VCB_args(key, value)
	case key.to_s
	when /symb/i
		@symb = value
	when /title/i
		@title = value
	end	
end

#Declare an input format. Conventions are
#  :_xxx : no suffix input where xxx is float, int, length
#  :seg : number of segment with suffix 's'
#  :factor : number of segment with suffix 'x'
#  :angle : angle in degrees with suffix d, g, r, %
# "<letter_xxx>" suffix <letter> where xxx is float, int, length
def declare_input_format(symb, type, text="", &validate_proc)
	info = InputInfo.new
	info.symb = symb
	info.text = text
	info.type = type
	info.validate_proc = validate_proc
	@hsh_inputs[symb] = info
end

#Parse the user text in the VCB and return the Hash array of information
def onUserText(text)
	match_input(text)
end

#Match the elements of VCB text with the registered inputs
def match_input(text)
	@hsh_errors = {}
	hsh = VCB.raw_parsing(text)
	hsh.each do |symb, val|
		puts "INP symb = #{symb} => #{val} class = #{val.class}"
	end	
	hsh_res = {}
	return {} if hsh.length == 0 || @hsh_inputs.length == 0
	#hsh.each { |a, b| puts " HSH = #{a} ==> #{b}" }
	@hsh_inputs.each do |symb, info|
		#puts "info type = #{info.type.to_s}"
		case info.type.to_s
		when /\A(\w*)_(.+)/
			letter = $1.downcase
			case $2
			when /length/
				handle_letter(symb, letter, hsh, hsh_res) { |a| Traductor.string_to_length_formula(a) }
			when /int/
				handle_letter(symb, letter, hsh, hsh_res) { |a| Traductor.string_to_integer_formula(a) }
			when /float/
				handle_letter(symb, letter, hsh, hsh_res) { |a| Traductor.string_to_float_formula(a) }
			end
			
		when /seg/i
			handle_letter(symb, 's', hsh, hsh_res) { |a| Traductor.string_to_integer_formula(a) }
		
		when /factor/i
			handle_letter(symb, 'x', hsh, hsh_res) { |a| Traductor.string_to_float_formula(a) }

		when /back_slash/i
			puts "found Back Slash"
			handle_letter(symb, "\\", hsh, hsh_res) { |a| "\\" }
			
		when /slash/i
			puts "found Slash"
			handle_letter(symb, '/', hsh, hsh_res) { |a| '/' }
			
		when /angle/i
			['r', 'g', 'd', '%'].each do |letter|
				handle_letter(symb, letter, hsh, hsh_res) { |a| Traductor.string_to_angle_degree("#{a}#{letter}") }
			end	
		end
	end
	txt = build_error_message
	hsh_res[:ERROR_MESSAGE] = txt if txt
	hsh_res	
end

def build_error_message
	return nil if @hsh_errors.empty?
	lst = []
	@hsh_errors.each do |symb, ls|
		info = @hsh_inputs[symb]
		lst.push "[#{T6[info.text]}: #{ls.join(' ')}]"
	end
	lst.join ' '
end

#Handle a category of suffix
def handle_letter(symb, letter, hsh, hsh_res, &convert_proc)
	ls = hsh[letter]
	return unless ls && ls.length > 0
	lv = []
	ls.each do |a|
		val = convert_proc.call a
		val = @validate_proc.call(val) if val && @validate_proc
		if val
			lv.push val
		else
			@hsh_errors[symb] = [] unless @hsh_errors[symb]
			@hsh_errors[symb].push "#{a}#{letter}"
		end
	end	
	return unless lv.length > 0
	hsh_res[symb] = [] unless hsh_res[symb]
	hsh_res[symb] += lv
	hsh.delete letter
end

#Analyze the VCB text and split it in elements by suffix as a Hash array
#No interpretation is done at this stage
def VCB.raw_parsing(text)
	hsh = {}
	text = text.strip
	litems = text.strip.split(/\s*;+\s*|\s+/)
	litems.each do |s|
		next if s.empty?
		if s =~ /(.*\d|.+\))([cdegrsuvx%])\Z/
			s = $1
			letter = $2
			puts "lett = #{letter}"
		elsif s =~ /\A(\/|\\)\Z/
			s = ""
			letter = $1
			puts "lett sla = #{letter}"
		else
			letter = ""
		end	
		hsh[letter] = [] unless hsh[letter]
		hsh[letter].push s
	end
	hsh
end

end	# VCB

end	#End Module Traductor
