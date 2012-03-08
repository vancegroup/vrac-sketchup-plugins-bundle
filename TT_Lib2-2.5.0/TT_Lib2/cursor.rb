#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'TT_Lib2/core.rb'

# @since 2.4.0
module TT::Cursor
  
  # Path to the cursor resources.
  PATH = File.join( TT::Lib.path, 'cursors')
  
  # Definitions of cursor resources.
  # :symbol_id => ['filename.png', x, y]
  @cursors = {
    :default          => 0,
    :offset           => ['offset.png',            8,  6],
    :offset_invalid   => ['offset_invalid.png',    8,  6],
    :dropper          => ['dropper.png',           2, 29],
    :dropper_invalid  => ['dropper_invalid.png',   2, 29],
    :select           => ['select.png',            3,  8],
    :select_add       => ['select_add.png',        3,  8],
    :select_remove    => ['select_remove.png',     3,  8],
    :select_toggle    => ['select_toggle.png',     3,  8],
    :vertex           => ['Vertex.png',           12, 19],
    :vertex_add       => ['Vertex_Add.png',       12, 19],
    :vertex_remove    => ['Vertex_Remove.png',    12, 19],
    :vertex_toggle    => ['Vertex_Toggle.png',    12, 19],
    :rectangle        => ['rectangle.png',         1, 30],
    :move             => ['move.png',             15, 15],
    :rotate           => ['rotate.png',           11, 20],
    :scale            => ['scale.png',             5,  9]
  }
  
  # Creates cursor ids for the requested cursor +id+. Cursors are created on demand and
  # reused to save resources.
  #
  # Valid +id+ arguments
  # * +:default+
  # * +:offset+
  # * +:offset_invalid+
  # * +:dropper+
  # * +:dropper_invalid+
  # * +:select+
  # * +:select_add+
  # * +:select_remove+
  # * +:select_toggle+
  # * +:vertex+ (2.5.0)
  # * +:vertex_add+ (2.5.0)
  # * +:vertex_remove+ (2.5.0)
  # * +:vertex_toggle+ (2.5.0)
  # * +:rectangle+ (2.6.0)
  # * +:move+ (2.6.0)
  # * +:rotate+ (2.6.0)
  # * +:scale+ (2.6.0)
  #
  # @param [Symbol] id
  #
  # @return [Integer, nil] +Integer+ of a cursor resource uon success, +nil+ upon failure.
  #
  # @since 2.4.0
  def self.get_id(id)
    return nil unless @cursors.key?(id)
    # Load cursors on demand
    if @cursors[id].is_a?(Array)
      cursor_file, x, y = @cursors[id]
      filename = File.join( TT::Cursor::PATH, cursor_file )
      @cursors[id] = UI.create_cursor( filename, x, y )
    end
    return @cursors[id]
  end
 
end # module TT::Cursor