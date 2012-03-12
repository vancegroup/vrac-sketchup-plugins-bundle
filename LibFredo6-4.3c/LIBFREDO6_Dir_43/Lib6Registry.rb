=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Dec. 2008 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Registry.rb
# Original Date	:  20 Jan 2011
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library to store and retrieve parameters in the SU Registry.
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

class Registry

#--------------------------------------------------------------------------------------------------------------
# GNEREIC routines
#--------------------------------------------------------------------------------------------------------------			 

def Registry.store(regkey, *args)
	Sketchup.write_default "libFredo6", regkey, args.join(';')
end

def Registry.load(regkey)
	param = Sketchup.read_default "libFredo6", regkey
	return nil unless param && param.length > 0
	param
end

#--------------------------------------------------------------------------------------------------------------
# Web Dialog
#--------------------------------------------------------------------------------------------------------------			 

#Store the size of the screen display in registry
def Registry.browser_info_store(*args)
	Registry.store "WDLG6-SCREEN", *args
end

#Store the size of the screen display in registry
def Registry.browser_info_load()
	param = Registry.load "WDLG6-SCREEN"
	return nil unless param
	param = param.split ';'
	browser, sw, sh = param
	[browser, sw.to_i, sh.to_i]
end

#Store the position and size of a Wldg in the registry under key
def Registry.wposition_store(key, *args)
	Registry.store "WDLG6-" + key, *args
end

#Load the position and size of a Wldg in the registry under key - Returns [xpos, ypos, sx, sy]
def Registry.wposition_load(key)
	param = Registry.load "WDLG6-" + key
	return [100, 100, 100, 100] unless param
	param = param.split(';').collect { |a| a.to_i }
	param
end

end #Class Registry

end #Module Traductor
