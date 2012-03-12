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
# Name			:  Lib6Mark.rb
# Original Date	:  23 Dec 2008 - version 3.1
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  Contains some utilities for drawing standard predefined marks and shapes
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module G6

#--------------------------------------------------------------------------------------------------------------
# Class DrawMark: Predefined marks for 2D and 3D drawing 
#--------------------------------------------------------------------------------------------------------------			 

class AllDrawMark

Traductor_DrawMark_Elt = Struct.new "Traductor_DrawMark_Elt", :lpt, :color, :width, :stipple, :gl_type

def creation_mark
	@list_elts = []
	@stipple = ""
	@color = 'black'
	@width = 1
end

def draw_at_point2d(view, pt2d)
	size = (@size) ? @size : 1
	t = Geom::Transformation.translation(pt2d) * Geom::Transformation.scaling(size)

	@list_elts.each do |elt|
		lpt = elt.lpt
		lpt2d = lpt.collect { |pt| t * pt }
		view.drawing_color = (elt.color) ? elt.color : @color
		view.line_width = (elt.width) ? elt.width : @width
		view.line_stipple = (elt.stipple) ? elt.stipple : @stipple
		view.draw2d elt.gl_type, lpt2d
	end	
end

def draw_at_xy(view, x, y)
	draw_at_point2d view, Geom::Point3d.new(x, y, 0)
end

def draw_at_point3d(view, pt3d)
	draw_at_point2d view, view.screen_coords(pt3d)
end

def create_element(lpt, gl_type, color=nil, width=nil, stipple=nil)
	elt = Traductor_DrawMark_Elt.new
	elt.lpt = lpt
	elt.gl_type = gl_type
	elt.color = color
	elt.width = width
	elt.stipple = stipple
	elt
end

def create_line(lpt)
	create_element lpt, GL_LINE_STRIP
end

end	#class AllDrawMark

#--------------------------------------------------------------------------------------------------------------
# Class DrawMark_Forbidden: Forbidden sign 
#--------------------------------------------------------------------------------------------------------------			 

class DrawMark_Forbidden < AllDrawMark

def initialize(size=nil, color=nil, width=nil)
	creation_mark
	@size = (size) ? size : 5
	@color = (color) ? color : 'red'
	@width = (width) ? width : 2
	
	#Main circle
	n = 12
	pi = Math::PI
	radius = 10
	circle = []
	for i in 0..n
		angle = 2 * pi * i / n
		cosinus = Math::cos angle
		sinus = Math::sin angle
		circle.push Geom::Point3d.new(cosinus, sinus, 0)
	end
	bar = [circle[5], circle[11]]
	@list_elts.push create_line(circle)
	@list_elts.push create_line(bar)
end

end	#class DrawMark_Forbidden

#--------------------------------------------------------------------------------------------------------------
# Class DrawMark_FourArrows: 4 arrows 
#--------------------------------------------------------------------------------------------------------------			 

class DrawMark_FourArrows < AllDrawMark

def initialize(size=nil, color=nil, width=nil)
	creation_mark
	@size = (size) ? size : 7
	@color = (color) ? color : 'blue'
	@width = (width) ? width : 2
	
	#Shape
	dec = 0.4
	pt1 = Geom::Point3d.new -1, 0, 0
	pt2 = Geom::Point3d.new 1, 0, 0
	pt3 = Geom::Point3d.new 0, -1, 0
	pt4 = Geom::Point3d.new 0, 1, 0
	@list_elts.push create_line([pt1, pt2])
	@list_elts.push create_line([pt3, pt4])
	@list_elts += make_arrow(pt1, -dec, 'X')
	@list_elts += make_arrow(pt2, dec, 'X')
	@list_elts += make_arrow(pt3, -dec, 'Y')
	@list_elts += make_arrow(pt4, dec, 'Y')
end

