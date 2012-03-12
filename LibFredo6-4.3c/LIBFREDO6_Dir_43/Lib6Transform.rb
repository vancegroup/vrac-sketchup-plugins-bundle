=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Dec. 2008 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Transform.rb
# Original Date	:  07 Jan 2009 - version 3.0
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  A utility library about Transformation for LibFredo6-compliant scripts.
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module G6

TR_Entities_Container = Struct.new "TR_Entities_Container", 
                                   :id, :entID, :entities, :upcontainer, :tr_abs, :tr_absinv, 
                                   :tr_up, :tr_upinv, :hsplit, :hsh_edges, :active_entities, :refpos, 
								   :component, :neutralized, :lstatus, :subs, :bounds, :grouponent,
								   :model

TR_Entities_Curve = Struct.new "TR_Entities_Curve", :curve, :container, :lstatus, :vertices

TR_Dicer_Param = Struct.new "TR_Dicer_Param", :nb, :edge_prop, :flg_auto, :skip_start, :skip_end, :angle

#--------------------------------------------------------------------------------------------------------------
# Dialog box to ask for newly createdEdge properties 
#--------------------------------------------------------------------------------------------------------------			 				   

#Dialog box for Dicing parameters - Return a list [dice, dice_format]
def G6.ask_prop_new_edges(titletool, edge_prop)
	#Creating the dialog box
	hparams = {}
	title = ((titletool) ? titletool + ' - ' : '') + T6[:T_DLG_EdgeProp_Title]
	dlg = Traductor::DialogBox.new title
		
	enum_yesno = { 'Y' => T6[:T_DLG_YES], 'N' => T6[:T_DLG_NO] }
	ted = T6[:T_DLG_EdgeAdditional] + ' '
	dlg.field_enum "Soft", ted + T6[:T_DLG_EdgeSoft], 'Y', enum_yesno
	dlg.field_enum "Smooth", ted + T6[:T_DLG_EdgeSmooth], 'Y', enum_yesno
	dlg.field_enum "Hidden", ted + T6[:T_DLG_EdgeHidden], 'N', enum_yesno

	#Invoking the dialog box
	hparams["Soft"] = (edge_prop =~ /S/i) ? 'Y' : 'N'
	hparams["Smooth"] = (edge_prop =~ /M/i) ? 'Y' : 'N'
	hparams["Hidden"] = (edge_prop =~ /H/i) ? 'Y' : 'N'
	
	#Cancel dialog box
	return edge_prop unless dlg.show! hparams		
	
	#Transfering the parameters
	ep = ''
	ep += 'S' if hparams["Soft"] == 'Y'
	ep += 'M' if hparams["Smooth"] == 'Y'
	ep += 'H' if hparams["Hidden"] == 'Y'
	ep
end

#--------------------------------------------------------------------------------------------------------------
# Scanner for Selection 
#--------------------------------------------------------------------------------------------------------------			 				   

class EntitiesScanner

#Initialization
def initialize(entities, origin, axes, check_zone_proc, selection_soft=nil)
	@selection = entities.find_all { |e| is_good_entity(e) }
	@origin = origin
	@check_zone_proc = check_zone_proc
	@axes = axes.collect { |v| v.clone }
	@tr_axe = Geom::Transformation.axes origin, axes[0], axes[1], axes[2]
	@tr_axeinv = @tr_axe.inverse
	@tr_identity = Geom::Transformation.new
	@selection_soft = selection_soft
	@lst_curves = []
	@curve_already = false
	@top_dice_group = nil
	precompute_all
end

#Set the minimum length of a component to be concerned by the deformation
def set_distmin(ldistmin)
	@ldistmin = ldistmin
end

#Precompute all configuration of the geometry
def precompute_all(entities=nil)
	@nb_container = 0
	@lst_containers = []
	@lst_compo = []
	@lst_unique = [[], [], []]
	@wireframe = [[[], []], [[], []], [[], []]]
	@selection = entities.find_all { |e| is_good_entity(e) } if entities
	
	#Analyzing the geometry and hierarchy of compoenents and groups
	@top_container = create_container nil, nil, @tr_identity
	analyze_geometry @top_container
	optimize_components
	[0, 1, 2].each { |iaxe| decide_on_unique iaxe }
	@to_recompute = false
	@curve_already = true
end

#Return the entities contained in the scanner
def get_entities
	le = @top_container.entities.to_a
	le.find_all { |e| e.valid? }
end

def restore_selection
	if @top_dice_group
		ss = Sketchup.active_model.selection
		ss.clear
		le = @top_dice_group.explode
		leg = le.find_all { |e| is_good_entity(e) }
		@top_dice_group = nil
		ss.add leg 
	else
		ss = Sketchup.active_model.selection
		#ss.clear
		le = @selection.find_all { |e| is_good_entity(e) }
		ss.add le
	end
end

def is_good_entity(e)
	e.valid? &&
	(e.class == Sketchup::Edge || e.class == Sketchup::Face || e.class == Sketchup::Group || 
	 e.class == Sketchup::ComponentInstance || e.class == Sketchup::ConstructionPoint)
end

