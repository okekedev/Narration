//
//  SpeechRecognitionService.swift
//  Narration
//
//  Speech-to-text service using WhisperKit for offline transcription
//

import Foundation
import AVFoundation
import WhisperKit

@MainActor
class SpeechRecognitionService: ObservableObject {
    static let shared = SpeechRecognitionService()
    
    @Published var isRecording = false
    @Published var isAuthorized = false
    @Published var recognizedText = ""
    @Published var isProcessing = false
    @Published var whisperKitReady = false
    
    private var audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var whisperKit: WhisperKit?
    private var audioBuffer: [Float] = []
    private var lastTranscriptionTime: Date = Date()
    
    private init() {
        checkAuthorization()
        initializeWhisperKitInBackground()
    }
    
    private func checkAuthorization() {
        // Only check microphone permission (no Siri dependency)
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            isAuthorized = true
        case .denied:
            isAuthorized = false
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                }
            }
        @unknown default:
            isAuthorized = false
        }
    }
    
    private func initializeWhisperKitInBackground() {
        Task {
            do {
                print("Initializing WhisperKit in background...")
                whisperKit = try await WhisperKit()
                whisperKitReady = true
                print("WhisperKit initialized successfully in background")
            } catch {
                print("Failed to initialize WhisperKit: \(error)")
                whisperKitReady = false
            }
        }
    }
    
    func startRecording() async throws {
        guard !isRecording else { return }
        guard isAuthorized else { throw SpeechError.microphoneNotAuthorized }
        
        // Create temporary file for recording
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("recording.wav")
        
        guard let recordingURL = recordingURL else {
            throw SpeechError.recordingSetupFailed
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Configure audio engine and recording
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        print("Recording format: \(recordingFormat)")
        
        // Create audio file with native format
        audioFile = try AVAudioFile(forWriting: recordingURL, settings: recordingFormat.settings)
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, when in
            guard let self = self, let audioFile = self.audioFile else { return }
            
            // Check audio levels and accumulate for streaming
            let channelData = buffer.floatChannelData?[0]
            let channelDataCount = Int(buffer.frameLength)
            
            if let channelData = channelData {
                var sum: Float = 0
                
                // Add to streaming buffer
                for i in 0..<channelDataCount {
                    let sample = channelData[i]
                    sum += abs(sample)
                    self.audioBuffer.append(sample)
                }
                
                let avgLevel = sum / Float(channelDataCount)
                if avgLevel > 0.01 {
                    print("Audio level: \(avgLevel)")
                }
                
                // Trigger streaming transcription every 2 seconds if we have audio
                let now = Date()
                if now.timeIntervalSince(self.lastTranscriptionTime) > 2.0 && avgLevel > 0.005 {
                    self.lastTranscriptionTime = now
                    Task { @MainActor in
                        await self.performStreamingTranscription()
                    }
                }
            }
            
            // Still write to file for final transcription
            do {
                try audioFile.write(from: buffer)
            } catch {
                print("Error writing audio buffer: \(error)")
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        recognizedText = ""
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioFile = nil
        
        isRecording = false
        
        // Process the recorded audio with WhisperKit
        Task {
            await transcribeRecording()
        }
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func transcribeRecording() async {
        guard let recordingURL = recordingURL else { return }
        
        isProcessing = true
        
        do {
            guard let whisperKit = whisperKit, whisperKitReady else {
                print("WhisperKit not ready - Ready: \(whisperKitReady), Instance: \(whisperKit != nil)")
                recognizedText = "Speech recognition not ready. Please type your response."
                isProcessing = false
                return
            }
            
            print("Starting transcription...")
            let results = try await whisperKit.transcribe(audioPath: recordingURL.path)
            print("Transcription completed: \(results.count) results")
            
            // Debug: Print the actual result structure
            if let firstResult = results.first {
                print("Result type: \(type(of: firstResult))")
                print("Result content: \(firstResult)")
            }
            
            // Extract the transcribed text
            if let firstResult = results.first {
                let text = firstResult.text
                recognizedText = text.isEmpty ? "No speech detected" : text
                print("Got text: '\(text)'")
            } else {
                recognizedText = "No transcription results"
                print("No results returned from WhisperKit")
            }
        } catch {
            print("Transcription failed: \(error)")
            recognizedText = "Transcription failed. Please try again or type your response."
        }
        
        isProcessing = false
        
        // Clean up temporary file
        try? FileManager.default.removeItem(at: recordingURL)
    }
    
    private func performStreamingTranscription() async {
        guard let whisperKit = whisperKit, 
              whisperKitReady,
              !audioBuffer.isEmpty,
              !isProcessing else { return }
        
        // Create a temporary audio file from buffer
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("stream_\(UUID().uuidString).wav")
        
        do {
            // Convert float buffer to audio file
            let sampleRate: Double = 16000
            let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            let audioFile = try AVAudioFile(forWriting: tempURL, settings: audioFormat.settings)
            
            let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(audioBuffer.count))!
            buffer.frameLength = AVAudioFrameCount(audioBuffer.count)
            
            // Copy float data to buffer
            if let channelData = buffer.floatChannelData?[0] {
                for i in 0..<audioBuffer.count {
                    channelData[i] = audioBuffer[i]
                }
            }
            
            try audioFile.write(from: buffer)
            
            // Transcribe streaming chunk
            print("Streaming transcription...")
            let results = try await whisperKit.transcribe(audioPath: tempURL.path)
            
            if let result = results.first, !result.text.contains("[BLANK_AUDIO]") {
                recognizedText = result.text
                print("Streaming result: '\(result.text)'")
            }
            
            // Clean up
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("Streaming transcription error: \(error)")
            try? FileManager.default.removeItem(at: tempURL)
        }
    }
    
    func clearText() {
        recognizedText = ""
        audioBuffer.removeAll()
    }
}

enum SpeechError: Error {
    case microphoneNotAuthorized
    case recordingSetupFailed
    case whisperKitNotInitialized
    
    var localizedDescription: String {
        switch self {
        case .microphoneNotAuthorized:
            return "Microphone access not authorized"
        case .recordingSetupFailed:
            return "Failed to set up audio recording"
        case .whisperKitNotInitialized:
            return "Speech recognition engine not ready"
        }
    }
}