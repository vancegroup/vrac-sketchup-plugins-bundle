=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright © 2012 Fredo6 - Designed and written June 2011 by Fredo6
#
# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   Lib6Material.rb
# Original Date	:   27 Feb 2012
# Description	:   Manage Materials
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor

#==================================================
#----------------------------------------------------------------------------------------------------
# Class MaterialManager: manages material to overcome bugs in SU
#----------------------------------------------------------------------------------------------------
#==================================================

class MaterialManager

#-------------------------------------------------------------------
# Class Methods
#-------------------------------------------------------------------

#Singleton instance
@@matos = nil unless defined?(@@matos)
def MaterialManager.manager
	return @@matos if @@matos
	@@matos = MaterialManager.new
end

#-------------------------------------------------------------------
# Initialization
#-------------------------------------------------------------------

#Initialization
def initialize
	@hsh_mat = {}
	@tw = Sketchup.create_texture_writer
	@texture_dir = File.join LibFredo6.tmpdir, "LibFredo6_Textures"
	Dir.mkdir @texture_dir unless FileTest.directory?(@texture_dir)
	
	#Creating the observers
	Sketchup.add_observer self
	model_changing Sketchup.active_model, 'Boot'
end

#-------------------------------------------------------------------
# Observer methods
#-------------------------------------------------------------------

#Observers events
def onNewModel(model) ; model_changing(model, 'new') ; end
def onOpenModel(model) ; model_changing(model, 'open') ; end

#New model or Opening the model
def model_changing(model, mode)
	model.materials.add_observer self
	history_initialize
end

def onMaterialSetCurrent(materials, curmat)
	notify_change
end

def onMaterialChange(materials, curmat)

end

def onMaterialRefChange(materials, curmat)

end

#Notification of a change of material by the user
def notify_change
	#Do nothing as change is initiated by MaterialManager
	if @setting_current
		@setting_current = false
		return
	end
	
	#Substitue a materail already in the model if applicable
	curmat = current()
	mat = is_material_loaded?(curmat)
	if mat != false && mat != curmat
		UI.start_timer(0) { load_material mat }
	end	
	
	#Store in the stack of recent materials
	history_store mat if mat && mat.valid?
end

#-------------------------------------------------------------------
# Managing Current Material
#-------------------------------------------------------------------

#Get current material
def current
	Sketchup.active_model.materials.current
end

def current=(mat)
	Sketchup.active_model.materials.current = mat
end

def private_set_current(mat)
	@setting_current = true
	Sketchup.active_model.materials.current = mat
end

def current_info
	mat = Sketchup.active_model.materials.current
	if mat
		info = mat.display_name
		tx = mat.texture
		if tx
			w = Sketchup.format_length tx.width
			h = Sketchup.format_length tx.height
			info += " - w = #{w} h = #{h}"
		end	
	else
		info = T6[:T_TXT_DefaultMaterial]
	end
	info
end

def current_name
	material_name Sketchup.active_model.materials.current
end

def material_name(mat)
	name = (mat && mat.valid?) ? mat.name : T6[:T_TXT_DefaultMaterial]
	return "" unless name
	name = name.gsub('[', '')
	name = name.gsub(']', '')
	name
end

#Check if current material has texture
def current_with_texture?
	curmat = Sketchup.active_model.materials.current
	(curmat && curmat.texture) ? true : false
end

#---------------------------------------------------------------------------
# Loading of material
#---------------------------------------------------------------------------

#Check if a material is loaded
#Default material (curmat == nil) is always loaded
#return the material which is already loaded or false
#test must be done with false: is_loaded?(mat) == false
def is_material_loaded?(curmat)
	return curmat unless curmat
	materials = Sketchup.active_model.materials
	
	#Part of the list of materials
	return curmat if curmat && materials.to_a.include?(curmat)
	
	#Checking if a material has the same attributes in the materials of the model
	materials.each do |mat|
		next if mat.materialType != curmat.materialType || mat.alpha != curmat.alpha 
		next unless color_same?(mat.color, curmat.color)
		curtx = curmat.texture
		tx = mat.texture
		next if (curtx && !tx) || (!curtx && tx)
		if tx && curtx
			next if File.basename(tx.filename) != File.basename(curtx.filename)
			next if tx.image_width != curtx.image_width || tx.image_height != curtx.image_height
			next if tx.width != curtx.width || tx.height != curtx.height
		end	
		return mat
	end
	false
