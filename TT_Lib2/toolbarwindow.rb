#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'TT_Lib2/core.rb'
require 'TT_Lib2/window.rb'

# (i) Alpha stage. Very likely to be subject to change!
#
# @example
#   w = TT::GUI::Toolbar.new
#   w.show_window
#
# @deprecated Not in use
# @since 2.5.0
class TT::GUI::Toolbar < TT::GUI::ToolWindow

	
	# @return <nil>
	# @since 2.5.0
	def initialize(*args)
    super
    self.add_style( File.join(TT::Lib.path, 'webdialog', 'css', 'wnd_toolbar.css') )
	end
  
  def add_control( control )
    raise ArgumentError unless button.is_a?( TT::GUI::Button )
  end


end # module TT::GUI::Window