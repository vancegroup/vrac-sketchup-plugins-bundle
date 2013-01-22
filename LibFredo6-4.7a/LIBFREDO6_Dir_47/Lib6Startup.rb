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
# Name			:  Lib6Startup.rb
# Original Date	:  10 Dec 2008 - version 3.0
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library including the startup methods for Shared Library LibFredo6
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

#Language Strings for LibFredo6 modules
T6[:T_STR_LibFredo6_Settings] = "LibFredo6 Settings..."
T6[:T_DEFAULT_SECTION_Plugin] = "Plugin Configuration"
T6[:T_DEFAULT_IconVisible] = "Icons visible in the toolbar"
T6[:T_DEFAULT_HandlerVisible] = "Menus activated in the Selection contextual menu"
T6[:T_DEFAULT_TopMenu] = "Top Menu"
T6[:T_DEFAULT_ToolbarName] = "Toolbar name"
T6[:T_DEFAULT_CheckForUpdateSection] = "Check for Update"
T6[:T_DEFAULT_CheckOnlyInstalled] = "Check only Plugins installed locally"
T6[:T_DEFAULT_DurationNextCheck] = "Next Check in (days)"
T6[:T_DEFAULT_MaintenanceSection] = "Plugin Maintenance Utilities"
T6[:T_DEFAULT_TraceLogNbmax] = "Number of Trace log files kept"
T6[:T_DEFAULT_DebugLogNbmax] = "Number of Debug log files kept"
T6[:T_DEFAULT_DebugShowMenu] = "Show Menu for Debug log files"

#--------------------------------------------------------------------------------------------------------------
# STARTUP Routines for LibFredo6
#--------------------------------------------------------------------------------------------------------------			 

#Initialize Default parameters and menus for LibFredo6 Plugin
def Traductor.startup
	Langue.load_file
	T6Mod.init_langpref
	
	Traductor.load_def_param	
	
	cmdfamily = CommandFamily.new LibFredo6.path, "Window", T6[:T_STR_LibFredo6_Settings], nil, true
	MYPLUGIN.populate_support_menu cmdfamily, nil, "LibFredo6"
	
	Traductor::CustomMenu.register :T_MenuTools_Fredo6Collection, "Fredo6 Collection", "Tools", true
	Traductor::CustomMenu.register :T_MenuPlugins_Fredo6Collection, "Fredo6 Collection", "Plugins", true
	Traductor::CustomMenu.register :T_MenuDraw_Fredo6Collection, "Fredo6 Collection", "Draw", true
	
	MaterialManager.manager
end

#Default Parameter for LibFredo6 Shared Library
def Traductor.load_def_param
	dp = MYDEFPARAM

	#alternate folders for icons, cursor and images
	dp.separator :T_DEFAULT_SECTION_Plugin
	dp.alternate_icon_dir :T_ICON_Dir, "", MYPLUGIN.picture_all_folders
	MYPLUGIN.declare_picture_folders_symb(:T_ICON_Dir)

	#Inference precision and colors
	dp.separator :T_DEFAULT_InferenceSection
	dp.declare :T_DEFAULT_InferencePrecision, 10, 'I:>=5<=50'
	dp.declare :T_DEFAULT_InferenceColor_None, "Black", "K"
	dp.declare :T_DEFAULT_InferenceColor_Collinear, "DeepPink", "K"
	dp.declare :T_DEFAULT_InferenceColor_Perpendicular, "Brown", "K"

	#Check for Update
	dp.separator :T_DEFAULT_CheckForUpdateSection
	dp.declare :T_DEFAULT_CheckOnlyInstalled, true, 'B'
	dp.declare :T_DEFAULT_DurationNextCheck, 15, 'F:>=0<=999'

	#Plugin Utilities
	dp.separator :T_DEFAULT_MaintenanceSection
	dp.declare :T_DEFAULT_TraceLogNbmax, 20, 'I:>=5<=50'
	dp.declare :T_DEFAULT_DebugShowMenu, false, 'B'
	dp.declare :T_DEFAULT_DebugLogNbmax, 10, 'I:>=5<=50'
	
	#Palette Default parameter
	Palette.config_default_parameters
	
	#Loading the default parameter file
	dp.load_file
end
	
#Folder containing the LibFredo6 library files	
def Traductor.version
	LibFredo6.folder
end

end #Module Traductor

