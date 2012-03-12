=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed December 2009 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Spline.rb
# Original Date	:  25 Dec 2009 - version 1.0
# Description	:  Methods for generating splines
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module G6

#--------------------------------------------------------------------------------------------------------------
# Bezier Curve
#--------------------------------------------------------------------------------------------------------------			 				   

class BezierCurve

@@time = 0

# Evaluate the curve at a number of points and return the points in an array
def BezierCurve.compute(pts, numpts) 
	return pts if pts.length < 3
	
	t0 = Time.now.to_f
    curvepts = []
    dt = 1.0 / numpts
	0.upto(numpts) { |i| curvepts[i] = evaluate(pts, i * dt) }
	@@time += Time.now.to_f - t0
    curvepts
end

def self.evaluate(pts, t)
    degree = pts.length - 1
    return nil if degree < 1
   
    t1 = 1.0 - t
    fact = 1.0
    n_choose_i = 1

    x = pts[0].x * t1
    y = pts[0].y * t1
    z = pts[0].z * t1
    
    for i in 1...degree
		fact = fact * t
		n_choose_i = n_choose_i * (degree - i + 1) / i
        fn = fact * n_choose_i
		x = (x + fn * pts[i].x) * t1
		y = (y + fn * pts[i].y) * t1
		z = (z + fn * pts[i].z) * t1
    end

	x = x + fact * t * pts[degree].x
	y = y + fact * t * pts[degree].y
	z = z + fact * t * pts[degree].z

    Geom::Point3d.new(x, y, z)  
end 

def BezierCurve.time(reset=false)
	@@time = 0 if reset
	@@time
end

end	#class BezierCurve

#--------------------------------------------------------------------------------------------------------------
# Uniform BSpline
#--------------------------------------------------------------------------------------------------------------			 				   

class UniformBSpline

@@time = 0

# Calculation function to compute the Cubic Bezier curve
# receive a array of points (array of three values, x, y and z) and the number of segments
# to interpolate betwen each two points of the array of points
def UniformBSpline.compute(pts, numseg, order)
	return pts if pts.length < 3
	t0 = Time.now.to_f

	#Adjusting the points
	pts = adjust_points pts
	
	#initialization
	curve = []
	nbpts = pts.length
	order = nbpts if (order > nbpts || order == 0)
	kmax = nbpts + order - 1
	
	#Generating the uniform open knot vector
	knot = []
	knot[0] = 0.0
	for i in 1..kmax
		knot[i] = ((i >= order) && (i < nbpts + 1)) ? knot[i-1] + 1.0 : knot[i-1]
	end
	
	#calculate the points of the B-Spline curve
	t = 0.0
	step = knot[kmax] / numseg
	for icrv in 0..numseg	
		#calculate parameter t
		t = knot[kmax] if (knot[kmax] - t) < 0.0000001
		
		#calculate the basis
		basis = SplineBasis.compute_basis order, t, nbpts, knot, numseg
		
		#Loop on the control points
		pt = Geom::Point3d.new
		pt.x = pt.y = pt.z = 0.0
		for i in 0..(nbpts-1)
			pt.x += basis[i] * pts[i].x
			pt.y += basis[i] * pts[i].y
			pt.z += basis[i] * pts[i].z
		end
		curve.push pt
		t += step
	end
 	@@time += Time.now.to_f - t0

    return curve
end

def self.adjust_points(pts)
	[pts.first] + pts + [pts.last]
end

def UniformBSpline.time(reset=false)
	@@time = 0 if reset
	@@time
end

end	#class UniformBSpline

#--------------------------------------------------------------------------------------------------------------
# Catmull Spline Curve
#--------------------------------------------------------------------------------------------------------------			 				   

class CatmullCurve

@@time = 0

