#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

require 'TT_Lib2/core.rb'

# @deprecated Unfinished
# @since 2.6.0
module TT::Gizmo

  # @deprecated Unfinished
	# @since 2.6.0
  class Manipulator
    
    CLR_X_AXIS    = Sketchup::Color.new( 255,   0,   0 )
    CLR_Y_AXIS    = Sketchup::Color.new(   0, 128,   0 )
    CLR_Z_AXIS    = Sketchup::Color.new(   0,   0, 255 )
    CLR_SELECTED  = Sketchup::Color.new( 255, 255,   0 )
    
    attr_reader( :origin )
    
    # @param [Geom::Point3d] origin
    # @param [Geom::Vector3d] xaxis
    # @param [Geom::Vector3d] yaxis
    # @param [Geom::Vector3d] zaxis
    #
    # @since 2.6.0
    def initialize( origin, xaxis, yaxis, zaxis )
      # Event callbacks
      @callback = nil
      @callback_start = nil
      @callback_end = nil
      
      # Origin
      @origin = origin
      
      # Set up axis and events
      @axes = []
      @axes << TT::Gizmo::Axis.new( @origin, xaxis, CLR_X_AXIS, CLR_SELECTED )
      @axes << TT::Gizmo::Axis.new( @origin, yaxis, CLR_Y_AXIS, CLR_SELECTED )
      @axes << TT::Gizmo::Axis.new( @origin, zaxis, CLR_Z_AXIS, CLR_SELECTED )
      
      @active_axis = nil
      
      for axis in @axes
        axis.on_transform_start { |axis|
          @callback_start.call unless @callback_start.nil?
        }
        axis.on_transform_end { |axis|
          @callback_end.call unless @callback_end.nil?
        }
        axis.on_transform { |axis, t_increment, t_total|
          @origin = axis.origin
          update_axes( axis.origin, axis )
          @callback.call( t_increment, t_total ) unless @callback.nil?
        }
      end
      
      # (!) ScaleGizmo
      
      #update()
    end
    
    # @return [Boolean]
    # @since 2.6.0
    def active?
      !@active_axis.nil?
    end
    
    # @since 2.6.0
    def tooltip
      for axis in @axes
        return axis.tooltip if axis.mouse_active?
      end
      ''
    end
    
    # @return [Geom::Vector3d]
    # @since 2.6.0
    def normal
      @axes.z.direction
    end
    
    # @param [Sketchup::View] view
    #
    # @return [Nil]
    # @since 2.6.0
    def resume( view )
      #update()
    end
    
    # @since 2.6.0
    def on_transform( &block )
      @callback = block
    end
    
    # @since 2.6.0
    def on_transform_start( &block )
      @callback_start = block
    end
    
    # @since 2.6.0
    def on_transform_end( &block )
      @callback_end = block
    end
    
    # @param [Geom::Point3d] new_origin
    #
    # @return [Geom::Point3d]
    # @since 2.6.0
    def origin=( new_origin )
      @origin = new_origin
      for axis in @axes
        axis.origin = new_origin
      end
      #update()
      new_origin
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onMouseMove( flags, x, y, view )
      if @active_axis
        @active_axis.onMouseMove( flags, x, y, view )
        return true
      else
        for axis in @axes
          return true if axis.onMouseMove( flags, x, y, view )
        end
      end
      false
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onLButtonDown( flags, x, y, view )
      for axis in @axes
        if axis.onLButtonDown( flags, x, y, view )
          @active_axis = axis
          return true 
        end
      end
      false
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onLButtonUp( flags, x, y, view )
      for axis in @axes
        if axis.onLButtonUp( flags, x, y, view )
          @active_axis = nil
          return true
        end
      end
      false
    end
    
    # @param [Sketchup::View] view
    #
    # @return [Nil]
    # @since 2.6.0
    def draw( view )
      for axis in @axes
        axis.draw( view )
      end
      nil
    end
    
    private
    
    # @param [Geom::Point3d] origin
    # @param [TT::Gizmo::Axis] ignore_axis
    #
    # @return [Nil]
    # @since 2.6.0
    def update_axes( origin, ignore_axis )
      for a in @axes
        next if a == ignore_axis
        a.origin = origin
      end
      nil
    end
    
  end # class Manipulator
  
  
  # @deprecated Unfinished
	# @since 2.6.0
  class Axis
  
    LENGTH = 110 # Pixels
    
    attr_accessor( :origin, :direction )
    
    # @param [Geom::Point3d] origin
    # @param [Geom::Vector3d] direction
    # @param [Sketchup::Color] color
    # @param [Sketchup::Color] active_color
    #
    # @since 2.6.0
    def initialize( origin, direction, color, active_color )
      @origin = origin.clone
      @direction = direction.clone
      @color = color
      @active_color = active_color
      
      # Event callbacks
      @callback = nil
      @callback_start = nil
      @callback_end = nil
      
      # MoveGizmo
      @move_gizmo = MoveGizmo.new( origin, direction, color, active_color )
      @move_gizmo.on_transform_start { |gizmo|
        @callback_start.call( self ) unless @callback_start.nil?
      }
      @move_gizmo.on_transform { |gizmo, t_increment, t_total|
        @origin = gizmo.origin
        @rotate_gizmo.origin = gizmo.origin
        @callback.call( self, t_increment, t_total ) unless @callback.nil?
      }
      @move_gizmo.on_transform_end { |gizmo|
        @callback_end.call( self ) unless @callback_end.nil?
      }
      
      # RotateGizmo
      @rotate_gizmo = RotateGizmo.new( origin, direction, color, active_color )
      @rotate_gizmo.on_transform_start { |gizmo|
        @callback_start.call( self ) unless @callback_start.nil?
      }
      @rotate_gizmo.on_transform { |gizmo, t_increment, t_total|
        @callback.call( self, t_increment, t_total ) unless @callback.nil?
      }
      @rotate_gizmo.on_transform_end { |gizmo|
        @callback_end.call( self ) unless @callback_end.nil?
      }
      
      @selected = false
    end
    
    # @since 2.6.0
    def on_transform( &block )
      @callback = block
    end
    
    # @since 2.6.0
    def on_transform_start( &block )
      @callback_start = block
    end
    
    # @since 2.6.0
    def on_transform_end( &block )
      @callback_end = block
    end
    
    # @return [Boolean]
    # @since 2.6.0
    def active?
      @move_gizmo.active? || @rotate_gizmo.tooltip
    end
    
    # @since 2.6.0
    def tooltip
      if @move_gizmo.mouse_active?
        @move_gizmo.tooltip
      elsif @rotate_gizmo.mouse_active?
        @rotate_gizmo.tooltip
      else
        ''
      end
    end
    
    # @return [Boolean]
    # @since 2.6.0
    def selected?
      @selected == true
    end
    
    # @return [Boolean]
    # @since 2.6.0
    def mouse_active?
      @mouse_active == true
    end
    
    # @param [Geom::Point3d] new_origin
    #
    # @return [Geom::Point3d]
    # @since 2.6.0
    def origin=( new_origin )
      @origin = new_origin.clone
      @move_gizmo.origin = @origin
      @rotate_gizmo.origin = @origin
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onLButtonDown( flags, x, y, view )
      if @move_gizmo.onLButtonDown( flags, x, y, view )
        true
      elsif @rotate_gizmo.onLButtonDown( flags, x, y, view )
        true
      elsif @selected
        @interacting = true
        # (!) ...
        @callback_start.call( self ) unless @callback_start.nil?
        true
      else
        false
      end
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onLButtonUp( flags, x, y, view )
      if @move_gizmo.onLButtonUp( flags, x, y, view )
        true
      elsif @rotate_gizmo.onLButtonUp( flags, x, y, view )
        true
      elsif @interacting
        # (!) ...
        @callback_end.call( self ) unless @callback_end.nil?
        @interacting = false
        true
      else
        @interacting = false
        false
      end
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onMouseMove( flags, x, y, view )
      if @interacting
        # (!) ...
        @mouse_active = true
        true
      else
        @selected = false
        if @move_gizmo.onMouseMove( flags, x, y, view )
          @mouse_active = true
          view.invalidate
          return true
        elsif @rotate_gizmo.onMouseMove( flags, x, y, view )
          @mouse_active = true
          view.invalidate
          return true
        elsif mouse_over?( x, y, view )
          @mouse_active = true
          @selected = true
          view.invalidate
          return true
        end
        @mouse_active = false
        false
      end
    end
    
    # @param [Sketchup::View] view
    #
    # @return [Nil]
    # @since 2.6.0
    def draw( view )
      segment = modelspace_segment( view )
      segment2d = segment.map { |point| view.screen_coords( point ) }
      
      view.line_stipple = ''
      view.line_width = 2
      view.drawing_color = (@selected) ? @active_color : @color
      view.draw2d( GL_LINES, segment2d )
      
      @move_gizmo.draw( view )
      @rotate_gizmo.draw( view )
    end
    
    private

    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def mouse_over?( x, y, view )
      segment = modelspace_segment( view )
      ph = view.pick_helper
      result = ph.pick_segment( segment, x, y, 10 )
      !( result == false ) # Cast .pick_segment result into true/false.
    end
    
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def modelspace_segment( view )
      model_length = view.pixels_to_model( LENGTH, @origin )
      [ @origin, @origin.offset( @direction, model_length ) ]
    end
    
  end # class Axis
  
  
  # @deprecated Unfinished
	# @since 2.6.0
  class MoveGizmo
  
    attr_accessor( :origin, :direction )
    
    # @param [Geom::Point3d] origin
    # @param [Geom::Vector3d] direction
    # @param [Sketchup::Color] color
    # @param [Sketchup::Color] active_color
    #
    # @since 2.6.0
    def initialize( origin, direction, color, active_color )
      @origin = origin.clone
      @direction = direction.clone
      @color = color
      @active_color = active_color
      
      @selected = false
      @interacting = false
      
      # Cache of the axis origin and orientation. Cached on onLButtonDown
      @old_origin = nil
      @old_vector = nil
      @old_axis = nil # [pt1, pt2]
      
      # User InputPoint
      @ip = Sketchup::InputPoint.new
      
      @pt_start = nil # Startpoint - IP projected to selected axis
      @pt_screen_start = nil # Screen projection of @pt_start
      
      @pt_mouse = nil # Mouse Point3d - projected to selected axis
      @pt_screen_mouse = nil
      
      # Event callbacks
      @callback = nil
      @callback_start = nil
      @callback_end = nil
    end
    
    # @since 2.6.0
    def on_transform( &block )
      @callback = block
    end
    
    # @since 2.6.0
    def on_transform_start( &block )
      @callback_start = block
    end
    
    # @since 2.6.0
    def on_transform_end( &block )
      @callback_end = block
    end
    
    # @return [Boolean]
    # @since 2.6.0
    def active?
      @interacting == true
    end
    
    # @return [Boolean]
    # @since 2.6.0
    def mouse_active?
      @mouse_active == true
    end
    
    # @since 2.6.0
    def tooltip
      'Move'
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onLButtonDown( flags, x, y, view )
      if @selected
        @interacting = true
        
        # Cache the origin for use in onMouseMove to work out the distance
        # moved.
        @old_origin = @origin.clone
        @old_axis = [ @origin, @origin.offset( @direction, 10 ) ] # Line (3D)
        
        # Get input point closest to the selected axis
        ip = view.inputpoint( x, y )
        @pt_start = ip.position.project_to_line( [@origin, @direction] )
        
        # Project to screen axis
        screen_point = Geom::Point3d.new( x, y, 0 )
        screen_axis = screen_points( @old_axis, view )
        @pt_screen_start = screen_point.project_to_line( screen_axis )
        
        @callback_start.call( self ) unless @callback_start.nil?
        true
      else
        false
      end
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onLButtonUp( flags, x, y, view )
      if @interacting
        @ip.clear
        @callback_end.call( self ) unless @callback_end.nil?
        @interacting = false
        true
      else
        @interacting = false
        false
      end
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onMouseMove(flags, x, y, view)
      if @interacting
        @mouse_active = true
        move_event( x, y, view ) # return true
      else
        @selected = mouse_over?( x, y, view )
        @mouse_active = @selected
      end
    end
    
    # @param [Sketchup::View] view
    #
    # @return [Nil]
    # @since 2.6.0
    def draw( view )
      segments = arrow_segments( view )
      
      # Edges
      view.line_stipple = ''
      view.line_width = 2
      view.drawing_color = (@selected) ? @active_color : @color
      for segment in segments
        screen_points = segment.map { |point| view.screen_coords( point ) }
        view.draw2d( GL_LINE_STRIP, screen_points )
      end
      
      # Fill
      circle = segments.last
      tip = segments.first.last
      triangles = []
      (0...circle.size-1).each { |i|
        triangles << circle[ i ]
        triangles << circle[ i+1 ]
        triangles << tip
      }
      color = TT::Color.clone( @color )
      color.alpha = 45
      view.drawing_color = color
      screen_points = triangles.map { |point| view.screen_coords( point ) }
      view.draw2d( GL_TRIANGLES, screen_points )
    end
    
    private
    
    # @param [Sketchup::View] view
    #
    # @return [Array<Array<Geom::Point3d>>]
    # @since 2.6.0
    def arrow_segments( view )
      base    = view.pixels_to_model( 110, @origin )
      tip     = view.pixels_to_model( 150, @origin )
      radius  = view.pixels_to_model(  10, @origin )
      
      base_pt = ORIGIN.offset( Z_AXIS, base )
      tip_pt  = ORIGIN.offset( Z_AXIS, tip )
      
      # Arrow base.
      circle = TT::Geom3d.circle( base_pt, Z_AXIS, radius, 8 )
      
      # Connect base circle to arrow tip.
      segments = []
      for point in circle
        segments << [ point, tip_pt ]
      end
      
      # Since the segments are drawn with GL_LINE_STRIP we need to manually close
      # the circle to form a loop.
      circle << circle.first
      segments << circle
      
      # Transform the segment into correct model space.
      tr = Geom::Transformation.new( @origin, @direction )
      for segment in segments
        segment.map! { |point| point.transform( tr ) }
      end
      
      segments
    end
    
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def mouse_over?( x, y, view )
      ph = view.pick_helper
      ph.do_pick( x,y )
      for segment in arrow_segments( view )
        result = ph.pick_segment( segment, x, y )
        return true unless result == false
      end
      false
    end
    
    # @param [Array<Geom::Point3d>] points
    # @param [Sketchup::View] view
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.6.0
    def screen_points( points, view )
      points.map { |pt|
        screen_pt = view.screen_coords( pt )
        screen_pt.z = 0
        screen_pt
      }
    end
    
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def move_event( x, y, view )
      # Axis vector
      vector = @old_axis[0].vector_to( @old_axis[1] )
      
      # Get mouse point on selected axis
      @ip.pick(view, x, y)
      @pt_mouse = @ip.position.project_to_line( @old_axis )

      # Get axis in screen space
      screen_axis = screen_points( @old_axis, view )
      
      # Calculate the Screen offset distance
      @pt_screen_mouse = Geom::Point3d.new( x, y, 0 ).project_to_line( screen_axis )
      mouse_distance = @pt_screen_start.distance( @pt_screen_mouse )
      
      if mouse_distance > 0
        # Direction vector
        direction = vector.clone
        
        # Get movement vector in screen space
        v = @pt_screen_start.vector_to( @pt_screen_mouse )
        
        # (!) validate vector.
        screen_v = screen_axis[0].vector_to( screen_axis[1] )
        direction.reverse! unless screen_v.samedirection?( v )
        
        # Work out how much in real world distance the offset is.
        screen_distance = v.length
        world_distance = view.pixels_to_model( screen_distance, @old_origin )
        
        Sketchup.vcb_label = 'Distance'
        Sketchup.vcb_value = world_distance.to_l.to_s
        view.tooltip = "Move: #{world_distance.to_l.to_s}"
        
        # Offset Origin
        offset = @old_origin.offset( direction, world_distance )
        
        # Global Offset Vectors
        v_increment  = @origin.vector_to( offset )
        v_total = @old_origin.vector_to( offset )

        # Move Gizmo Origin
        t_total = Geom::Transformation.new( v_total )
        @origin = @old_origin.transform( t_total )

        #update_segments(view)
        
        # Call event with local transformations
        t_increment  = Geom::Transformation.new( v_increment )
        t_total = Geom::Transformation.new( v_total )
        @callback.call( self, t_increment, t_total ) unless @callback.nil?
      end
      true
    end
    
  end # class MoveGizmo
  
  
  # @deprecated Unfinished
	# @since 2.6.0
  class RotateGizmo
  
    attr_accessor( :origin, :direction )
    
    # @param [Geom::Point3d] origin
    # @param [Geom::Vector3d] direction
    # @param [Sketchup::Color] color
    # @param [Sketchup::Color] active_color
    #
    # @since 2.6.0
    def initialize( origin, direction, color, active_color )
      @origin = origin.clone
      @direction = direction.clone
      @color = color
      @active_color = active_color
      
      @selected = false
      @interacting = false
      
      # Cache of the axis origin and orientation. Cached on onLButtonDown
      @old_origin = nil
      @old_vector = nil
      @old_axis = nil # [pt1, pt2]
      
      # User InputPoint
      @pt_screen_start = nil
      @pt_screen_mouse = nil
      
      @pt_start = nil
      @pt_mouse = nil
      
      # Event callbacks
      @callback = nil
      @callback_start = nil
      @callback_end = nil
    end
    
    # @since 2.6.0
    def on_transform( &block )
      @callback = block
    end
    
    # @since 2.6.0
    def on_transform_start( &block )
      @callback_start = block
    end
    
    # @since 2.6.0
    def on_transform_end( &block )
      @callback_end = block
    end
    
    # @return [Boolean]
    # @since 2.6.0
    def active?
      @interacting == true
    end
    
    # @return [Boolean]
    # @since 2.6.0
    def mouse_active?
      @mouse_active == true
    end
    
    # @since 2.6.0
    def tooltip
      'Rotate'
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onLButtonDown( flags, x, y, view )
      if @selected
        
        # Cache the origin for use in onMouseMove to work out the distance
        # moved.
        @old_origin = @origin.clone
        @old_axis = [ @origin.clone, @direction.clone ] # Line (3D)
        
        @pt_screen_start = Geom::Point3d.new( x, y, 0 )
        @pt_screen_mouse = @pt_screen_start.clone
        
        segment = rotation_segment( view )
        @pt_start = project_to_segment( view, x, y, segment )
        return true unless @pt_start
        
        @last_vector = @origin.vector_to( @pt_start )
        
        @interacting = true
        @callback_start.call( self ) unless @callback_start.nil?
        true
      else
        false
      end
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onLButtonUp( flags, x, y, view )
      if @interacting
        @callback_end.call( self ) unless @callback_end.nil?
        @interacting = false
        true
      else
        @interacting = false
        false
      end
    end
    
    # @param [Integer] flags
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def onMouseMove( flags, x, y, view )
      if @interacting
        @mouse_active = true
        
        segment = rotation_segment( view )
        screen_point = Geom::Point3d.new( x, y, 0 )
        
        @pt_mouse = project_to_segment( view, x, y, segment )
        return false unless @pt_mouse
        
        start_vector = @origin.vector_to( @pt_start )
        mouse_vector = @origin.vector_to( @pt_mouse )
        
        # Increment
        increment_angle = full_angle_between( @last_vector, mouse_vector, @direction )
        t_increment = Geom::Transformation.rotation( @origin, @direction, increment_angle )
        
        # Total
        total_angle = full_angle_between( start_vector, mouse_vector, @direction )
        t_total = Geom::Transformation.rotation( @origin, @direction, total_angle )
        
        @pt_screen_mouse = screen_point
        @last_vector = mouse_vector
        
        @callback.call( self, t_increment, t_total ) unless @callback.nil?
        true
      else
        @selected = mouse_over?( x, y, view )
        @mouse_active = @selected
      end
    end
    
    # @param [Sketchup::View] view
    #
    # @return [Nil]
    # @since 2.6.0
    def draw( view )
      points = rotation_segment( view )
      screen_pts = screen_points( points, view )
      
      view.line_stipple = ''
      view.line_width = 2
      view.drawing_color = (@selected) ? @active_color : @color
      view.draw2d( GL_LINE_STRIP, screen_pts )
      
      if @selected
        fill = TT::Color.clone( @color )
        fill.alpha = 0.1
        view.drawing_color = fill
        view.draw( GL_POLYGON, points )
      end
      
      # DEBUG
      
      if @interacting && @pt_start && @pt_mouse
        start_vector = @origin.vector_to( @pt_start )
        mouse_vector = @origin.vector_to( @pt_mouse )
        
        view.line_stipple = ''
        view.line_width = 1
        
        view.drawing_color = 'orange'
        view.draw( GL_LINES, [@origin, @pt_start] )
        
        view.drawing_color = 'purple'
        view.draw( GL_LINES, [@origin, @pt_mouse] )
      end
    end
    
    private
    
    # Return the full orientation of the two lines. Going counter-clockwise.
    #
    # @return [Float]
    # @since 2.6.0
    def full_angle_between( vector1, vector2, normal = Z_AXIS )
      direction = ( vector1 * vector2 ) % normal      
      angle = vector1.angle_between( vector2 )
      angle = 360.degrees - angle if direction < 0.0
      return angle
    end

    
    # @param [Sketchup::View] view
    #
    # @return [Geom::Point3d, Nil]
    # @since 2.6.0
    def project_to_segment( view, x, y, segment )
      screen_point = Geom::Point3d.new( x, y, 0 )
      ray = view.pickray( x, y )
      center = @origin
      plane = [ center, @direction ]
      point_on_plane = Geom::intersect_line_plane( ray, plane )
      mouse_line = [ center, point_on_plane ]
      # 
      closest_distance = nil
      closest_point = nil
      (0...segment.size-1).each { |i|
        line = segment[i, 2]
        pt1 = Geom.intersect_line_line( mouse_line, line )
        next unless pt1
        next unless TT::Point3d.between?( line[0], line[1], pt1 )
        vector_to_segment = center.vector_to( pt1 )
        vector_to_mouse = center.vector_to( point_on_plane )
        #next unless TT::Point3d.between?( center, point_on_plane, pt1 )
        next unless vector_to_mouse.samedirection?( vector_to_segment )
        distance = center.distance( pt1 )
        if closest_distance.nil? || distance < closest_distance
          closest_distance = distance
          closest_point = pt1
        end
      }
      closest_point
    end
    
    # @param [Sketchup::View] view
    #
    # @return [Array<Array<Geom::Point3d>>]
    # @since 2.6.0
    def rotation_segment( view )
      # Generate Circle
      radius = view.pixels_to_model( 150, @origin ) 
      segments = TT::Geom3d.circle( @origin, @direction, radius, 32 )
      
      # Since the segments are drawn with GL_LINE_STRIP we need to manually close
      # the circle to form a loop.
      segments << segments.first
      
      segments
    end
    
    # @param [Integer] x
    # @param [Integer] y
    # @param [Sketchup::View] view
    #
    # @return [Boolean]
    # @since 2.6.0
    def mouse_over?( x, y, view )
      ph = view.pick_helper
      ph.do_pick( x,y )
      segment = rotation_segment( view )
      result = ph.pick_segment( segment, x, y, 15 )
      return true unless result == false
      false
    end
    
    # @param [Array<Geom::Point3d>] points
    # @param [Sketchup::View] view
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.6.0
    def screen_points( points, view )
      points.map { |pt|
        screen_pt = view.screen_coords( pt )
        screen_pt.z = 0
        screen_pt
      }
    end
    
  end # class RotateGizmo
  
end # module TT::Gizmo