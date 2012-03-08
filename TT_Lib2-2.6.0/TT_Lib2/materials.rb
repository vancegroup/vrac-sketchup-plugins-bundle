#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'TT_Lib2/core.rb'

# Collection of Material methods.
#
# @since 2.5.0
module TT::Material 
  
  # When the user clicks on a material in the materials browser
  # +model.materials.current+ will return a material that does not exist in the
  # model. It is possible to apply this material to entities in the model, but
  # it will evetually BugSplat.
  #
  # This method checks if a given material exist in the model and is safe to use.
  #
  # @param [Sketchup::Material] material
  # @param [Sketchup::Model] model
  #
  # @return [Boolean]
  # @since 2.5.0
  def self.in_model?( material, model = Sketchup.active_model )
    #model.materials.any? { |m| m == material }
    # This is probably just as good to write. Is this wrapper method needed?
    model.materials.include?( material )
  end
  
  
  
  # Safely removes a material from a model.
  #
  # @param [Sketchup::Material] material
  # @param [Sketchup::Model] model
  #
  # @return [Boolean]
  # @since 2.5.0
  def self.remove( material, model = Sketchup.active_model )
    # SketchUp 8.0M1 introduced model.materials.remove, which turned out to be
    # bugged. It didn't remove the material from the entities in the model - 
    # leaving the model with rouge invalid materials.
    # To work around this all entities are processed before the method is called.
    # The workaround for older versions also require this to be done.
    for e in model.entities
      e.material = nil if e.respond_to?( :material ) && e.material == material
      e.back_material = nil if e.respond_to?( :back_material ) && e.back_material == material
    end
    for d in model.definitions
      next if d.image?
      for e in d.entities
        e.material = nil if e.respond_to?( :material ) && e.material == material
        e.back_material = nil if e.respond_to?( :back_material ) && e.back_material == material
      end
    end
    materials = model.materials
    if materials.respond_to?( :remove )
      materials.remove( material )
    else
      # Workaround for SketchUp versions older than 8.0M1. Add all materials
      # except the one to be removed to temporary groups and purge the materials.
      temp_group = model.entities.add_group
      for m in model.materials
        next if m == material
        g = temp_group.add_group
        g.material = material
      end
      materials.purge_unused
      temp_group.erase!
      true
    end
  end
  
end # module TT::Material