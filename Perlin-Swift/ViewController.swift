//
//  ViewController.swift
//  Perlin-Swift
//
//  Created by Lachlan Hurst on 24/08/2015.
//  Copyright (c) 2015 Lachlan Hurst. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var zoomLabel: UILabel!
    @IBOutlet var persistenceLabel: UILabel!
    @IBOutlet var octavesLabel: UILabel!
    
    @IBOutlet var zoomSlider: UISlider!
    @IBOutlet var persistenceSlider: UISlider!
    @IBOutlet var octavesSlider: UISlider!
    
    @IBOutlet var sizeXtext: UITextField!
    @IBOutlet var sizeYtext: UITextField!
    
    @IBOutlet var imageView: UIImageView!
    
    fileprivate var generator = PerlinGenerator()
    
    @IBAction func aSliderChanged(_ sender: AnyObject) {
        
        let slider = sender as! UISlider
        if slider === zoomSlider {
            zoomLabel.textAlignment = NSTextAlignment.left
            zoomLabel.text = String(format: "Z = %.2f", slider.value)
        } else if slider === persistenceSlider {
            persistenceLabel.textAlignment = NSTextAlignment.left
            persistenceLabel.text = String(format: "P = %.2f", slider.value)
        } else if slider === octavesSlider {
            octavesLabel.textAlignment = NSTextAlignment.left
            octavesLabel.text = "O = \(Int(slider.value))"
        }
        
        updateNoiseImage()
    }

    @IBAction func newPressed(_ sender: AnyObject) {
        generator = PerlinGenerator()
        updateNoiseImage()
    }
    
    func updateNoiseImage() {
        
        generator.octaves = Int(octavesSlider.value)
        generator.zoom = zoomSlider.value
        generator.persistence = persistenceSlider.value
        
        let sizeX = CGFloat(NSString(string: sizeXtext.text!).floatValue)
        let sizeY = CGFloat(NSString(string: sizeYtext.text!).floatValue)
        let size = CGSize(width: sizeX, height: sizeY)
        
        let noise = generateNoiseImage(generator, size: size)
        imageView.image = noise
    }
    
    
    func generateNoiseImage(_ generator:PerlinGenerator, size:CGSize) -> UIImage {

        let width = Int(size.width)
        let height = Int(size.height)
        
        let startTime = CFAbsoluteTimeGetCurrent();
        
        var pixelArray = [PixelData](repeating: PixelData(a: 255, r:0, g: 0, b: 0), count: width * height)
        
        for i in 0 ..< height {
            for j in 0 ..< width {
                var val = abs(generator.perlinNoise(Float(j), y: Float(i), z: 0, t: 0))
                if val > 1 {
                    val = 1
                }
                let index = i * width + j
                let u_I = UInt8(val * 255)
                pixelArray[index].r = u_I
                pixelArray[index].g = u_I
                pixelArray[index].b = 0
            }
        }
        let outputImage = imageFromARGB32Bitmap(pixelArray, width: width, height: height)
        
        print(" R RENDER:" + String(format: "%.4f", CFAbsoluteTimeGetCurrent() - startTime));
        
        return outputImage
        
        /*
        let bounds = CGRect(origin: CGPoint.zeroPoint, size: size)
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let ctx = UIGraphicsGetCurrentContext()
        
        CGContextSetRGBFillColor(ctx, 1.000, 0.0, 0.000, 1.000); // light blue
        CGContextFillRect(ctx, CGRectMake(0.0, 0.0, size.width, size.height));
        for (var x:CGFloat = 0.0; x < size.width; x+=1.0) {
            for (var y:CGFloat=0.0; y < size.height; y+=1.0) {
                let val = generator.perlinNoise(Float(x), y: Float(y), z: 0, t: 0)
                CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, CGFloat(abs(val)))
                CGContextFillRect(ctx, CGRectMake(x, y, 1.0, 1.0));
            }
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image*/
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sizeXtext.delegate = self
        sizeYtext.delegate = self
        
        //strech to fit but maintain aspect ratio
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        
        //use nearest neighbour, we want to see the pixels (not blur them)
        imageView.layer.magnificationFilter = kCAFilterNearest
    }

    override func viewDidLayoutSubviews() {
        if sizeXtext.text == "" {
            let size = self.imageView.bounds.size
            sizeXtext.text = "\(Int(size.width/5))"
            sizeYtext.text = "\(Int(size.height/5))"
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        updateNoiseImage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //
    //   UITextFieldDelegate funcs
    //
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateNoiseImage()
    }

    //
    //  drawing images from pixel data
    //      http://blog.human-friendly.com/drawing-images-from-pixel-data-in-swift
    //
    struct PixelData {
        var a:UInt8 = 255
        var r:UInt8
        var g:UInt8
        var b:UInt8
    }
    
    fileprivate let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    fileprivate let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    
    func imageFromARGB32Bitmap(_ pixels:[PixelData], width:Int, height:Int)->UIImage {
        let bitsPerComponent:Int = 8
        let bitsPerPixel:Int = 32
        
        assert(pixels.count == Int(width * height))
        
        var data = pixels // Copy to mutable []
        let bdata = Data(bytes: &data, count: data.count * MemoryLayout<PixelData>.size)

        let providerRef = CGDataProvider(data: bdata as CFData)
        
        let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width * Int(MemoryLayout<PixelData>.size),
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef!,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent
        )
        return UIImage(cgImage: cgim!)
    }
    
    
}

