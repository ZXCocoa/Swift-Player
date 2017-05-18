//
//  VideoPlayerController.swift
//  PlayerSwift
//
//  Created by 张鑫 on 2017/5/12.
//  Copyright © 2017年 CrowForRui. All rights reserved.
//

import UIKit
class VideoPlayerController: UIViewController , VideoRecordingManagerDelegate{

    public var videoPath:NSURL? = nil
    var player : VideoPlayer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.setupBottomToolBar()
        self.recordingManager.previewLayer.frame = self.view.bounds
        self.view.layer.insertSublayer(self.recordingManager.previewLayer, at: 0)
        self.recordingManager.startCapture()
//        self.videoPath = NSURL.init(string: "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
    }
    
    func setupBottomToolBar(){
        self.view.addSubview(self.bottomToolBar)
        self.startRecordingBtn.frame = CGRect.init(x: (bottomToolBar.frame.size.width - 75) * 0.5, y: (bottomToolBar.frame.size.height - 75) * 0.5, width: 75, height: 75)
        self.bottomToolBar.addSubview(self.startRecordingBtn)
        self.recordingProgress.isHidden = true
        self.playVideoBtn.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateRecordingProgress(progress: CGFloat) {
        self.recordingProgress.setProgress(progress: progress)
        if progress >= 1.0 {
            self.stopRecording()
        }
    }
    
    func stopRecording(){
        self.startRecordingBtn.isHidden = false
        self.recordingProgress.isHidden = true
        self.playVideoBtn.isHidden = false
        self.recordingManager.stopRecoringHandler { (image) in
            
        }
        self.playVideoAction()
    }

    func startRecordingBtnAction(sender:UIButton){
        sender.isHidden = true
        self.playVideoBtn.isHidden = true
        self.recordingProgress.isHidden = false
        self.recordingManager.startRecoring()
    }
    
    func playVideoAction(){
        if (self.videoPath != nil) {
            //网络视频
            self.player = VideoPlayer.init(frame: self.view.frame, videoUrl: self.videoPath!)
        }else{
            //本地视频
            let url = self.recordingManager.videoPath
            self.player = VideoPlayer.init(frame: self.view.frame, videoUrl: url! as NSURL)
            self.player?.uploadBlock = {(filePath) in
                
            }
        }
        self.view.addSubview(self.player!)
    }
    
    lazy var recordingManager: VideoRecordingManager = {
        let recordingManager = VideoRecordingManager.init()
        recordingManager.maxRecordingTime = 15
        recordingManager.delegate = self
        recordingManager.callBack = {
            DispatchQueue.main.sync {
                self.stopRecording()
            }
        }
        return recordingManager
    }()
    
    lazy var startRecordingBtn: UIButton = {
        let startRecordingBtn = UIButton.init(type: UIButtonType.custom)
        startRecordingBtn.setImage(UIImage.init(named: "start_recording"), for: UIControlState.normal)
        startRecordingBtn.addTarget(self, action: #selector(startRecordingBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        return startRecordingBtn
    }()
    
    lazy var recordingProgress: VideoRecordingProgress = {
        let recordingProgress = VideoRecordingProgress.init(frame: self.startRecordingBtn.frame, tintColor: UIColor.red)
        recordingProgress.progressTintColor = UIColor.init(red: 1.00, green: 0.28, blue: 0.26, alpha: 1.0)
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(stopRecording))
        recordingProgress.addGestureRecognizer(tap)
        recordingProgress.isHidden = true
        self.bottomToolBar.addSubview(recordingProgress)
        return recordingProgress
    }()
    
    lazy var bottomToolBar: UIView = {
        let bottomToolBar = UIView.init(frame: CGRect.init(x: 0, y: kDeviceHeight - 150, width: kDeviceWidth, height: 150))
        bottomToolBar.backgroundColor = UIColor.init(white: 0, alpha: 0.25)
        return bottomToolBar
    }()
    
    lazy var playVideoBtn: UIButton = {
        let playVideoBtn = UIButton.init()
        playVideoBtn.frame = CGRect.init(x: self.bottomToolBar.frame.size.width * 0.5 - 25, y: (self.bottomToolBar.frame.size.height - 50) * 0.5, width: 50, height: 50)
        playVideoBtn.imageView?.contentMode = UIViewContentMode.scaleAspectFill
        playVideoBtn.layer.cornerRadius = playVideoBtn.frame.size.width/2
        playVideoBtn.layer.masksToBounds = true
        playVideoBtn.addTarget(self, action: #selector(playVideoAction), for: UIControlEvents.touchUpInside)
        return playVideoBtn
    }()

}


