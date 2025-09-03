//
//  SpeechRecognitionService.swift
//  Narration
//
//  Clean chunk-based speech recognition using WhisperKit
//

import Foundation
import AVFoundation
@preconcurrency import WhisperKit
import AudioToolbox
import Observation

@Observable
@MainActor
class SpeechRecognitionService {
    static let shared = SpeechRecognitionService()
    
    var isRecording = false
    var isAuthorized = false
    var recognizedText = ""
    var isProcessing = false
    var whisperKitReady = false
    var errorMessage = ""
    
    // Callback for direct text insertion
    var onTextRecognized: ((String) -> Void)?
    
    private var audioRecorder: AVAudioRecorder?
    private var whisperKit: WhisperKit?
    private var currentChunkURL: URL?
    private var chunkNumber = 0
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 4.0  // Increased to 4 seconds for longer pauses
    
    private init() {
        initializeWhisperKit()
    }
    
    // MARK: - WhisperKit Setup
    private func initializeWhisperKit() {
        Task { @MainActor in
            do {
                print("Initializing WhisperKit...")
                let kit = try await WhisperKit(
                    verbose: false,
                    logLevel: .error,
                    prewarm: true,
                    load: true,
                    download: true
                )
                whisperKit = kit
                whisperKitReady = true
                print("WhisperKit ready")
            } catch {
                print("WhisperKit initialization failed: \(error)")
                whisperKitReady = false
            }
        }
    }
    
    // MARK: - Authorization  
    private func checkAuthorization() async {
        // Swift 6 - modern approach without deprecated APIs
        await MainActor.run {
            isAuthorized = true // Audio session will handle permissions automatically
        }
    }
    
    // MARK: - Recording Control
    func startRecording() async throws {
        guard !isRecording else { return }
        
        await checkAuthorization()
        guard isAuthorized else { throw SpeechError.microphoneNotAuthorized }
        
        // Configure audio session - Swift 6 modern approach
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(
            .playAndRecord, 
            mode: .spokenAudio,
            options: [.defaultToSpeaker, .allowBluetooth]
        )
        try audioSession.setActive(true)
        
        // Start first chunk
        try startNewChunk()
        
        isRecording = true
        recognizedText = ""
        
        playRecordingSound(isStart: true)
        startSilenceMonitoring()
        
        print("Started chunk-based recording")
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        finishCurrentChunk()
        silenceTimer?.invalidate()
        silenceTimer = nil
        isRecording = false
        
        playRecordingSound(isStart: false)
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
        
        print("Stopped recording")
    }
    
    // MARK: - Chunk Management
    private func startNewChunk() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "chunk_\(chunkNumber)_\(Date().timeIntervalSince1970).wav"
        currentChunkURL = documentsPath.appendingPathComponent(fileName)
        chunkNumber += 1
        
        guard let chunkURL = currentChunkURL else {
            throw SpeechError.recordingSetupFailed
        }
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: chunkURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        
        print("Started chunk: \(fileName)")
    }
    
    private func finishCurrentChunk() {
        guard let recorder = audioRecorder, let chunkURL = currentChunkURL else { return }
        
        recorder.stop()
        audioRecorder = nil
        
        Task {
            await processChunk(at: chunkURL)
        }
    }
    
    // MARK: - Silence Detection
    private func startSilenceMonitoring() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForSilence()
            }
        }
    }
    
    private func checkForSilence() {
        guard let recorder = audioRecorder, isRecording else { return }
        
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let threshold: Float = -30.0
        
        if averagePower < threshold {
            // Silence detected - wait for threshold duration
            if silenceTimer?.timeInterval != silenceThreshold {
                silenceTimer?.invalidate()
                silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.handleSilenceTimeout()
                    }
                }
            }
        } else {
            // Speech detected - reset monitoring
            if let timer = silenceTimer, timer.timeInterval == silenceThreshold {
                timer.invalidate()
                startSilenceMonitoring()
            }
        }
    }
    
    private func handleSilenceTimeout() {
        guard isRecording else { return }
        
        print("Silence detected - processing chunk")
        finishCurrentChunk()
        
        // Start new chunk for continued recording
        do {
            try startNewChunk()
            startSilenceMonitoring()
        } catch {
            print("Failed to start new chunk: \(error)")
        }
    }
    
    // MARK: - Audio Processing
    private func processChunk(at chunkURL: URL) async {
        print("Processing: \(chunkURL.lastPathComponent)")
        
        guard FileManager.default.fileExists(atPath: chunkURL.path) else {
            print("Chunk file missing")
            return
        }
        
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: chunkURL.path)
            let fileSize = fileAttributes[.size] as? Int ?? 0
            
            guard fileSize > 1000 else {
                print("Chunk too small: \(fileSize) bytes")
                try? FileManager.default.removeItem(at: chunkURL)
                return
            }
            
            await MainActor.run { isProcessing = true }
            
            guard let whisperKit = whisperKit else {
                await MainActor.run { isProcessing = false }
                return
            }
            
            let results = try await whisperKit.transcribe(audioPath: chunkURL.path)
            let rawText = results.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            await MainActor.run {
                // Filter out inaudible and meaningless content
                let filteredText = filterInaudibleContent(rawText)
                
                if !filteredText.isEmpty {
                    // Direct insertion callback
                    onTextRecognized?(filteredText)
                    print("Recognized and inserted: '\(filteredText)'")
                }
                isProcessing = false
            }
            
        } catch {
            print("Processing error: \(error)")
            await MainActor.run { isProcessing = false }
        }
        
        try? FileManager.default.removeItem(at: chunkURL)
    }
    
    // MARK: - Utility
    func clearText() {
        recognizedText = ""
        chunkNumber = 0
    }
    
    private func filterInaudibleContent(_ text: String) -> String {
        var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercaseText = cleanedText.lowercased()
        
        // Filter out common inaudible/meaningless patterns - exact matches
        let exactInaudiblePatterns = [
            "[blank_audio]",
            "(inaudible)",
            "inaudible",
            "[music]",
            "[background noise]",
            "(music)",
            "(background noise)",
            "[music playing]",
            "(music playing)",
            "music playing",
            "um",
            "uh",
            "hmm",
            "...",
            ".",
            " ",
            ""
        ]
        
        // Check if the entire text is just noise or meaningless
        for pattern in exactInaudiblePatterns {
            if lowercaseText == pattern {
                return ""
            }
        }
        
        // Remove bracketed content that indicates audio artifacts
        let bracketPatterns = [
            "\\[music.*?\\]",
            "\\[.*?playing.*?\\]",
            "\\[background.*?\\]",
            "\\[noise.*?\\]",
            "\\[.*?inaudible.*?\\]",
            "\\(music.*?\\)",
            "\\(.*?playing.*?\\)",
            "\\(background.*?\\)",
            "\\(noise.*?\\)",
            "\\(sniffing\\)",
            "\\(coughing\\)",
            "\\(clearing throat\\)",
            "\\(sighs\\)",
            "\\(breathing\\)",
            "\\(.*?ing\\)",
            "\\[sniffing\\]",
            "\\[coughing\\]",
            "\\[breathing\\]"
        ]
        
        for pattern in bracketPatterns {
            cleanedText = cleanedText.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        // Clean up extra whitespace
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanedText = cleanedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Check if text is too short to be meaningful (less than 3 characters after cleaning)
        if cleanedText.count < 3 {
            return ""
        }
        
        return cleanedText
    }
    
    private func playRecordingSound(isStart: Bool) {
        let soundID: SystemSoundID = isStart ? 1108 : 1104
        AudioServicesPlaySystemSound(soundID)
    }
}

// MARK: - Error Types
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