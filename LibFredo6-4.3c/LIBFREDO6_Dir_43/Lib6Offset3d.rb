=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed January 2011 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:   Lib6Offset3d.rb
# Original Date	:   01 Jan 2011
# Description	:   Utilities related to Offset 3d for curves
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

module G6

#-----------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------
# Curve 3D Offsetting
#-----------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------

#Compute the vector and mediator planes for a curve and return a data structure for further use
#This is to speed up perfromance when offsetting several times the same curve
def G6.offset3d_info(crvpts, range=nil)
	#Computing the list of point triplets
	ltriplets = G6.curl_triplets crvpts, range
	ncrv = crvpts.length - 1
	range = G6.range range, 0, ncrv
	
	#Computing the line vectors and the bissector planes
	planes = []
	vecs = []
	normals = []
	for i in range
		pt1, pt2, pt3 = ltriplets[i]
		if pt1 == nil
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
			vec = vplane = pt1.vector_to(pt2)
		end	
		planes.push [pt2, vplane]
		vecs.push vec
		normals.push vplane
	end
	
	#Computing the rotation angles
	offset_info = [crvpts, planes, vecs, normals, ltriplets]
	
	#Returning the information
	offset_info  
end

#Compute the offset curve at a single point
# Direction is specified as 
#    +1 --> onward
#    0   --> both side
#    -1  --> backward
def G6.offset3d_at_point(offset_info, pt, iseg=nil, direction=nil, simplify=false)
	#Retrieving the curl parameters
	crvpts, planes, vecs = offset_info
	loop = (crvpts[0] == crvpts[-1])
	nb = crvpts.length
	ncrv = nb - 1
	loop = (crvpts[0] == crvpts[-1])
	pts = []

	#Finding the candidate segments
	ibeg = G6.offset3d_locate_point offset_info, pt, iseg
	ibeg = 1 unless ibeg
		
	#deciding on the direction
	direction = 0 unless direction
	direction = 0 if loop
	
	#Computing the offset curve - onward from point
	if direction >= 0
		ptcur = pt
		for i in ibeg..ncrv
			ptcur = Geom.intersect_line_plane [ptcur, vecs[i-1]], planes[i]
			pts[i] = ptcur
		end
	end
	
	#Computing the offset curve - backward from point
	if direction <= 0
		ptcur = pt
		n = ibeg - 1
		for i in 0..n
			j = n - i
			ptcur = Geom.intersect_line_plane [ptcur, vecs[j]], planes[j]
			pts[j] = ptcur
		end
	end
	
	#Completing the points
	if direction != 0
		for i in 0..ncrv
			pts[i] = pt unless pts[i]
		end
	end
		
	#Resolving the overlaps
	pts = G6.offset3d_resolve_overlaps crvpts, pts if simplify

	pts
end

#Compute the resulting curve along the path between two points
def G6.offset3d_at_two_points(offset_info, ptbeg, ptend, iseg1=nil, iseg2=nil, simplify=false)
	#Retrieving the curl parameters
	crvpts, planes, vecs = offset_info
	nb = crvpts.length
	ncrv = nb - 1
	loop = (crvpts[0] == crvpts[-1])

	#Finding the candidate segments
	ibeg = G6.offset3d_locate_point offset_info, ptbeg, iseg1
	iend = G6.offset3d_locate_point offset_info, ptend, iseg2
	ibeg = 1 unless ibeg
	iend = ncrv unless loop || (iend && iend >= ibeg)
		
	#Computing the offset curve - onward from beg point
	pts_beg = Array.new ibeg, ptbeg
	ptcur = ptbeg
	for i in ibeg..ncrv
		ptcur = Geom.intersect_line_plane [ptcur, vecs[i-1]], planes[i]
		pts_beg.push ptcur
	end

	#Computing the offset curve - backward from end point
	pts_end = []
	ptcur = ptend
	for i in 0..iend-1
		j = iend - i - 1
		ptcur = Geom.intersect_line_plane [ptcur, vecs[j]], planes[j]
		pts_end.push ptcur
	end
	pts_end = pts_end.reverse
	for i in iend..ncrv
		pts_end[i] = ptend
	end	
	pts_end[ncrv] = ptend
	
	#Resolving the possible overlaps
	if simplify
		pts_beg = G6.offset3d_resolve_overlaps crvpts, pts_beg
		pts_end = G6.offset3d_resolve_overlaps crvpts, pts_end
	end
	
	#Average of the two curves
	G6.curl_average_curve pts_beg, pts_end, true
