//
// Port of a Perlin noise Objective-C implementation in Swift
// Original source https://github.com/czgarrett/perlin-ios
//
// For references on the Perlin algorithm:
// Each of these has a slightly different way of explaining Perlin noise.  They were all useful:
// Overviews of Perlin: http://paulbourke.net/texture_colour/perlin/ and http://freespace.virgin.net/hugo.elias/models/m_perlin.htm
// Awesome C++ tutorial on Perlin: http://www.dreamincode.net/forums/topic/66480-perlin-noise/

//  MIT License:

//  Perlin-Swift Copyright (c) 2015 Lachlan Hurst
//  Perlin-iOS Copyright (C) 2011 by Christopher Z. Garrett

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN


import Foundation

let PERMUTATION_SIZE = 256


class PerlinGenerator {
    
    static let gradient:[[Int8]] = [
        [ 1, 1, 1, 0], [ 1, 1, 0, 1], [ 1, 0, 1, 1], [ 0, 1, 1, 1],
        [ 1, 1, -1, 0], [ 1, 1, 0, -1], [ 1, 0, 1, -1], [ 0, 1, 1, -1],
        [ 1, -1, 1, 0], [ 1, -1, 0, 1], [ 1, 0, -1, 1], [ 0, 1, -1, 1],
        [ 1, -1, -1, 0], [ 1, -1, 0, -1], [ 1, 0, -1, -1], [ 0, 1, -1, -1],
        [-1, 1, 1, 0], [-1, 1, 0, 1], [-1, 0, 1, 1], [ 0, -1, 1, 1],
        [-1, 1, -1, 0], [-1, 1, 0, -1], [-1, 0, 1, -1], [ 0, -1, 1, -1],
        [-1, -1, 1, 0], [-1, -1, 0, 1], [-1, 0, -1, 1], [ 0, -1, -1, 1],
        [-1, -1, -1, 0], [-1, -1, 0, -1], [-1, 0, -1, -1], [ 0, -1, -1, -1]
    ]
    
    var permut:[Int]
    
    var octaves:Int
    var persistence:Float
    var zoom:Float
    
    init(){
        permut = []
        for var i = 0; i < PERMUTATION_SIZE; i++ {
            permut.append(Int(rand() & 0xff))
        }
        octaves = 1
        persistence = 1.0
        zoom = 1.0
    }
    
    func gradientAt(i:Int, j:Int, k:Int, l:Int) -> Int {
        return (permut[(l + permut[(k + permut[(j + permut[i & 0xff])
                                                & 0xff])
                                    & 0xff])
                       & 0xff]
            & 0x1f)
    }
    
    func productOf(a:Float, b:Int8) -> Float {
        if b > 0 {
            return a
        }
        if b < 0 {
            return -a
        }
        return 0
    }
    
    func dotProductI(x0:Float, x1:Int8,
                     y0:Float, y1:Int8,
                     z0:Float, z1:Int8,
                     t0:Float, t1:Int8) -> Float {
            return self.productOf(x0, b: x1) +
                   self.productOf(y0, b: y1) +
                   self.productOf(z0, b: z1) +
                   self.productOf(t0, b: t1)
    }
    
    func spline(state:Float) -> Float{
        var square = state * state
        var cubic = square * state
        return cubic * (6 * square - 15 * state + 10)
    }
    
    func interpolate(a:Float, b:Float, x:Float) -> Float {
        return a + x*(b-a)
    }
    