#Enumerator on containers
def each_container(&proc)
	@lst_containers.each do |container|
		yield container
	end	
end

#Create and initialize a container structure
def create_container(grouponent, upcontainer, tr_up)
	tcomp = TR_Entities_Container.new
	@lst_containers.push tcomp
	tcomp.active_entities = G6.grouponent_entities grouponent
	tcomp.grouponent = grouponent
	tcomp.entities = (grouponent) ? tcomp.active_entities : @selection.to_a
	if grouponent.respond_to?(:definition)
		tcomp.component = grouponent
		@lst_compo.push tcomp
	end	
	tcomp.upcontainer = upcontainer
	upcontainer.subs.push tcomp if upcontainer
	tcomp.model = (upcontainer) ? upcontainer.active_entities : Sketchup.active_model.active_entities
	tcomp.tr_up = tr_up
	tcomp.tr_upinv = tr_up.inverse
	tcomp.tr_abs = (upcontainer) ? upcontainer.tr_abs * tr_up : tr_up
	tcomp.tr_absinv = tcomp.tr_abs.inverse
	tcomp.hsh_edges = {}
	tcomp.lstatus = []
	tcomp.bounds = Geom::BoundingBox.new
	tcomp.neutralized = []
	tcomp.hsplit = [[[], [], []], [[], [], []], [[], [], []]]
	tcomp.subs = []
	tcomp
end

#Analyze the geometry of a component
def analyze_geometry(container)
	t = @tr_axeinv * container.tr_up
	hsh_edges = container.hsh_edges
	bb = container.bounds
	hsh_curve = {}
	container.entities.each do |entity|
		#Edges in natural geometry
		if entity.class == Sketchup::Edge
			next if hsh_edges[entity.entityID]
			curve = entity.curve
			if curve
				store_edges container, curve.edges, t, curve, nil, hsh_edges, hsh_curve, bb
			else	
				store_edges container, [entity], t, nil, side_curve(entity), hsh_edges, hsh_curve, bb
			end	
			
		#Component or group
		elsif entity.class == Sketchup::Group || entity.class == Sketchup::ComponentInstance
			tcomp = create_container entity, container, container.tr_up * entity.transformation
			analyze_geometry tcomp
			bbcomp = tcomp.bounds
			for i in 0..7
				bb.add bbcomp.corner(i)
			end	
		end	
	end	
end

#Check if an edge touches a curve - If so, return the curve, otherwise nil
def side_curve(edge)
	#return nil
	[edge.start, edge.end].each do |v|
		v.edges.each do |e|
			curve = e.curve
			return curve if curve
		end
	end
	nil	
end

#Store a list of associated edges with calculation of their relative position within the container
def store_edges(container, ledges, t, curve, sidecurve, hsh_edges, hsh_curve, bb)
	#Handling the curve if not already done
	if sidecurve
		lstatus2 = hsh_curve[sidecurve.to_s]
		unless lstatus2
			lstatus2 = store_edges container, sidecurve.edges, t, sidecurve, nil, hsh_edges, hsh_curve, bb
		end	
	end
	
	#Computing the position status for edges and storing it for deformation and wireframe
	twf = @tr_axe * t
	lstatus = edges_min_max ledges, t, bb
	if sidecurve
		for i in 0..2
			lstatus[i] = lstatus2[i] if lstatus[i] < 2
		end
	end	
	lstatus.each_with_index do |status, iaxe|
		next unless status
		container.hsplit[iaxe][status] += ledges
		if status < 2
			lwf = @wireframe[iaxe][status]
			ledges.each { |e| lwf.push twf * e.start.position, twf * e.end.position }
		end	
	end	
	
	#Marking the edges and curve as treated
	ledges.each { |e| hsh_edges[e.entityID] = lstatus } 
	if curve
		hsh_curve[curve.to_s] = lstatus
		store_curve container, curve, lstatus
	end	
	lstatus
end

#Store a curve for further reconstruction
def store_curve(container, curve, lstatus)
	return if @curves_already
	scurve = TR_Entities_Curve.new
	scurve.curve = curve
	scurve.container = container
	scurve.lstatus = lstatus
	scurve.vertices = curve.vertices.collect { |v| v }
	@lst_curves.push scurve
end

#Compute the relative position 0, 1 or 2 for a family of associated edges
def edges_min_max(lst_edges, t, bb)
	lstatus = []
	lst_edges.each do |edge|
		ptbeg = t * edge.start.position
		ptend = t * edge.end.position
		bb.add ptbeg, ptend
		lbeg = ptbeg.to_a
		lend = ptend.to_a
		[0, 1, 2].each do |iaxe|
			status = @check_zone_proc.call iaxe, ptbeg, ptend
			lstatus[iaxe] = status unless lstatus[iaxe]
			if status != lstatus [iaxe]
				lstatus [iaxe] = 2
				break
			end	
		end
	end
	lstatus
end

