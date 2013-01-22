=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Apr. 2011 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6_API.rb
# Original Date	:  04 Apr 2011
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  Expose the official external APIs 
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module LibFredo6

#--------------------------------------------------------------------------------------------------------------------------------
#  LibFredo6.register_ruby
#
# Register a Ruby script when an interactive tool is launched
# This associates a name to the ruby tool ID (maintained in an internal hash table
#
# Argument:
#  - <ruby> --> name of the Ruby script

# Usage:
# - to be invoked in the Activate method of the tool class
#--------------------------------------------------------------------------------------------------------------------------------

def LibFredo6.register_ruby(ruby=nil)
	Traductor::Ruby.register_ruby ruby
end

end	#Module LibFredo6