def make_arrow(pt2d, dec, code)
	lselt = []
	case code
	when 'X'
		x1 = pt2d.x - dec
		y1 = pt2d.y + dec
		y2 = pt2d.y - dec
		lselt.push create_line([pt2d, Geom::Point3d.new(x1, y1, 0)])
		lselt.push create_line([pt2d, Geom::Point3d.new(x1, y2, 0)])
	when 'Y'
		y1 = pt2d.y - dec
		x1 = pt2d.x + dec
		x2 = pt2d.x - dec
		lselt.push create_line([pt2d, Geom::Point3d.new(x1, y1, 0)])
		lselt.push create_line([pt2d, Geom::Point3d.new(x2, y1, 0)])
	end
	lselt	
end

end	#class DrawMark_FourArrows

#--------------------------------------------------------------------------------------------------------------
# Class DrawMark_H2Arrows: 2 arrows horizontal
#--------------------------------------------------------------------------------------------------------------			 

class DrawMark_H2Arrows < G6::AllDrawMark

def initialize(size=nil, color=nil, width=nil)
	creation_mark
	@size = (size) ? size : 7
	@color = (color) ? color : 'darkgreen'
	@width = (width) ? width : 2
	
	#Shape
	dec = 0.4
	pt1 = Geom::Point3d.new -1, 0, 0
	pt2 = Geom::Point3d.new 1, 0, 0
	@list_elts.push create_line([pt1, pt2])
	@list_elts += make_arrow(pt1, -dec)
	@list_elts += make_arrow(pt2, dec)
end

def make_arrow(pt2d, dec)
	lselt = []
	x1 = pt2d.x - dec
	y1 = pt2d.y + dec
	y2 = pt2d.y - dec
	lselt.push create_line([pt2d, Geom::Point3d.new(x1, y1, 0)])
	lselt.push create_line([pt2d, Geom::Point3d.new(x1, y2, 0)])
	lselt	
end

end	#class DrawMark_FourArrows

#--------------------------------------------------------------------------------------------------------------
# Class DrawMark_Curve: Half circle
#--------------------------------------------------------------------------------------------------------------			 

class DrawMark_Curve < G6::AllDrawMark

def initialize(size=nil, color=nil, width=nil)
	creation_mark
	@size = (size) ? size : 9
	@color = (color) ? color : 'blue'
	@width = (width) ? width : 2
	
	#Shape
	lpt = []
	n = 8
	angle = Math::PI / n
	for i in 0..n
		lpt.push Geom::Point3d.new(Math.sin(angle * i), Math.cos(angle * i), 0)
	end	
	for i in 0..n-1
		@list_elts.push create_line([lpt[i], lpt[i+1]])
	end	
end

end	#class DrawMark_Curve

#--------------------------------------------------------------------------------------------------------------
# Class ProtractorShape: Input tool to show angle selection
#--------------------------------------------------------------------------------------------------------------			 				   
		
class ShapeProtractor

attr_reader :origin, :normal, :base_angle, :basedir, :cur_angle, :curdir, :radius_bigcircle

def initialize
	@origin = nil
	@cur_angle = 0
	@base_angle = 0
	@normal = nil
	@curdir = nil
	@basedir = nil
	
	#Basic colors
	@black_color = Sketchup::Color.new "black"
	@green_color = Sketchup::Color.new "lawngreen"
	@blue_color = Sketchup::Color.new "blue"
	@red_color = Sketchup::Color.new "red"
	@gray_color = Sketchup::Color.new "gray"
	@color = @black_color
		
	#geometry of the protractor
	@bigcircle = []
	@graduations = []
	@inner_up = []
	@inner_down = []
	n = 24
	pi = Math::PI
	radius = 200.cm
	fact_grad = 0.9
	fact_inner = 0.75
	limit = Math::sin(pi / 12)
	
	#defining the Protractor
	for i in 0..n
		angle = 2 * pi * i / n
		cosinus = Math::cos angle
		sinus = Math::sin angle
		pt_ext = Geom::Point3d.new radius * cosinus, radius * sinus, 0
		@bigcircle.push pt_ext
		pt_int = Geom::Point3d.new radius * fact_grad * cosinus, radius * fact_grad * sinus, 0
		@graduations.push pt_int
		@graduations.push pt_ext
		if (sinus.abs >= limit)
			pt_ext = Geom::Point3d.new radius * fact_inner * cosinus, radius * fact_inner * sinus, 0
			if (sinus > 0.0)
				@inner_up.push pt_ext
			else
				@inner_down.push pt_ext
			end	
		end
	end
	@inner_up.push @inner_up[0]
	@inner_down.push @inner_down[0]
