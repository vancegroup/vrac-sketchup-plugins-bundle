#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'TT_Lib2/core.rb'

# Javascript helper module.
#
# @since 2.5.0
module TT::Javascript
  
  # Query to whether it's a Group or ComponentInstance
	#
	# @param [Object] object
	#
	# @return [String]
	# @since 2.5.0
  def self.to_js(object, format=false)
    if object.is_a?( TT::JSON )
      object.to_s(format)
    elsif object.is_a?( Hash )
      TT::JSON.new(object).to_s(format)
    elsif object.is_a?( Symbol ) # 2.5.0
      object.inspect.inspect
    elsif object.nil?
      'null'
    else
      # (!) Filter out accepted objects.
      # (!) Convert unknown into strings - then inspect.
      object.inspect
    end
  end
  
end # module TT::Javascript