=begin
#------------------------------------------------------------------------------------------------------------
#************************************************************************************************************
# Copyright © 2008 Fredo6 - Designed and written December 2008 by Fredo6
#
# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   Lib6Core_40.rb
# Original Date	:   10 Sep 2008 - version 3.0
# Type			:   Ruby Library
# Description	:   Plugin Management for all Library utilities of Fredo6's scripts
# Note			:   This file is always loaded first
#				:	The rest of the code resides in other Lib6***.rb files, which are loaded afterward
#------------------------------------------------------------------------------------------------------------
#************************************************************************************************************
=end

require 'sketchup.rb'
require 'extensions.rb'

module Traductor
@@file_trace6 = nil

#-------------------------------------------------------------------------------------------------------------------------------			 				   
#-------------------------------------------------------------------------------------------------------------------------------			 				   
# T6  Language Translation Management (only  top routines) - Rest in LibTraductor_xx.rb 
#-------------------------------------------------------------------------------------------------------------------------------			 				   
#-------------------------------------------------------------------------------------------------------------------------------			 				   

T6MOD_LNG_DEFAULT = '--'			#Code for Language by Default
T6MOD_RKEY_Langpref = "langpref"	#Registry key for preferred languages
RUN_ON_MAC = (RUBY_PLATFORM =~ /darwin/i) ? true : false
SU_MAJOR_VERSION = Sketchup.version.to_i

#computing the current language
@@langdef = (defined?(TRADUCTOR_DEFAULT) && TRADUCTOR_DEFAULT.strip =~ /^\w\w$/) ? $&.upcase : Sketchup.get_locale[0..1]
@@lang = @@langdef
@@patlang = Regexp.new '\|' + @@lang + '\|', Regexp::IGNORECASE

def Traductor.get_language 
	@@lang
end	

def Traductor.set_language(lang=nil) 
	@@lang = (lang && lang.strip != "") ? lang[0..1]: @@langdef
	@@patlang = Regexp.new '\|' + @@lang + '\|', Regexp::IGNORECASE
end	

class T6Mod

Traductor_T6Root = Struct.new("Traductor_T6Root", :rootname, :path, :hsh_t6, :t6edit) 

@@langpref = nil
@@hsh_t6 = {}
@@hsh_root = {}

#Set the Preferred languages (in registry)
def T6Mod.set_langpref(llang)
	llang = [] unless llang
	@@langpref = llang
	Traductor.set_language llang[0]
	ll = Sketchup.write_default "LibFredo6", T6MOD_RKEY_Langpref, llang.join(" ")
end

def T6Mod.init_langpref
	ll = Sketchup.read_default "LibFredo6", T6MOD_RKEY_Langpref
	ll = Sketchup.get_locale[0..1] unless ll
	@@langpref = ll.split(" ")
	Traductor.set_language @@langpref[0]
end

#Create a language translation context for the module hmod
def initialize(hmod, path, rootname)
	#Default Languages
	T6Mod.init_langpref unless @@langpref
	
	#initialization
	@hmod = hmod
	@modname = hmod.name	
	@hstrings = {}
	@hlng = {}
	@path = path
	@rootname = rootname
	@hloaded = {}
	@@hsh_t6[@modname] = self
	
	#Storing the handler for its root and path
	hroot = @@hsh_root[rootname]
	unless hroot
		hroot = Traductor_T6Root.new
		hroot.hsh_t6 = {}
		hroot.rootname = rootname
		hroot.path = path
		hroot.t6edit = nil
		@@hsh_root[rootname] = hroot
	end	
	hroot.hsh_t6[@modname] = self
	self
end

def T6Mod.get_langpref 
	@@langpref
end	

#Set and declare a symbolic string and its translation
def []=(symb, sval)
	self.set symb, sval
end