# Calculation function to compute the Catmull Spline
# Receive a array of points (array of three values, x, y and z) and the number of segments
# numseg can be a number of interpolated segment by portion or a list of numbers for each individual portion
def CatmullCurve.compute(pts, numseg)
	return pts if pts.length < 3
	t0 = Time.now.to_f
	
	#Adding points at extremities, unless we close the loop
	ptslast = pts.last
	loop = (pts.first == pts.last) && !pts[1..-2].include?(pts.last)
	pts = pts[0..-2] if loop
	pts = CatmullCurve.adjust_points pts unless loop
	nbpts = pts.length - 4	
	
	#List of numseg
	lnumseg = (numseg.is_a?(Array)) ? numseg : Array.new(pts.length - 1, numseg)
	lnumseg = [lnumseg.first] + lnumseg + [lnumseg.last] unless loop
	
	#computing the Catmull spline by portion	
	curve = []
	CatmullCurve.portion curve, pts, -1, lnumseg if loop
	for i in 0..nbpts
		CatmullCurve.portion curve, pts, i, lnumseg
	end	

	# Closing the loop via a segment or a portion of Catmull spline
	if loop 
		CatmullCurve.portion curve, pts, -3, lnumseg
		CatmullCurve.portion curve, pts, -2, lnumseg
		curve.push ptslast
	else
		curve.push ptslast
	end

 	@@time += Time.now.to_f - t0
	
    return curve
end


# Add a point at each extremity, to handle first and last point
def CatmullCurve.adjust_points(pts)
	ptfirst = pts[0].offset pts[0].vector_to(pts[1]).reverse
	ptlast = pts[-1].offset pts[-2].vector_to(pts[-1])	
	[ptfirst] + pts + [ptlast]
end

#Compute a portion of the Catmull spline
def CatmullCurve.portion (curve, pts, ibeg, lnumseg)
	p1 = pts[ibeg]
	p2 = pts[ibeg+1]
	p3 = pts[ibeg+2]
	p4 = pts[ibeg+3]
	numseg = lnumseg[ibeg+1]
	dt = 1.0 / numseg
	for i in 0..numseg-1
		t = i * dt
		pt = Geom::Point3d.new
		pt.x = CatmullCurve.interpolate p1.x, p2.x, p3.x, p4.x, t		
		pt.y = CatmullCurve.interpolate p1.y, p2.y, p3.y, p4.y, t		
		pt.z = CatmullCurve.interpolate p1.z, p2.z, p3.z, p4.z, t	
		curve.push pt
	end
end

# Calculate the coordinates of a point interpolated at <t>
def CatmullCurve.interpolate(a1, a2, a3, a4, t)
	(a1 * ((-t + 2) * t - 1) * t + a2 * (((3 * t - 5) * t) * t + 2) +
     a3 * ((-3 * t + 4) * t + 1) * t + a4 * ((t - 1) * t * t)) * 0.5
end

def CatmullCurve.time(reset=false)
	@@time = 0 if reset
	@@time
end

end	#class CatmullCurve

#--------------------------------------------------------------------------------------------------------------
# Uniform FSpline
#--------------------------------------------------------------------------------------------------------------			 				   

class FSpline

def FSpline.compute(pts_orig, precision)	
	#Computing the bissector for each original control points
	order = 3
	order = pts_orig.length if order > pts_orig.length
	nbpts = pts_orig.length - 2
	vplane = []
	result = []
	pts = [pts_orig.first]
	for i in 1..nbpts
		vec1 = pts_orig[i].vector_to(pts_orig[i-1]).normalize
		break if (pts_orig[i] == pts_orig[i+1])
		vec2 = pts_orig[i].vector_to(pts_orig[i+1]).normalize
		vbis = vec1 + vec2
		normal = (vbis.valid?) ? vbis * (vec1 * vec2) : vec1
		vplane[i] = [pts_orig[i], normal]
		pts[i] = pts_orig[i]
	end
	
	#Iteration on moving control points
	pts += [pts_orig.last]
	factor = 1.5
	
	curve = UniformBSpline.compute pts_orig, precision, order
	for iter in 0..2
		ptinter = FSpline.compute_intersect pts_orig, curve, vplane
		next unless ptinter.length > 0
		for i in 1..nbpts
			d = pts_orig[i].distance ptinter[i]
			vec = ptinter[i].vector_to pts_orig[i]
			pts[i] = pts[i].offset vec, d * factor if vec.valid?
		end	
		curve = UniformBSpline.compute pts, precision, order
		
	end	
	return curve
end

def FSpline.compute_intersect(pts, curve, vplane)
	nbpts = pts.length - 2
	nbcurve = curve.length - 2
	ptinter = [curve[0]]
	jbeg = 0
	for i in 1..nbpts
		for j in jbeg..nbcurve
			begin
				pt = FSpline.intersect_segment_plane(curve[j], curve[j+1], vplane[i])
			rescue
				break
			end	
			if pt
				ptinter[i] = pt
				jbeg = j
				break
			end
		end
	end	
	ptinter += [curve.last]
	return ptinter
