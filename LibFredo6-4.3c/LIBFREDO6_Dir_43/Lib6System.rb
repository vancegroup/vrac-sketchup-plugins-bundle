=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright © 2011 Fredo6 - Designed and written Avril 2011 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6System.rb
# Original Date	:  10 Avr 2011
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library to assist system calls from Ruby
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end


module Traductor

#--------------------------------------------------------------------------------------------------------------
# File management methods
#--------------------------------------------------------------------------------------------------------------

#Open a document or URL address
def Traductor.open_doc(filename)
	w = UI::openURL "file://" + filename
end

#Return a temporary Directory
def Traductor.temp_dir
	(RUN_ON_MAC) ? "/tmp" : ENV["TEMP"].gsub(/\\/, '/')
end

#Open a URL
def Traductor.openURL(path)
	return unless path
	path = path.strip
	return if path.empty?
	return UI.openURL(path) if path =~ /:\/\//
	path = "file://" + path if RUN_ON_MAC
	UI.openURL path
end

#Test a directory, either an absolute path, or a path related to the $: environment constnat
def Traductor.test_directory(dir)
	#Full path given
	return dir if FileTest.directory?(dir)
		
	#Checking $: environment	
	$:.each do |d|
		path = File.join d, dir
		return path if FileTest.directory?(path)
	end
	nil
end
	
#Compute th relative path of a path given a reference directory
def Traductor.relative_path(path, ref_path=nil)
	return path unless ref_path && ref_path.length > 0
	return ref_path unless path && path.length > 0
	
	path = File.expand_path path
	ref_path = File.expand_path ref_path
	
	lpath = path.split '/'
	lrfpath = ref_path.split '/'
	
	#Finding common elements
	nrf = lrfpath.length - 1
	ic = nil
	for i in 0..nrf
		if (lrfpath[i] != lpath[i])
			ic = i
			break
		end				
	end
	
	#Assembling the path
	return path unless ic && ic > 0
	relpath = Array.new(nrf-ic+1, '..') + lpath[ic..-1]
	File.join relpath
end
	
#Run a system shell command in silent mode
#Command is passed as one or several arguments, which will be joined by a single space
#Note: This avoids the black window in Windows
def Traductor.run_shell_command(cmd, &end_proc)
	puts "end proc = #{end_proc}"
	
	#Generating the VB script on Windows
	unless RUN_ON_MAC
		fvbs = File.join Traductor.temp_dir, "LibFredo_Shell.vbs"
		File.open fvbs, "w" do |f|
			f.puts "Set WshShell = CreateObject(\"WScript.Shell\")"
			f.puts "WshShell.Run \"#{cmd}\", 0"
			puts "WshShell.Run \"#{cmd}\", 0"
			f.puts "Set WshShell = Nothing"
		end
		cmd = "wscript #{fvbs}"
	end	
	
	#Syncrhonous call
	puts "proc = #{end_proc}"
	return system(cmd) unless end_proc
	
	#Asyncrhonous
	t = Thread.start do
		status = system("wscript #{fvbs}") 
		puts "end Thread"
		yield status
		puts "end yield"
	end	
	puts "after POPEN"
end
	
def Traductor.finish(t)
	puts "FINISH #{t}"
	t.kill
end
	
#Download a URL as text into a file
#Return nil if failed, and the local_file is successful
def Traductor.download_from_url(url, local_file=nil, &end_proc)	
	if (RUN_ON_MAC) 
		curl = "curl" 
	else
		curl = File.join(MYPLUGIN.plugin_dir, "Ancillary", "curl_win.exe")
		return nil unless FileTest.exist? curl
	end
	
	local_file = File.join Traductor.temp_dir, "curl_temp.tmp" unless local_file
	
	cmd = "#{curl} -L -k -o \"\"#{local_file}\"\" \"\"#{url}\"\""
	File.unlink local_file if FileTest.exist?(local_file)
	
	if end_proc
		status = Traductor.run_shell_command(cmd) do |status|
			Traductor.download_from_url_notify(status) do
				end_proc.call((FileTest.exist?(local_file)) ? local_file : nil)
			end
		end	
	else
		status = Traductor.run_shell_command cmd
	end
	(status) ? local_file : nil
end

def Traductor.download_from_url_notify(status, &proc)
	puts "URL notify status = #{status}"
	yield
end

end #Module Traductor

