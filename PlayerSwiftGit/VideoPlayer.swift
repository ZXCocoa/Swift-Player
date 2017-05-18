//
//  VideoPlayer.swift
//  PlayerSwift
//
//  Created by 张鑫 on 2017/5/12.
//  Copyright © 2017年 CrowForRui. All rights reserved.
//

import UIKit
import AVFoundation

let kDeviceWidth = UIScreen.main.bounds.width
let kDeviceHeight = UIScreen.main.bounds.height

class VideoPlayer: UIView {
    var videoUrl : NSURL? = nil
    var ctrlView :UIView? = nil
    var player : AVPlayer? = nil
    var playerItem : AVPlayerItem? = nil
    var isPlaying = false
    var uploadBlock : ((_ faileUrl: NSString) -> Void)?
    
    convenience  init(frame: CGRect,videoUrl:NSURL) {
        self.init(frame: frame)
        self.videoUrl = videoUrl
        self.setupSubviews()
    }

    func setupSubviews(){
        self.ctrlView = UIView.init(frame: self.frame)
        self.ctrlView?.backgroundColor = UIColor.black
        self.addSubview(self.ctrlView!)
        NotificationCenter.default.addObserver(self, selector: #selector(playEnd), name:NSNotification.Name.AVPlayerItemDidPlayToEndTime , object: nil)
        let videoAsset = AVURLAsset.init(url: self.videoUrl! as URL)
        self.playerItem = AVPlayerItem.init(asset: videoAsset)
        self.player = AVPlayer.init(playerItem: self.playerItem)
        let playerLayer = AVPlayerLayer.init(player: self.player)
        playerLayer.frame = CGRect.init(x:0, y: 0, width: kDeviceWidth, height: kDeviceHeight)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.ctrlView?.layer.addSublayer(playerLayer)       
        
        let cancelBtn = UIButton.init(frame: CGRect.init(x: 100, y: kDeviceHeight - 100, width: 80, height: 80))
        cancelBtn.backgroundColor = UIColor.black
        cancelBtn.setTitle("取消", for: UIControlState.normal)
        cancelBtn.setTitleColor(UIColor.white, for: UIControlState.normal)
        cancelBtn.layer.cornerRadius = cancelBtn.frame.width/2
        cancelBtn.layer.masksToBounds = true
        cancelBtn.addTarget(self, action: #selector(cancelMethod(sender:)), for: UIControlEvents.touchUpInside)
        self.ctrlView?.addSubview(cancelBtn)
        
        let doneBtn = UIButton.init(frame: CGRect.init(x: kDeviceWidth - 180, y: kDeviceHeight - 100, width: 80, height: 80))
        doneBtn.backgroundColor = UIColor.black
        doneBtn.setTitle("完成", for: UIControlState.normal)
        doneBtn.setTitleColor(UIColor.white, for: UIControlState.normal)
        doneBtn.layer.cornerRadius = doneBtn.frame.width/2
        doneBtn.layer.masksToBounds = true
        doneBtn.addTarget(self, action: #selector(doneMethod), for: UIControlEvents.touchUpInside)
        self.ctrlView?.addSubview(doneBtn)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapAction))
        self.ctrlView?.addGestureRecognizer(tap)
        self.tapAction()
    }
    
    func tapAction(){
        if self.isPlaying {
            self.player?.pause()
        }else{
            self.player?.play()
        }
        self.isPlaying = !self.isPlaying
    }
    
    func cancelMethod(sender:UIButton){
        self.endPlayMethod()
    }
    
    func doneMethod(){
        let fileStr = "\(String(describing: self.videoUrl))" as NSString
        uploadBlock?(fileStr)
        self.endPlayMethod()
    }
    
    func endPlayMethod(){
        self.player?.pause()
        self.player?.currentItem?.cancelPendingSeeks()
        self.player?.currentItem?.asset.cancelLoading()
        self.removeFromSuperview()
        NotificationCenter.default.removeObserver(self)
    }
    
    func playEnd(){
        self.player?.seek(to: kCMTimeZero, completionHandler: { (finish) in
            self.player?.play()
        })
    }
    
}
