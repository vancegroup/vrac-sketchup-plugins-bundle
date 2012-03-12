=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed April / August 2008 by Fredo6

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   Zloader__OnSurface.rb
# Original Date	:   04 June 2008 - version 1.2
#				:	12 July 2008 - version 1.3 (new config for installation)
#				:	20 Aug 2008 - version 1.4 
#				:	20 Jul 2009 - version 1.5 
# Description	:   Declaring for the Suite of Tools to draw on a surface as a Sketchup extension
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

fro6__plugin = "ToolsOnSurface"
fro6__dir = "TOS_Dir_18"

begin
	require 'LibFredo6.rb'
rescue
	unless @fro6__url
		@fro6__url = "http://forums.sketchucation.com/viewtopic.php?f=323&t=17947#p144178"
		case Sketchup.get_locale
		when /\AFR/i
			text = "Probl\ème avec l'installation du plugin #{fro6__plugin}"
			text += "\nLibFredo6 n'est pas install\é ou bien n'est pas dans le bon dossier\nConsulter"
		else	
			text = "Problem with the installation of plugin #{fro6__plugin}"
			text += "\nLibFredo6 is not installed or not in the right location\nPlease see"
		end
		text += ' ' + @fro6__url
		UI.messagebox text
	end	
end	

begin
	LibFredo6.register_plugin fro6__plugin, fro6__dir
rescue
end
