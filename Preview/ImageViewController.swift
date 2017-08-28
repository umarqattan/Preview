//
//  ImageViewController.swift
//  Preview
//
//  Created by Umar Qattan on 8/12/17.
//  Copyright © 2017 Umar Qattan. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class ImageViewController: UIViewController {

    @IBOutlet weak var videoPreviewView: VideoPreviewView!
    @IBOutlet weak var optionSegmentedControl: UISegmentedControl!
    
    // AVCaptureSession variables and properties
    var captureSession:AVCaptureSession = AVCaptureSession()
    var capturePhotoOutput = AVCapturePhotoOutput()
    var isCaptureSessionConfigured = false // Instance property on this view controller class
    var dragVideoPreviewViewPanGestureRecognizer:UIPanGestureRecognizer!
    var scaleVideoPreviewViewPinchGestureRecognizer:UIPinchGestureRecognizer!
    var zoomVideoPreviewViewPinchGestureRecognizer:UIPinchGestureRecognizer!
    var maskVideoPreviewViewPanGestureRecognizer:UIPanGestureRecognizer!
    private let sessionQueue = DispatchQueue(label: "session queue",
                                             attributes: [],
                                             target: nil) // Communicate with the session and other session objects on this queue.
    
    var firstPoint:CGPoint = CGPoint.zero
    var previousPoint:CGPoint = CGPoint.zero
    var previewLayer:AVCaptureVideoPreviewLayer?
    var captureDevice:AVCaptureDevice?
    //var overlay:UIView? = UIView()
    var overlay:MaskView!
    var lastPoint = CGPoint.zero
    var image:UIImage!
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.image = image
        
        if self.isCaptureSessionConfigured {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        } else {
            
            // First time: request camera access, configure capture session, and start it.
            
            self.checkCameraAuthorization({ authorized in
                
                guard authorized else {
                    
                    print("Permission to use camera denied.")
                    
                    return
                    
                }
                
                self.sessionQueue.async {
                    
                    self.configureCaptureSession({ success in
                        
                        guard success else { return }
                        
                        self.isCaptureSessionConfigured = true
                        
                        self.captureSession.startRunning()
                        
                        DispatchQueue.main.async {
                            
                            
                            self.setupMoveGesture()
                            self.videoPreviewView.updateVideoOrientationForDeviceOrientation()
                            self.videoPreviewView.alpha = 1.0
                            self.videoPreviewView.session = self.captureSession
                            
                        
                            
                        }
                        
                    })
                    
                }
                
            })
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession.isRunning {
            
            captureSession.stopRunning()
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationController?.isNavigationBarHidden = true
        
        /**
         
        overlay?.layer.borderColor = UIColor.black.cgColor
        overlay?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)
        overlay?.isHidden = true
        self.imageView.addSubview(overlay!)
         
        */
    }
    
    func checkCameraAuthorization(_ completionHandler: @escaping ((_ authorized: Bool) -> Void)) {
        
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        
        case .authorized:
            
            // The user has previously granted access to the camera.
            
            completionHandler(true)
            
        case .notDetermined:
            
            // The user has not yet been presented with the option to grant video access so request access.
            
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { success in
                completionHandler(success)
            })
        
        case .denied:
            
            // The user has previously denied access.
            
            completionHandler(false)
            
        case .restricted:
            
            // The user doesn't have the authority to request access e.g. parental restriction.
            
            completionHandler(false)
            
        }
        
    }
    
    func checkPhotoLibraryUsageDescription(_ completionHandler: @escaping ((_ authorized: Bool) -> Void)) {
        
        switch PHPhotoLibrary.authorizationStatus() {
            
        case .authorized:
            
            // The user has previously granted access to the photo library.
            
            completionHandler(true)
            
        case .notDetermined:
            
            // The user has not yet been presented with the option to grant photo library access so request access.
            
            PHPhotoLibrary.requestAuthorization({ status in
                
                completionHandler((status == .authorized))
                
            })
            
        case .denied:
            
            // The user has previously denied access.
            
            completionHandler(false)
        
        case .restricted:
            
            // The user doesn't have the authority to request access e.g. parental restriction.
            
            completionHandler(false)
        
        }
        
    }
    
    // Step 1: Create the capture session
    
    func createCaptureSession() {
        
        self.captureSession = AVCaptureSession()
        
    }
    
    // Step 2: Select a camera input
    
    func defaultDevice() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera, for: AVMediaType.video, position: .back) {
            return device // use dual camera on supported devices
        } else if let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            return device // use default back facing camera, otherwise
        } else {
            fatalError("All supported devices are expected to have at least one of the queried capture devices.")
        }
    }
    
    // Step 3: Create and configure a photo capture output
    
    func configureCaptureSession(_ completionHandler: @escaping ((_ success: Bool) -> Void)) {
        
        var success = false
    
        defer { completionHandler(success) } // Ensure all exit paths call completion handler
        
        // Get video input for the default camera.
        
        let videoCaptureDevice = defaultDevice()
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            
            print("Unable to obtain video input for default camera.")
            
            return
            
        }
        
        // Create and configure the photo output.
        
        let capturePhotoOutput = AVCapturePhotoOutput()
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        capturePhotoOutput.isLivePhotoCaptureEnabled = capturePhotoOutput.isLivePhotoCaptureSupported
        
        // Make sure inputs and output can be added to session.
        
        guard self.captureSession.canAddInput(videoInput) else { return }
        
        guard self.captureSession.canAddOutput(capturePhotoOutput) else { return }
        
        
        // Configure the session
        self.captureSession.beginConfiguration()
        
        self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        self.captureSession.addInput(videoInput)
        
        self.captureSession.addOutput(capturePhotoOutput)
        
        self.captureSession.commitConfiguration()
        
        self.capturePhotoOutput = capturePhotoOutput
        
        success = true
        
    }
    
    @objc func handlePan(_ gestureRecognizer:UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: view)
            gestureRecognizer.view!.center = CGPoint(x: gestureRecognizer.view!.center.x+translation.x , y: gestureRecognizer.view!.center.y+translation.y)
            gestureRecognizer.setTranslation(CGPoint.zero, in: view)
        }
    }
    
    @objc func handlePinch(_ gestureRecognizer:UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let currentScale:CGFloat = gestureRecognizer.view?.layer.value(forKeyPath: "transform.scale.x") as! CGFloat
            
            let minScale:CGFloat = 0.15
            let maxScale:CGFloat = 2.0
            let zoomSpeed:CGFloat = 0.5
            
            var deltaScale:CGFloat = gestureRecognizer.scale
            
            deltaScale = ((deltaScale - 1)*zoomSpeed) + 1
            deltaScale = min(deltaScale, maxScale/currentScale)
            deltaScale = max(deltaScale, minScale/currentScale)

            
            gestureRecognizer.view?.transform = gestureRecognizer.view!.transform.scaledBy(x:deltaScale, y:deltaScale)
            gestureRecognizer.scale = 1
            
        }
        
    }
    
    @objc func handlePinch2(_ gestureRecognizer:UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
           
            let pinchVelocityDividerFactor:CGFloat = 5.0
            var device = defaultDevice()
            var error:NSError!
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            
            let desiredZoomFactor = device.videoZoomFactor + CGFloat(atan2f(Float(gestureRecognizer.velocity), Float(pinchVelocityDividerFactor)))
            device.videoZoomFactor = max(1.0, min(desiredZoomFactor, device.activeFormat.videoMaxZoomFactor))
            device.unlockForConfiguration()
            } catch let error {
                print("Error: \(error.localizedDescription)")
                //print("Unable to set zoom: (max: \(device.maxAvailableVideoZoomFactor), asked: \(CGFloat(sender.value))")
            }
        }
    }
    
    
    
    @objc func handlePan2(_ gestureRecognizer:UIPanGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
             self.firstPoint = gestureRecognizer.location(ofTouch: 0, in: gestureRecognizer.view!)
        }
        
        print("self.firstPoint=\(self.firstPoint)")
        let point = gestureRecognizer.location(in: gestureRecognizer.view!)
        
        
        
        
        let maskView = UIView(frame: CGRect(x: gestureRecognizer.view!.frame.origin.x, y: gestureRecognizer.view!.frame.origin.y, width: self.firstPoint.x, height: self.firstPoint.y))
        maskView.backgroundColor = UIColor.black
        videoPreviewView.mask = maskView
        
        
        
    }
    
    func setupZoomGesture() {
        zoomVideoPreviewViewPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ImageViewController.handlePinch2(_:)))
        view.addGestureRecognizer(zoomVideoPreviewViewPinchGestureRecognizer)
    }
    
    func setupMoveGesture() {
        dragVideoPreviewViewPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ImageViewController.handlePan(_:)))
        scaleVideoPreviewViewPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ImageViewController.handlePinch(_ :)))
        
        videoPreviewView.addGestureRecognizer(dragVideoPreviewViewPanGestureRecognizer)
        videoPreviewView.addGestureRecognizer(scaleVideoPreviewViewPinchGestureRecognizer)
    }
    
    func tearDownZoomGesture() {
        
        view.gestureRecognizers = nil
       
    }
    
    func tearDownMoveGesture() {
        
        videoPreviewView.gestureRecognizers = nil
    }
    
    
    
