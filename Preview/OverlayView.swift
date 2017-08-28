//
//  MaskView.swift
//  Preview
//
//  Created by Umar Qattan on 8/25/17.
//  Copyright © 2017 Umar Qattan. All rights reserved.
//

import Foundation
import UIKit



class MaskView: UIView {
    
    var isResizingLR:Bool = false
    var isResizingUL:Bool = false
    var isResizingUR:Bool = false
    var isResizingLL:Bool = false
    var touchStart:CGPoint = CGPoint.zero
    let kResizeThumbSize:CGFloat = 45.0
    
    
   
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        _ = event?.allTouches?.first!
        let touchStart = touches.first!.location(in: self)
        isResizingLR = (bounds.size.width - touchStart.x < kResizeThumbSize && bounds.size.height - touchStart.y < kResizeThumbSize)
        isResizingUL = (touchStart.x < kResizeThumbSize && touchStart.y < kResizeThumbSize)
        isResizingUR = (bounds.size.width - touchStart.x < kResizeThumbSize && touchStart.y < kResizeThumbSize)
        isResizingLL = (touchStart.x < kResizeThumbSize && bounds.size.height - touchStart.y < kResizeThumbSize)
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchPoint = touches.first!.location(in: self)
        let previous = touches.first!.previousLocation(in: self)
        
        let deltaWidth = touchPoint.x - previous.x
        let deltaHeight = touchPoint.y - previous.y
        
        let x = frame.origin.x
        let y = frame.origin.y
        let width = frame.size.width
        let height = frame.size.height
        
        if isResizingLR {
            frame = CGRect(x: x,
                           y: y,
                           width: touchPoint.x+deltaWidth,
                           height: touchPoint.y+deltaWidth)
            self.mask = UIView(frame: frame)
        } else if isResizingUL {
            frame = CGRect(x: x+deltaWidth,
                           y: y+deltaHeight,
                           width: width-deltaWidth,
                           height: height-deltaHeight)
            self.mask = UIView(frame: frame)
        } else if isResizingUR {
            frame = CGRect(x: x,
                           y: y+deltaWidth,
                           width: width+deltaWidth,
                           height: height-deltaHeight)
            self.mask = UIView(frame: frame)
        } else if isResizingLL {
            frame = CGRect(x: x+deltaWidth,
                           y: y,
                           width: width-deltaWidth,
                           height: height+deltaHeight)
        } else {
            center = CGPoint(x: center.x+touchPoint.x-touchStart.x,
                             y: center.y+touchPoint.y-touchStart.y)
            
        }
    }
    
}
