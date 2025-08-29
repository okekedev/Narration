# Home Health Narrative Generator

A HIPAA-compliant iOS app for generating clinical narratives from home health visits using structured documentation.

## Features

- **Voice-to-Text Input**: Record responses using iOS Speech Recognition
- **7-Question Framework**: Structured home health visit documentation
- **Simple Narrative Formatting**: Converts answers into professional clinical format
- **Privacy First**: No data storage, ephemeral processing only
- **Medicare Compliant**: Professional clinical language suitable for documentation
- **Offline Operation**: Works completely offline for privacy
- **Broad Compatibility**: Supports iOS 16+ devices

## Requirements

- **iOS 16.0+** (Wide device compatibility)
- Any iPhone supporting iOS 16+
- Xcode 15.0+
- Swift 6.0
- Microphone and Speech Recognition permissions

## The 7 Questions

1. What is the patient's name?
2. How is the patient's mental status and alertness?
3. How is the patient's mobility and safety?
4. What is the medication compliance status?
5. Were any treatments or wound care performed?
6. What patient education was provided?
7. What is the plan for the next visit?

## Privacy & Compliance

- All processing occurs on-device
- No persistent storage of patient information
- Data automatically cleared when app backgrounds or terminates
- Session data cleared immediately after narrative is copied
- HIPAA-compliant by design

## Usage Flow

1. **Answer Questions**: Navigate through 7 structured questions
2. **Voice Input**: Use microphone for hands-free text entry
3. **Generate Narrative**: AI creates professional clinical documentation
4. **Copy & Clear**: Copy narrative to clipboard, data auto-clears

## Technical Architecture

### Core Components

- **QuestionAnswerView**: Main Q&A interface with voice input
- **NarrativeView**: Display and copy generated narratives
- **SpeechRecognitionService**: Voice-to-text functionality
- **NarrativeGenerationService**: AI narrative generation
- **PrivacyManager**: HIPAA compliance and data clearing

### Project Structure

```
Narration/
├── Models/
│   ├── Question.swift          # Question data model
│   └── VisitSession.swift      # Session state management
├── Services/
│   ├── SpeechRecognitionService.swift    # Voice input
│   ├── NarrativeGenerationService.swift  # AI generation
│   └── PrivacyManager.swift             # Privacy compliance
├── Views/
│   ├── ContentView.swift       # Main app view
│   ├── QuestionAnswerView.swift # Q&A interface
│   └── NarrativeView.swift     # Narrative display
└── NarrationApp.swift          # App entry point
```

## Narrative Generation

Simple, reliable narrative formatting:
- **Direct answer formatting**: Takes your 7 responses and formats them professionally
- **Clinical language**: Uses proper first-person nursing documentation style
- **Instant generation**: No AI processing delays or failures
- **100% reliable**: Always works, no internet or special hardware required

## Building and Running

1. Open `Narration.xcodeproj` in Xcode 15+
2. Set deployment target to iOS 16.0
3. Build and run on simulator or device (any iPhone with iOS 16+)
4. Grant microphone and speech recognition permissions when prompted

## Permissions Required

- **Microphone**: For voice input recording
- **Speech Recognition**: For converting speech to text

These permissions are automatically requested on first use and are required for voice input functionality.

## Compliance Notes

- No network connectivity required or used
- No data leaves the device
- No analytics or tracking
- Session data cleared automatically
- Suitable for HIPAA-covered entities

## Future Enhancements

- Additional clinical templates for different visit types
- Export options beyond clipboard (PDF, text files)
- Voice commands for navigation
- Custom narrative templates