#Optimize the move of components. If they are on one side of the middle limit, then treat them as a whole
# in their up container
def optimize_components
	#Checking if components are on one side or the other of the middle points
	@lst_compo.reverse.each do |container|
		upcontainer = container.upcontainer
		next unless upcontainer
		compo = container.component
		hsplit = container.hsplit
		for iaxe in 0..2
			len0 = hsplit[iaxe][0].length
			len1 = hsplit[iaxe][1].length
			len2 = hsplit[iaxe][2].length
			if len2 > 0 || (len0 * len1) > 0
				if @ldistmin && dim_container(container, iaxe) < @ldistmin[iaxe]
					container.neutralized[iaxe] = true
				end	
				upcontainer.hsplit[iaxe][2].push compo
			elsif len0 == 0
				container.neutralized[iaxe] = true
				upcontainer.hsplit[iaxe][1].push compo
			else
				container.neutralized[iaxe] = true
				upcontainer.hsplit[iaxe][0].push compo
			end	
		end	
	end	
	
	#Populating the neutralized status
	@lst_compo.each do |container|
		upcontainer = container.upcontainer
		for iaxe in 0..2
			container.neutralized[iaxe] = true if upcontainer.neutralized[iaxe]
		end	
	end	
end

#Return the dimension of a container along a given direction
def dim_container(container, iaxe)
	bb = container.bounds
	pt1 = bb.corner 0
	pt2 = bb.corner [1, 2, 4][iaxe]
	pt1.distance(pt2)
end

def min_container(container, iaxe)
	bb = container.bounds
	pt = bb.corner 0
	pt[iaxe]
end

def max_container(container, iaxe)
	bb = container.bounds
	pt = bb.corner 7
	pt[iaxe]
end

#Compute which components need to be make unique for a given direction iaxe
def decide_on_unique(iaxe)
	lunique = @lst_unique[iaxe]
	@lst_containers.each do |c|
		next if c.neutralized[iaxe]
		compo = c.component
		if compo
			lunique.push compo if compo.definition.count_instances > 1
		elsif c.grouponent && c.grouponent.class == Sketchup::Group
			lunique.push c.grouponent unless G6.is_group_unique?(c.grouponent)
		end	
	end	
end

#Determine if some components need to be made unique for the given direction
def need_make_unique?(iaxe)
	(@lst_unique[iaxe].length > 0)
end

#Perform a Make unique on all concerned components for the given direction
def proceed_make_unique(iaxe)
	return if @lst_unique[iaxe].length == 0
	@lst_unique[iaxe].each do |c|
		c.make_unique
		c.glued_to = nil if c.class == Sketchup::ComponentInstance && c.glued_to
	end
	precompute_all
	@lst_unique[iaxe].each do |c|
		c.make_unique
		precompute_all
	end
end

#Explode the curves necessary
def explode_curves(iaxe, &curve_proc)
	return unless curve_proc
	@lst_curves.each do |scurve|
		next unless scurve.curve.valid?
		scurve.curve.edges[0].explode_curve if yield(scurve.lstatus[iaxe])
	end	
end

#Specifiy a dicer to be used
def specify_dicer(dicer, dice)
	@dicer = dicer
	@dice = dice
end
	
#Perform the deformation for the given entities, along the axes given
def execute_deformation(iaxe, lcurve_status=[0, 1, 2], &proc)

	#Progress Bar
	dicer = (@dicer && @dice != 0) ? @dicer : nil
	nb = @lst_containers.length + 4
	pb = Traductor::ProgressionBar.new nb+1, T6[:T_VCB_Steps]
	
	#Make component unique
	pb.set_label T6[:T_VCB_MakeUnique]
	pb.countage
	proceed_make_unique iaxe

	#Explode curves as required
	pb.set_label T6[:T_VCB_Curves]
	pb.countage
	explode_curves(iaxe) { |status| lcurve_status.include?(status) }
		
	#Dicing the selection
	pb.set_label T6[:T_VCB_Dicing]
	pb.countage
	if dicer
		dice_entities dicer
	else
		@top_dice_group = make_top_group
	end	
	
	#Storing the position of container to avoid moving them twice
	@lst_containers.each do |container| 
		next if container.neutralized[iaxe]
		g = container.component
		container.refpos = g.bounds.center if g
	end	
	
	#Deforming each containers
	pb.set_label T6[:T_VCB_Entities]
	@lst_containers.each do |container| 
		pb.countage if pb
		next if container.neutralized[iaxe]
		g = container.component
		next if g && container.refpos != g.bounds.center
		yield container 
		soften_container container
	end	
	
	#Clean up coinear edges created by the dicer
	dicer.clean_up_colinear if dicer
	
	#Transforming new created edges into Soft or so
	pb.set_label T6[:T_VCB_Curves]
	pb.countage
	reconstruct_curves
	restore_selection	
end

def reconstruct_curves
	tg = (@top_dice_group) ? @top_dice_group.transformation : @tr_identity
	@lst_curves.each do |scurve|
		container = scurve.container
		g = container.active_entities.add_group
		t = (container.upcontainer == nil) ? tg : @tr_identity
		lpt = scurve.vertices.collect { |v| t * v.position }
		g.entities.add_curve lpt
		g.explode
	end		
end

