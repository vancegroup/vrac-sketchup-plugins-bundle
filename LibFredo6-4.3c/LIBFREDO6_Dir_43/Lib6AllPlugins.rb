=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright © 2011 Fredo6 - Designed and written August 2011 by Fredo6
#
# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6AllPlugins.rb
# Original Date	:  04 Aug 2011
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  Manage extrenal plugins.
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end


#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# Class Upgrade: Manage check for Updates
#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------

module Traductor

#--------------------------------------------------------------------------------------------------------------
# Class AllPlugins: classinitialization part
#--------------------------------------------------------------------------------------------------------------			 

#Class variables initialization
unless defined?(self::AllPlugins)
class AllPlugins
	@@hsh_allplugins = {}
	
end
end

class AllPlugins

#--------------------------------------------------------------------------------------------------------------
# Class methods: Manage plugin registration
#Valid fields are
# 	:name
#	:author
#	:description
#	:load_time
#	:load_time_startup
#	:load_time_files
#	:load_time_second --> Phase 2 loading time
#	:lst_obsolete_files --> List of obsolete files (just the basenames)
#--------------------------------------------------------------------------------------------------------------

#Plugin Registration: Parameters are passed in one or several hash arrays
def self.register(plugin_name, *hargs)
	return unless plugin_name.class == String && plugin_name.length > 0
	hsh = @@hsh_allplugins[plugin_name]
	@@hsh_allplugins[plugin_name] = hsh = {} unless hsh
	hargs.each do |h| 
		h.each do |key, val| 
			val = Traductor.encode_to_ruby val
			hsh[key] = (val.class == String || val.class == Symbol) ? T6[val] : val
		end	
	end	
	hsh[:name] = plugin_name
	hsh[:author] = T6[:T_TXT_Anonymous] unless hsh[:author]
	hsh[:installed] = true
	hsh
end

def self.cleanup_string_encoding(s)
	return s unless s.class == String
	begin
		s.unpack 'U*'
	rescue
		s = s.unpack('C*').pack('U*')
	end
	s
end

#Fetch external plugin registration
def self.get_all_plugins ; @@hsh_allplugins ; end

def self.get_all_registered_plugins
	lmodules = []
	ObjectSpace.each_object { |m| lmodules.push m if m.class == Module }
	
	lmodules.each do |m|
		next unless defined?(m.register_plugin_for_LibFredo6)
		begin
			method = m.method "register_plugin_for_LibFredo6"
			if method.arity == 1
				lang = T6Mod.get_langpref[0]
				lang = "" unless lang
				harg = method.call lang
			elsif method.arity == 0	
				harg = method.call
			else
				next
			end	
			next unless harg
			name = harg[:name]
			name = harg[:plugin] unless name
			register name, harg if name
		rescue
		end
	end
	@@hsh_allplugins
end

#Declare that a plugin is obsolete
def self.declare_obsolete_plugin(plugin_name, text)
	return unless plugin_name.class == String && plugin_name.length > 0
	hsh = @@hsh_allplugins[plugin_name]
	@@hsh_allplugins[plugin_name] = hsh = {} unless hsh
	hsh[:obsolete] = text
end

#Return load time info in ms
def self.load_time_info(plugin_name)
	hsh = @@hsh_allplugins[plugin_name]
	return [] unless hsh
	t = []
	t[0] = hsh[:load_time_files]
	t[1] = hsh[:load_time_startup]
	t[2] = hsh[:load_time]
	t[3] = hsh[:load_time_second]
	if t[2] || t[3]
		t[4] = 0
		t[4] += t[2] if t[2]
		t[4] += t[3] if t[3]
	else
		t[4] = nil
	end	
	t = t.collect { |a| (a * 1000).to_i if a}
	t
end

#Compute the load time at SU startup of all registered plugins, including LibFredo6
def self.total_load_time
	ttot = 0
	@@hsh_allplugins.each do |key, hsh|
		t = hsh[:load_time]
		ttot += t if t
	end
	(ttot * 1000).to_i
end

#Compute a tooltip text with plugin name, version, date and author
def self.compute_tooltip(plugin_name)
	hsh = @@hsh_allplugins[plugin_name]
	return [] unless hsh
	plugin6 = hsh[:plugin6]
	return plugin6.compute_tooltip if plugin6
	"#{@plugin_name} v#{hsh[:version]} - #{hsh[:date]} - #{hsh[:author]}"
end

#Get the list of obsolete files for a plugin
def self.get_obsolete_files(plugin_name)
	hsh = @@hsh_allplugins[plugin_name]
	return [] unless hsh
	plugin6 = hsh[:plugin6]

	#Registered files
	return plugin6.check_obsolete_files if plugin6
	
	#Other plugins
	ls = hsh[:lst_obsolete_files]
	return [] unless ls
	ls = [ls] unless ls && ls.class == Array
	return [] unless ls.length > 0
	
	lfiles = []
	$:.each do |sudir|
		ls.each do |f|
			lfiles += Dir[File.join(sudir, f)]
		end	
	end
	lfiles
end

end	#class AllPlugins

end #Module Traductor

