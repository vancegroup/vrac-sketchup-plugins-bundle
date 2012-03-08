#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'TT_Lib2/core.rb'

# Collection of Group, ComponentInstnace and Image methods.
#
# @since 2.0.0
module TT::Instance
  
  # Returns the definition for a +Group+, +ComponentInstance+ or +Image+
	#
	# @param [Sketchup::ComponentInstance, Sketchup::Group, Sketchup::Image] instance
	#
	# @return [Sketchup::ComponentDefinition]
	# @since 2.0.0
  def self.definition(instance)
    if instance.is_a?(Sketchup::ComponentInstance)
      # ComponentInstance
      return instance.definition
    elsif instance.is_a?(Sketchup::Group)
      # Group
      #
      # (i) group.entities.parent should return the definition of a group.
      # But because of a SketchUp bug we must verify that group.entities.parent returns
      # the correct definition. If the returned definition doesn't include our group instance
      # then we must search through all the definitions to locate it.
      if instance.entities.parent.instances.include?(instance)
        return instance.entities.parent
      else
        Sketchup.active_model.definitions.each { |definition|
          return definition if definition.instances.include?(instance)
        }
      end
    elsif instance.is_a?(Sketchup::Image)
      Sketchup.active_model.definitions.each { |definition|
        return definition if definition.image? && definition.instances.include?(instance)
      }
    end
    return nil # Error. We should never exit here.
  end
  
  
  # Query to whether it's a Group or ComponentInstance
	#
	# @param [Sketchup::Entity] instance
	#
	# @return [Boolean]
	# @since 2.0.0
  def self.is?(entity)
    entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
  end
  
end # module TT::Instance