#Deform the natural geometry within a container
def register_natural_geometry(container, entities)
	#Storing the vertices to transform
	hvertex = {}
	entities.each do |e|
		if e.class == Sketchup::Face
			e.vertices.each { |v| hvertex[v.to_s] = v }
		elsif e.class == Sketchup::Edge
			hvertex[e.start.to_s] = e.start
			hvertex[e.end.to_s] = e.end
		elsif e.class == Sketchup::ConstructionPoint
			hvertex[e.to_s] = e
		end
	end
	hvertex
end

#Deform the natural geometry within a container
def deform_natural_geometry(container, entities, &tranform_point_proc)
	#Storing the vertices to transform
	hvertex = register_natural_geometry container, entities
	return unless hvertex.length > 0
	
	#Transformation by vector
	vectors = []
	lvertices = []
	t = container.tr_up
	tinv = t.inverse
	hvertex.each do |key, v|
		pt = t * v.position
		ptgoal = yield pt
		ptgoal2 = tinv * ptgoal
		vectors.push v.position.vector_to(ptgoal2)
		lvertices.push v
	end
	
	container.active_entities.transform_by_vectors lvertices, vectors
end

#Deform component and groups as a whole
#The transform proc returns the transformation in absolute coordinates
def deform_whole_grouponent(container, entities, &transform_proc)
	entities.each do |e|
		if e.class == Sketchup::Group || e.class == Sketchup::ComponentInstance		
			t = container.tr_upinv * yield(e) * container.tr_up
			container.model.transform_entities t, e
		end
	end	
end

#Soften newly created edges
def soften_container(container)	
	return unless container.upcontainer 
	ledges = []
	hsh_edges = container.hsh_edges
	container.active_entities.each do |e|
		ledges.push e if e.class == Sketchup::Edge && !hsh_edges[e.entityID]
	end	
	ledges.each { |e| e.soft = true } if @selection_soft =~ /S/i
	ledges.each { |e| e.smooth = true } if @selection_soft =~ /M/i
	ledges.each { |e| e.hidden = true } if @selection_soft =~ /H/i
end

#Handle the properties of the new edges created by the deformation
def soften_edges(hsh_edges)	
	hsh_edges.each do |key, e|
		e.soft = true
		e.smooth = true
	end	
end

#Dice the entities contained in the scanner
def dice_entities(dicer)
	ldim = [0, 1, 2].collect { |iaxe| dim_container(@top_container, iaxe) }
	lminmax = [0, 1, 2].collect { |iaxe| [min_container(@top_container, iaxe), max_container(@top_container, iaxe)] }
	@top_dice_group = dicer.dice_entities @selection, ldim, lminmax
	precompute_all [@top_dice_group]
	@top_dice_group
end

#Make a top group with the entities of the top_container
def make_top_group
	entities = @top_container.entities
	if entities.length == 1 
		cl = entities[0].class
		return nil if cl == Sketchup::Group || cl == Sketchup::ComponentInstance
	end	
	@top_dice_group = @top_container.active_entities.add_group entities
	precompute_all [@top_dice_group]
	@top_dice_group
end

end	#class  EntitiesScanner

#--------------------------------------------------------------------------------------------------------------
# Dicer Utility
#--------------------------------------------------------------------------------------------------------------			 				   

class TR_Dicer

def initialize(origin, axes, height, iaxe, dice_param, from_center, tranform_point_proc)
	@origin = origin
	@height = height
	@iaxe = iaxe
	@from_center = from_center
	@dice_param = dice_param
	@dice = TR_Dicer.get_effective_dice dice_param
	@main_axis = [X_AXIS, Y_AXIS, Z_AXIS][@iaxe]
	@axes = axes.collect { |v| v.clone }
	@tr_axe = Geom::Transformation.axes origin, axes[0], axes[1], axes[2]
	@tr_axeinv = @tr_axe.inverse
	@tr_identity = Geom::Transformation.new
	@tranform_point_proc = tranform_point_proc
	
	if from_center
		@ymin = -@height
		@ymax = @height
		@ylen = 2 * @height
	else
		@ymin = 0
		@ymax = @height
		@ylen = @height
	end
end

def TR_Dicer.get_effective_dice(dice_param)
	return 0 unless dice_param
	dice = dice_param.nb
	if dice < 0 && dice_param.flg_auto
		dice = (dice_param.angle) ? (-dice * (24 * dice_param.angle.abs / Math::PI / 2).ceil) : 0
	end
	dice.abs
end

def TR_Dicer.create_param(nb, flg_auto=false, edge_prop='SM', skip_start=false, skip_end=false, angle=0)
	dice_param = TR_Dicer_Param.new
	dice_param.nb = nb
	dice_param.flg_auto = flg_auto
	dice_param.edge_prop = edge_prop
	dice_param.skip_start = skip_start
	dice_param.skip_end = skip_end
	dice_param.angle = angle
	dice_param
end

def TR_Dicer.drawing_marks(view, dice_param, pt1, pt2)
	return [] unless dice_param && dice_param.nb != 0 && pt1 != pt2

	dice = TR_Dicer.get_effective_dice dice_param
	dice = 2 if dice == 0
	ibeg = 0
	iend = dice
	incr = 1.0 / dice
	lpt = []
	for i in ibeg..iend
		a1 = i * incr
		lpt.push Geom.linear_combination(a1, pt1, 1.0 - a1, pt2)
	end
	lpt