end

#specify the placement of the Protactor
def set_placement(origin, normal, basedir=nil, face=nil)
	@origin = origin
	view = Sketchup.active_model.active_view
	@normal = (normal % view.camera.direction < 0) ? normal : normal.reverse
	@axe0 = @normal.axes[0] 
	@axe1 = @normal.axes[1] 
	@face = face
	set_basedir basedir
	@color = Traductor::Couleur.color_vector @normal, @black_color, @face
end

#Set the base direction for the protractor, and thus allow to rotate it
def set_basedir(basedir, ptinf=nil)
	@basedir = (basedir && basedir.valid?) ? (@normal * (basedir * @normal)) : @axe0
	check_inference @basedir, 'B', ptinf if ptinf
	recompute_after_base_changed
end

#Set the base direction via an angle in radians (absolute or increment)
def set_baseangle(angle, incr=false)
	angle += @base_angle if incr
	@basedir = Geom::Transformation.rotation(@origin, @normal, angle) * @axe0
	recompute_after_base_changed
end

#Recompute the parameters after the base angle was changed
def recompute_after_base_changed
	#computing the base angle
	angle = @axe0.angle_between(@basedir)
	angle = -angle if @basedir % @axe1 < 0
	@base_angle = angle
	
	#Computing the current angle
	@otherdir = @normal * @basedir
	@curdir = Geom::Transformation.rotation(@origin, @normal, @cur_angle) * @basedir
	@basedir
end

#Set the current direction for the protractor
def set_curdir(curdir, ptinf=false)
	@curdir = (curdir) ? (@normal * (curdir * @normal)) : @basedir
	check_inference @curdir, 'C', ptinf if ptinf
	recompute_after_cur_changed
end

#Set the current direction via an angle in radians (absolute or increment)
def set_curangle(angle, incr=false)
	angle += @cur_angle if incr
	@curdir = Geom::Transformation.rotation(@origin, @normal, angle) * @basedir
	recompute_after_cur_changed
end

#Recompute the parameters after the current angle was changed
def recompute_after_cur_changed
	#computing the base angle
	angle = @basedir.angle_between(@curdir)
	angle = -angle if @curdir % @otherdir < 0
	@cur_angle = angle
	@curdir
end

#Check inference for a given vector (direction and length)
def check_inference(vecdir, inftype, ptinf)
	return vecdir unless ptinf && vecdir && vecdir.valid? && @radius_bigcircle && @normal.valid?
	pt = ptinf.project_to_plane [@origin, @normal]
	factor = @origin.distance(pt) / @radius_bigcircle
	if inftype == 'B'
		angle = @axe0.angle_between vecdir
		angle = -angle if vecdir % @axe1 < 0
		angle = adjust_angle angle, factor
		@basedir = Geom::Transformation.rotation(@origin, @normal, angle) * @axe0
	else	
		angle = @basedir.angle_between vecdir
		angle = -angle if vecdir % @otherdir < 0
		angle = adjust_angle angle, factor
		@curdir = Geom::Transformation.rotation(@origin, @normal, angle) * @basedir
	end
end

