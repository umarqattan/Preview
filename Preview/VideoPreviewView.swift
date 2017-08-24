//
//  VideoPreviewView.swift
//  Preview
//
//  Created by Umar Qattan on 8/16/17.
//  Copyright © 2017 Umar Qattan. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit



class VideoPreviewView: UIView {
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        
        return layer as! AVCaptureVideoPreviewLayer
        
        
    }
    
    var session: AVCaptureSession? {
        
        get { return videoPreviewLayer.session }
        
        set { videoPreviewLayer.session = newValue }
        
    }
    
    override class var layerClass: AnyClass {
        
        return AVCaptureVideoPreviewLayer.self
        
    }
    
    private var orientationMap: [UIDeviceOrientation : AVCaptureVideoOrientation] = [
    
        .portrait           : .portrait,
        
        .portraitUpsideDown : .portraitUpsideDown,
        
        .landscapeLeft      : .landscapeRight,
        
        .landscapeRight     : .landscapeLeft
        
    ]
    
    func updateVideoOrientationForDeviceOrientation() {
        
        if let videoPreviewLayerConnection = videoPreviewLayer.connection {
            
            let deviceOrientation = UIDevice.current.orientation
            
            guard let newVideoOrientation = orientationMap[deviceOrientation],
                
                deviceOrientation.isPortrait || deviceOrientation.isLandscape
                
                else { return }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
            
        }
        
    }
    
}
