//
//  VideoRecordingManager.swift
//  PlayerSwift
//
//  Created by 张鑫 on 2017/5/10.
//  Copyright © 2017年 CrowForRui. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

protocol VideoRecordingManagerDelegate:class {
    func updateRecordingProgress(progress:CGFloat)
}

typealias finishBlock = ()->()

class VideoRecordingManager: NSObject ,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate{
    
    public var maxRecordingTime = 10.0 //最大时长
    public var autoSaveVideo = false // 自动保存
    public var isRecoading = false //开始录制
    public weak var delegate:VideoRecordingManagerDelegate?
    var videoPath : URL? = nil
    var startRecordingCMTime = CMTimeMake(0, 0)
    var recordingWriter : VideoRecordWriter? = nil
    var currentRecording = 0.0
    var videoFileURL : URL? = nil
    var callBack:finishBlock?
    
    override init() {
        super.init()
        //缓存文件
        let cachePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentationDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first
        var isDirectory : ObjCBool = false
        //TODO objcBool 和 bool 区别
        let isExists = FileManager.default.fileExists(atPath: cachePath!, isDirectory: &isDirectory)
        if (!isExists){
            try? FileManager.default.createDirectory(at: NSURL.init(string:cachePath!)! as URL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    //开始播放流
    public func startCapture(){
        self.isRecoading = false
        self.captureSession.startRunning()
    }

    func stopCapture(){
        self.captureSession.stopRunning()
    }

    public func startRecoring(){
        if self.isRecoading{
            return
        }
        self.isRecoading = true
    }
        
    public func stopRecoringHandler(handler:@escaping ((_ firstFrameImage:UIImage) -> Void)){
        if !self.isRecoading{
            return;
        }
        self.isRecoading = false
        self.videoFileURL = self.recordingWriter?.videoPath
        self.captureQueue.async {
            self.recordingWriter?.finishWritingWithCompletionHandler {
                self.isRecoading = false
                self.startRecordingCMTime = CMTimeMake(0, 0)
                self.currentRecording = 0
                self.recordingWriter = nil
                DispatchQueue.main.sync {
                    self.delegate?.updateRecordingProgress(progress: CGFloat(self.currentRecording/self.maxRecordingTime))
                }
                if self.autoSaveVideo{
                    self.saveCurrentRecordingVideo()
                }
                let videoFileURL = self.videoPath
                let videoAsset = AVURLAsset.init(url: videoFileURL!)
                let imageGenerator = AVAssetImageGenerator.init(asset: videoAsset)
                imageGenerator.appliesPreferredTrackTransform = true
                let thumbTime = CMTime.init(value: 0, timescale: 60)
                imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels
                imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue.init(time: thumbTime)], completionHandler: { (requestedTime, image, actualTime, result, error) in
                    if result != AVAssetImageGeneratorResult.succeeded{
                        return
                    }
                    let firstFrameImage = UIImage.init(cgImage: image!)
                    handler(firstFrameImage)
                })
            }
        }
    }
    
    public func switchCameraAnimation(){
        let filpAnimation = CATransition.init()
        filpAnimation.duration = 0.5
        filpAnimation.type = "oglFlip"
        filpAnimation.subtype = kCATransitionFromRight
        filpAnimation.timingFunction =  CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        self.previewLayer.add(filpAnimation, forKey: "filpAnimation")
    }
    
    public func switchCameraInputDeviceToFront(){
        self.captureSession.stopRunning()
        self.captureSession.removeInput(self.backCameraInput)
        if self.captureSession.canAddInput(self.frontCameraInput) {
            self.captureSession.addInput(self.frontCameraInput)
            self.captureSession.startRunning()
            self.switchCameraAnimation()
        }
    }
    
    public func swithCameraInputDeviceToBack(){
        self.captureSession.stopRunning()
        self.captureSession.removeInput(self.frontCameraInput)
        if self.captureSession.canAddInput(self.backCameraInput) {
            self.captureSession.addInput(self.backCameraInput)
            self.captureSession.startRunning()
            self.switchCameraAnimation()
        }
    }
    
    func saveCurrentRecordingVideo(){
        self.PHAuthorizationStatus()
    }
    
    func PHAuthorizationStatus(){
        PHPhotoLibrary.shared().performChanges({ 
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoFileURL!)
        }) { (success, error) in
            if (success){
                print("success")
            }else{
                print("faile\(String(describing: error))")
            }
        }
    }
    
