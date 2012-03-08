# Copyright 2004-2005, @Last Software, Inc.

# This software is provided as an example of using the Ruby interface
# to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

#-----------------------------------------------------------------------------
#
# This bezier.rb file is modified from the original @Last version.
# All the tools and menu items have been removed.
# - Thomas Thomassen
#
#-----------------------------------------------------------------------------

require 'TT_Lib2/core.rb'
require 'TT_Lib2/geom3d.rb'

# @since 2.5.0
module TT::Geom3d::Bezier

  # Evaluate a Bezier curve at a parameter.
  # The curve is defined by an array of its control points.
  # The parameter ranges from 0 to 1
  # This is based on the technique described in "CAGD  A Practical Guide, 4th Editoin"
  # by Gerald Farin. page 60
  #
  # @since 2.5.0
  def self.eval(pts, t)

    degree = pts.length - 1
    if degree < 1
      return nil
    end
    
    t1 = 1.0 - t
    fact = 1.0
    n_choose_i = 1

    x = pts[0].x * t1
    y = pts[0].y * t1
    z = pts[0].z * t1
    
    for i in 1...degree
      fact = fact*t
      n_choose_i = n_choose_i*(degree-i+1)/i
      fn = fact * n_choose_i
      x = (x + fn*pts[i].x) * t1
      y = (y + fn*pts[i].y) * t1
      z = (z + fn*pts[i].z) * t1
    end

    x = x + fact*t*pts[degree].x
    y = y + fact*t*pts[degree].y
    z = z + fact*t*pts[degree].z

    Geom::Point3d.new(x, y, z)
    
  end # method eval

  # Evaluate the curve at a number of points and return the points in an array
  #
  # @since 2.5.0
  def self.points(pts, numpts)
    
    curvepts = []
    dt = 1.0 / numpts

    # evaluate the points on the curve
    for i in 0..numpts
      t = i * dt
      curvepts[i] = self.eval(pts, t)
    end
    
    curvepts
  end

end # module TT::Geom3d::Bezier