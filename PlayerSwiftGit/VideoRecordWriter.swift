//
//  VideoRecordWriter.swift
//  PlayerSwift
//
//  Created by 张鑫 on 2017/5/10.
//  Copyright © 2017年 CrowForRui. All rights reserved.
//

import UIKit
import AVFoundation

class VideoRecordWriter: NSObject {
    
    private(set) var videoPath : URL? = nil
    var assetWriter:AVAssetWriter? = nil
    var assetVideoInput:AVAssetWriterInput? = nil
    var assetAudioInput:AVAssetWriterInput? = nil
    
    convenience init(videoPath:URL,width:NSInteger,height:NSInteger) {
        self.init()
        self.videoPath = videoPath
        try? FileManager.default.removeItem(at: self.videoPath!)
        do {
            try self.assetWriter =  AVAssetWriter.init(url: videoPath, fileType: AVFileTypeMPEG4)
        } catch  let error{
            print(error)
        }

        self.assetWriter?.shouldOptimizeForNetworkUse = true
        let settings = [AVVideoCodecKey:AVVideoCodecH264,AVVideoWidthKey:width,AVVideoHeightKey:height] as [String : Any]
        self.assetVideoInput = AVAssetWriterInput.init(mediaType: AVMediaTypeVideo, outputSettings: settings)
        self.assetVideoInput?.expectsMediaDataInRealTime = true
        self.assetWriter?.add(self.assetVideoInput!)
        
        let audioSetting = [AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC)),AVNumberOfChannelsKey : NSNumber(value: 1),AVSampleRateKey : NSNumber(value: Float(44100.0)),AVEncoderBitRateKey:128000] as [String : Any]
        self.assetAudioInput = AVAssetWriterInput.init(mediaType: AVMediaTypeAudio, outputSettings: audioSetting)
        self.assetAudioInput?.expectsMediaDataInRealTime = true
        self.assetWriter?.add(self.assetAudioInput!)
    }

    public func writeWithSampleBuffer(sampleBuffer:CMSampleBuffer,isVideo:Bool){
        if CMSampleBufferDataIsReady(sampleBuffer) {
            if self.assetWriter?.status == AVAssetWriterStatus.unknown && isVideo{
                self.assetWriter?.startWriting()
                self.assetWriter?.startSession(atSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            }
            if isVideo {
                if (self.assetVideoInput?.isReadyForMoreMediaData)! {
                    self.assetVideoInput?.append(sampleBuffer)
                }
            }else{
                if (self.assetAudioInput?.isReadyForMoreMediaData)! {
                    self.assetAudioInput?.append(sampleBuffer)
                }
            }
            if self.assetWriter?.status == AVAssetWriterStatus.failed {
                print("write error \(String(describing: self.assetWriter?.error?.localizedDescription))")
            }
        }
    }
    
    public func finishWritingWithCompletionHandler(_ hander:@escaping (Void) -> Void){
        self.assetWriter?.finishWriting(completionHandler: hander)
    }
    
}