end
	
def material_print(mat, text)
	puts "\nText = #{text}"
	puts "Name = #{mat.name}"
	puts "Display Name = #{mat.display_name}"
	puts "Color = #{mat.color.to_a.inspect} i = #{mat.color.to_i}"
	puts "Alpha = #{mat.alpha}"
	puts "Type = #{mat.materialType}"
	tx = mat.texture
	if tx
		puts "Filename = #{File.basename tx.filename}"
		puts "image = #{tx.image_width} - #{tx.image_height}"
		puts "image = #{tx.width} - #{tx.height}"
	end	
end
	
def color_same?(color1, color2)
	lc1 = color1.to_a
	lc2 = color2.to_a
	for i in 0..2
		return false if (lc1[i] - lc2[i]).abs > 2
	end
	true
end
	
#Load and set the current material into the model
def load_material(curmat=false, ops_text=nil)
	model = Sketchup.active_model
	materials = model.materials
	curmat = materials.current if curmat == false
	newmat = is_material_loaded?(curmat)
	
	#Already loaded
	unless newmat == false
		private_set_current newmat
		return newmat
	end	

	#Cloning the material without a texture
	tx = curmat.texture
	unless tx
		newmat = materials.add curmat.name
		newmat.alpha = curmat.alpha
		newmat.color = curmat.color
		private_set_current newmat
		return newmat
	end	
	
	#Loading the material with a texture - Use a fake group and abort
	t0 = Time.now.to_f
	
	#Getting the Texture file of the current material
	tx_fullpath = tx.filename
	
	if FileTest.exist?(tx_fullpath)
		new_txpath = tx_fullpath
		mpath = nil
		
	#Applying it to a fake group - This allows to copy the texture imgae to the temp directory
	else	
		texture_path = File.basename tx_fullpath
		mpath = File.join @texture_dir, texture_path
		ops_text = "LibFredo6 Texture" unless ops_text
		model.start_operation ops_text
		g = model.active_entities.add_group 
		g.material = curmat
		@tw.load g
		@tw.write g, mpath
		model.abort_operation
		new_txpath = mpath
	end	
	
	#Adding the material
	newmat = materials.add curmat.name
	newmat.alpha = curmat.alpha
	newmat.color = curmat.color
	newmat.texture = new_txpath
	newtx = newmat.texture
	newtx.size = [tx.width, tx.height]
	File.delete mpath if mpath
	
	private_set_current newmat
	newmat
end

#-------------------------------------------------------------------
# Material History Management
#-------------------------------------------------------------------

#Clean up after usage
def history_initialize
	@lst_history = []
	@ipos_history = 0
end

def history_store(mat)
	@lst_history = @lst_history.find_all { |m| m && m.valid? }
	return unless mat && mat.valid?
	@lst_history.delete mat
	@lst_history.push mat
end

def history_remove(mat)
	@lst_history.delete mat
end

def history_navigate(incr, beg_end=false)
	lsm = history_build_list
	curmat = Sketchup.active_model.materials.current
	newmat = is_material_loaded?(curmat)
	curmat = newmat if newmat != false && newmat != curmat
	n = lsm.length
	if beg_end
		ipos = (incr > 0) ? n-1 : n - @lst_history.length
	else
		if RUN_ON_MAC
			ipos = @ipos_history
		else
			ipos = lsm.index(curmat)
			ipos = n-1 unless ipos
		end
		ipos += incr
	end	
	ipos = ipos.modulo(n)
	@ipos_history = ipos
	load_material lsm[ipos]
end

def history_build_list
	lsm = []
	materials = Sketchup.active_model.materials
	for i in 0...materials.count-1
		lsm.push materials[i]
	end
	lsm = lsm.sort { |a, b| a.display_name <=> b.display_name }
	#@lst_history.each { |mat| lsm.delete mat }
	lsm + @lst_history
end

end	#class MaterialManager


end	#End Module Traductor