end

#Drawing the dicing marks
def TR_Dicer.draw_dicer_marks(view, dice_param, pt1, pt2, vec, color='darkorange', pxsize=10, width=3, stipple='')	
	return unless dice_param && dice_param.nb != 0 && vec.valid?
	lpt = G6::TR_Dicer.drawing_marks view, dice_param, pt1, pt2
	return unless lpt && lpt.length > 0
	size = view.pixels_to_model pxsize, pt1
	lldpt = []
	lpt.each { |pt| lldpt.push pt.offset(vec, size), pt.offset(vec, -size) }
	view.line_width = width
	view.line_stipple = stipple
	view.drawing_color = color
	view.draw2d GL_LINES, lldpt.collect { |pt| view.screen_coords pt }
end

#Dialog box for Dicing parameters - Return a list [dice, dice_format]
def TR_Dicer.ask_dice_parameters(titletool, dice_param)
	#Creating the dialog box
	hparams = {}
	dlg = Traductor::DialogBox.new(titletool + ' - ' + T6[:T_DLG_DicerParam_Title])
	
	if (dice_param.flg_auto)
		tx = T6[:T_DLG_DicerParam_Nb] + ' (' + T6[:T_DLG_DicerParam_Auto] + ')'
		dlg.field_numeric "Nb", tx, -3, -6, 60
	else
		tx = T6[:T_DLG_DicerParam_Nb]
		dlg.field_numeric "Nb", tx, 0, 0, 60
	end	
	
	enum_yesno = { 'Y' => T6[:T_DLG_YES], 'N' => T6[:T_DLG_NO] }
	ted = T6[:T_DLG_EdgeAdditional] + ' '
	dlg.field_enum "Soft", ted + T6[:T_DLG_EdgeSoft], 'Y', enum_yesno
	dlg.field_enum "Smooth", ted + T6[:T_DLG_EdgeSmooth], 'Y', enum_yesno
	dlg.field_enum "Hidden", ted + T6[:T_DLG_EdgeHidden], 'N', enum_yesno
	dlg.field_enum "Keep", ted + T6[:T_DLG_EdgeKeep], 'N', enum_yesno
	dlg.field_enum "Start", T6[:T_DLG_DicerParam_SkipStart], 'N', enum_yesno
	dlg.field_enum "End", T6[:T_DLG_DicerParam_SkipEnd], 'N', enum_yesno

	#Invoking the dialog box
	dice_format = dice_param.edge_prop
	hparams["Nb"] = dice_param.nb
	hparams["Soft"] = (dice_format =~ /S/i) ? 'Y' : 'N'
	hparams["Smooth"] = (dice_format =~ /M/i) ? 'Y' : 'N'
	hparams["Hidden"] = (dice_format =~ /H/i) ? 'Y' : 'N'
	hparams["Keep"] = (dice_format =~ /K/i) ? 'Y' : 'N'
	hparams["Start"] = (dice_param.skip_start) ? 'Y' : 'N'
	hparams["End"] = (dice_param.skip_end) ? 'Y' : 'N'
	
	#Cancel dialog box
	return dice_param unless dlg.show! hparams		
	
	#Transfering the parameters
	dice_param.nb = hparams["Nb"]
	ep = ''
	ep += 'S' if hparams["Soft"] == 'Y'
	ep += 'M' if hparams["Smooth"] == 'Y'
	ep += 'H' if hparams["Hidden"] == 'Y'
	ep += 'K' if hparams["Keep"] == 'Y'
	dice_param.edge_prop = ep
	dice_param.skip_start = (hparams["Start"] == 'Y')
	dice_param.skip_end = (hparams["End"] == 'Y')

	return dice_param
end

def transform_point(pt)
	@tranform_point_proc.call pt
end

#Dice the wireframe
def dice_wireframe(lpt)
	return [] unless lpt && lpt.length > 1
	
	#No dicing required
	return lpt.collect { |pt| transform_point pt } unless @dice && @dice != 0
		
	#Dicing by introducing additional segments
	create_lydice
	ll = []
	n = lpt.length / 2 - 1
	for i in 0..n
		pt1 = lpt[2 * i]
		pt2 = lpt[2 * i + 1]
		ll += dice_segment(pt1, pt2) { |pt| transform_point pt }
		break if ll.length > 9999
	end
	ll
end

