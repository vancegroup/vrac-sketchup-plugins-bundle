#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'TT_Lib2/core.rb'
require 'TT_Lib2/win32.rb'

module TT  
  
  # Outputs debug data.
  #
  # Under Windows the data is sent to OutputDebugString and
  # requires a utility like DebugView to see the data. Without it the call
  # is muted.
  #
  # Under other platforms the data is sent to the console.
	#
	# @param [Mixed] data
	#
	# @return [Nil]
	# @since 2.5.0
  def self.debug(data)
    if data.is_a?( String )
      str = data
    else
      str = data.inspect
    end
    if TT::System.is_windows?
      TT::Win32::OutputDebugString.call( "#{str}\0" )
    else
      puts data
    end
    nil
  end
  
end # module TT