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

    @IBOutlet var zoomSlider: UISlider!
    @IBOutlet var persistenceSlider: UISlider!
    @IBOutlet var octavesSlider: UISlider!
    
    @IBOutlet var sizeXtext: UITextField!
    @IBOutlet var sizeYtext: UITextField!
    
    @IBOutlet var imageView: UIImageView!
    
    @IBAction func aSliderChanged(sender: AnyObject) {
        updateNoiseImage()
    }

    func updateNoiseImage() {
        var generator = PerlinGenerator()
        generator.octaves = Int(octavesSlider.value)
        generator.zoom = octavesSlider.value
        generator.persistence = persistenceSlider.value
        
        var sizeX = CGFloat((sizeXtext.text as NSString).floatValue)
        var sizeY = CGFloat((sizeYtext.text as NSString).floatValue)
        var size = CGSizeMake(sizeX, sizeY)
        
        var noise = generateNoiseImage(generator, size: size)
        imageView.image = noise
    }
    
    
    func generateNoiseImage(generator:PerlinGenerator, size:CGSize) -> UIImage {
        
        let bounds = CGRect(origin: CGPoint.zeroPoint, size: size)
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let ctx = UIGraphicsGetCurrentContext()
        
        CGContextSetRGBFillColor(ctx, 0.000, 0.0, 0.000, 1.000); // light blue
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
        return image
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sizeXtext.delegate = self
        sizeYtext.delegate = self
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
    }

    override func viewDidLayoutSubviews() {
        if sizeXtext.text == "" {
            var size = self.imageView.bounds.size
            sizeXtext.text = "\(Int(size.width/10))"
            sizeYtext.text = "\(Int(size.height/10))"
            
            updateNoiseImage()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        updateNoiseImage()
    }

}