#dice a segment
def dice_segment(pt1, pt2, &proc)
	return [] if pt1 == pt2
	ppt1 = @tr_axeinv * pt1
	ppt2 = @tr_axeinv * pt2
	y1 = ppt1[@iaxe]
	y2 = ppt2[@iaxe]
	
	#Segment outside of bending zone
	if (y1 == y2) || (y1 <= @ymin && y2 <= @ymin) || (y1 >= @ymax && y2 >= @ymax)
		return [yield(pt1), yield(pt2)]
	end

	#Point in the bending zone
	lly = [ppt1, ppt2]
	lly.sort! { |pta, ptb| pta.y <=> ptb.y }
	@lydice.each do |pty|
		next if pty[@iaxe] <= lly[0][@iaxe]
		break if pty[@iaxe] >= lly[1][@iaxe]
		pt = Geom.intersect_line_plane([ppt1, ppt2], [pty, @main_axis])
		lly.push pt if pt
	end
	
	#Sorting points by ordinates to have meaningful segments
	lly.sort! { |pta, ptb| pta[@iaxe] <=> ptb[@iaxe] }
	ll = []
	for i in 0..lly.length-2
		next if lly[i] == lly[i+1]
		ll.push yield(@tr_axe * lly[i]), yield(@tr_axe * lly[i+1])
	end
	ll
end

#Create the Dicing origin reference
def create_lydice(lminmax=nil)
	#Calculating whether extremities should be included or not
	@lydice = []
	ibeg = 0
	iend = @dice
	if lminmax
		ymin = lminmax[@iaxe][0]
		ymax = lminmax[@iaxe][1]
		ibeg = 1 if ymin == @ymin || (@dice_param && @dice_param.skip_start)
		iend = @dice - 1 if ymax == @ymax || (@dice_param && @dice_param.skip_end)
	end
	
	#Creating the divisions
	yincr = @ylen / @dice
	for i in ibeg..iend
		pt = Geom::Point3d.new(0, 0, 0)
		pt[@iaxe] = @ymin + yincr * i
		@lydice.push pt
	end
end

#Dice a set of entities
def dice_entities(entities, ldim, lminmax, model_entities=nil)
	#Making a group of the entities
	model_entities = Sketchup.active_model.active_entities unless model_entities
	grp = model_entities.add_group entities
	
	#create diceplane
	create_lydice lminmax
	gplanes = create_dice_planes model_entities, ldim
	
	# Performing the intersection
	if gplanes
		intersect gplanes, grp.entities, grp.transformation
		gplanes.erase!
	else	
		create_dice_1D grp.entities, entities, grp.transformation
	end	
	
	return grp
end

#Create the dice planes in a group at top level
def create_dice_planes(model_entities, ldim)
	g = model_entities.add_group
	iothers = [0, 1, 2] - [@iaxe]
	ix = iothers[0]
	xaxis = [X_AXIS, Y_AXIS, Z_AXIS][ix]
	dimx = ldim[ix] * 2.2
	iz = iothers[1]
	zaxis = [X_AXIS, Y_AXIS, Z_AXIS][iz]
	dimz = ldim[iz] * 2.2
	
	#Model is only 1D. Cuts the edges
	if dimx == 0 && dimz == 0
		return nil
	end
	
	#Computing the plane and creating them
	dimx = 10 if dimx == 0
	dimz = 10 if dimz == 0
	@lydice.each do |ptmid|
		pt0 = ptmid.offset xaxis, dimx * 0.5
		pt1 = pt0.offset zaxis, dimz * 0.5
		pt2 = pt1.offset xaxis, -dimx
		pt3 = pt2.offset zaxis, -dimz
		pt4 = pt3.offset xaxis, dimx
		lpt = [pt1, pt2, pt3, pt4].collect { |pt| @tr_axe * pt }
		g.entities.add_face lpt
	end
	g
end

#Dice a single set of aligned edges
def create_dice_1D(model_entities, entities, t)
	lpt = []
	tinv = t.inverse
	entities.each do |e|
		if e.class == Sketchup::Edge
			pt1 = t * e.start.position
			pt2 = t * e.end.position
			lpt += dice_segment(pt1, pt2) { |pt| pt }
		elsif e.class == Sketchup::Group
			create_dice_1D e.entities, e.entities, t * e.transformation
		elsif e.class == Sketchup::ComponentInstance
			create_dice_1D e.definition.entities, e.definition.entities, t * e.transformation
		end	
	end	
	model_entities.add_edges lpt.collect { |pt| tinv * pt } if lpt.length > 1
end

#Perfrom the intersection of the dice planes with the selection	
#Group and component must be unique
def intersect(gplanes, entities, t)	
	hsh_vertex = {}
	entities.each do |e|
		if e.class == Sketchup::Edge
			hsh_vertex[e.start.entityID] = true
			hsh_vertex[e.end.entityID] = true
		elsif e.class == Sketchup::Group
			intersect gplanes, e.entities, t * e.transformation
		elsif e.class == Sketchup::ComponentInstance
			intersect gplanes, e.definition.entities, t * e.transformation
		end	
	end
	
	#Setting the properties of the created edges at intersection
	if hsh_vertex.length > 0
		dice_format = (@dice_param) ? @dice_param.edge_prop : 'SM'
		ledges = entities.intersect_with false, t, entities, t, false, [gplanes]
		ledges = ledges.find_all {|e| !hsh_vertex[e.start.entityID] || !hsh_vertex[e.end.entityID]}
		ledges.each { |e| e.soft = true } if dice_format =~ /S/i
		ledges.each { |e| e.smooth = true } if dice_format =~ /M/i
		ledges.each { |e| e.visible = false } if dice_format =~ /H/i
		@ledges_diced = ledges.collect { |e| [e, entities] }
	end	
