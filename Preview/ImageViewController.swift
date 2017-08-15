//
//  ImageViewController.swift
//  Preview
//
//  Created by Umar Qattan on 8/12/17.
//  Copyright © 2017 Umar Qattan. All rights reserved.
//

import UIKit
import AVFoundation

class ImageViewController: UIViewController {

    
    // AVCaptureSession variables and properties
    var captureSession = AVCaptureSession()
    var previewLayer:AVCaptureVideoPreviewLayer?
    var captureDevice:AVCaptureDevice?
    let overlay = UIView()
    var lastPoint = CGPoint.zero
    var image:UIImage!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var photoButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.image = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
        overlay.layer.borderColor = UIColor.black.cgColor
        overlay.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)
        overlay.isHidden = true
        self.view.addSubview(overlay)
        photoButton.isHidden = true
        photoButton.isEnabled = false
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if previewLayer != nil {
            previewLayer = nil
        }
        if captureDevice != nil {
            captureDevice = nil
        }
        photoButton.isHidden = true
        photoButton.isEnabled = false
        if let touch = touches.first {
            lastPoint = touch.location(in: imageView)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let currentPoint = touch.location(in: imageView)
            redrawSelectionArea(fromPoint: lastPoint, toPoint: currentPoint)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // TODO: camera should open in the rectangle overlay area
        
        photoButton.isHidden = false
        photoButton.isEnabled = true
        
        setUpCameraView(frame: overlay.frame)
    }
    
    
    func redrawSelectionArea(fromPoint: CGPoint, toPoint: CGPoint) {
        overlay.isHidden = false
        let rect = CGRect(x: min(fromPoint.x, toPoint.x), y: min(fromPoint.y, toPoint.y), width: fabs(fromPoint.x-toPoint.x), height: fabs(fromPoint.y-toPoint.y))
        
        overlay.frame = rect
        
    }
    
    func configureDevice() {
        var err : NSError? = nil
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
            } catch let error as NSError {
                err = error
                print(err!.localizedDescription)
            }
            device.focusMode = .locked
            device.unlockForConfiguration()
        }
        
    }
    
    func setUpCameraView(frame: CGRect) {
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices! {
            // Make sure this particular device supports video
            if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if((device as AnyObject).position == AVCaptureDevicePosition.back) {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        print("Capture device found")
                        beginSession(frame: frame)
                    }
                }
            }
        }
    }
    
    func beginSession(frame: CGRect) {
        
        configureDevice()
        
        var err : NSError? = nil
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))

        } catch let error as NSError {
            err = error
            print(err!.localizedDescription)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.imageView.layer.addSublayer(previewLayer!)
        previewLayer?.frame = frame
        captureSession.startRunning()
    }

    @IBAction func takePhoto(_ sender: UIButton) {
        
        
    }
    
    

    
}