//    func setupGestureRecognizer() {
//
//        dragVideoPreviewViewPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ImageViewController.handlePan(_:)))
//        scaleVideoPreviewViewPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ImageViewController.handlePinch(_ :)))
//
//        videoPreviewView.addGestureRecognizer(dragVideoPreviewViewPanGestureRecognizer)
//        videoPreviewView.addGestureRecognizer(scaleVideoPreviewViewPinchGestureRecognizer)
//
//    }

    @IBAction func changeOption(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
                print("zoom to move")
                
                
                tearDownZoomGesture()
                setupMoveGesture()
                
            break
        case 1:
                print("move to zoom")
                
                
                tearDownMoveGesture()
                setupZoomGesture()
                
                
            break
            
        default:
            break
        }
    }
    
    
    @IBAction func zoom(_ sender: UISlider) {
        
        var device = defaultDevice()
        var error:NSError!
        do {
            try device.lockForConfiguration()
            defer {device.unlockForConfiguration()}
            if CGFloat(sender.value) <= (device.activeFormat.videoMaxZoomFactor) {
                device.videoZoomFactor = CGFloat(sender.value)
                
            } else {
                print("Unable to set zoom: (max: \(device.maxAvailableVideoZoomFactor), asked: \(CGFloat(sender.value))")
            }
        } catch error as NSError {
            print("Unable to set zoom: \(error.localizedDescription)")
        } catch _ {
            
        }
    }
    
    
    
   
    
    
    
    var isResizingLR:Bool = false
    var isResizingUL:Bool = false
    var isResizingUR:Bool = false
    var isResizingLL:Bool = false
    var touchStart:CGPoint = CGPoint.zero
    let kResizeThumbSize:CGFloat = 45.0
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if optionSegmentedControl.selectedSegmentIndex == 1 {
            _ = event?.allTouches?.first!
            let touchStart = touches.first!.location(in: view)
            isResizingLR = (videoPreviewView.bounds.size.width - touchStart.x < kResizeThumbSize && videoPreviewView.bounds.size.height - touchStart.y < kResizeThumbSize)
            isResizingUL = (touchStart.x < kResizeThumbSize && touchStart.y < kResizeThumbSize)
            isResizingUR = (videoPreviewView.bounds.size.width - touchStart.x < kResizeThumbSize && touchStart.y < kResizeThumbSize)
            isResizingLL = (touchStart.x < kResizeThumbSize && videoPreviewView.bounds.size.height - touchStart.y < kResizeThumbSize)
            
        }
        
       
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if optionSegmentedControl.selectedSegmentIndex == 1 {
            
            
            
            
            let touchPoint:CGPoint! = touches.first!.location(in: videoPreviewView)
            let previous:CGPoint! = touches.first!.previousLocation(in: videoPreviewView)
            
            let x = videoPreviewView.bounds.origin.x
            let y = videoPreviewView.bounds.origin.y
            
            var frame = CGRect.zero
            
            if isResizingLR {
                
                frame = CGRect(x: x,
                               y: y,
                               width: touchPoint.x,
                               height: touchPoint.y)
                
                videoPreviewView.mask = UIView(frame: frame)
                
            }
            videoPreviewView.mask?.backgroundColor = UIColor.red
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if optionSegmentedControl.selectedSegmentIndex == 1 {
            previousPoint.x = videoPreviewView.mask!.bounds.origin.x + videoPreviewView.mask!.bounds.width
            previousPoint.y = videoPreviewView.mask!.bounds.origin.y + videoPreviewView.mask!.bounds.height
            
        }
    }
    
    
    
    /*
 
     //else if isResizingUL {
     //                frame = CGRect(x: x+deltaWidth,
     //                               y: y+deltaHeight,
     //                               width: width-deltaWidth,
     //                               height: height-deltaHeight)
     //                videoPreviewView.mask = UIView(frame: frame)
     //                print("Upper Left")
     //            } else if isResizingUR {
     //                frame = CGRect(x: x,
     //                               y: y+deltaWidth,
     //                               width: width+deltaWidth,
     //                               height: height-deltaHeight)
     //                videoPreviewView.mask = UIView(frame: frame)
     //                print("Upper Right")
     //            } else if isResizingLL {
     //                frame = CGRect(x: x+deltaWidth,
     //                               y: y,
     //                               width: width-deltaWidth,
     //                               height: height+deltaHeight)
     //                videoPreviewView.mask = UIView(frame: frame)
     //                print("Lower Left")
 
     */

    
    
    
}
