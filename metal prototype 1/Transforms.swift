//
//  Transforms.swift
//  metal prototype 1
//
//  Created by Daniel Pasco on 7/13/17.
//  Copyright © 2017 Daniel Pasco. All rights reserved.
//

import Foundation
import UIKit

// DLP - I am trying to group and house most of the sizing logic from Kaleidoscope here.
// Note: this is the original KS code for the most port, migrated to swift.
public class Transforms:NSObject {
    
    public static let kMinZoom:CGFloat = 0.05
    public static let kMaxZoom:CGFloat = 64.0

    public class func NSMidX(aRect:CGRect)->CGFloat  {
        return CGFloat(aRect.origin.x) + CGFloat(aRect.size.width) * CGFloat(0.5)
    }

    public class func NSMidY(aRect:CGRect)->CGFloat  {
        return CGFloat(aRect.origin.y) + CGFloat(aRect.size.height) * CGFloat(0.5)
    }

    public class func NSWidth(aRect:CGRect)->CGFloat  {
        return CGFloat(aRect.size.width)
    }

    public class func NSHeight(aRect:CGRect)->CGFloat  {
        return CGFloat(aRect.size.height)
    }


//    void setProjectionMatrix(const float &angleOfView, const float &near, const float &far, Matrix44f &M)
//    {
//    // set the basic projection matrix
//    float scale = 1 / tan(angleOfView * 0.5 * M_PI / 180);
//    M[0][0] = scale; // scale the x coordinates of the projected point
//    M[1][1] = scale; // scale the y coordinates of the projected point
//    M[2][2] = -far / (far - near); // used to remap z to [0,1]
//    M[3][2] = -far * near / (far - near); // used to remap z [0,1]
//    M[2][3] = -1; // set w = -z
//    M[3][3] = 0;
//    }
    
    
    public class func centerRect(rectToCenter:CGRect, containerRect:CGRect )->CGRect {
        var rectToReturn:CGRect = CGRect.zero
        
        if (containerRect.size.width > 0 && containerRect.size.height > 0 && rectToCenter.size.width > 0 && rectToCenter.size.height > 0) {
            // scale the rect maintaining its aspect ratio
            let aspectRatio:CGFloat = rectToCenter.size.width / rectToCenter.size.height
            if aspectRatio > 1 {
                // landscape photo
                if (containerRect.size.width > containerRect.size.height) {
                    // if the view is landscape
                    // take the height
                    rectToReturn.size.height = containerRect.size.height;
                    rectToReturn.size.width = rectToReturn.size.height * aspectRatio;
                    if rectToReturn.size.width > containerRect.size.width {
                        rectToReturn.size.width = containerRect.size.width;
                        rectToReturn.size.height = rectToReturn.size.width / aspectRatio;
                    }
                }
                else {
                    // if the view is portrait
                    // take the width
                    rectToReturn.size.width = containerRect.size.width;
                    rectToReturn.size.height = rectToReturn.size.width / aspectRatio;
                }
            }
            else if aspectRatio < 1 {
                // portrait photo
                
                if (containerRect.size.width > containerRect.size.height) {
                    // if the view is landscape
                    // take the height
                    rectToReturn.size.height = containerRect.size.height;
                    rectToReturn.size.width = rectToReturn.size.height * aspectRatio;
                }
                else {
                    // if the view is portrait
                    // take the width
                    rectToReturn.size.width = containerRect.size.width;
                    rectToReturn.size.height = rectToReturn.size.width / aspectRatio;
                    if rectToReturn.size.height > containerRect.size.height {
                        rectToReturn.size.height = containerRect.size.height;
                        rectToReturn.size.width = rectToReturn.size.height * aspectRatio;
                    }
                }
            }
            else if aspectRatio == 1 {
                if containerRect.size.width > containerRect.size.height {
                    // if the view is landscape
                    // take the height
                    rectToReturn.size.height = containerRect.size.height;
                    rectToReturn.size.width = rectToReturn.size.height * aspectRatio;
                }
                else {
                    // if the view is portrait
                    // take the width
                    rectToReturn.size.width = containerRect.size.width;
                    rectToReturn.size.height = rectToReturn.size.width / aspectRatio;
                }
            }
            
            let origin:CGFloat = NSMidX(aRect:containerRect) - NSWidth(aRect:rectToReturn) * 0.5
            rectToReturn.origin = CGPoint(x:round(origin), y:round(NSMidY(aRect:containerRect) - NSHeight(aRect:rectToReturn) * 0.5));
            rectToReturn.size.width = round(rectToReturn.size.width);
            rectToReturn.size.height = round(rectToReturn.size.height);
        }
        return rectToReturn;
    }

    public class func calculateZoomValueForImageSize(imageSize:CGSize, textureWidth:CGFloat)->CGFloat {
        var zoomValueToReturn:CGFloat = 0.0
        if textureWidth > 0 {
            zoomValueToReturn = CGFloat(imageSize.width) / textureWidth
        }
        
        return zoomValueToReturn
    }
    
    public class func zoomValueForFitToView(width:CGFloat, height:CGFloat, bounds:CGRect)->CGFloat {
        let originalImageRect:CGRect = CGRect(x: 0, y: 0, width:width, height: height)
        let insets:CGRect = CGRect(x: bounds.minX + 10, y: bounds.minX + 10, width: bounds.width - 10, height: bounds.height - 10)
        let rectForZoom:CGRect =  Transforms.centerRect(rectToCenter:originalImageRect, containerRect:insets)
        let zoomValue:CGFloat = Transforms.calculateZoomValueForImageSize(imageSize:rectForZoom.size, textureWidth:CGFloat(width))
        return zoomValue
    }
    
    public class func normalizedZoomValueForRealZoomValue(theZoomValue:CGFloat, theMinValue:CGFloat, theMaxValue:CGFloat)->CGFloat {
        let B:CGFloat = Transforms.kMinZoom
        var A:CGFloat = Transforms.kMaxZoom - B
        
        if A == 0.0 {
            A = 1.0
        }
        let aNormalizedScale:CGFloat = CGFloat(sqrt((theZoomValue - B)/A))
        return aNormalizedScale
    }
}
