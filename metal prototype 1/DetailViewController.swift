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
    @IBOutlet weak var metalView: MetalView!
    
    static var cachedMetalView: MetalView!
    static var cachedMetalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var firstTexture: MTLTexture?
    var secondTexture: MTLTexture?
    
    override func awakeFromNib() {
        if DetailViewController.cachedMetalView != nil {
            self.metalView = DetailViewController.cachedMetalView
//            initMetal()
        }
    }
    func initMetal() {
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            DetailViewController.cachedMetalDevice = defaultDevice
        }
        
        if DetailViewController.cachedMetalView == nil {
            if self.metalView != nil {
                DetailViewController.cachedMetalView = self.metalView
            }
        }
        self.metalCommandQueue = DetailViewController.cachedMetalDevice.makeCommandQueue()
        self.metalView.device = DetailViewController.cachedMetalDevice
        self.metalView.contentMode = .scaleAspectFit
        self.metalView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        self.metalView.framebufferOnly = false
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.description
            }
        }
        if DetailViewController.cachedMetalView == nil {
            if self.metalView != nil {
                DetailViewController.cachedMetalView = self.metalView
            }
        }
        else {
            initMetal()
            renderImage()
        }
    }

    func loadTexture(name:String)->MTLTexture? {
        let image = UIImage(named:name)
        let cgImage = image?.cgImage
        var texture:MTLTexture?
        do {
            texture = try MTKTextureLoader(device: DetailViewController.cachedMetalDevice).newTexture(with: cgImage!, options: nil)
        }  catch let error as NSError {
            print("[ERROR] - Failed to create texture. \(error)")
        }
        return texture
    }
    
    func renderImage() {
        self.firstTexture = loadTexture(name: self.detailItem!)
        self.secondTexture = loadTexture(name: self.detailItem!)
        
        let texture:MTLTexture? = self.secondTexture
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

    var detailItem: String? {
        didSet {
            // Update the view.
            configureView()
        }
    }
}

