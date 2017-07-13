//
//  DetailViewController.swift
//  metal prototype 1
//
//  Created by Daniel Pasco on 7/12/17.
//  Copyright © 2017 Daniel Pasco. All rights reserved.
//

import UIKit
import MetalKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var metalView: MTKView!
    
    var metalCommandQueue: MTLCommandQueue!
    var firstTexture: MTLTexture?
    var secondTexture: MTLTexture?
    var metalDevice: MTLDevice!
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.description
            }
        }
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = defaultDevice
            self.metalCommandQueue = self.metalDevice.makeCommandQueue()
            self.metalView.device = self.metalDevice
            self.metalView.contentMode = .scaleAspectFit
            renderImage()
        }
    }

    func loadTexture(name:String)->MTLTexture? {
        let image = UIImage(named:name)
        let cgImage = image?.cgImage
        var texture:MTLTexture?
        do {
            texture = try MTKTextureLoader(device: metalDevice).newTexture(with: cgImage!, options: nil)
        }  catch let error as NSError {
            print("[ERROR] - Failed to create texture. \(error)")
        }
        return texture
    }
    
    func renderImage() {
        self.firstTexture = loadTexture(name: "0.png")
        self.secondTexture = loadTexture(name: "1.png")
        
        let texture:MTLTexture? = self.firstTexture
        self.metalView.drawableSize = CGSize(width: (texture?.width)!, height: (texture?.height)!)
        let commandBuffer = self.metalCommandQueue.makeCommandBuffer()
        let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
        let drawable = self.metalView.currentDrawable
        blitEncoder?.copy(from: texture!, sourceSlice: 0, sourceLevel: 0,
                          sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                          sourceSize: MTLSizeMake((texture?.width)!, (texture?.height)!, (texture?.depth)!),
                          to: (drawable?.texture)!, destinationSlice: 0, destinationLevel: 0,
                          destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blitEncoder?.endEncoding()
        
        // Present current drawable
        commandBuffer?.present(drawable!)
        commandBuffer?.commit()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var detailItem: NSDate? {
        didSet {
            // Update the view.
            configureView()
        }
    }
}

