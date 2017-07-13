//
//  DetailViewController.swift
//  metal prototype 1
//
//  Created by Daniel Pasco on 7/12/17.
//  Copyright © 2017 Daniel Pasco. All rights reserved.
//

//

import UIKit
import MetalKit

class DetailViewController: UIViewController, MTKViewDelegate {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    var metalView: MTKView!
    
    var metalCommandQueue: MTLCommandQueue?
    var firstTexture: MTLTexture?
    var secondTexture: MTLTexture?

    /// Metal device
    var metalDevice = MTLCreateSystemDefaultDevice()
    
    /// Metal pipeline state we use for rendering
    var renderPipelineState: MTLRenderPipelineState?
    
    func loadTexture(name:String)->MTLTexture? {
        let image = UIImage(named:name)
        let cgImage = image?.cgImage
        var texture:MTLTexture?
        do {
            texture = try MTKTextureLoader(device: metalDevice!).newTexture(with: cgImage!, options: nil)
        }  catch let error as NSError {
            print("[ERROR] - Failed to create texture. \(error)")
        }
        return texture
    }

    override func awakeFromNib() {
        initMetal()
    }
    
    func initMetal() {
        
        let debugMetalView = MTKView(frame: view.bounds, device: metalDevice )
        metalView = debugMetalView
        metalCommandQueue = metalDevice?.makeCommandQueue()
        
        metalView.framebufferOnly = false
        metalView.contentMode = .scaleAspectFit
        metalView.autoResizeDrawable = true
        metalView.contentScaleFactor = UIScreen.main.scale
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        metalView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        view.insertSubview(self.metalView, at: 0)
        firstTexture = loadTexture(name: "0.png")
        secondTexture = loadTexture(name: "0.png")
        metalView.delegate = self

        initializeRenderPipelineState()
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
    }

    open func didRenderTexture(_ texture: MTLTexture, withCommandBuffer commandBuffer: MTLCommandBuffer, device: MTLDevice) {
        /**
         * Override if neccessary
         */
    }
    
    func draw(in view: MTKView) {
        guard
            let currentRenderPassDescriptor = metalView.currentRenderPassDescriptor,
            let currentDrawable = metalView.currentDrawable,
            let renderPipelineState = renderPipelineState
        else {
            return
        }
        let commandBuffer = metalCommandQueue?.makeCommandBuffer()

        let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor)
        encoder?.pushDebugGroup("RenderFrame")
        encoder?.setRenderPipelineState(renderPipelineState)
        encoder?.setFragmentTexture(secondTexture, index: 0)
        encoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        encoder?.popDebugGroup()
        encoder?.endEncoding()

        commandBuffer?.addScheduledHandler { [weak self] (buffer) in
            guard let unwrappedSelf = self else { return }

            unwrappedSelf.didRenderTexture(unwrappedSelf.secondTexture!, withCommandBuffer: buffer, device: unwrappedSelf.metalDevice!)
        }
        commandBuffer?.present(currentDrawable)
        commandBuffer?.commit()
    }

    
//
//    NSParameterAssert([self imageTransformation] != nil);
//    if ([[self imageTransformation] _initialZoomValueHasBeenSet])
//    {
//    [self setZoomValue:[[self imageTransformation] zoom]];
//    }
//    else
//    {
//    // See the decl of this property for an explanation of this hack.
//    [[self imageTransformation] _setInitialZoomValueHasBeenSet:YES];
//
//    // If the image size is larger than our view, we zoom to fit otherwise don't do anything
//    // The |imageTransformation| hasn't been set yet, meaning this is the first time this image scope has been dispalyed, and we need to initially zoom to fit (if the image is too big for the view).
//    NSSize originalImageSize = [[self imageLayer] visibleOriginalImageSize];
//    NSSize viewSize = [self bounds].size;
//    if (viewSize.width < originalImageSize.width
//    || viewSize.height < originalImageSize.height)
//    {
//    CGFloat aZoomToSet = [[self imageTransformation] normalizedZoomValueForRealZoomValue:[self zoomValueForFitToView] minValue:0 maxValue:0];
//    [[self imageTransformation] setZoom:aZoomToSet];
//    }
//    }
//
//    // bounds is already pixel based, no need to do backing rect conversion.
//    NSRect bounds = [self bounds];
//    // This method expects the point in the view's coordinae system
//    [self _setImageCenterPointInView:SFRectCenter(bounds)];
    
    fileprivate func initializeRenderPipelineState() {
        let library = metalDevice?.makeDefaultLibrary()
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.sampleCount = 1
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
        
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "mapTexture")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "displayTexture")
        
        do {
            try renderPipelineState = metalDevice?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        catch {
            assertionFailure("Failed creating a render state pipeline. Can't render the texture without one.")
            return
        }
    }

    var detailItem: String? {
        didSet {
            // Update the view.
            if let detail = detailItem {
                if let label = detailDescriptionLabel {
                    label.text = detail.description
                }
            }
            if detailItem != nil {
                firstTexture = loadTexture(name: detailItem!)
                secondTexture = loadTexture(name: detailItem!)
            }
        }
    }
}