    deinit {
        self.captureSession.stopRunning()
    }
    
    //MARK:Delegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if !self.isRecoading {
            return;
        }
        if captureOutput! == self.videoOutput && !(self.recordingWriter != nil) {
            //指针初始化失败
            let tmpFileURL = NSURL.fileURL(withPath: "\(NSTemporaryDirectory())tmp.mp4")
            self.videoPath = tmpFileURL
            self.recordingWriter = VideoRecordWriter.init(videoPath: self.videoPath!, width: NSInteger(kDeviceWidth), height:NSInteger(kDeviceHeight))
        }
        
        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if self.startRecordingCMTime.value == 0 {
            self.startRecordingCMTime = presentationTimeStamp
        }
        let subtract = CMTimeSubtract(presentationTimeStamp, self.startRecordingCMTime)
        self.currentRecording = CMTimeGetSeconds(subtract)
        if self.currentRecording > self.maxRecordingTime {
            self.callBack!()
            return
        }
        self.recordingWriter?.writeWithSampleBuffer(sampleBuffer: sampleBuffer, isVideo: captureOutput == self.videoOutput ? true:false)
        DispatchQueue.main.async {
            self.delegate?.updateRecordingProgress(progress: CGFloat(self.currentRecording/self.maxRecordingTime))
        }
    }

    //MARK:lazyloading
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let previewLayer = AVCaptureVideoPreviewLayer.init(session: self.captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        return previewLayer!
    }()
    
    //dispatch_t
    lazy var captureQueue: DispatchQueue = {
        let captureQueue = DispatchQueue.init(label: "captureQueue")
        return captureQueue
    }()
    
    //视频输出
    lazy var videoOutput: AVCaptureVideoDataOutput = {
        let videoOutput = AVCaptureVideoDataOutput.init()
        videoOutput.setSampleBufferDelegate(self, queue: self.captureQueue)
        return videoOutput
    }()
    
    //音频输入
    lazy var audioInput: AVCaptureDeviceInput = {
        let captureDeviceAudio = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        let audioInput = try? AVCaptureDeviceInput.init(device: captureDeviceAudio)
        return audioInput!
    }()
    
    //音频输出
    lazy var audioOutput: AVCaptureAudioDataOutput = {
        let audioOutput = AVCaptureAudioDataOutput.init()
        audioOutput.setSampleBufferDelegate(self, queue: self.captureQueue)
        return audioOutput
    }()

    //后置摄像头
    lazy var backCameraInput: AVCaptureDeviceInput = {
        var backDevice : AVCaptureDevice? = nil
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        for item in devices{
            if item.position == AVCaptureDevicePosition.back{
                backDevice = item
                break;
            }
        }
        let backCameraInput = try? AVCaptureDeviceInput.init(device: backDevice)
        return backCameraInput!
    }()
    
    lazy var frontCameraInput: AVCaptureDeviceInput = {
        var fontDevice : AVCaptureDevice? = nil
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        for item in devices{
            if item.position == AVCaptureDevicePosition.front{
                fontDevice = item
                break;
            }
        }
        let frontCameraInp = try? AVCaptureDeviceInput.init(device: fontDevice)
        return frontCameraInp!
    }()
    
    lazy var captureSession: AVCaptureSession = {
        let captureSession = AVCaptureSession.init()
        if captureSession.canAddInput(self.backCameraInput){
            captureSession.addInput(self.backCameraInput)
        }
        if captureSession.canAddInput(self.audioInput){
            captureSession.addInput(self.audioInput)
        }
        if captureSession.canAddOutput(self.audioOutput){
            captureSession.addOutput(self.audioOutput)
        }
        if captureSession.canAddOutput(self.videoOutput){
            captureSession.addOutput(self.videoOutput)
        }
        self.videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
        return captureSession
    }()
    
    //视频连接
    lazy var videoConnection: AVCaptureConnection = {
        let videoConnection : AVCaptureConnection = self.videoOutput.connection(withMediaType: AVMediaTypeVideo)
        return videoConnection
    }()
    
    //音频连接
    lazy var audioConnection: AVCaptureConnection = {
        let audioConnection = self.audioOutput.connection(withMediaType: AVMediaTypeAudio)
        return audioConnection!
    }()
    
}