end

#Clean up colinear edges created by the dicer
def clean_up_colinear
	return unless @ledges_diced
	dice_format = (@dice_param) ? @dice_param.edge_prop : ''
	return if dice_format =~ /K/i
	@ledges_diced.each do |ee|
		edge = ee[0]
		next unless edge.valid? && edge_colinear?(edge)
		entities = ee[1]
		entities.erase_entities edge
	end	
end

#check if an edge is colinear
def edge_colinear?(edge)
	return false if edge.faces.length != 2
	face1 = edge.faces[0]
	face2 = edge.faces[1]
	return false unless face1.normal.parallel? face2.normal
	return false unless face1.material == face2.material
	return false unless face1.back_material == face2.back_material
	true
end
		
end	#class TR_Dicer
		
#--------------------------------------------------------------------------------------------------------------
# Base Class for All Transformation
#--------------------------------------------------------------------------------------------------------------			 				   

class TR_BaseClass

#Apply the transformation to a point or a list of entities
def *(entity)
	return transform_point(entity) if entity.class == Geom::Point3d
	transform_entities [entity]
end

end	#class TR_BaseClass

#--------------------------------------------------------------------------------------------------------------
# Tapering Transformation
#--------------------------------------------------------------------------------------------------------------			 				   

class TR_Tapering < TR_BaseClass

#Create a new Tapering transformation
def initialize(origin, axes, xscale, yscale, height)
	@origin = origin
	@axes = axes
	@xscale = xscale
	@yscale = yscale
	@height = height
	@tr_axe = Geom::Transformation.axes origin, axes[0], axes[1], axes[2]
	@tr_axeinv = @tr_axe.inverse
	@tr_identity = Geom::Transformation.new
end

def transform_point(pt)
	pt = @tr_axeinv * pt
	zscale = pt.z / @height
	pt.x *= (1.0 + (@xscale - 1.0) * zscale)
	pt.y *= (1.0 + (@yscale - 1.0) * zscale)
	return @tr_axe * pt
end

#Call back method for checking in which zones are points, for a given axe
def proc_check_zone(iaxe, pt1, pt2)
	return 2
end

#Transform the entities - Recommended not be used in live deform, as it is not guaranteed to be fast
def transform_entities(entities, selection_soft=nil)
	#Creating the Entities scanner and analysing the geometry
	scanner = EntitiesScanner.new entities, @origin, @axes, self.method(:proc_check_zone), selection_soft
	
	#Make component unique and explode curves as required
	iaxe = 1
	
	#Executing the deformation on the containers
	scanner.execute_deformation(iaxe) do |container|
		entities2 = container.hsplit[iaxe][2]
		scanner.deform_natural_geometry(container, entities2) { |pt| transform_point pt }
	end	
end

end	#class TR_Tapering

#--------------------------------------------------------------------------------------------------------------
# Shearing Transformation
#--------------------------------------------------------------------------------------------------------------			 				   

class TR_Shearing

#Create a new Tapering transformation
def initialize(origin, normal, basedir, angle)
	@model = nil
	@origin = origin
	@tgt = Math::tan angle
	@tgt = 100 if @tgt.abs > 100
	@tgt = 0 if @tgt.abs < 0.0001
	axes = [basedir, normal * basedir, normal]
	@tr_axe = Geom::Transformation.axes origin, axes[0], axes[1], axes[2]
	@tr_axeinv = @tr_axe.inverse
	coef = [1, @tgt, 0, 0] + [0, 1, 0, 0] + [0, 0, 1, 0] + [0, 0, 0, 1]
	@tr = @tr_axe * Geom::Transformation.new(coef) * @tr_axeinv
end

def transform_point(pt)
	@tr * pt
end

#Transform one or several entities
def transform_entities(entities)
	model = @model
	model = entities[0].parent unless model
	model.entities.transform_entities @tr, entities
end

end	#class TR_Shearing

#--------------------------------------------------------------------------------------------------------------
# Twisting Transformation
#--------------------------------------------------------------------------------------------------------------			 				   

class TR_Twisting < TR_BaseClass

def initialize(origin, axes, angle, height, from_center, dice_param=nil)
	@origin = origin
	@axes = axes
	@height = height
	@from_center = from_center
	angle = angle.modulo(Math::PI * 2)
	angle = angle - Math::PI * 2 if (angle > Math::PI)
	@angle = angle
	@tr_axe = Geom::Transformation.axes origin, axes[0], axes[1], axes[2]
	@tr_axeinv = @tr_axe.inverse
	@tr_identity = Geom::Transformation.new
	
	#Creating the dicer
	@dice_param = dice_param
	@dice = TR_Dicer.get_effective_dice dice_param
	@dicer = TR_Dicer.new @origin, @axes, @height, 2, @dice_param, from_center, self.method(:transform_point)
end

def inverse
	TR_Twisting.new @origin, @axes, -@angle, @height, @from_center, @dice_param
end

def transform_point(pt)
	pt = @tr_axeinv * pt
	zscale = pt.z / @height
	angle = (@angle * zscale)
	t = Geom::Transformation.rotation ORIGIN, Z_AXIS, angle
	return @tr_axe * t * pt
