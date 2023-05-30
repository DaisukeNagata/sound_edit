//
//  AudioRecorder.swift
//  Runner
//
//  Created by 永田大祐 on 2023/05/28.
//

import AVFoundation
/// TODO function
class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    var isRecording = false

    func startRecording(path: String) {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
            try audioSession.setInputGain(1.0)
            let recordingSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false
            ]
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFileUrl = documentsDirectory.appendingPathComponent(path)
            
            audioRecorder = try AVAudioRecorder(url: audioFileUrl, settings: recordingSettings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Error setting up audio recorder: \(error.localizedDescription)")
        }
    }

    func stopRecording(call: @escaping () -> Void) {
        audioRecorder?.stop()
        isRecording = false
        call()
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Error: Recording was not successful")
        }
    }
}
