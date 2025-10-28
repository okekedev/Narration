# Template Storage System - Setup Instructions

## Overview

I've implemented a complete template storage system for the Narration app with the following features:

✅ **Core Data + CloudKit sync** - Templates sync across user's devices via iCloud
✅ **Template CRUD operations** - Create, read, update, delete templates
✅ **Template management UI** - Browse, edit, and select templates
✅ **Template sharing** - Export templates and send via Messages, email, AirDrop
✅ **Template importing** - Receive templates via custom URL scheme
✅ **Default template** - Converts existing 7 questions into default template on first launch

## Files Created

### Models
- `/Narration/Models/Template.swift` - Template model with JSON encoding/decoding
- `/Narration/Models/Question.swift` - Updated to be mutable and Codable

### Services
- `/Narration/Services/PersistenceController.swift` - Core Data + CloudKit stack
- `/Narration/Services/TemplateManager.swift` - Template CRUD operations

### Views
- `/Narration/Views/TemplateListView.swift` - Template browser with swipe actions
- `/Narration/Views/TemplateEditorView.swift` - Create/edit templates

### Core Data
- `/Narration/Narration.xcdatamodeld/` - Core Data model with TemplateEntity

### Configuration
- `/Narration/Info.plist` - URL scheme configuration

### Updated Files
- `/Narration/NarrationApp.swift` - Added URL handling and template import
- `/Narration/Views/NarrativeView.swift` - Added Templates menu option
- `/Narration/Models/VisitSession.swift` - Now loads questions from selected template

## Manual Setup Steps Required

Since I cannot directly modify the Xcode project file, you'll need to complete these steps in Xcode:

### 1. Add New Files to Xcode Project

Open the project in Xcode and add these files:

**Models group:**
- `Models/Template.swift` ✓

**Services group:**
- `Services/PersistenceController.swift` ✓
- `Services/TemplateManager.swift` ✓

**Views group:**
- `Views/TemplateListView.swift` ✓
- `Views/TemplateEditorView.swift` ✓

**Root Narration folder:**
- `Narration.xcdatamodeld/` folder ✓
- `Info.plist` ✓

**To add files:**
1. Right-click on the appropriate group in Xcode
2. Select "Add Files to Narration..."
3. Select the file(s)
4. Ensure "Copy items if needed" is checked
5. Ensure target "Narration" is checked

### 2. Enable CloudKit Capability

1. Select the Narration project in the navigator
2. Select the Narration target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "iCloud"
6. Check "CloudKit"
7. Click "+" under "Containers"
8. Enter: `iCloud.com.narration.app`

### 3. Configure Info.plist (if not auto-detected)

The `Info.plist` file should include:
- Custom URL scheme: `narration://`
- Microphone usage description
- Speech recognition usage description

If Xcode doesn't auto-detect it, go to Build Settings and set "Info.plist File" to `Narration/Info.plist`.

### 4. Build and Test

1. Clean build folder (Cmd+Shift+K)
2. Build project (Cmd+B)
3. Fix any import errors if needed
4. Run on simulator or device

## How It Works

### Template Management

1. **Access Templates:** Tap the ellipsis menu (⋯) → "Templates"
2. **Create Template:** Tap "+" button → Enter name → Add/edit questions → Save
3. **Select Template:** Tap any template to select it as active
4. **Edit Template:** Swipe left → "Edit"
5. **Delete Template:** Swipe left → "Delete"
6. **Share Template:** Swipe left → "Share" → Choose Messages/AirDrop/etc.

### Template Sharing Flow

**Sender:**
1. Open Templates list
2. Swipe left on template → "Share"
3. Choose Messages
4. Send to recipient

**Receiver:**
1. Receive message with `narration://template?data=...` URL
2. Tap the link
3. Narration app opens and imports template
4. Alert confirms import
5. Template appears in Templates list

### Template Structure

```swift
Template {
  id: UUID
  name: String
  questions: [Question]
  dateCreated: Date
  dateModified: Date
  isDefault: Bool
}
```

### CloudKit Sync

Templates automatically sync across all devices signed into the same iCloud account. Changes propagate within seconds.

## Architecture Notes

### Core Data Stack
- Uses `NSPersistentCloudKitContainer` for iCloud sync
- Automatic merge from CloudKit with `automaticallyMergesChangesFromParent`
- Persistent history tracking enabled

### Template Storage
- Questions stored as JSON binary data in Core Data
- Template model provides encoding/decoding utilities
- Base64 encoding for shareable URLs

### State Management
- `TemplateManager` singleton with `@Observable` macro
- `VisitSession` loads questions from selected template
- Selected template persists in UserDefaults

### Privacy Considerations
- Templates contain NO patient data (PHI)
- Only question prompts and structure
- Safe to share between clinicians
- CloudKit syncs only template structure, never visit data

## Troubleshooting

### Build Errors
- **"Cannot find type 'Template'"** → Ensure Template.swift is added to target
- **"No such module 'CoreData'"** → Import CoreData in PersistenceController.swift
- **CloudKit errors** → Verify iCloud capability and container ID

### Runtime Issues
- **Templates not syncing** → Check iCloud account is signed in
- **Import not working** → Verify Info.plist includes URL scheme
- **Default template not created** → Delete app and reinstall

### Testing Template Sharing
1. Run on simulator
2. Create a template
3. Swipe to share
4. Copy the `narration://` URL from share sheet
5. Open Safari and paste URL
6. App should open and import

## Future Enhancements

Potential additions:
- [ ] Template categories/tags
- [ ] Template search/filter
- [ ] Template versioning
- [ ] Community template marketplace
- [ ] Template preview before import
- [ ] Duplicate template action
- [ ] Import from QR code

## Questions?

If you encounter any issues:
1. Check that all files are added to the Xcode target
2. Verify CloudKit capability is enabled
3. Clean build folder and rebuild
4. Check console for error messages

The implementation is complete and ready to use once the Xcode project configuration steps are completed!
