#-----------------------------------------------------------------------------
# Compatible: SketchUp 7 (PC)
#             (other versions untested)
#-----------------------------------------------------------------------------
#
# CHANGELOG
# 1.0.0 - 13.09.2010
#		 * Initial release.
#
#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'TT_Lib2/core.rb'

TT::Lib.compatible?('2.0.0', 'TT Exporter')

#-----------------------------------------------------------------------------

module TT::Plugins::Exporter  
  
  ### CONSTANTS ### --------------------------------------------------------
  
  VERSION = '1.0.1'
  
  
  ### MODULE VARIABLES ### -------------------------------------------------
  
  # Preference
  @settings = TT::Settings.new('TT_Exporter')
  @settings[:width,  800]
  @settings[:height, 600]
  @settings[:aa, false]
  @settings[:compression, 0.9]
  @settings[:transparent, true]
  
  
  ### MENU & TOOLBARS ### --------------------------------------------------
  
  unless file_loaded?( File.basename(__FILE__) )
    m = TT.menu('View')
    m.add_item('Export 2D') { self.export_current_view }
  end
  
  
  ### MAIN SCRIPT ### ------------------------------------------------------
  
  def self.export_current_view
    # Convert default settings to user friendly format
    s = @settings
    aa = ( s[:aa] ) ? 'Yes' : 'No'
    transparent = ( s[:transparent] ) ? 'Yes' : 'No'
    
    # Prompts for settings
    prompts = ['Width', 'Height', 'Antialias', 'Compression', 'Transparent']
    defaults = [ s[:width], s[:height], aa, s[:compression], transparent ]
    lists = ['', '', 'Yes|No', '', 'Yes|No']
    results = UI.inputbox(prompts, defaults, lists, 'Export Settings')
    return if results == false
    width, height, aa, compression, transparent = results
    p results
    
    # Convert default settings to computer format
    aa = (aa == 'Yes')
    transparent = (transparent == 'Yes')
    
    # Prompt for file
    filename = UI.savepanel('Export Current View in 2D')
    return if filename.nil?
    
    # Export Image
    options = {
      :filename     => filename,
      :width        => width,
      :height       => height,
      :antialias    => aa,
      :compression  => compression,
      :transparent  => transparent
    }
    p options
    Sketchup.active_model.active_view.write_image(options)
  end
  
  
  ### DEBUG ### ------------------------------------------------------------
  
  def self.reload
    load __FILE__
  end
  
end # module

#-----------------------------------------------------------------------------
file_loaded( File.basename(__FILE__) )
#-----------------------------------------------------------------------------