end

#Locate the segment number of a given 3D point 
def G6.offset3d_locate_point(offset_info, pt, iseg=nil)
	#Retrieving the curl parameters
	crvpts, planes, vecs = offset_info
	ncrv = crvpts.length - 1
	lres = []

	#Finding the candidate segment close to the segment given
	if iseg
		i0, d0 = G6.offset3d_match_segment offset_info, pt, iseg
		for j in iseg+1..ncrv+1
			i, d = G6.offset3d_match_segment offset_info, pt, j
			#break if d0 && (d == nil || d > d0)
			break if d0 && (!d || d > d0)
			i0, d0 = i, d
		end
		for k in 0..iseg-1
			j = iseg - 1 - k
			i, d = G6.offset3d_match_segment offset_info, pt, j
			next unless d
			break if d0 && d > d0
			i0, d0 = i, d
		end
		return i0
	end
	
	#Finding the candidate segment when no indication of close segment is given
	for i in 0..ncrv+1
		res = G6.offset3d_match_segment offset_info, pt, i
		lres.push res if res
	end	
	return nil if lres.empty?
	lres = lres.sort { |a, b| (a[1] == b[1]) ? a[0] <=> b[0] : a[1] <=> b[1] }
	lres[0][0]
end

#Locate the segment number of a given 3D point 
# iseg is the index of the segment, with the following convention:
#   - 0 --> on open segment before the first point of the curve
#   - 1 --> on segment between the first point and the last point of the curve
#   - ncrv+1 --> on open segment after the last point of the
def G6.offset3d_match_segment(offset_info, pt, iseg)
	#Retrieving the curl parameters
	crvpts, planes, vecs = offset_info
	ncrv = crvpts.length - 1

	#Adjustment and main directions
	i = iseg
	i = 1 if i <= 0
	i = ncrv if i > ncrv
	line = [pt, vecs[i-1]]
	pt1 = Geom.intersect_line_plane line, planes[i-1]
	pt2 = Geom.intersect_line_plane line, planes[i]
	d, = G6.proximity_point_segment pt, crvpts[i-1], crvpts[i]
	#d = pt.distance_to_line [crvpts[i-1], crvpts[i]]
	vec12 = pt1.vector_to pt2
	
	#Before the first segment
	if iseg <= 0
		return [i, d] if pt == pt1 || (pt.vector_to(pt1) % pt.vector_to(pt2) > 0 && pt.vector_to(pt1) % vec12 > 0)

	#After the last segment
	elsif iseg > ncrv
		return [i, d] if pt == pt2 || (pt.vector_to(pt1) % pt.vector_to(pt2) > 0 && pt.vector_to(pt1) % vec12 < 0)
	
	#Within the curve
	else
		return [i, d] if pt == pt1 || pt == pt2 || pt.vector_to(pt1) % pt.vector_to(pt2) < 0
	end	
	
	#Point does not match requested segment
	nil
end

#Compute the rotation angles along the curve
def G6.offset3d_twist_angle(offset_info, ibeg=nil, iend=nil)
	crvpts, planes, vecs, normals = offset_info
	loop = (crvpts[0] == crvpts[-1])
	ncrv = crvpts.length - 1
	nb = crvpts.length
	ibeg = 1 unless ibeg && ibeg > 0
	iend = ncrv unless iend && iend <= ncrv
	
	#Parameters at the beginning
	istart = (ibeg-1+nb).modulo(nb)
	normal0 = planes[istart][1]
	axes = vecs[istart].axes
	vec0 = axes[1]
	ptoff0 = crvpts[istart].offset vec0, 10.0
	ptoff = ptoff0.clone

	#Computing the path for the offset points and rotation angles
	langles = [0]
	angle = nil
	iend += nb if crvpts[0] == crvpts[-1]
	lim = (iend - ibeg).abs
	for k in 0..lim
		i = (ibeg+k).modulo(nb)
		i1 = (i-1+nb).modulo(nb)
		ptoff = Geom.intersect_line_plane [ptoff, vecs[i1]], planes[i]
		normal = normals[i]
		if normal.parallel?(normal0)
			ptflat = ptoff
		else
			angle_normal = normal0.angle_between normal
			vz = normal0 * normal
			trot = Geom::Transformation.rotation crvpts[i], vz, -angle_normal
			ptflat = trot * ptoff
		end	
		vx = crvpts[i].vector_to ptflat
		angle = vec0.angle_between vx
		angle = -angle if (vec0 * vx) % normal0 > 0
	end

	angle
