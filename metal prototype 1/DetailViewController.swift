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
import GLKit
import Foundation

class DetailViewController: UIViewController, MTKViewDelegate {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    var metalView: MTKView!
    
    var metalCommandQueue: MTLCommandQueue?
    var firstTexture: MTLTexture?
    var secondTexture: MTLTexture?
    /// Metal device
    var metalDevice = MTLCreateSystemDefaultDevice()
    var perspectiveMatrix:GLKMatrix4 = GLKMatrix4Identity
    var transformationMatrix:GLKMatrix4 = GLKMatrix4Identity
    var uniformBuffer:MTLBuffer?
    let matrix4x4Size = MemoryLayout<Float>.size * 4*4

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
        updatePerspectiveMatrix()
    }
    
    // DLP: Original Sofa code here for short term reference
//    [self stopPushingImageLayer];
//    mZoom = theZoom;
//    CGFloat aRealZoomValue = [self realZoom];
//    if(aRealZoomValue > kMaxZoom)
//    {
//    aRealZoomValue = kMaxZoom;
//    mZoom = [self normalizedZoomValueForRealZoomValue:aRealZoomValue minValue:0 maxValue:0];
//    }
//    else if(aRealZoomValue < kMinZoom)
//    {
//    aRealZoomValue = kMinZoom;
//    mZoom = [self normalizedZoomValueForRealZoomValue:aRealZoomValue minValue:0 maxValue:0];
//    }
//
//    if(mShouldOffsetCenterForZoom)
//    {
//    // only offset the center if a zoom "focus" has been set
//    // we directly access the center ivar to avoid triggering kvo
//    // a zoom using the scroll wheel with the mouse over some
//    // part of the visible image
//    mCenter = NSMakePoint((mZoomLocation.x - (mZoomOffset.x * aRealZoomValue)),
//    (mZoomLocation.y - (mZoomOffset.y * aRealZoomValue)));
//    }
    
    // DLP: also
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
    //    // The |imageTransformation| hasn't been set yet, meaning this is the first time this image scope has been displayed, and we need to initially zoom to fit (if the image is too big for the view).
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
    
    func updatePerspectiveMatrix() {
        let textureWidth:CGFloat = firstTexture != nil ? CGFloat(firstTexture!.width) : 0
        let textureHeight:CGFloat = firstTexture != nil ? CGFloat(firstTexture!.height) : 0
        let boundsWidth:CGFloat = CGFloat(view.bounds.width)
        let boundsHeight:CGFloat = CGFloat(view.bounds.height)
        perspectiveMatrix = GLKMatrix4Identity
        transformationMatrix = GLKMatrix4Identity
        let aspect:Float = Float(boundsWidth/boundsHeight)
        
        if(aspect > 1.0) {
            perspectiveMatrix = GLKMatrix4MakeOrtho(-aspect, aspect, -1, 1, -1, 1)
        }
        else {
            perspectiveMatrix = GLKMatrix4MakeOrtho(-1, 1, -1/aspect, 1/aspect, -1, 1)
        }

        // Doing this the KS way is seriously broken right now
        if false {
            if (boundsWidth < textureWidth) || (boundsHeight < textureHeight) {
                // DLP: I have not traversed this logic fully in KS yet and really have no idea where this is going
                let zoomValue = Transforms.zoomValueForFitToView(width:textureWidth, height:textureHeight, bounds:view.bounds)
                let aZoomToSet:CGFloat = Transforms.normalizedZoomValueForRealZoomValue(theZoomValue:zoomValue, theMinValue:0, theMaxValue: 0 )
                transformationMatrix = GLKMatrix4Scale(GLKMatrix4Identity, Float(aZoomToSet), Float(aZoomToSet), 1.0)
            }
        }
        else {
            // DLP: not as fancy but it does the job for now
            let textureAspect:Float = Float(textureWidth/textureHeight)
            
            if(textureAspect > 1.0) {
                transformationMatrix = GLKMatrix4Scale(GLKMatrix4Identity, 1.0, Float(1.0/textureAspect), 1.0)
            }
            else {
                transformationMatrix = GLKMatrix4Scale(GLKMatrix4Identity, textureAspect, 1.0, 1.0)
            }
        }

        perspectiveMatrix = GLKMatrix4Multiply(perspectiveMatrix, transformationMatrix)
        if uniformBuffer != nil {
            let bufferPointer = uniformBuffer?.contents()
            memcpy(bufferPointer, &perspectiveMatrix, matrix4x4Size)
        }
    }
    
    func initMetal() {
        
        let debugMetalView = MTKView(frame: view.bounds, device: metalDevice )
        metalView = debugMetalView
        metalCommandQueue = metalDevice?.makeCommandQueue()
        
        metalView.framebufferOnly = false
        metalView.contentScaleFactor = UIScreen.main.scale
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        metalView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        view.insertSubview(self.metalView, at: 0)
        firstTexture = loadTexture(name: "0.png")
        secondTexture = loadTexture(name: "0.png")
        metalView.delegate = self

        // Make a buffer to hold our project matrix (so we can have the right proportions when our view isn't square)
        updatePerspectiveMatrix()
        uniformBuffer = metalDevice?.makeBuffer(length: MemoryLayout<Float>.size * 4*4, options: [])
        let bufferPointer = uniformBuffer?.contents()

        memcpy(bufferPointer, &perspectiveMatrix, matrix4x4Size)
        initializeRenderPipelineState()
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        updatePerspectiveMatrix()
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

        let render = commandBuffer?.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor)
        render?.pushDebugGroup("RenderFrame")
        render?.setRenderPipelineState(renderPipelineState)
        render?.setFragmentTexture(secondTexture, index: 0)
        render?.setVertexBuffer(uniformBuffer, offset: 0, index: 0)
        render?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        render?.popDebugGroup()
        render?.endEncoding()

        commandBuffer?.addScheduledHandler { [weak self] (buffer) in
            guard let unwrappedSelf = self else { return }

            unwrappedSelf.didRenderTexture(unwrappedSelf.secondTexture!, withCommandBuffer: buffer, device: unwrappedSelf.metalDevice!)
        }
        commandBuffer?.present(currentDrawable)
        commandBuffer?.commit()
    }

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
                // DLP: actually just using one texture right now.
                firstTexture = loadTexture(name: detailItem!)
                secondTexture = loadTexture(name: detailItem!)
            }
        }
    }
}