def set(symb, sval)
	return nil unless symb
	symb = symb.to_s.strip 
	sval = symb unless sval
		
	#Parsing the string specification, either a sring or a list of string
	lsval = (sval.class == Array) ? sval : [sval]
	lsval.each do |spec|
		rest = spec.strip
		lng = T6MOD_LNG_DEFAULT
		nodefault = false
		while (rest =~ /\|(\w\w)\|(.*)/)
			if $`.strip.length == 0
				nodefault = true
			else
				store_value lng, symb, $`.strip
				if nodefault
					store_value T6MOD_LNG_DEFAULT, symb, $`.strip
					nodefault = false
				end
			end	
			lng = $1
			rest = $2.strip
		end
		store_value lng, symb, rest
		store_value T6MOD_LNG_DEFAULT, symb, rest if nodefault
	end	
	
	true
end

#Get the translation of a symbol according to current preferred language
#the method works with Hash, Keylist and simple list of symbols
def [](symb, *args)
	self.get symb, *args
end

def get(symb, *args)
	#Symbol is actually from Traductor
	if @hmod != Traductor && symb.class == Symbol && (symb.id2name =~ /\AT_/ || symb.id2name =~ /\AT6_/)
		return Traductor::T6[symb, *args]
	end	
	
	#Hash table and [key, value] lists - Translate the symbols
	if symb.class == Hash
		hsh = {}
		symb.each { |key, val| hsh[key] = get(val, *args) }
		return hsh	
	elsif symb.class == Array && symb.length > 0 && symb[0].class == Array && symb[0].length == 2
		lst = []
		symb.each { |l| lst.push [l[0], get(l[1], *args)] }
		return lst	
	elsif symb.class == Array && symb.length > 0 && symb[0].class == Symbol
		lst = []
		symb.each { |l| lst.push get(l, *args) }
		return lst	
	end
	
	#Old style With Traductor
	return Traductor[symb, *args] unless symb.class == Symbol
	
	#Checking if translation file is loaded
	check_loaded
	
	#Retrieving the string
	symb = symb.id2name
	hsh = @hstrings[symb]
	return symb unless hsh
	
	#Retrieving the hash table
	sval = nil
	@@langpref.each do |lng|
		break if (sval = hsh[lng])
	end
	sval = hsh[T6MOD_LNG_DEFAULT] unless sval
	return symb unless sval
	
	#Performing argument substitution
	for i in 0..args.length-1 do
		sval = sval.gsub "%#{i+1}", args[i].to_s
	end
	
	#returning the value
	sval
end

#Technical storage of the string according to language
def store_value(lng, symb, sval)
	#removing the '~' for leading or trailing space preservation
	val = " " + $' if ((val =~ /\A~\s/) == 0)		# '~' followed by at least one space at beginning of string
	val = $` + " " if (val =~ /\s~\z/)				# '~' preceded by at least one space at end of string
	lng = lng.upcase
	
	#Storing the string
	symb = symb.to_s
	hln = @hstrings[symb]
	hln = (@hstrings[symb] = {}) unless hln
	@hlng[lng] = 0 unless @hlng[lng]
	@hlng[lng] += 1 unless hln[lng]
	sval = sval.gsub /\\n/, "\n" if sval
	hln[lng] = UTF.real(sval)
end

def T6Mod.handler(modulename)
	@@hsh_t6[modulename]
end

#Enabling usage of T6 notation in order to call via T6[]= and T6[] in the module <hmod>
def T6Mod.enable(hmod, path, rootname)
	return if hmod.const_defined?('T6')
	txt = "T6 = Traductor::T6Mod.new(#{hmod}, '#{path}', '#{rootname}') "
	hmod.module_eval txt
end

end	#class T6Mod

#--------------------------------------------------------------------------------------------------------------
# Class UTF: Helpers to manage UTF strings
#--------------------------------------------------------------------------------------------------------------			 

class UTF

#Convert a string to another pure ASCII string where special charaters are encoded !code! 
def UTF.flatten(s)
	return s unless s && s != ""
	begin
		begin
			ls = s.unpack("U*")
		rescue
			ls = []
			for i in 0..s.length-1
				ls.push s[i]
			end	
		end	
		s2 = ""
		ls.each { |c| s2 += ((c >= 128) ? "!#{c}!" : c.chr) }
		return s2
	rescue
		return s
	end
end

#Take an encoded string with !number! convention and build a UTF compatible string
def UTF.real(s)
	return s unless s && s != ""
	s = UTF.flatten s
	s.gsub(/!(\d{3,5})!/) { |u| [$1.to_i].pack("U") }
end

#Take an encoded string with !number! convention and build a UTF compatible string
def UTF.from_iso(s)
	return s unless s && s != ""
	begin
		ls = s.unpack("C*")
		s2 = ls.pack("U*")
		return UTF.real(s2)
	rescue
		return s
	end	
