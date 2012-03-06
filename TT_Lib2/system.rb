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
module TT::System
  
  # @since 2.5.0
  PLATFORM_IS_OSX     = (Object::RUBY_PLATFORM =~ /darwin/i) ? true : false
  
  # @since 2.5.0
  PLATFORM_IS_WINDOWS = !PLATFORM_IS_OSX
  
  # @since 2.5.5
  TEMP_PATH = File.expand_path( ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] ).freeze
  
  # @return [Boolean]
  # @since 2.4.0
  def self.is_osx?
    PLATFORM_IS_OSX
  end
  
  # @return [Boolean]
  # @since 2.5.0
  def self.is_windows?
    PLATFORM_IS_WINDOWS
  end
  
  # Returns path to the user's temp path.
  #
  # @return [String]
  # @since 2.4.0
  def self.temp_path
    TEMP_PATH.dup
  end
  
end # module TT::System