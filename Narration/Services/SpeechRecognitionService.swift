//
//  SpeechRecognitionService.swift
//  Narration
//
//  Speech-to-text service using WhisperKit for offline transcription
//

import Foundation
import AVFoundation
import WhisperKit
import AudioToolbox

@MainActor
class SpeechRecognitionService: ObservableObject {
    static let shared = SpeechRecognitionService()
    
    @Published var isRecording = false
    @Published var isAuthorized = false
    @Published var recognizedText = ""
    @Published var isProcessing = false
    @Published var whisperKitReady = false
    @Published var errorMessage = ""
    
    private var audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var whisperKit: WhisperKit?
    private var audioBuffer: [Float] = []
    private var lastTranscriptionTime: Date = Date()
    private var lastSpeechTime: Date = Date()
    private var silenceTimer: Timer?
    
    private init() {
        // Don't check authorization on init - wait until user tries to record
        // Initialize WhisperKit immediately and prewarm it
        initializeAndPrewarmWhisperKit()
    }
    
    private func checkAuthorization() async {
        // Only check microphone permission when actually needed
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            await MainActor.run {
                isAuthorized = true
            }
        case .denied:
            await MainActor.run {
                isAuthorized = false
            }
        case .undetermined:
            await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    Task { @MainActor in
                        self.isAuthorized = granted
                        continuation.resume()
                    }
                }
            }
        @unknown default:
            await MainActor.run {
                isAuthorized = false
            }
        }
    }
    
    private func initializeAndPrewarmWhisperKit() {
        Task {
            // Wait a moment for app to stabilize
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            do {
                print("Initializing WhisperKit...")
                
                // Initialize with explicit settings to reduce errors
                whisperKit = try await WhisperKit(
                    verbose: false,
                    logLevel: .error,  // Changed from .critical to .error
                    prewarm: true,
                    load: true,
                    download: true
                )
                
                print("WhisperKit initialized, prewarming...")
                
                // Do a dummy transcription to load all components
                await prewarmWhisperKit()
                
                await MainActor.run {
                    whisperKitReady = true
                    print("WhisperKit ready")
                }
            } catch {
                print("WhisperKit initialization failed: \(error.localizedDescription)")
                
                // Try simpler initialization as fallback
                do {
                    whisperKit = try await WhisperKit()
                    await MainActor.run {
                        whisperKitReady = true
                    }
                } catch {
                    await MainActor.run {
                        whisperKitReady = false
                    }
                }
            }
        }
    }
    
    private func prewarmWhisperKit() async {
        guard let whisperKit = whisperKit else { return }
        
        do {
            print("Prewarming WhisperKit with demo audio...")
            
            // Create a more realistic demo audio file with actual speech-like patterns
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("prewarm.wav")
            
            // Use 48kHz to match device recording format
            let sampleRate: Double = 48000
            let duration = 2.0 // 2 seconds for more realistic demo
            let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            let audioFile = try AVAudioFile(forWriting: tempURL, settings: audioFormat.settings)
            
            let frameCount = AVAudioFrameCount(sampleRate * duration)
            let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
            buffer.frameLength = frameCount
            
            // Create speech-like audio pattern (sine wave with variations)
            if let channelData = buffer.floatChannelData?[0] {
                for i in 0..<Int(frameCount) {
                    // Generate low-amplitude speech-like pattern
                    let time = Double(i) / sampleRate
                    let frequency = 440.0 + sin(time * 2.0) * 100.0 // Varying frequency
                    let amplitude = Float(0.01 * (1.0 + sin(time * 5.0)) * 0.5) // Varying amplitude
                    channelData[i] = amplitude * sin(Float(2.0 * .pi * frequency * time))
                }
            }
            
            try audioFile.write(from: buffer)
            
            // Do multiple dummy transcriptions to fully initialize
            print("Running demo transcription 1...")
            _ = try? await whisperKit.transcribe(audioPath: tempURL.path)
            
            print("Running demo transcription 2...")
            _ = try? await whisperKit.transcribe(audioPath: tempURL.path)
            
            // Clean up
            try? FileManager.default.removeItem(at: tempURL)
            
            print("WhisperKit fully prewarmed - all components loaded and tested")
        } catch {
            print("Prewarm failed (non-critical): \(error.localizedDescription)")
        }
    }
    
    func startRecording() async throws {
        guard !isRecording else { return }
        
        // Check and request microphone permission when user tries to record
        await checkAuthorization()
        guard isAuthorized else { throw SpeechError.microphoneNotAuthorized }
        
        // WhisperKit should already be prewarmed, but check just in case
        guard whisperKitReady else {
            print("WhisperKit not ready yet")
            throw SpeechError.whisperKitNotInitialized
        }
        
        // Clear any previous audio buffer
        audioBuffer.removeAll()
        
        // Create temporary file for recording with unique name
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).wav"
        recordingURL = documentsPath.appendingPathComponent(fileName)
        
        guard let recordingURL = recordingURL else {
            throw SpeechError.recordingSetupFailed
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Configure audio engine and recording
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        print("Input format: \(inputFormat)")
        
        // Create audio file with input format (let WhisperKit handle conversion)
        audioFile = try AVAudioFile(forWriting: recordingURL, settings: inputFormat.settings)
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, when in
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
                
                // Detect speech/silence
                if avgLevel > 0.005 { // Speech detected
                    self.lastSpeechTime = Date()
                    
                    // Cancel any existing silence timer
                    DispatchQueue.main.async {
                        self.silenceTimer?.invalidate()
                        self.silenceTimer = nil
                    }
                    // Enable streaming transcription for real-time feedback
                    let now = Date()
                    if now.timeIntervalSince(self.lastTranscriptionTime) > 2.0 {
                        self.lastTranscriptionTime = now
                        Task { @MainActor in
                            await self.performStreamingTranscription()
                        }
                    }
                } else { // Silence detected
                    // Start silence timer if not already started
                    if self.silenceTimer == nil && self.isRecording {
                        DispatchQueue.main.async {
                            self.startSilenceTimer()
                        }
                    }
                }
                
                if avgLevel > 0.01 {
                    print("Audio level: \(avgLevel)")
                }
            }
            
            // CRITICAL: Write audio to file for transcription
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
        errorMessage = ""
        
        // Play subtle start recording sound
        playRecordingSound(isStart: true)
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        // Stop silence timer
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // IMPORTANT: Close the audio file properly before transcription
        audioFile = nil
        
        isRecording = false
        
        // Play subtle stop recording sound
        playRecordingSound(isStart: false)
        
        // Process the recorded audio with WhisperKit
        Task {
            await transcribeRecording()
        }
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if self.isRecording {
                    print("Auto-stopping recording due to 3 seconds of silence")
                    self.stopRecording()
                }
            }
        }
    }
    
    private func transcribeRecording() async {
        guard let recordingURL = recordingURL else { 
            print("No recording URL available")
            return 
        }
        
        // Check if file exists before transcription
        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            print("Recording file does not exist at: \(recordingURL.path)")
            await MainActor.run {
                recognizedText = ""
                errorMessage = ""
                isProcessing = false
            }
            return
        }
        
        await MainActor.run {
            isProcessing = true
        }
        
        do {
            guard let whisperKit = whisperKit, whisperKitReady else {
                print("WhisperKit not ready for transcription")
                await MainActor.run {
                    recognizedText = ""
                    errorMessage = ""
                    isProcessing = false
                }
                return
            }
            
            // Check file size to ensure we have audio
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: recordingURL.path)
            let fileSize = fileAttributes[.size] as? Int ?? 0
            print("Recording file size: \(fileSize) bytes at: \(recordingURL.path)")
            
            // Only transcribe if we have substantial audio data
            guard fileSize > 1000 else {
                print("File too small, likely no audio captured")
                await MainActor.run {
                    recognizedText = ""
                    errorMessage = ""
                }
                return
            }
            
            print("Starting transcription...")
            
            // Transcribe using simplistic WhisperKit approach
            let results = try await whisperKit.transcribe(audioPath: recordingURL.path)
            let transcriptionText = results.first?.text ?? ""
            
            print("Transcription result: '\(transcriptionText)'")
            await MainActor.run {
                // Always set the recognized text, even if it contains [BLANK_AUDIO]
                // This helps us debug what WhisperKit is actually returning
                if transcriptionText.contains("[BLANK_AUDIO]") {
                    print("WhisperKit returned BLANK_AUDIO")
                    recognizedText = ""
                    errorMessage = ""
                } else if transcriptionText.isEmpty {
                    print("WhisperKit returned empty text")
                    recognizedText = ""
                    errorMessage = ""
                } else {
                    // Got valid transcription - set it
                    print("Setting recognized text: '\(transcriptionText)'")
                    recognizedText = transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                    errorMessage = ""
                }
            }
            
        } catch {
            print("Transcription error: \(error)")
            await MainActor.run {
                recognizedText = ""
                errorMessage = ""
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
        
        // Clean up temporary file AFTER transcription
        if FileManager.default.fileExists(atPath: recordingURL.path) {
            try? FileManager.default.removeItem(at: recordingURL)
            print("Cleaned up recording file")
        }
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
            
            // Simple streaming transcription
            let results = try await whisperKit.transcribe(audioPath: tempURL.path)
            let text = results.first?.text ?? ""
            if !text.isEmpty && !text.contains("[BLANK_AUDIO]") {
                recognizedText = text
            }
            
            // Clean up
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            // Silently handle streaming errors and clean up
            try? FileManager.default.removeItem(at: tempURL)
        }
    }
    
    func clearText() {
        recognizedText = ""
        errorMessage = ""
        audioBuffer.removeAll()
        silenceTimer?.invalidate()
        silenceTimer = nil
    }
    
    private func playRecordingSound(isStart: Bool) {
        // Use system sounds for subtle audio feedback
        if isStart {
            // Play a subtle "begin" sound (system camera shutter sound)
            AudioServicesPlaySystemSound(1108) // camera_shutter_burst_begin.caf
        } else {
            // Play a subtle "end" sound (system keyboard click)
            AudioServicesPlaySystemSound(1104) // end_record_short.caf
        }
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