end

end	#class UTF

#--------------------------------------------------------------------------------------------------------------
# Default Parameters Management (only the top routines) - Rest in LibTraductor_xx.rb
#--------------------------------------------------------------------------------------------------------------			 				   

class DefaultParameters
@@defparam_dir = nil		#Plugins folder of Sketchup

def initialize(file, hmod)
	@file = file
	@rootname = File.basename file
	@hmod = hmod
	@hparam = {}
	@lparam = []
	@wdlg = nil
	@herror = {}
	@lst_no_default_check = [:T_DEFAULT_IconVisible]
end

def DefaultParameters.get_dir
	unless @@defparam_dir
		@@defparam_dir = File.join LibFredo6.sudir, "DEFPARAM_Dir"
		begin
			Dir.mkdir @@defparam_dir unless FileTest.directory?(@@defparam_dir)
		rescue
			@@defparam_dir = nil
		end	
	end	
	@@defparam_dir
end

end	#class DefaultParameters

#--------------------------------------------------------------------------------------------------------------
# PLugin Management (only the top routines) - Rest in LibTraductor_xx.rb
#--------------------------------------------------------------------------------------------------------------			 				   

class Plugin

attr_reader :plugin_dir, :version, :load_time, :plugin_name, :folder, :loaded_rubys, :defparam,
            :main_module, :lst_obsolete_files, :name, :load_time, :load_time_startup, :load_time_second

@@hsh_plugins = {}
@@lst_files_error = []
@@timer_error_id = nil

def Plugin.hsh_plugins ; @@hsh_plugins ; end

def initialize
	@list_commands = []
	@list_handlers = []
	@handler_menu = nil
	@hsh_commands = {}
	@hsh_tpc = {}
	@default_icons_visible = []
	@default_handlers_visible = []
end
	
