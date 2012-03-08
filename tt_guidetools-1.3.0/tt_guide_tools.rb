#-----------------------------------------------------------------------------
# Compatible: SketchUp 7 (PC)
#             (other versions untested)
#-----------------------------------------------------------------------------
#
# CHANGELOG
# 1.3.0 - 21.10.2010
#		 * CPoint at Camera Eye
#
# 1.2.0 - 11.10.2010
#		 * CPoint at Edge-Face Intersection
#		 * CPoint at Edge-Edge Intersection
#
# 1.1.0 - 06.09.2010
#		 * CPoint at Insertion Point.
#
# 1.0.0 - 30.08.2010
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

TT::Lib.compatible?('2.4.0', 'TT Guide Tools')

#-----------------------------------------------------------------------------

module TT::Plugins::GuideTools  
  
  ### CONSTANTS ### --------------------------------------------------------
  
  VERSION = '1.3.0'
  
  
  ### MENU & TOOLBARS ### --------------------------------------------------
  
  unless file_loaded?( File.basename(__FILE__) )
    m = TT.menu('Plugins').add_submenu('Guide Tools')
    m.add_item('CPoint at Arc Center')          { self.cpoint_at_arc_center }
    m.add_item('CPoint at Circle Center')       { self.cpoint_at_arc_center(true) }
    m.add_item('CPoint at Exploded Arc Center') { self.cpoint_at_exploded_arc_center }
    m.add_item('CPoint at Bounds Center')       { self.cpoint_at_bounds_center }
    m.add_item('CPoint at Bounds Bottom Center'){ self.cpoint_at_bounds_bottom_center }
    m.add_item('CPoint at Insertion Point')     { self.cpoint_at_insert_point }
    m.add_item('CPoint at Camera Eye')          { self.cpoint_at_camera_eye }
    m.add_separator
    m.add_item('CPoint at Edge-Face Intersection')  { self.cpoint_at_edge_face_intersect }
    m.add_item('CPoint at Edge-Edge Intersection')  { self.cpoint_at_edge_edge_intersect }
    m.add_separator
    m.add_item('Insert Components at CPoints')  { self.insert_components_at_cpoints }
  end
  
  
  ### MAIN SCRIPT ### ------------------------------------------------------
  
  # 1.3.0
  # Adds CPoint at camera eye
  def self.cpoint_at_camera_eye
    model = Sketchup.active_model
    camera = model.active_view.camera
    model.start_operation('CPoint at Camera Eye')
    model.active_entities.add_cpoint( camera.eye )
    model.commit_operation
  end
  
  
  # 1.2.0
  # Adds CPoint at edge intersection of faces
  def self.cpoint_at_edge_face_intersect
    model = Sketchup.active_model
    
    edges = []
    faces = []
    
    model.selection.each { |e|
      edges << e if e.is_a?(Sketchup::Edge)
      faces << e if e.is_a?(Sketchup::Face)
    }
    
    if edges.empty? || faces.empty?
      UI.messagebox( 'Select some Edges and Faces.', MB_OK | TT::MB_ICONINFORMATION )
      return nil
    end
    
    valid = Sketchup::Face::PointInside |
            Sketchup::Face::PointOnVertex |
            Sketchup::Face::PointOnEdge
    
    # Account for new SU8 constant.
    if Sketchup::Face.constants.include?('PointOnFace')
      valid |= Sketchup::Face::PointOnFace
    end
    
    TT::Model.start_operation( 'CPoint at Edge-Face Intersection' )
    edges.each { |edge|
      faces.each { |face|
        intersect = Geom.intersect_line_plane(edge.line, face.plane)
        next if intersect.nil?
        # Check if the intersection is on the face
        result = face.classify_point(intersect)
        next if result & valid == 0
        # Check if the intersection is on the edge
        next unless TT::Point3d.between?(
          edge.start.position,
          edge.end.position,
          intersect
          )
        model.active_entities.add_cpoint(intersect)
      }
    }
    model.commit_operation
  end
  
  
  # 1.2.0
  # Adds CPoint at edge intersections
  def self.cpoint_at_edge_edge_intersect
    model = Sketchup.active_model
    
    if model.selection.empty?
      UI.messagebox( 'Select some Edges.', MB_OK | TT::MB_ICONINFORMATION )
      return nil
    end
    
    edges = model.selection.select { |e|
      e.is_a?(Sketchup::Edge) && e.faces.length == 0
    }
    
    vertices = edges.map { |e| e.vertices }
    vertices.flatten!
    vertices.uniq!
    
    TT::Model.start_operation( 'CPoint at Edge-Edge Intersection' )
    for v in vertices
      ve = v.edges & edges
      if ve.length > 1 && ve.all? { |e| e.faces.length == 0 }
        model.active_entities.add_cpoint( v.position )
      end
    end
    model.commit_operation
  end
  
  
  # 1.1.0
  # Adds CPoint at insertion point
  def self.cpoint_at_insert_point
    model = Sketchup.active_model
    if model.selection.empty?
      result = UI.messagebox('Would you like to insert a CPoint to all components in the model?', MB_YESNO)
      return if result == 7
      comps = model.definitions.reject { |d| d.image? || d.group? }
    else
      insts = model.selection.select { |e| e.is_a?( Sketchup::ComponentInstance) }
      comps = insts.map { |i| i.definition }
      comps.uniq!
    end
    TT::Model.start_operation( 'CPoint at Insertion Point' )
    comps.each { |d|
      d.entities.add_cpoint( ORIGIN )
    }
    model.commit_operation
  end
  
  
  # Adds a CPoint for all selected Arcs/Circles.
  def self.cpoint_at_arc_center(circle = false)
    model = Sketchup.active_model
    TT::Model.start_operation('CPoint at Arc Center')
    c = Set.new
    model.selection.each { |e|
      next unless e.is_a?(Sketchup::Edge)
      if circle
        next unless TT::Arc.circle?( e.curve )
      else
        next unless TT::Arc.is?( e.curve )
      end
      next if c.include?(e.curve)
      c.insert(e.curve)
      g=model.active_entities.add_cpoint(e.curve.center)
      g.layer = e.layer
    }
    model.commit_operation
  end
  
  
  # Iterates all selected edges and place a CPoint at the center of all the 
  # exploded arcs that is found.
  def self.cpoint_at_exploded_arc_center
    model = Sketchup.active_model
    TT::Model.start_operation('CPoint at Exploded Arc Center')
    
    # Sort out groups of connected geometry. Assume they are exploded arcs.
    arcs = []
    ents = model.selection.to_a
    until ents.empty?
      e = ents.shift
      next unless e.respond_to?(:all_connected)
      arcs << e.all_connected.select { |e| e.is_a?(Sketchup::Edge) }
      ents -= e.all_connected.to_a
    end
    
    # Verify the groups are arcs and add CPoint at the center.
    for arc in arcs
      next if arc.length < 2
      
      # Take first two edges and work out the center.
      e1 = arc.shift
      e2 = arc.shift
      center = TT::Arc.exploded_center(e1, e2)
      next if center.nil?
      
      # Iterate the rest and verify that they match.
      is_arc = true
      last_edge = e2
      for edge in arc
        point = TT::Arc.exploded_center(last_edge, edge)
        if point.nil? || center != point
          is_arc = false
          break
        else
          last_edge = edge
        end
      end
      
      # Add CPoint
      if is_arc
        model.active_entities.add_cpoint(center)
      end
    end
    
    model.commit_operation
  end
  
  
  # Adds a CPoint to the center of all selected Groups/Components's bounds.
  def self.cpoint_at_bounds_center
    model = Sketchup.active_model
    pts = []
    TT::Model.start_operation('CPoint at Bounds Center')
    model.selection.each { |e|
      if TT::Instance.is?( e )
        g = model.active_entities.add_cpoint( e.bounds.center )
        g.layer = e.layer
        pts << g
      end
    }
    model.selection.clear
    model.selection.add(pts)
    model.commit_operation
  end
  
  
  # Adds a CPoint to the bottom center of all selected Groups/Components's bounds.
  def self.cpoint_at_bounds_bottom_center
    model = Sketchup.active_model
    pts = []
    TT::Model.start_operation('CPoint at Bounds Bottom Center')
    model.selection.each { |e|
      if TT::Instance.is?( e )
        p1 = e.bounds.corner(0)
        p2 = e.bounds.corner(3)
        center = Geom::Point3d.linear_combination(0.5, p1, 0.5, p2)
        g=model.active_entities.add_cpoint( center )
        g.layer = e.layer
        pts << g
      end
    }
    model.selection.clear
    model.selection.add(pts)
    model.commit_operation
  end
  
  
  # Inserts an instance of the selected component at the selected CPoints.
  def self.insert_components_at_cpoints
    model = Sketchup.active_model
    
    # Collect all selected CPoints and one Component Instance.
    component = nil
    cpoints = []
    model.selection.each { |e|
      if component.nil? && e.is_a?(Sketchup::ComponentInstance)
        component = e.definition
      end
      cpoints << e if e.is_a?(Sketchup::ConstructionPoint)
    }
    if component.nil?
      UI.messagebox( 'No Component Instance selected.' )
      return
    end
    if cpoints.empty?
      UI.messagebox( 'No CPoints selected.' )
      return
    end
    
    TT::Model.start_operation('Insert Components at CPoint')
    cpoints.each { |c|
      t = Geom::Transformation.new(c.position)
      instance = model.active_entities.add_instance(component, t)
    }
    model.commit_operation
  end
  
  
  ### DEBUG ### ------------------------------------------------------------
  
  def self.reload
    load __FILE__
  end
  
end # module

#-----------------------------------------------------------------------------
file_loaded( File.basename(__FILE__) )
#-----------------------------------------------------------------------------