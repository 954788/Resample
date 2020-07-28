//
//  ViewController.swift
//  AVAudioEngine
//
//  Created by Fatm on 2020/7/28.
//  Copyright © 2020 梁展焯. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    // MARK: Variable
    /// 录音引擎
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    /// 采样率
    private let sampleRate:Double = 48000
    /// 采样间隔
    private let ioBufferDuration = 0.1
    /// 位宽
    private let bit = 16
    /// 重采样队列
    private let audioQueue = DispatchQueue.init(label: "com.resample.test")
    
    
    // MARK: UI

    // MARK: Initialize
     override func loadView() {
         super.loadView()
        
     }
     
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupEngine()
    }
    
    // MARK: Action
    @IBAction func startAction(_ sender: Any) {
        try? audioEngine.start()
    }
    
    // MARK: Method
    private func setupEngine(){
        let audiosession = AVAudioSession.sharedInstance()
        do{
            try audiosession.setPreferredSampleRate(sampleRate)
            try audiosession.setPreferredIOBufferDuration(ioBufferDuration)
            try audiosession.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        }catch{
            print(error)
        }
        
        let inputNode = audioEngine.inputNode
        var setting = audioEngine.inputNode.inputFormat(forBus: 0).settings
        setting[AVLinearPCMBitDepthKey] = bit
        setting[AVSampleRateKey] = sampleRate
        setting[AVLinearPCMIsFloatKey] = 0
        
        // 录音信息
        let newFormat = AVAudioFormat.init(settings: setting)
        
        // 重采样信息
        let resampleFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(16000), channels: 1, interleaved: false)
        let formatConverter =  AVAudioConverter(from:newFormat!, to: resampleFormat!)
        
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(0.1*sampleRate), format: newFormat) { (buffer, time) in
            
            self.audioQueue.async {
                guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: resampleFormat!, frameCapacity: AVAudioFrameCount(1600)) else{
                    return
                }
                
                let inputBlock: AVAudioConverterInputBlock = {inNumPackets, outStatus in
                    outStatus.pointee = AVAudioConverterInputStatus.haveData
                    return buffer
                }
                
                var error: NSError? = nil
                formatConverter?.convert(to: pcmBuffer, error: &error, withInputFrom: inputBlock)
                
                print("\(pcmBuffer) \(Date().timeIntervalSince1970)")
            }
        }
    }
    
    func toNSData(PCMBuffer: AVAudioPCMBuffer) -> NSData {
        let channelCount = 1  // given PCMBuffer channel count is 1
        let channels = UnsafeBufferPointer(start: PCMBuffer.int16ChannelData, count: channelCount)
        let ch0Data = NSData(bytes: channels[0], length:Int(PCMBuffer.frameCapacity * PCMBuffer.format.streamDescription.pointee.mBytesPerFrame))
        return ch0Data
    }
}