end

def FSpline.intersect_segment_plane(pt1, pt2, plane)
	pt = Geom.intersect_line_plane [pt1, pt2], plane
	return nil unless pt
	return pt if (pt == pt1) || (pt == pt2)
	vec1 = pt1.vector_to pt
	vec2 = pt2.vector_to pt
	(vec1 % vec2 <= 0) ? pt : nil
end

end	#class FSpline

#--------------------------------------------------------------------------------------------------------------
# CubicBezier Interpolation
#--------------------------------------------------------------------------------------------------------------			 				   

class CubicBezier

# Calculation function to compute the Cubic Bezier curve
# receive a array of control points <pts> (array of three values, x, y and z) and the number of segments
# to interpolate betwen each two points of the array of points
# numseg can be a number of interpolated segment by portion or a list of numbers for each individual portion
def CubicBezier.compute(pts, numseg)
	pts = CubicBezier.prepare_points pts
	curve = []
	npts = pts.length - 1

 	#List of numseg
	lnumseg = (numseg.is_a?(Array)) ? numseg : Array.new(pts.length - 1, numseg)
	lnumseg = [lnumseg.first] + lnumseg + [lnumseg.last]
 
	#Computing the auxiliary points
	aux_cpoints = find_cpoints(pts)
	aux_pointscpoints = join_pointscpoints(pts, aux_cpoints)

	nt1 = lnumseg[0]
	nt2 = lnumseg[-1]
	for i in 0..npts-1
		nt = lnumseg[i]
		aux_p0 = aux_pointscpoints[3 * i]
		aux_p1 = aux_pointscpoints[3 * i + 1]
		aux_p2 = aux_pointscpoints[3 * i + 2]
		aux_p3 = aux_pointscpoints[3 * i + 3]
		aux_abc = CubicBezier.calculate_coef_abc aux_p0, aux_p1, aux_p2, aux_p3
		aux_segment = CubicBezier.segment aux_p0, aux_abc, lnumseg[i]
		aux_segment.pop
		curve = curve + aux_segment
	end

	curve.push aux_pointscpoints[3 * npts]

	curve[nt1..-(nt2+1)]
end

#Prepare extremities
def CubicBezier.prepare_points(points)
	pt1 = points[0]
	pt2 = points[1]
	vec = pt2.vector_to pt1
	d = pt1.distance pt2
	ptbeg = pt1.offset vec, d
	
	pt1 = points[-1]
	pt2 = points[-2]
	vec = pt2.vector_to pt1
	vec = points[-3].vector_to pt1 unless vec.valid?	
	d = pt1.distance pt2
	ptend = pt1.offset vec, d
	
	[ptbeg] + points + [ptend]
end

# given a nt integer (number of segments to interpolate) interpolate nt points of a segment
def CubicBezier.segment(p0, abc, nt)
	segment = []
	for ind in (0..nt)
		segment[ind] = CubicBezier.point p0, abc, ind/nt.to_f
	end
	segment
end

# given a point, the abc coeficients and a 0<=t<=1, interpolate a point using the cubic formula
def CubicBezier.point(p0, abc, t)
	t2 = t * t
	t3 = t2 * t
	x = abc[0][0] * t3 + abc[1][0] * t2 + abc[2][0] * t + p0[0] 
	y = abc[0][1] * t3 + abc[1][1] * t2 + abc[2][1] * t + p0[1]
	z = abc[0][2] * t3 + abc[1][2] * t2 + abc[2][2] * t + p0[2]
	Geom::Point3d.new(x, y, z)
end

# calculate the abc coeficients of four points for the cubic formula
def CubicBezier.calculate_coef_abc(p0, p1, p2, p3)
	aux_c = [3 * (p1[0] - p0[0]), 3 * (p1[1] - p0[1]), 3 * (p1[2] - p0[2])]
	aux_b = [3 * (p2[0] - p1[0]) - aux_c[0], 3 * (p2[1] - p1[1]) - aux_c[1], 3 * (p2[2] - p1[2]) - aux_c[2]]
	aux_a = [p3[0] - p0[0] - aux_c[0] - aux_b[0], p3[1] - p0[1] - aux_c[1] - aux_b[1], p3[2] - p0[2] - aux_c[2] - aux_b[2]]

	[aux_a, aux_b, aux_c]