end

#Call back method for checking in which zones are points, for a given axe
def proc_check_zone(iaxe, pt1, pt2)
	return 2
end

#Transform the entities - Recommended not be used in live deform, as it is not guaranteed to be fast
def transform_entities(entities, selection_soft=nil)
	#Creating the Entities scanner and analysing the geometry
	scanner = EntitiesScanner.new entities, @origin, @axes, self.method(:proc_check_zone), selection_soft
	
	#Make component unique and explode curves as required
	iaxe = 1
	
	#Dicing the selection
	if @dice_param && @dice_param.nb != 0
		scanner.specify_dicer @dicer, @dice_param.nb
		#scanner.dice_entities @dicer
	end

	#Executing the deformation on the containers
	scanner.execute_deformation(iaxe) do |container|
		entities2 = container.hsplit[iaxe][2]
		scanner.deform_natural_geometry(container, entities2) { |pt| transform_point pt }
	end	
end

end	#class TR_Twisting

#--------------------------------------------------------------------------------------------------------------
# Radial Bending Transformation
#--------------------------------------------------------------------------------------------------------------			 				   

class TR_RadialBending < TR_BaseClass

def initialize(origin, normal, vecbase, angle, height, dice_param=nil)
	#Initialization
	@origin = origin
	@normal = normal
	@vecbase = vecbase
	angle = angle.modulo(Math::PI * 2)
	angle = angle - Math::PI * 2 if (angle > Math::PI)
	@angle = -angle
	@height = height
	@axes = [vecbase * normal, vecbase, normal]
	@tr_axe = Geom::Transformation.axes origin, @axes[0], @axes[1], @axes[2]
	@tr_axeinv = @tr_axe.inverse
	@tr_identity = Geom::Transformation.new
	
	#Computing the parameters
	@precision = @height * 0.0001
	@radius = @height / @angle
	@ptcenter = Geom::Point3d.new @radius, 0, 0
	ptend = Geom::Point3d.new 0, @height, 0
	@ptextrem = Geom::Point3d.new @radius * (1.0 - Math.cos(@angle)), @radius * Math.sin(@angle), 0
	tr = Geom::Transformation.rotation ptend, Z_AXIS, -@angle
	tm = Geom::Transformation.translation ptend.vector_to(@ptextrem)
	@tr_above = @tr_axe * tm * tr
	
	#Creating the dicer
	@dice_param = dice_param
	@dice_param.angle = @angle if @dice_param
	@dice = TR_Dicer.get_effective_dice dice_param
	@dicer = TR_Dicer.new @origin, @axes, @height, 1, @dice_param, false, self.method(:transform_point)
end

def inverse
	TR_RadialBending.new @origin, @normal, @vecbase, -@angle, @height
end

#Apply the transformation to a point or a list of entities
def transform_point(pt)
	return pt if @angle.abs < 1.degrees
	pt = @tr_axeinv * pt
	
	#Point below the origin
	return @tr_axe * pt if pt.y <= 0
	
	#Point above the extremity
	return @tr_above * pt if pt.y >= @height
	
	#Point within the curvature zone
	angle = @angle * pt.y / @height
	ptcircle = Geom::Point3d.new @radius * (1.0 - Math.cos(angle)), @radius * Math.sin(angle), pt.z
	ptori = Geom::Point3d.new @radius, 0, pt.z 
	fac = (@angle < 0) ? 1 : -1
	ptend = ptcircle.offset ptori.vector_to(ptcircle), fac * pt.x
	return @tr_axe * ptend
end

#Dice the wireframe
def dice_wireframe(lpt)
	return [] unless @angle.abs > 1.degrees
	@dicer.dice_wireframe lpt
end

#Call back method for checking in which zones are points, for a given axe
def proc_check_zone(iaxe, pt1, pt2)
	return 2 unless iaxe == 1
	return 0 if pt1.y < 0 && pt2.y < 0
	return 1 if pt1.y > @height && pt2.y > @height
	return 2
end

#Transform the entities - Recommended not be used in live deform, as it is not guaranteed to be fast
def transform_entities(entities, selection_soft=nil)
	#Creating the Entities scanner and analysing the geometry
	scanner = EntitiesScanner.new entities, @origin, @axes, self.method(:proc_check_zone), selection_soft	
		
	#Specifying the dicer
	if @angle.abs > 1.degrees && @dice != 0
		scanner.specify_dicer @dicer, @dice
	end
	
	#Executing the deformation on the containers
	iaxe = 1
	tgc = @tr_above * @tr_axeinv
	scanner.execute_deformation(iaxe, [1, 2]) do |container|
		entities0 = container.hsplit[iaxe][0]
		entities1 = container.hsplit[iaxe][1]
		entities2 = entities1 + container.hsplit[iaxe][2]
		scanner.register_natural_geometry container, entities0
		scanner.deform_natural_geometry(container, entities2) { |pt| transform_point pt }
		scanner.deform_whole_grouponent(container, entities1) { |e| tgc }
	end
end

end	#class TR_RadialBending

end #Module Traductor

