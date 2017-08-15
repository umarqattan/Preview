//
//  ImageViewController.swift
//  Preview
//
//  Created by Umar Qattan on 8/12/17.
//  Copyright © 2017 Umar Qattan. All rights reserved.
//

import UIKit


class ImageViewController: UIViewController {

    let overlay = UIView()
    var lastPoint = CGPoint.zero
    
    var image:UIImage!
    @IBOutlet weak var imageView: UIImageView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.image = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
        overlay.layer.borderColor = UIColor.black.cgColor
        overlay.backgroundColor = UIColor.clear.withAlphaComponent(0.5)
        overlay.isHidden = true
        self.view.addSubview(overlay)
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
        
        
        
    }
    
    
    func redrawSelectionArea(fromPoint: CGPoint, toPoint: CGPoint) {
        overlay.isHidden = false
        let rect = CGRect(x: min(fromPoint.x, toPoint.x), y: min(fromPoint.y, toPoint.y), width: fabs(fromPoint.x-toPoint.x), height: fabs(fromPoint.y-toPoint.y))
        
        overlay.frame = rect
        
    }
    
    
    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        
//        //Save original tap Point
//        if let touch = touches.first {
//            lastPoint = touch.location(in: self.view)
//        }
//    }
//    
//    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        //Get the current known point and redraw
//        if let touch = touches.first {
//            let currentPoint = touch.location(in: view)
//            reDrawSelectionArea(fromPoint: lastPoint, toPoint: currentPoint)
//        }
//    }
//    
//    func reDrawSelectionArea(fromPoint: CGPoint, toPoint: CGPoint) {
//        overlay.isHidden = false
//        
//        //Calculate rect from the original point and last known point
//        let rect = CGRect(min(fromPoint.x, toPoint.x),
//                              min(fromPoint.y, toPoint.y),
//                              fabs(fromPoint.x - toPoint.x),
//                              fabs(fromPoint.y - toPoint.y));
//        
//        overlay.frame = rect
//    }
//    
//    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        overlay.isHidden = true
//        
//        //User has lift his finger, use the rect
//        applyFilterToSelectedArea(overlay.frame)
//        
//
//        
//        overlay.frame = RectZero //reset overlay for next tap
//    }

    
}


