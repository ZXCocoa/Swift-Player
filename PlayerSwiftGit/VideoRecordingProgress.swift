//
//  VideoRecordingProgress.swift
//  PlayerSwift
//
//  Created by 张鑫 on 2017/5/10.
//  Copyright © 2017年 CrowForRui. All rights reserved.
//

import UIKit


class RecordingProgressViewBackgroundLayer: CALayer {
    var tintsColor:UIColor? = nil
    
    convenience init(tintColor:UIColor) {
        self.init()
        self.tintsColor = tintColor
        self.setNeedsDisplay()
    }

    override func draw(in ctx: CGContext) {
        ctx.setFillColor(UIColor.white.cgColor);
        let WH = self.bounds.size.width * 0.3;
        ctx.fill(CGRect.init(x: self.bounds.midX - WH * 0.5, y: self.bounds.midY - WH * 0.5, width: WH, height: WH))
        ctx.setStrokeColor((tintsColor?.cgColor)!);
        ctx.strokeEllipse(in: self.bounds.insetBy(dx: 1, dy: 1));
    }
}

class VideoRecordingProgress: UIView{
    var backgroundLayer:RecordingProgressViewBackgroundLayer? = nil
    var shapeLayer:CAShapeLayer? = nil
    public var progressTintColor : UIColor? = nil
    var progress:Float = 0
    
    convenience init(frame:CGRect , tintColor : UIColor) {
        self.init()
        self.frame = frame
        self.progressTintColor = tintColor
        self.backgroundLayer = RecordingProgressViewBackgroundLayer.init(tintColor: self.progressTintColor!)
        self.backgroundLayer?.frame = self.bounds
        self.layer.addSublayer(self.backgroundLayer!)
        
        self.shapeLayer = CAShapeLayer.init()
        self.shapeLayer?.frame = self.bounds
        self.shapeLayer?.fillColor = UIColor.clear.cgColor
        self.shapeLayer?.strokeColor = self.progressTintColor?.cgColor
        self.shapeLayer?.lineWidth = 1
        let circlePath = UIBezierPath()
        circlePath.addArc(withCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                          radius: bounds.size.width/2 - 2,
                          startAngle:CGFloat(-Float.pi / 2), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        self.shapeLayer?.path = circlePath.cgPath
        self.layer.addSublayer(self.shapeLayer!)
    }
    
    public func setProgress(progress:CGFloat){
        self.progress = Float(progress)
        if self.progress <= 0{
            self.shapeLayer?.removeAnimation(forKey: "strokeEndAnimation")
            return;
        }
        self.shapeLayer?.lineWidth = 3
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.shapeLayer?.strokeEnd = progress
        CATransaction.commit()
    }
    
    func setProgressTintColor(progressTintColor:UIColor){
        self.progressTintColor = progressTintColor
        self.backgroundLayer?.tintsColor = progressTintColor
        self.shapeLayer?.strokeColor = progressTintColor.cgColor
    }

}


