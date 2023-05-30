import UIKit
import Flutter
import AVFoundation

enum Channel {
    case trim
    case drag
}

public class SoundEditPlugin: NSObject, FlutterPlugin , AVAudioPlayerDelegate  {
    private var audioTime = AVAudioTime()
    private let audioEngine = AVAudioEngine()
    private let audioRecorder = AudioRecorder()
    private var bufferArray = [AVAudioPCMBuffer]()
    private let audioPlayerNode = AVAudioPlayerNode()
    private var audioPlayer:AVAudioPlayer?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = SoundEditPlugin()
        let music = FlutterMethodChannel(name: "co.jp.everydaysoft.sound_edit/music", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: music)
        
        let instance2 = SoundEditPlugin()
        let trim = FlutterMethodChannel(name: "co.jp.everydaysoft.sound_edit/trim", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance2, channel: trim)
        
        let instance3 = SoundEditPlugin()
        let drag = FlutterMethodChannel(name: "co.jp.everydaysoft.sound_edit/drag", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance3, channel: drag)
        
        let instance4 = SoundEditPlugin()
        let record = FlutterMethodChannel(name: "co.jp.everydaysoft.sound_edit/record", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance4, channel: record)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "audioPause":
            self.playPause()
        case "audioStop":
            self.playStop()
        case "recordStop":
            self.audioRecorder.stopRecording( call: {
                let response = self.doSomething()
                result(response)
            });
        default:
            if (call.method.contains("play")) {
                let word = call.method.replacingOccurrences(of: "play/", with: "")
                self.play(path: word, call: {
                    result(self.doSomething())
                })
            } else if (call.method.contains("trim")) {
                let word = call.method.replacingOccurrences(of: "trim/", with: "")
                self.convertSampleRateAndBitRate(type: Channel.trim, path:word, bitDepth: 16) { success, error, url, urls in
                    if success {
                        let input = call.method.replacingOccurrences(of: " ", with: "")
                        let soundList = call.method.replacingOccurrences(of: " ", with: "").split(separator:",")
                        let inputList = input.components(separatedBy: ",")
                        let digitsRegEx = "^[0-9]*\\.?[0-9]+$"
                        let digitsStrings = inputList.filter { $0.range(of: digitsRegEx, options: .regularExpression) != nil }
                        
                        self.deletePath(urls: urls)
                        self.audioFilePlayTrim(url: url,
                                               start: Double(digitsStrings.first ?? "") ?? 0.0,
                                               end: Double(digitsStrings.last ?? "") ?? 0.0,
                                               createURL: self.getAudioFileUrl(path: (String(soundList.last ?? ""))),
                                               completionHandler: { success, error,url  in
                            let response = self.getAudioDuration(url: url)
                            result(response)
                        })
                    } else {
                        result(1.0)
                        print("Failed to convert MP3 to WAV: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
            else if (call.method.contains("drag")) {
                let word = call.method.replacingOccurrences(of: "drag/", with: "")
                self.convertSampleRateAndBitRate(type: Channel.drag, path: word, bitDepth: 16) { success, error, url, urls in
                    if success {
                        let response = self.getAudioDuration(url: url)
                        result(response)
                        self.deletePath(urls: [url])
                        self.deletePath(urls: urls)
                    } else {
                        result(1.0)
                        self.deletePath(urls: urls)
                        print("Failed to convert MP3 to WAV: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            } else if (call.method.contains("record")) {
                self.audioRecorder.stopRecording {}
                result("")
            } else {
                self.audioRecorder.startRecording(path: call.method);               
            }
            break
        }
    }
    
    private func doSomething() -> String {
        return "Method completed"
    }
    
    private func getAudioDuration(url: URL) -> Double {
        let asset = AVURLAsset(url: url)
        let audioDuration = asset.duration
        let audioDurationInSeconds = CMTimeGetSeconds(audioDuration)
        return Double(audioDurationInSeconds)
    }
    
    private func getAudioFileUrl(path: String) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(path)
    }
    
    private func play(path: String, call: @escaping () -> Void) {
        if audioEngine.isRunning {
            audioPlayerNode.play()
        } else {
            audioFilePlay(url: self.getAudioFileUrl(path: path), call: {
                call()
            })
        }
    }
    
    private func playPause() {
        audioPlayerNode.pause()
    }
    
    private func playStop() {
        audioEngine.stop()
        audioPlayerNode.stop()
    }
    
    private func deletePath(urls: [URL]) {
        for i in 0..<urls.count {
            self.deleteFileInDocumentsDirectory(named: urls[i].lastPathComponent)
        }
    }
    
    private func deleteFileInDocumentsDirectory(named fileName: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not find documents directory")
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        deleteFile(atPath: fileURL.path)
    }
    
    private func deleteFile(atPath path: String) {
        let fileManager = FileManager.default
        
        do {
            try fileManager.removeItem(atPath: path)
            print("File deleted successfully at path: \(path)")
        } catch {
            print("Error deleting file at path:")
        }
    }
    
    private func audioFilePlay(url: URL, call: @escaping () -> Void) {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: .init(audioFile.length)) else { return }
            
            audioEngine.attach(audioPlayerNode)
            audioEngine.connect(audioPlayerNode, to: audioEngine.mainMixerNode, format: buffer.format)
            let currentPosition = Double(audioPlayerNode.lastRenderTime?.sampleTime ?? 0) / audioPlayerNode.outputFormat(forBus: 0).sampleRate
            audioPlayerNode.scheduleSegment(audioFile,
                                            startingFrame: AVAudioFramePosition(currentPosition),
                                            frameCount: AVAudioFrameCount(audioFile.length),
                                            at: nil) {
                
            }
            audioPlayerNode.scheduleBuffer(buffer, completionHandler: { [weak self] in
                print("Playback finished.")
                self?.audioEngine.reset()
                self?.audioEngine.stop()
                call()
            })
            if !audioEngine.isRunning {
                do {
                    try audioEngine.start()
                    audioPlayerNode.play()
                } catch {
                    return
                }
            }
        } catch {
            print(error)
        }
    }
    
    private func audioFilePlayTrim(url: URL, start: Double, end: Double, createURL: URL, completionHandler: @escaping (Bool, Error?, URL) -> Void) {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let sampleRate = audioFile.fileFormat.sampleRate
            let startSeconds = start * 0.01
            let endSeconds = end * 0.01
            guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: .init(audioFile.length)) else { return }
            let startFrame = AVAudioFramePosition(startSeconds * sampleRate)
            audioFile.framePosition = startFrame
            let endFrame = AVAudioFramePosition(endSeconds * sampleRate)
            let frameCount = UInt32(endFrame - startFrame)
            guard let editedBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: frameCount) else {
                print("Error: Unable to create destination buffer.")
                return
            }
            try audioFile.read(into: editedBuffer)
            do {
                let outputFile = try AVAudioFile(forWriting: createURL, settings: audioFile.fileFormat.settings)
                try outputFile.write(from: editedBuffer)
                print("Trimmed audio file saved at: \(createURL)")
            } catch {
                print("Error: \(error.localizedDescription)")
                return
            }
            completionHandler(true, nil, url)
        } catch {
            print(error)
        }
    }
    
    private func convertSampleRateAndBitRate(type: Channel, path: String, bitDepth: Int, completionHandler: @escaping (Bool, Error?, URL, [URL]) -> Void) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let soundList = path.replacingOccurrences(of: " ", with: "").split(separator:",")
        let sampleFileURL = documentsDirectory.appendingPathComponent(String(soundList.last ?? ""))
        // ２つの音楽ファイルを設定します。
        if FileManager.default.fileExists(atPath: sampleFileURL.relativePath) || soundList.count == 4 && type == Channel.drag || soundList.last == ".wav" {
            completionHandler(false, nil, documentsDirectory.appendingPathComponent(String(soundList.last ?? "")).absoluteURL, [])
            return
        }
        
        var urls = [URL]()
        for element in soundList {
            if (soundList.last != element) {
                urls.append(getAudioFileUrl(path: String(element).replacingOccurrences(of: " ", with: "")))
            }
        }
        
        
        for i in 0..<urls.count {
            
            let asset = AVURLAsset(url: urls[i])
            guard let track = asset.tracks(withMediaType: .audio).first else {
                return
            }
            do {
                
                let audioFile = try AVAudioFile(forReading: urls[i])
                let audioFileFormat = audioFile.processingFormat
                let audioFileBitDepth = audioFileFormat.streamDescription.pointee.mBitsPerChannel
                if (audioFileFormat.sampleRate <= 44100 || audioFileFormat.sampleRate >= 44100) {
                    let reader = try AVAssetReader(asset: asset)
                    let readerOutputSettings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVLinearPCMBitDepthKey: audioFileBitDepth,
                        AVLinearPCMIsFloatKey: false,
                        AVLinearPCMIsNonInterleaved: false,
                        AVLinearPCMIsBigEndianKey: false, // Add this line
                        AVSampleRateKey: audioFileFormat.sampleRate,
                        AVNumberOfChannelsKey: 2
                    ]
                    
                    let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: readerOutputSettings)
                    reader.add(readerOutput)
                    
                    let writer = try AVAssetWriter(outputURL: getAudioFileUrl(path: "writer\(Int.random(in: 1..<100000)).wav"), fileType: .wav)
                    let writerInputSettings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVLinearPCMBitDepthKey: bitDepth,
                        AVLinearPCMIsFloatKey: false,
                        AVLinearPCMIsNonInterleaved: false,
                        AVLinearPCMIsBigEndianKey: false, // Add this line
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 2
                    ]
                    
                    let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: writerInputSettings)
                    writerInput.expectsMediaDataInRealTime = false
                    writer.add(writerInput)
                    reader.startReading()
                    writer.startWriting()
                    writer.startSession(atSourceTime: .zero)
                    let mediaInputQueue = DispatchQueue(label: "mediaInputQueue")
                    writerInput.requestMediaDataWhenReady(on: mediaInputQueue) {
                    outerLoop: while writerInput.isReadyForMoreMediaData {
                        if let buffer = readerOutput.copyNextSampleBuffer() {
                            writerInput.append(buffer)
                        } else {
                            writerInput.markAsFinished()
                            writer.finishWriting {
                                reader.cancelReading()
                                if writer.status == .completed {
                                    let composition = AVMutableComposition()
                                    let audioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                                    var currentTime = CMTime.zero
                                    let index = urls.firstIndex(of: urls[i]) ?? 0
                                    urls[index] = writer.outputURL
                                    
                                    for fileURL in urls {
                                        let asset = AVAsset(url: fileURL)
                                        guard let track = asset.tracks(withMediaType: AVMediaType.audio).first else { continue }
                                        try? audioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: track, at: currentTime)
                                        currentTime = CMTimeAdd(currentTime, asset.duration)
                                    }
                                    
                                    guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else { return }
                                    exportSession.outputFileType = AVFileType.wav
                                    guard let path = soundList.last else {
                                        return
                                    }
                                    exportSession.outputURL = self.getAudioFileUrl(path: String(path))
                                    exportSession.exportAsynchronously(completionHandler: {
                                        if exportSession.status == .completed {
                                            
                                            completionHandler(true, nil, exportSession.outputURL!, urls)
                                            print("音声ファイルの結合が完了しました。")
                                            
                                        } else if exportSession.status == .failed {
                                            if (!urls[i].absoluteString.contains(writer.outputURL.absoluteString)) {
                                                
                                                completionHandler(false, nil, urls[i], urls)
                                                print("音声ファイルの結合が失敗しました。\(exportSession.error.debugDescription)")
                                            }
                                        } else if exportSession.status == .cancelled {
                                            print("音声ファイルの結合がキャンセルされました。")
                                        }
                                    })
                                }
                            }
                        }
                        break outerLoop
                    }
                    }
                }
            } catch {
                print("error")
            }
        }
    }
}