    func smoothNoise(x:Float, y:Float, z:Float, t:Float) -> Float {
        let x0 = Int(x > 0 ? x : x - 1)
        let y0 = Int(y > 0 ? y : y - 1)
        let z0 = Int(z > 0 ? z : z - 1)
        let t0 = Int(t > 0 ? t : t - 1)
        
        let x1 = x0+1
        let y1 = y0+1
        let z1 = z0+1
        let t1 = t0+1
        
        // The vectors
        var dx0 = x-Float(x0)
        var dy0 = y-Float(y0)
        var dz0 = z-Float(z0)
        var dt0 = t-Float(t0)
        let dx1 = x-Float(x1)
        let dy1 = y-Float(y1)
        let dz1 = z-Float(z1)
        let dt1 = t-Float(t1)
        
        // The 16 gradient values
        var g0000 = PerlinGenerator.gradient[self.gradientAt(x0, j: y0, k: z0, l: t0)]
        var g0001 = PerlinGenerator.gradient[self.gradientAt(x0, j: y0, k: z0, l: t1)]
        var g0010 = PerlinGenerator.gradient[self.gradientAt(x0, j: y0, k: z1, l: t0)]
        var g0011 = PerlinGenerator.gradient[self.gradientAt(x0, j: y0, k: z1, l: t1)]
        var g0100 = PerlinGenerator.gradient[self.gradientAt(x0, j: y1, k: z0, l: t0)]
        var g0101 = PerlinGenerator.gradient[self.gradientAt(x0, j: y1, k: z0, l: t1)]
        var g0110 = PerlinGenerator.gradient[self.gradientAt(x0, j: y1, k: z1, l: t0)]
        var g0111 = PerlinGenerator.gradient[self.gradientAt(x0, j: y1, k: z1, l: t1)]
        var g1000 = PerlinGenerator.gradient[self.gradientAt(x1, j: y0, k: z0, l: t0)]
        var g1001 = PerlinGenerator.gradient[self.gradientAt(x1, j: y0, k: z0, l: t1)]
        var g1010 = PerlinGenerator.gradient[self.gradientAt(x1, j: y0, k: z1, l: t0)]
        var g1011 = PerlinGenerator.gradient[self.gradientAt(x1, j: y0, k: z1, l: t1)]
        var g1100 = PerlinGenerator.gradient[self.gradientAt(x1, j: y1, k: z0, l: t0)]
        var g1101 = PerlinGenerator.gradient[self.gradientAt(x1, j: y1, k: z0, l: t1)]
        var g1110 = PerlinGenerator.gradient[self.gradientAt(x1, j: y1, k: z1, l: t0)]
        var g1111 = PerlinGenerator.gradient[self.gradientAt(x1, j: y1, k: z1, l: t1)]
        
        // The 16 dot products
        let b0000 = self.dotProductI(dx0, x1: g0000[0], y0:dy0, y1:g0000[1], z0:dz0, z1:g0000[2], t0:dt0, t1:g0000[3])
        let b0001 = self.dotProductI(dx0, x1: g0001[0], y0:dy0, y1:g0001[1], z0:dz0, z1:g0001[2], t0:dt1, t1:g0001[3])
        let b0010 = self.dotProductI(dx0, x1: g0010[0], y0:dy0, y1:g0010[1], z0:dz1, z1:g0010[2], t0:dt0, t1:g0010[3])
        let b0011 = self.dotProductI(dx0, x1: g0011[0], y0:dy0, y1:g0011[1], z0:dz1, z1:g0011[2], t0:dt1, t1:g0011[3])
        let b0100 = self.dotProductI(dx0, x1: g0100[0], y0:dy1, y1:g0100[1], z0:dz0, z1:g0100[2], t0:dt0, t1:g0100[3])
        let b0101 = self.dotProductI(dx0, x1: g0101[0], y0:dy1, y1:g0101[1], z0:dz0, z1:g0101[2], t0:dt1, t1:g0101[3])
        let b0110 = self.dotProductI(dx0, x1: g0110[0], y0:dy1, y1:g0110[1], z0:dz1, z1:g0110[2], t0:dt0, t1:g0110[3])
        let b0111 = self.dotProductI(dx0, x1: g0111[0], y0:dy1, y1:g0111[1], z0:dz1, z1:g0111[2], t0:dt1, t1:g0111[3])
        let b1000 = self.dotProductI(dx1, x1: g1000[0], y0:dy0, y1:g1000[1], z0:dz0, z1:g1000[2], t0:dt0, t1:g1000[3])
        let b1001 = self.dotProductI(dx1, x1: g1001[0], y0:dy0, y1:g1001[1], z0:dz0, z1:g1001[2], t0:dt1, t1:g1001[3])
        let b1010 = self.dotProductI(dx1, x1: g1010[0], y0:dy0, y1:g1010[1], z0:dz1, z1:g1010[2], t0:dt0, t1:g1010[3])
        let b1011 = self.dotProductI(dx1, x1: g1011[0], y0:dy0, y1:g1011[1], z0:dz1, z1:g1011[2], t0:dt1, t1:g1011[3])
        let b1100 = self.dotProductI(dx1, x1: g1100[0], y0:dy1, y1:g1100[1], z0:dz0, z1:g1100[2], t0:dt0, t1:g1100[3])
        let b1101 = self.dotProductI(dx1, x1: g1101[0], y0:dy1, y1:g1101[1], z0:dz0, z1:g1101[2], t0:dt1, t1:g1101[3])
        let b1110 = self.dotProductI(dx1, x1: g1110[0], y0:dy1, y1:g1110[1], z0:dz1, z1:g1110[2], t0:dt0, t1:g1110[3])
        let b1111 = self.dotProductI(dx1, x1: g1111[0], y0:dy1, y1:g1111[1], z0:dz1, z1:g1111[2], t0:dt1, t1:g1111[3])
        
        dx0 = self.spline(dx0)
        dy0 = self.spline(dy0)
        dz0 = self.spline(dz0)
        dt0 = self.spline(dt0)
        
        let b111 = self.interpolate(b1110, b:b1111, x:dt0)
        let b110 = self.interpolate(b1100, b:b1101, x:dt0)
        let b101 = self.interpolate(b1010, b:b1011, x:dt0)
        let b100 = self.interpolate(b1000, b:b1001, x:dt0)
        let b011 = self.interpolate(b0110, b:b0111, x:dt0)
        let b010 = self.interpolate(b0100, b:b0101, x:dt0)
        let b001 = self.interpolate(b0010, b:b0011, x:dt0)
        let b000 = self.interpolate(b0000, b:b0001, x:dt0)
        
        let b11 = self.interpolate(b110, b:b111, x:dz0)
        let b10 = self.interpolate(b100, b:b101, x:dz0)
        let b01 = self.interpolate(b010, b:b011, x:dz0)
        let b00 = self.interpolate(b000, b:b001, x:dz0)
        
        let b1 = self.interpolate(b10, b:b11, x:dy0)
        let b0 = self.interpolate(b00, b:b01, x:dy0)
        
        let result = self.interpolate(b0, b:b1, x:dx0)
        
        return result;
    }
    
    func perlinNoise(x:Float, y:Float, z:Float, t:Float) -> Float{
        
        var noise:Float = 0.0
        for (var octave = 0; octave<self.octaves; octave++) {
            var frequency:Float = powf(2,Float(octave))
            var amplitude = powf(self.persistence, Float(octave))
            
            noise += self.smoothNoise(x * frequency/zoom,
                                      y: y * frequency/zoom,
                                      z: z * frequency/zoom,
                                      t: t * frequency/zoom) * amplitude
        }
        return noise
    }
}







