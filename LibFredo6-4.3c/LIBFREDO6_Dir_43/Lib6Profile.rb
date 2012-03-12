=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed by Fredo6 - Copyright July 2010

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   Lib6Profile.rb
# Original Date	:   8 Jul 10 
# Description	:   Algorithms for profiling
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module Traductor								  

#---------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------
# Class Profiling: implement the algorithm for profile rounding
#---------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------

class Profiling

@@hsh_profile_pts = {}

#---------------------------------------------------------------------------------------------------------------------------
# Profiling methods
#---------------------------------------------------------------------------------------------------------------------------

#Compute the transformed profile by indicating the start and end point, and the start vector and end face
def Profiling.compute_by_vectors(prf_type, pt1, vec1, pt2, normal2)
	origin = Geom.intersect_line_plane [pt1, vec1], [pt2, normal2]
	offset1 = origin.distance pt1
	offset2 = origin.distance pt2
	vec2 = origin.vector_to pt2
	Profiling.compute_by_offset prf_type, origin, vec1, offset1, vec2, offset2
end

def Profiling.compute_by_vectors2(prf_type, pt1, vec1, pt2, vec2)
	lpt = Geom.closest_points [pt1, vec1], [pt2, vec2]
	origin = Geom.linear_combination 0.5, lpt[0], 0.5, lpt[1]
	offset1 = origin.distance pt1
	offset2 = origin.distance pt2
	vec1 = origin.vector_to pt1
	vec2 = origin.vector_to pt2
	Profiling.compute_by_offset prf_type, origin, vec1, offset1, vec2, offset2
end

def Profiling.compute_by_normals(prf_type, pt1, normal1, pt2, normal2)

	if pt1 == pt2
		return Array.new(prf_type[1]+1, pt1)
	end
	
	lpt = Geom.closest_points [pt1, normal1], [pt2, normal2]
	
	#Deciding on S-curve
	vecm1 = pt1.vector_to lpt[0]
	vecm2 = pt2.vector_to lpt[1]
	unless vecm1.valid? && vecm2.valid? && vecm1.samedirection?(normal1) && vecm2.samedirection?(normal2.reverse)
		ptmid = Geom.linear_combination 0.5, pt1, 0.5, pt2
		if normal1.parallel?(normal2)
			if ptmid.on_line? [pt1, normal1]
				d = pt1.distance ptmid
				return Profiling.compute_by_offset(prf_type, ptmid, normal1, d, normal2, d)
			end
			znormal = normal1 * pt1.vector_to(ptmid)
			vecmid = normal1 * znormal			
		else
			znormal = normal1 * normal2		
			vecsum = Geom.linear_combination 0.5, normal1, 0.5, normal2
			vecmid = vecsum.normalize * znormal.normalize
		end
		pts1 = Profiling.compute_by_vectors2 prf_type, pt2, vecmid.normalize, pt1, normal1
		pts2 = Profiling.compute_by_vectors2 prf_type, pt2, normal2, pt1, vecmid.normalize
		bz = G6.curl_average_curve pts1, pts2
		return bz
	end
	
	#Direct path
	Profiling.compute_by_vectors2 prf_type, pt2, normal2, pt1, normal1
end

#Compute the transformed profile by indicating the offsets and direction on faces
def Profiling.compute_by_offset(prf_type, origin, vec1, offset1, vec2, offset2)	
	#Getting the nominal profile
	pts = Profiling.nominal_profile prf_type

	#Transformation from golden normalized form
	coef = [0, -offset1, 0, 0] + [-offset1, 0, 0, 0] + [0, 0, 1, 0] + [offset1, offset1, 0, 1]
	tsg = Geom::Transformation.new coef
	
	#Scaling and shearing to adjust differences of offset and angle
	angle = 0.5 * Math::PI - vec1.angle_between(vec2)
	tgt = Math.tan angle
	fac = offset2 / offset1 * Math.cos(angle)
	coef = [1, 0, 0, 0] + [0, fac, 0, 0] + [0, 0, 1, 0] + [0, 0, 0, 1]
	ts = Geom::Transformation.new coef
	coef = [1, 0, 0, 0] + [tgt, 1, 0, 0] + [0, 0, 1, 0] + [0, 0, 0, 1]
	tsh = Geom::Transformation.new coef
	
	#Transforming to match given coordinates at origin, vec1, vec2
	normal = vec1 * vec2
	if normal.valid?
		taxe = Geom::Transformation.axes origin, vec1, normal * vec1, normal
	else
		axes = vec1.axes
		taxe = Geom::Transformation.axes origin, axes[2], axes[0], axes[1]
	end
	t = taxe * tsh * ts * tsg
	
	#Performing the transformation
	pts.collect { |pt| t * pt }
end

#Get the nominal profile and compute Nb of segment
def Profiling.verify_profile(prf_type, numseg=nil)
	type = prf_type[0]
	@num_seg_lock = (type =~ /P/i) ? true : false
	if numseg && !@num_seg_lock
		@prf_type[1] = numseg
	end	
	pts = Profiling.nominal_profile(@prf_type)
	@num_seg = pts.length - 1
end

#Get the nominal profile and compute Nb of segment
def Profiling.nominal_profile(prf_type)
	#Computing the normalized profile in X, Y
	type = prf_type[0]
	param = prf_type[1]
	key = "#{type}-#{param}"
			
	#Profile already computed
	pts = @@hsh_profile_pts[key]
	return pts if pts
	
	#Creating the profile
	case type
	when 'BZ'
		pts = Profiling.golden_bezier param
	when 'CR'
		pts = Profiling.golden_circular_reverse param
	when /\AP/i
		pts = Profiling.golden_perso param
	else
		pts = Profiling.golden_circular param
	end
	@@hsh_profile_pts[key] = pts
	
	pts
end

def Profiling.golden_circular(nb_seg)
	pts = []
	anglesec = 0.5 * Math::PI / nb_seg
	for i in 0..nb_seg
		angle = anglesec * i
		x = Math.cos(angle)
		y = Math.sin(angle)
		pts.push Geom::Point3d.new(x, y, 0)
	end	
	pts.reverse
end

def Profiling.golden_circular_reverse(nb_seg)
	pts = []
	anglesec = 0.5 * Math::PI / nb_seg
	for i in 0..nb_seg
		angle = anglesec * i
		x = 1.0 - Math.sin(angle)
		y = 1.0 - Math.cos(angle)
		pts.push Geom::Point3d.new(x, y, 0)
	end	
	pts.reverse
end

def Profiling.golden_bezier(nb_seg)
	pt1 = Geom::Point3d.new 0, 1, 0
	pt2 = Geom::Point3d.new 1, 1, 0
	pt3 = Geom::Point3d.new 1, 0, 0
	ctrl_pts = [pt1, pt2, pt3]
	G6::BezierCurve.compute(ctrl_pts, nb_seg)
end

def Profiling.golden_perso(fac)
	pt1 = Geom::Point3d.new 0, 1, 0
	pt2 = Geom::Point3d.new 1, 1, 0
	pt3 = Geom::Point3d.new 1, 0, 0
	pt4 = Geom::Point3d.new fac, fac, 0
	ctrl_pts = [pt1, pt2, pt3]
	crv1 = G6::BezierCurve.compute ctrl_pts, 8
	ctrl_pts = [crv1[3], pt4, crv1[5]]
	crv2 = G6::BezierCurve.compute ctrl_pts, 6
	crv = crv1[0..2] + crv2 + crv1[6..-1]
	crv
end

end	#class profiling

end	#End Module Traductor
