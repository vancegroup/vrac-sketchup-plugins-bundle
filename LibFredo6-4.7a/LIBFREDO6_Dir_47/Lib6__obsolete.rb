=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed by Fredo6 - Copyright April 2009

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   Lib6__obsolete.rb
# Original Date	:   11 Jan 2011 - version 1.0
# Description	:   Obsolete code kept for a while for compatibility reasons
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# TRADUCTOR Module
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

module Traductor

class Palette

#Shadow bug message
def handle_shadow_bug
	@shadow_bug_displayed = true
end

end	#Class Palette

end	#module Traductor

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
# G6 Module
#--------------------------------------------------------------------------------------------------------------			 
#--------------------------------------------------------------------------------------------------------------			 

module G6

#----------------------------------------------------------------------------
# Curl offset: Offset of a curve with various modes
#----------------------------------------------------------------------------

#Compute the vector and mediator planes for a curve and return a data structure for further use
#This is to speed up perfromance when offsetting several times the same curve
def G6.curl_offset_info(crvpts)
	ncrv = crvpts.length - 1
	
	#Computing the line vectors and the bissector planes
	planes = []
	vecs = []
	normals = []
	for i in 0..ncrv
		pt1 = crvpts[i-1]
		pt2 = crvpts[i]
		pt3 = crvpts[i+1]
		normal = nil
		if i == 0
			vec = vplane = pt2.vector_to(pt3)
		elsif pt3
			vec21 = pt2.vector_to pt1
			vec = pt2.vector_to pt3
			if vec.parallel?(vec21)
				vplane = vec
			else
				normal = vec21 * vec
				vsum = Geom.linear_combination 0.5, vec21, 0.5, vec
				vplane = normal * vsum
			end	
		else
			###vec = vplane = pt2.vector_to(pt1)
			vec = vplane = pt1.vector_to(pt2)
		end	
		planes.push [pt2, vplane]
		vecs.push vec
		normals.push vplane
	end
	
	#Computing the rotation angles
	offset_info = [crvpts, planes, vecs, normals]
	G6.curl_offset_compute_angles offset_info
	
	#Returning the information
	offset_info  
end

#Compute the rotation angles along the curve
def G6.curl_offset_compute_angles(offset_info)
	crvpts, planes, vecs, normals = offset_info
	ncrv = crvpts.length - 1
	
	normal0 = planes[0][1]
	axes = vecs[0].axes
	ori0 = crvpts[0]
	vec0 = axes[1]
	ptoff0 = ori0.offset vec0, 10.0
	ptoff = ptoff0.clone

	#Computing the path for the offset points and rotation angles
	langles = [0]
	angle = nil
	for i in 1..ncrv
		ptoff = Geom.intersect_line_plane [ptoff, vecs[i-1]], planes[i]
		normal = normals[i]
		if normal.parallel?(normal0)
			angle_normal = 0
			ptflat = ptoff
		else
			angle_normal = normal0.angle_between normal
			vz = normal0 * normal
			trot = Geom::Transformation.rotation crvpts[i], vz, -angle_normal
			ptflat = trot * ptoff
		end	
		vx = crvpts[i].vector_to ptflat
		angle = vec0.angle_between vx
	end
	angle
end

#Offset a curl by moving its two extremities
def G6.curl_offset_by_two_points(crvpts, ptbeg, ptend, keep=false)
	G6.curl_Ioffset_by_two_points G6.curl_offset_info(crvpts), G6.curl_offset_info(crvpts.reverse), ptbeg, ptend, keep
end

def G6.curl_Ioffset_by_two_points(offset_info, offset_info_r, ptbeg, ptend, keep=false)
	pts1 = G6.curl_Ioffset_at_point offset_info, ptbeg, keep
	pts2 = G6.curl_Ioffset_at_point offset_info_r, ptend, keep
	G6.curl_average_curve pts1, pts2.reverse
end

#Offset a curl so that its origin passes through a given point <pt>
def G6.curl_offset_at_point(crvpts, pt, keep=false)
	G6.curl_Ioffset_at_point G6.curl_offset_info(crvpts), pt, keep
end

def G6.curl_Ioffset_at_point(offset_info, pt, vecdir=nil)
	#Retrieving the curl parameters
	crvpts, planes, vecs = offset_info
	ncrv = crvpts.length - 1
	#vecdir = Z_AXIS

	#Finding the candidate segment
	lres = []
	for i in 1..ncrv
		line = [pt, vecs[i]]
		pt1 = Geom.intersect_line_plane line, planes[i-1]
		pt2 = Geom.intersect_line_plane line, planes[i]
		d1 = pt.distance crvpts[i-1]
		d2 = pt.distance crvpts[i]
		d = [d1, d2].min
		if pt1 == nil || pt == pt1
			lres.push [i, d]
		elsif pt2 && pt != pt2
			vec12 = pt1.vector_to pt2
			next unless vec12 % vecs[i-1] > 0
			if pt.vector_to(pt1) % pt.vector_to(pt2) < 0
				lres.push [i, d]
			elsif i == 1 && pt.vector_to(pt1) % pt1.vector_to(pt2) > 0
				lres.push [1, d]
			elsif i == ncrv && pt.vector_to(pt1) % pt1.vector_to(pt2) < 0
				lres.push [ncrv+1, d]
			end	
		end
	end	
	lres = lres.sort { |a, b| a[1] <=> b[1] }
	nbeg = (lres.length > 0) ? lres[0][0] : 1

	if vecdir
		ptproj = pt.project_to_plane [crvpts[nbeg-1], vecdir]
		vec0 = ptproj.vector_to pt
	end	
	
	#Computing the offset curve
	ptbeg = pt
	pts_res = Array.new nbeg, ptbeg
	for i in nbeg..ncrv
		ptbeg = Geom.intersect_line_plane [ptbeg, vecs[i-1]], planes[i]
		if vecdir
			pivot = (vec0.valid?) ? crvpts[i].offset(vec0) : crvpts[i]
			ptbeg = ptbeg.project_to_plane([pivot, vecdir])
		end	
		pts_res.push ptbeg
	end

	pts_res	
end

#----------------------------------------------------------------------------
# Curve Offsetting
#----------------------------------------------------------------------------

#Offset a curl so that a point of the curve through a given point <pt>
def G6.curl_offset_by_reference(crvpts, pt, ptref, iseg=nil, keep=nil)
	#Computing the position of the reference on the curve
	unless iseg
		iseg = 0
		for i in 0..crvpts.length-2
			if G6.point_within_segment(ptref, crvpts[i], crvpts[i+1])
				iseg = i
				break
			end	
		end
	end
	
	#Piece onward
	if ptref == crvpts.last
		offpts1 = []
	else	
		pts1 = crvpts[iseg+1..-1]
		pts1 = [ptref] + pts1 unless pts1.first == ptref
		offpts1 = G6.curl_offset_at_point pts1, pt, keep
	end
	
	#Piece backward
	if ptref == crvpts.first
		offpts2 = []
	else	
		pts2 = crvpts[0..iseg]
		pts2.push ptref unless pts2.last == ptref
		offpts2 = G6.curl_offset_at_point pts2.reverse, pt, keep
		offpts2 = offpts2.reverse
	end	
	
	#final offset curve
	offpts2 + offpts1
end


end	#module G6

