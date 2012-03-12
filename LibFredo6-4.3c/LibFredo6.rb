=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright © 2008 Fredo6 - Designed and written Dec 2008 by Fredo6
#
# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   LibFredo6.rb
# Original Date	:   20 Aug 2008 - version 3.0
# Type			:   Ruby Library
# Description	:   Top loading module for all Library utilities of Fredo6's scripts
# Usage			:   See Tutorial and Quick Ref Card in PDF format
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

unless defined?(LibFredo6)
require 'sketchup.rb'
require 'LibTraductor.rb' if Sketchup.find_support_file('LibTraductor.rb', "Plugins")	#Compatibility
require 'TOS_Dir_13/LibTraductor_20.rb' if Sketchup.find_support_file('TOS_Dir_13/LibTraductor_20.rb', "Plugins")	#Compatibility

module LibFredo6

@@time_start = Time.now
if RUBY_PLATFORM =~ /darwin/i
	@@tmp_dir = ENV["TMPDIR"] 
	@@tmp_dir = "/tmp" unless @@tmp_dir
else
	@@tmp_dir = ENV["TEMP"].gsub(/\\/, '/')
end	

#Trace logging
def LibFredo6.tmpdir ; @@tmp_dir ; end
def LibFredo6.log_file ; @logfile_path ; end
def LibFredo6.rootlog ; "LibFredo6Trace_#{Sketchup.version.to_i}_*.txt" ; end
def self.mask_dir(s) ; (s.class == String && s =~ /(\.rb.*:\d+:)/) ? File.basename($`) + $1 + " " + $' : s ; end
def LibFredo6.sagwarum(*args) ; LibFredo6.sag(*args) ; end
def LibFredo6.sag(*args) ; LibFredo6.sag(*args) ; end

def LibFredo6.log(*args)
	t0 = args.find { |a| a.class == Time }
	args = args.find_all { |a| a }
	if args[0].class == Time
		t0 = args[0]
		args = args[1..-1]
	else	
		t0 = Time.now
	end	
	unless @logfile_handle
		@code = ">>>> "
		tmpdir = @@tmp_dir
		@logfile_path = File.join tmpdir, LibFredo6.rootlog.sub('*', "#{(@@time_start.to_f*1000).to_i}")
		@logfile_handle = File.open(@logfile_path, "w")
		return false unless @logfile_handle
		LibFredo6.log "DATE / TIME: #{@@time_start}", "SKETCHUP VERSION: #{Sketchup.version}", "RUBY_PLATFORM: #{RUBY_PLATFORM}",
		              "LOG FILE: #{File.basename(@logfile_path)}"
	end
	lines = caller
	line = (caller[0] =~ /sagwarum/) ? lines[1] : lines[0]
	@logfile_handle.puts "#{@code}#{t0.to_f};#{mask_dir line}"
	largs2 = args.collect { |s| mask_dir(s) }
	@logfile_handle.puts *largs2
	@logfile_handle.puts "\n"
	@logfile_handle.flush
	true
end

#Show a message box for error
def LibFredo6.log_messagebox(*args)
	text = args.join("\n") + "\n\n" + caller[0]
	UI.messagebox text
end

#Debug Logging
def LibFredo6.debug_file ; @debugfile_path ; end
def LibFredo6.rootdebug ; "LibFredo6Debug_#{Sketchup.version.to_i}_*.txt" ; end
def LibFredo6.debug2(*args) ; puts LibFredo6.debug(*args) ; end

def LibFredo6.debug(*args)
	unless @debugfile_handle
		tmpdir = @@tmp_dir
		@debugfile_path = File.join tmpdir, LibFredo6.rootdebug.sub('*', "#{(@@time_start.to_f*1000).to_i}")
		@debugfile_handle = File.open(@debugfile_path, "w")
		return false unless @debugfile_handle
		LibFredo6.debug "DATE / TIME: #{@@time_start}", "SKETCHUP VERSION: #{Sketchup.version}", "RUBY_PLATFORM: #{RUBY_PLATFORM}",
		              "LOG FILE: #{File.basename(@debugfile_path)}", " "
	end
	args[0] = ["\n=========== time = #{Time.now.to_f} =============="] if args.empty? || args[0] == ""
	@debugfile_handle.puts *args
	@debugfile_handle.flush
	args
end

#Register the latest version of LibFredo6 family 
def LibFredo6.startup
	LibFredo6.log "LibFredo6: Starting up LibFredo6.rb"
	
	#For compatibility: avoid overriding by the old library
	$".push "LibTraductor.rb", "libtraductor.rb"
	
	#Localize latest folder for LibFredo6 shared libraries
	$:.each do |sudir|
		dir = File.join sudir, '*'
		ld = []
		Dir[dir].each { |f| ld.push [f, $1] if f =~ /LIBFREDO6_Dir_([0-9][0-9])\Z/i }
		next if ld.length == 0
		@@lib_fredo_version = ld.last[1]
		@@lib_fredo_path = ld.last[0]
		@@lib_fredo_folder = File.basename @@lib_fredo_path
		@@lib_fredo_sudir = sudir
		LibFredo6.log "LibFredo6: Beginning of loading Cycle***+"
		
		#Loading the minimum routines to enable the LibFredo6 environment (file Lib6Core.rb)
		lib_pattern = "Lib6Core*.rb"
		rb = Dir[File.join(@@lib_fredo_path, lib_pattern)].last
		next unless rb
		@@lib_loaded = File.basename(rb)
		rbfile = File.join(@@lib_fredo_folder, @@lib_loaded)
		begin
			#require rbfile
			require rb
			LibFredo6.log "LibFredo6 Core: #{rbfile} successfully loaded"
		rescue Exception => e
			LibFredo6.log "!LibFredo6 Core: ERROR loading #{rbfile}", "#{e.message}"
			return
		end
		
		#Registering the rest of the LibFredo6 library (but not loading it)
		Traductor::Plugin.new.load_from_config "LibFredo6", @@lib_fredo_folder
		break
	end
	LibFredo6.log "LibFredo6: End of loading Cycle***-"
	@timer_error_id = UI.start_timer(0, false) { LibFredo6.after_startup }
end

#Task to execute right after startup
def LibFredo6.after_startup
	if @timer_error_id
		UI.stop_timer @timer_error_id
		@timer_error_id = nil
	end	
	Traductor::TraceLog.purge if defined?(Traductor::TraceLog.purge)
	Traductor::DebugLog.purge if defined?(Traductor::DebugLog.purge)
	Traductor::Plugin.signal_error_in_loading if defined?(Traductor::Plugin.signal_error_in_loading)
	Traductor::Upgrade.time_for_check? if defined?(Traductor::Upgrade.time_for_check?)
end

#Register a Plugin from a configuration file
def LibFredo6.register_plugin(rootname, folder, plugin_name=nil)
	#obsolete - left because called by Z_Loader__ files
end

#Return module variables for LibFredo6
def LibFredo6.sudir ; @@lib_fredo_sudir ; end
def LibFredo6.path ; @@lib_fredo_path ; end
def LibFredo6.folder ; @@lib_fredo_folder ; end
def LibFredo6.lib_loaded ; @@lib_loaded ; end
def LibFredo6.version ; @@lib_fredo_version ; end
	
#Always Loading  the Lib6Core file (minimum code)
LibFredo6.startup	
	
end	#Module LibFredo6

end	#Defined? LibFredo6