#Register a plugin as an extension, based on its declaration file .plugin - does not do more	
# <folder> is given by reference to the Sketchup plugin directory
# <rootname> is the name to be used for files (declaration, translation, def param), without extensions
def load_from_config(rootname, folder, plugin_name=nil)
	#Checking the rootname and Plugin_name
	rootname = plugin_name unless rootname && rootname.strip.length > 0
	plugin_name = rootname unless plugin_name && plugin_name.strip.length > 0
	return false unless rootname && rootname.strip.length > 0

	#checking if plugin already loaded
	return true if @@hsh_plugins[@plugin_name]
	
	#Checking the folder and root directory
	return false unless folder
	@folder = folder
	@plugin_dir = nil
	$:.each do |sudir|
		pdir = File.join sudir, folder
		next unless FileTest.directory?(pdir)
		@plugin_dir = pdir
		@su_plugin_dir = sudir
		break
	end	
	return false unless @plugin_dir
	
	#Checking the declaration file for the plugin
	@rootname = rootname
	@plugin_name = plugin_name
	file = File.join @plugin_dir, (rootname + '.plugin')
	return false unless FileTest.exist?(file)
	
	#Loading the declaration file
	sulng = Sketchup.get_locale
	lst_var = ['modules', 'version', 'date', 'name', 'description', 'copyright', 'creator', 
	           'ruby_files', 'ext_load', 'web_site_name', 'web_site_link', 'web_support_link', 
			   'credits', 'old_file', 'old_dir', 'picture_prefix', 'startup', 'donation',
			   'icon_conv', 'cursor_conv', 'toolbar', 'video', 'libfredo6', 'sketchup_version',
			   'web_repository', 'web_repository_link', 'bootstrap', 'upd_website', 'upd_url', 
			   'doc_pattern', 'doclinks']
	lst_var.each { |var| eval "@lst_" + var + "=[]" }		   
	IO.foreach(file) do |line| 
		lst_var.each do |var| 
			next unless Regexp.new('\A' + var + '\s*=\s*"*(.*)', Regexp::IGNORECASE).match(line)
			sval = $1.strip
			sval = $`.strip if sval =~ /"|#/
			sval = UTF.from_iso sval
			eval "@lst_#{var}.push " + '"' + sval + '"'
			if sval =~ /\|(\w\w)\|(.*)/ 
				sval = $2
				if ($1.upcase == sulng[0..1].upcase)
					eval '@' + var + '="' + sval + '"'
					next
				end	
			end	
			eval '@' + var + '="' + sval + '" unless @' + var
		end	
	end	
	
	#Checking modules
	@lst_modules = [[rootname]] unless @lst_modules.length > 0
	@lst_modules = super_flatten @lst_modules
	@main_module = @lst_modules[0]
	@lst_ruby_files = super_flatten @lst_ruby_files
	@lst_old_file = super_flatten @lst_old_file
	@lst_old_dir = super_flatten @lst_old_dir
	@ext_load = (@ext_load =~ /true/i) ? true : false
	@nice_name = @name
	
	#Obsolete files
	@lst_obsolete_files = [] unless @lst_obsolete_files
	@lst_obsolete_files |= ["ZLoader__#{@plugin_name}.rb"]
	@lst_obsolete_files |= @lst_old_file if @lst_old_file
	@lst_obsolete_files |= @lst_old_dir if @lst_old_dir
	
	#Other parameters
	@date = "??" unless @date
	@ext_load = true if @ext_load == nil
		
	#Storing the plugin instance
	@@hsh_plugins[@plugin_name] = self
	
	#Preparing modules with the variable @@myplugin defined and enabling T6 language translation
	@lst_modules.each do |m|
		Object.module_eval "module #{m} ; MYPLUGIN = Traductor::Plugin.myplugin('#{@plugin_name}') ; end"
	end
	@hmod_main_module = eval(@main_module)
	@plugin_title_symb = @plugin_name
	
	#Creating the loader file
	if @plugin_name == "LibFredo6"
		effective_load
	else
		floader = File.join @plugin_dir, "__loader.rb"
		unless FileTest.exist?(floader)
			File.open(floader, "w") do |f| 
				f.puts "Traductor::Plugin.myplugin('#{@plugin_name}').effective_load"
			end
		end	
	end	

	#Registering the plugin as an extension of Sketchup
	if rootname =~ /LibFredo6/i
		Traductor::Plugin.load_all_plugins		

	else
		ext = SketchupExtension.new @name, File.join(@folder, File.basename(floader))
		ext.creator = @creator 
		ext.description = @description 
		ext.version = @version + " - " + @date 
		ext.copyright = @creator + " - " + @copyright 
		Sketchup.register_extension ext, true
	end

	self	
end

def super_flatten(list)
	return nil if list == nil
	list = [list] unless list.class == Array
	return list if list.length == 0
	lm = []
	list.each { |m| lm.push m.split(/;\s*|,\s*/) }
	lm.flatten
end

#Return the class instance of a Plugin given by its name
def Plugin.myplugin(plugin_name)
	@@hsh_plugins[plugin_name]
end

#Return the name of a plugin
def get_name
	@plugin_name
end

def get_upd_info
	[@upd_website, @upd_url]
end
	
#Create the Default parameter class for the plugin
def create_def_param(hmod)
	unless @defparam
		#@defparam = Traductor::DefaultParameters.new File.join(@plugin_dir, @rootname) + ".def", hmod
		filedef = File.join(DefaultParameters.get_dir, @rootname) + ".def"
		@defparam = Traductor::DefaultParameters.new filedef, hmod
	end	
	@defparam
end

#Check if the plugin required version of LibFredo6 is correct
def libfredo6_version_valid?
	if @libfredo6 && @libfredo6.to_i > LibFredo6.version.to_i
		text = T6[:T_ERROR_VersionModule, @plugin_name, @libfredo6, LibFredo6.version] 
		LibFredo6.log "?#{text}"
		UI.messagebox text
		return false
	end	
	true
end

#Check if the plugin required version of Sketchup is correct
def sketchup_version_valid?
	return true unless @sketchup_version && @sketchup_version.class == String
	curv = Sketchup.version
	curv =  $1 + $2 if curv =~ /(\d+\.\d+)\.(\d+)/
	minv = @sketchup_version
	minv =  $1 + $2 if minv =~ /(\d+\.\d+)\.(\d+)/
	if curv < minv
		text = T6[:T_ERROR_VersionSketchup, @plugin_name, @sketchup_version, Sketchup.version] 
		LibFredo6.log "?#{text}"
		UI.messagebox text 
		return false
	end	
	true
end

#Get the LibFredo6 required version (as a string with 2 digis version, i.e "30", not "3.0") 
def get_libfredo6_version
	@libfredo6
end

#Start the loading process for the Plugin
def effective_load	
	return if @effective_loaded
	
	#Testing the Default Dir directory
	defdir = DefaultParameters.get_dir
	unless defdir
		text = "Cannot load plugin #{@plugin_name} because the script cannot create DEFPARAM_Dir folder in:\n "
		text += "#{LibFredo6.sudir}\n\n"
		text += "Please create it manually, respecting the case"
		UI.messagebox text
		return
	end	
	
	#Loading Other LibFredo6 module if not already loaded
	@effective_loaded = true
	
	#Loading the required plugin
	self.effective_load_part2 if libfredo6_version_valid? && sketchup_version_valid?
end

#Effective load of a plugin (follow up)
def effective_load_part2
	t0 = Time.now.to_f
	
	#Enabling all modules for T6
	@lst_modules.each do |m|
		txt = "module #{m} ;"
		txt += "Traductor::T6Mod.enable(self, '#{@plugin_dir}', '#{@rootname}') ; "
		txt += "MYDEFPARAM = MYPLUGIN.create_def_param(self) ; "
		txt += "SU_MAJOR_VERSION = (Sketchup.version[0..0]).to_i	; "
		txt += "PC_OR_MAC = (RUBY_PLATFORM =~ /darwin/i) ? 'MAC' : 'PC' ;"
		txt += "RUN_ON_MAC = #{RUN_ON_MAC.inspect} ;"
		txt += "end"		
		Object.module_eval txt
	end
	
	#Loading specified ruby files
	load_full_rubies unless load_bootstrap_rubies

	#Invoke the startup commands
	t1 = Time.now.to_f
	@lst_startup = ["startup"] if @lst_startup.length == 0
	@lst_startup.each do |m|
		begin
			m = @main_module + '.' + m 
			eval m
		rescue Exception => e
			text = "#{@plugin_name}  #{@version}: Error starting up plugin (creating menus and icons)"
			err = LibFredo6.mask_dir e.message
			LibFredo6.log "?#{text}", err
			LibFredo6.log_messagebox text, err
		end
	end
	@load_time_startup = Time.now.to_f - t1
	
	#Storing the load time
	@load_time = Time.now.to_f - t0
	
	#Registering the Plugin for common services
	hargs = { :version => @version, :date => T6[@lst_date], :author => @creator, :dir => @plugin_dir,
              :link_info => @web_support_link, :description => Traductor[@lst_description],
			  :load_time => @load_time, :load_time_startup => @load_time_startup, 
			  :load_time_files => (@load_time - @load_time_startup),
			  :plugin6 => self,
              :required => ((@libfredo6) ? "LibFredo6 v#{@libfredo6}" : nil) }
	AllPlugins.register @plugin_name, hargs	
end

#Load bootstrap ruby
def load_bootstrap_rubies
	t0 = Time.now
	@loaded_bootstrap = []
	@lst_bootstrap = "bootstrap*" if @lst_bootstrap.length == 0
	lst_errors = []
	@lst_bootstrap.each do |rb|
		rb += '.rb' unless rb =~ /\.rb\Z/i
		Dir[File.join(@plugin_dir, rb)].each do |f| 
			bf = File.basename(f)
			begin
				#status = require File.join(@folder, bf)
				status = require f
				@loaded_bootstrap.push bf if status
			rescue Exception => e
				err = LibFredo6.mask_dir e.message
				LibFredo6.log "?#{@plugin_name}  #{@version}: ERROR in Loading ruby bootstrap file #{bf}", err
				lst_errors.push bf
			end	
		end	
	end
	if lst_errors.length > 0
		@@lst_files_error += lst_errors
	else
		delta = ((Time.now - t0) * 1000).to_i
		LibFredo6.log "#{@plugin_name} #{@version}: Bootstrap Ruby files loaded         [#{delta} ms]" if @loaded_bootstrap.length > 0
	end
	@loaded_bootstrap.length > 0
end

#Load all other rubies
def load_full_rubies
	t0 = Time.now
	@loaded_rubys = []
	@lst_ruby_files = "*" if @lst_ruby_files.length == 0
	lst_errors = []
	@lst_ruby_files.each do |rb|
		rb += '.rb' unless rb =~ /\.rb\Z/i
		Dir[File.join(@plugin_dir, rb)].each do |f| 
			bf = File.basename(f)
			begin
				status = require f
				@loaded_rubys.push bf if status
			rescue Exception => e
				err = LibFredo6.mask_dir e.message
				LibFredo6.log "?#{@plugin_name} #{@version}: ERROR in Loading ruby file #{bf}", err
				lst_errors.push bf
			end	
		end	
	end	
	if lst_errors.length > 0
		@@lst_files_error += lst_errors
	else
		delta = ((Time.now - t0) * 1000).to_i
		LibFredo6.log "#{@plugin_name} #{@version}: Ruby files loaded         [#{delta} ms]" if @loaded_rubys.length > 0
	end
	@fully_loaded = true
end

#Second phase loading of rubies
def load_second_phase_rubies
	return if @fully_loaded
	
	Sketchup.set_status_text T6[:T_HELP_LoadingModules, @plugin_name]
	t0 = Time.now.to_f
	@@lst_files_error = []
	load_full_rubies
	@load_time_second = Time.now.to_f - t0
	AllPlugins.register @plugin_name, { :load_time_second => @load_time_second }
	text = "#{(@load_time_second * 1000.0).to_i} ms"
	Sketchup.set_status_text T6[:T_HELP_LoadedModules, @plugin_name, text]
end

#Find the list of plugins to load and load them
def Plugin.load_all_plugins
	@@lst_files_error = []
	t0 = Time.now.to_f
	hsh_plug = {}
	Dir[File.join(LibFredo6.sudir, "*_Dir_*")].each do |f|
		s = File.basename f
		next unless s =~ /\A(.+)_Dir_(\d\d)/i
		lplu = Dir[File.join(f, "*.plugin")]
		next if lplu.empty?
		pluname = File.basename lplu[0], ".plugin"
		key = $1
		next if key == "LIBFREDO6"
		oldver = hsh_plug[key] 
		if oldver
			hsh_plug[key][1] = s if s > oldver[1]
		else
			hsh_plug[key] = [pluname, s]
		end	
	end	
	
	#Loading the plugins
	lplug = hsh_plug.values.sort { |a, b| a[0] <=> b[0] }
	lplug.each { |a| Traductor::Plugin.new.load_from_config *a }
	Plugin.average_load_time true
	
	#Signaling errors
	#@@timer_error_id = UI.start_timer(0, false) { Plugin.signal_error_in_loading }
	
	lplug
end

#Signal the errors in Plugins loading phase
def Plugin.signal_error_in_loading
	#UI.stop_timer @@timer_error_id if @@timer_error_id
	return unless @@lst_files_error.length > 0
	T6[:MSG_Error_LoadingRuby] = "The following files are in ERROR and cannot be loaded:"
	T6[:MSG_Error_OpenTraceLog] = "Do you want to open the Trace Log?"
	text = "Message from LibFredo6\n\n"
	text += T6[:MSG_Error_LoadingRuby] + "\n" + @@lst_files_error.join("\n") + "\n\n" + T6[:MSG_Error_OpenTraceLog]
	status = UI.messagebox text, MB_YESNO
	if status == 6
		TraceLogDialog.invoke
	end	
end

end	#class Plugin

#For troubleshooting purpose
def Traductor.trace6(*args)
	unless @@file_trace6
		file = File.join LibFredo6.sudir, "Fredo6Trace.txt"
		@@file_trace6 = File.open(file, "w")
		@@file_trace6.puts "RUBY_PLATFORM = #{RUBY_PLATFORM}"
	end
	@@file_trace6.puts *args
	@@file_trace6.flush
end

#--------------------------------------------------------------------------------------------------------------
# Mixin module MixinCallBack: 
#     - mechanism of sub classing callback
#     - Common methods to ALL tools 
#--------------------------------------------------------------------------------------------------------------			 

module MixinCallBack

#Register the caller class instance
def _register_caller(caller)
	@_calleR = caller
end

#Call the caller methgod, with convention 'sub_xxxx'
def _sub(func, *args)
	return unless @_calleR && func
	smeth = 'sub_' + func.to_s
	symb = smeth.intern
	if @_calleR.respond_to? symb
		return @_calleR.send(symb, *args)
	elsif self.respond_to? symb
		return self.send(symb, *args)
	elsif block_given?
		return yield
	end	
	nil
end

end	#mixin module MixinCallBack

end	#module Traductor

	