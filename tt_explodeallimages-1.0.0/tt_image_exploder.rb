# tt_image_exploder.rb
#-----------------------------------------------------------------------------
# Version: 1.0.0
# Compatible: SketchUp 7
#-----------------------------------------------------------------------------
#
# Explodes all Images.
#
#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'sketchup.rb'

#-----------------------------------------------------------------------------
# Add some menu items to access this
if( not file_loaded?('tt_image_exploder.rb') )
    plugins_menu = UI.menu('Plugins')
    plugins_menu.add_item('Explode all Images') { TT_Image_Exploder::explode_images() }
    plugins_menu.add_item('Explode all Images and Group') { TT_Image_Exploder::explode_images(true) }
end
#-----------------------------------------------------------------------------
file_loaded('tt_image_exploder.rb')
#-----------------------------------------------------------------------------

module TT_Image_Exploder
	def self.explode_images(group = false)
		
		if Sketchup.version.split('.')[0].to_i < 7
			Sketchup.active_model.start_operation('Explode all Images')
		else
			Sketchup.active_model.start_operation('Explode all Images', true)
		end
		
		# Stats
		images_total = 0
		images_exploded = 0
		
		definitions = Sketchup.active_model.definitions.to_a
		definitions.each { |d|
			next if !d.image?
			images_total += 1
			d.instances.each { |i|
				# Get a list of entities before we explode
				p = i.parent
				before = p.entities.to_a
				
				# Explode the Image
				entities = i.explode
				
				# Process results
				puts 'Failed to explode' if entities == false
				next if entities == false
				
				images_exploded += 1
				
				# Get a list of entities after we explode so we can produce a list
				# of the new face and edges.
				after = p.entities.to_a
				entities = after - before
				
				# Hide all the Edges
				entities.each { |e|
					e.hidden = true if e.kind_of?(Sketchup::Edge)
				}
				
				# Group it if required
				if group
					p.entities.add_group(entities)
				end
			}
		}
		
		UI.messagebox("Exploded #{images_exploded} images of #{images_exploded} total.")
		
		Sketchup.active_model.commit_operation 
	end
end