#Adjust angleto round value,depending on distance of input point to Origin
def adjust_angle(angle, factor)
	fac = factor.round + 1
	incr = (fac <= 2) ? 15.0 : ((fac <= 4) ? 5.0 : 1.0)
	tolerance = (fac <= 4) ? incr : (2 * incr / fac)
	dangle = angle.radians
	dangle = dangle.round if fac < 4
	a = dangle / incr
	around = a.round * incr
	afinal = ((dangle - around).abs < tolerance) ? around : dangle
	afinal.degrees
end

#Draw method for tool
def draw(view, factor=1.0)
	return unless @origin
	
	#Compute the right scale to keep the protractor the same size
	size = view.pixels_to_model 1, @origin
	size *= factor if factor
	tdir = Geom::Transformation.axes @origin, @basedir, @otherdir, @normal
	return unless tdir
	t = tdir * Geom::Transformation.scaling(size)
	
	#draw the protractor
	view.drawing_color = @color 
	view.line_stipple = ""
	view.line_width = 1

	pts = []
	@bigcircle.each { |pt| pts.push(t * pt)}
	@radius_bigcircle = @origin.distance pts[0]
	draw2d view, pts, GL_LINE_STRIP		#bug in Sketchup, need a first dummy drawing in 2d
	draw2d view, pts, GL_LINE_STRIP
	
	pts = []
	@inner_up.each { |pt| pts.push(t * pt)}
	draw2d view, pts, GL_LINE_STRIP
	
	pts = []
	@inner_down.each { |pt| pts.push(t * pt)}
	draw2d view, pts, GL_LINE_STRIP
	
	pts = []
	@graduations.each { |pt| pts.push(t * pt)}
	draw2d view, pts, GL_LINES

end

def draw2d(view, pts, type)
	pts2d = pts.collect { |pt| view.screen_coords pt }
	view.draw2d type, pts2d
end

#Draw the dashed line indicating the current angle, with clipping on the view
def draw_dashed_line(view, color=nil, stipple=nil, width=nil)
	return unless @curdir.valid?
	view.drawing_color = Traductor::Couleur.color_vector @curdir, @black_color, @face
	view.line_stipple = (stipple) ? stipple : "_"
	view.line_width = (width) ? width : 1
	pt1 = view.screen_coords @origin
	pt2 = view.screen_coords @origin.offset(@curdir, 1)
	view.draw2d GL_LINES, clip_to_box(view, pt1, pt2)
end

def clip_to_box(view, pt1, pt2)	
	x1 = pt1.x
	y1 = pt1.y
	x2 = pt2.x
	y2 = pt2.y
	vpwidth = view.vpwidth
	vpheight = view.vpheight
	ptbox = [Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(0, 0, 0)]	

	ay = (y1 - y2)
	ax = (x1 - x2)
	
	if (ay == 0)
		ptbox[0].x = 0
		ptbox[0].y = ptbox[1].y = y1
		ptbox[1].x = vpwidth
	elsif (ax == 0)
		ptbox[0].x = ptbox[1].x = x1
		ptbox[0].y = 0
		ptbox[1].y = vpheight
	else
		a = ay / ax
		i = 0
		v = y1 - a * x1						#left edge
		if (v >= 0 && v <= vpheight)		
			ptbox[i].x = 0
			ptbox[i].y = v
			i += 1	
		end	
		v = y1 + a * (vpwidth - x1)		#right edge
		if (v >= 0 && v <= vpheight)
			ptbox[i].x = vpwidth
			ptbox[i].y = v
			return ptbox if ((i += 1) > 1)
		end
		v = x1 - y1 / a 					#top edge
		if (v >= 0 && v <= vpwidth)
			ptbox[i].x = v
			ptbox[i].y = 0
			return ptbox if ((i += 1) > 1)
		end	
		v = x1 + (vpheight - y1) / a		#bottom edge
		if (v >= 0 && v <= vpwidth)
			ptbox[i].x = v
			ptbox[i].y = vpheight
		end
	end
	ptbox
end

end	#class ProtractorShape


end #Module G6