end

#Resolve the overlaps of an offset curve pts, generated by offset
def G6.offset3d_resolve_overlaps(crvpts, pts)
	#return pts
	ncrv = crvpts.length - 1
	loop = (crvpts.first == crvpts.last)
		
	#Splitting the curve into straight and reversed sections
	ls_chunks = []
	cur_chunk = nil
	sign = true
	for i in 1..ncrv
		k = i - 1
		vec = pts[k].vector_to pts[i]
		crvec = crvpts[k].vector_to crvpts[i]	
		sign = vec.samedirection?(crvec) if vec.valid?
		
		if cur_chunk && sign == cur_chunk[0]
			cur_chunk[1].push i
		else
			cur_chunk = [sign, [i-1, i]]
			ls_chunks.push cur_chunk
		end	
	end
	
	#No overlap - Simplification not needed
	return pts if ls_chunks.length < 2
	
	#Extending the chunks when loop
	if loop
		chunk_beg = ls_chunks.first
		chunk_end = ls_chunks.last
		if chunk_beg[0] == chunk_end[0]
			chunk_beg[1] = chunk_end[1] + chunk_beg[1]
			ls_chunks = ls_chunks[0..-2]
		end	
	end

	#Building the portions to treat
	newpts = pts.clone
	nchunks = ls_chunks.length - 1
	for i in 0..nchunks
		chunk = ls_chunks[i]
		next if chunk[0]
		prev_chunk = (i == 0 && loop) ? ls_chunks.last : ls_chunks[i-1]
		next_chunk = (i == nchunks && loop) ? ls_chunks.first : ls_chunks[i+1]
		return newpts unless next_chunk && prev_chunk
		G6.offset3d_adjust_chunks pts, newpts, loop, prev_chunk[1], chunk[1], next_chunk[1]
	end
		
	newpts
end

#Ancillary method to proceed with the resolution of an overlap based on calculated chunks
def G6.offset3d_adjust_chunks(pts, newpts, loop, prev_chunk, chunk, next_chunk)
	#Simplification only applies at first level for now
	ptchunk = chunk.collect { |i| pts[i] }
	return unless G6.curl_is_aligned?(ptchunk)
	
	#Determining the intersection couples in order
	nprev = prev_chunk.length - 2
	nnext = next_chunk.length - 2
	n = [nprev, nnext].max

	lsnum = []
	for k in 0..n
		if k <= nnext
			for i in 0..k-1
				break if i > nprev
				lsnum.push [i, k]
			end
		end	
		if k <= nprev
			for i in 0..k
				break if i > nnext
				lsnum.push [k, i]
			end
		end	
	end	
	
	#Checking the intersections
	good = nil
	lsnum.each do |a|
		i, j = a
		k = nprev - i
		lpt = [pts[prev_chunk[k]], pts[prev_chunk[k+1]], pts[next_chunk[j]], pts[next_chunk[j+1]]]
		result = G6.segments_intersection3D *lpt
		next unless result
		d, pt1, pt2 = result
		if d == 0
			good = [i, j] + result
			break
		elsif !good || d < good[2]
			good = [i, j] + result
		end
	end	
	
	#Modifying the curve
	return unless good
	
	i, j, d, pt1, pt2 = good
	lspt = prev_chunk[nprev-i..-2] + chunk + next_chunk[0..j+1]
	ptfirst = pts[chunk.first]
	ptlast = pts[chunk.last]
	dseg = [ptfirst.distance(pts[lspt[1]]), ptlast.distance(pts[lspt[-1]])].min
	
	ptmid = Geom.linear_combination 0.5, pt1, 0.5, pt2
	d = pt1.distance(pt2)
	if d <= 0.6 * dseg || lspt.length <= 3	
		newpts[lspt[1]] = pt1
		lspt[1..-2].each { |i| newpts[i] = ptmid }
		newpts[lspt[-2]] = pt2
	else
		vec1 = pts[lspt[0]].vector_to pts[lspt[1]]
		vec2 = pts[lspt[-1]].vector_to pts[lspt[-2]]
		pt1a = pt1.offset vec1, d * 0.4
		pt2a = pt2.offset vec2, d * 0.4
		n = lspt.length - 2
		bz = G6::BezierCurve.compute [pt1, pt1a, pt2a, pt2], n
		for i in 0..n
			newpts[lspt[i+1]] = bz[i]
		end	
	end
end

end	#module G6