end

# find the cpoints vector of a main points vector
def CubicBezier.find_cpoints(points)
	cpoints = []
	aux_a = []
	aux_b = []
	np = points.length - 1

	cpoints[0] = [(points[1][0] - points[0][0]) / 3, (points[1][1] - points[0][1]) / 3, (points[1][2] - points[0][2]) / 3]
	cpoints[np] = [(points[np][0] - points[np - 1][0]) / 3, (points[np][1] - points[np - 1][1]) / 3, (points[np][2] - points[np - 1][2]) / 3]
						  
	aux_b[1] = -0.25
	aux_a[1] = [(points[2][0] - points[0][0] - cpoints[0][0]) / 4, 
	            (points[2][1] - points[0][1] - cpoints[0][1]) / 4, 
				(points[2][2] - points[0][2] - cpoints[0][2]) / 4]

	for i in 2..np-1
		aux_b[i] = -1 / (4 + aux_b[i - 1])
		aux_a[i] = [-(points[i + 1][0] - points[i - 1][0] - aux_a[i - 1][0]) * aux_b[i], 
		            -(points[i + 1][1] - points[i - 1][1] - aux_a[i - 1][1]) * aux_b[i], 
					-(points[i + 1][2] - points[i - 1][2] - aux_a[i - 1][2]) * aux_b[i]]
	end

	for i in 1..np-1
		cpoints[np - i] = [aux_a[np - i][0] + aux_b[np - i] * cpoints[np - i + 1][0], 
		                   aux_a[np - i][1] + aux_b[np - i] * cpoints[np - i + 1][1], 
						   aux_a[np - i][2] + aux_b[np - i] * cpoints[np - i + 1][2]]
	end

	return cpoints
end


# Join two vectors, main points vector and cpoints vector
def CubicBezier.join_pointscpoints(points, cpoints)
	pointscpoints = []
	np = points.length - 1

	for i in 0..np-1
		j = i + 1
		pointscpoints.push points[i]
		pointscpoints.push [points[i][0] + cpoints[i][0], points[i][1] + cpoints[i][1], points[i][2] + cpoints[i][2]]
		pointscpoints.push [points[j][0] - cpoints[j][0], points[j][1] - cpoints[j][1], points[j][2] - cpoints[j][2]]
	end

	pointscpoints.push points[np]

	pointscpoints
end

end	#class CubicBezier

#--------------------------------------------------------------------------------------------------------------
# SplineBasis: utility class to compute spline basis (used for Bspline and NURBS)
#--------------------------------------------------------------------------------------------------------------			 				   

class SplineBasis

@@hsh_all_basis = {}
@@lst_all_basis = []
@@max_basis = 500

# given a nt integer (number of segments to interpolate) interpolate nt points of a segment
def SplineBasis.compute_basis(order, t, nbpts, knot, numseg)
	t0 = Time.now.to_f
	
	#Checking if basis not already computed
	key = "#{order} - #{t * 1000000} - #{nbpts} - #{numseg}"
	basis = @@hsh_all_basis[key]
	return basis if basis
	
	#Computing the basis vector
    basis = []
	kmax = nbpts + order - 1

    for i in 0..(kmax-1)
		basis [i] = (t >= knot[i] && t < knot[i+1]) ? 1.0 : 0.0
    end
	
	for k in 1..(order-1)
		for i in 0..(kmax-k-1)
			d = (basis[i] == 0.0) ? 0 : ((t - knot[i]) * basis[i]) / (knot[i+k] - knot[i])
			e = (basis[i+1] == 0.0) ? 0 : ((knot[i+k+1] - t) * basis[i+1]) / (knot[i+k+1] - knot[i+1])
			basis[i] = d + e
		end
	end
	basis[nbpts-1] = 1.0 if t == knot[kmax]

	#Saving the values to avoid recomputation
	@@hsh_all_basis[key] = basis
	
	#Register the key and possible cleanup
	if @@lst_all_basis.length > @@max_basis
		n = @@max_basis / 2
		for i in 0..n
			@@hsh_all_basis.delete @@lst_all_basis[i]
		end	
		@@lst_all_basis = @@lst_all_basis[n+1..-1]
	end
	
	@@lst_all_basis.push key
	
	return basis
end

end	#class SplineBasis

end	#End Module G6
