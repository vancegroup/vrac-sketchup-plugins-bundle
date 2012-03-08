#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'TT_Lib2/core.rb'

# ...
#
# @since 2.4.0
module TT::Binary
  
  # Base64 encodes binary data.
	#
	# @param [Mixed] data
	#
	# @return [String]
	# @since 2.4.0
  def self.encode64(data)
		return [data].pack('m')
	end
	
  
  # Decodes Base64 strings.
	#
	# @param [String] string
	#
	# @return [Mixed]
	# @since 2.4.0
	def self.decode64(string)
		return string.unpack('m')[0]
	end
  
end # module TT::Binary