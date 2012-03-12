#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright 2004, @Last Software, Inc.
# Updated Dec. 2007 by Fredo6

# This software is provided as an example of using the Ruby interface to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name		:   Bezierspline.rb
# Type		:   Sketchup Tool
# Description	:   A tool to create and edit Bezier, Cubic Bezier, Polyline and other mathematical curves.
# Menu Item	:   Draw --> one menu item for each curve type
# Context Menu	:   Edit xxx Curve, Convert to xxx curve
# Usage		:   See Tutorial on  'Bezierspline' in PDF format
# Initial Date	:   10 Dec 2007 (original Bezier.rb 8/26/2004)
# Releases		:   08 Jan 2008 -- fixed some bugs in inference drawing
#			:   17 Oct 2008 -- fixed other bugs, cleanup menu and more flexible on icons
# Credits	           ;   CadFather for the toolbar icons
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

require 'sketchup.rb' 
require 'extensions.rb' 

module JointPushPull

@@name = "JointPushPull"
@@version = "2.0b"
@@folder = "JPP_Dir_20"
@@sdate = "17 Jul 11"
@@creator = "Fredo6"
@@url = "http://forums.sketchucation.com/viewtopic.php?f=323&t=6708#p42783"

if Sketchup.get_locale == "FR"
	@@description = "Push Pull: jointif, par vecteur et par normal" 
else
	@@description = "Push Pull: Joint, by Vector and by Normal" 
end	

path = File.join(File.dirname(__FILE__), @@folder, "jointpushpull_main.rb") 
ext = SketchupExtension.new(@@name, path) 
ext.description = @@description
ext.creator = @@creator 
ext.version = @@version + " - " + @@sdate 
ext.copyright = @@creator + " - \© 2008-2011" 
Sketchup.register_extension ext, true

def JointPushPull.register_plugin_for_LibFredo6 
	{	
		:name => @@name,
		:author => @@creator,
		:version => @@version,
		:date => @@sdate,	
		:description => @@description,
		:link_info => @@url
	}
end

end #Module JoinPushPull


