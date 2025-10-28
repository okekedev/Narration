#!/bin/bash

# Script to help add files to Narration Xcode project
# This will open Xcode and provide instructions

PROJECT_DIR="/Users/christian/Desktop/Narration"
XCODE_PROJECT="$PROJECT_DIR/Narration.xcodeproj"

echo "================================================"
echo "Narration Template System - Xcode Setup"
echo "================================================"
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed or not in PATH"
    exit 1
fi

echo "✅ Xcode found"
echo ""

# List new files to add
echo "📁 New files created:"
echo ""
echo "Models:"
echo "  - Models/Template.swift"
echo ""
echo "Services:"
echo "  - Services/PersistenceController.swift"
echo "  - Services/TemplateManager.swift"
echo ""
echo "Views:"
echo "  - Views/TemplateListView.swift"
echo "  - Views/TemplateEditorView.swift"
echo ""
echo "Core Data:"
echo "  - Narration.xcdatamodeld/"
echo ""
echo "Configuration:"
echo "  - Info.plist"
echo ""

# Open Xcode
echo "🚀 Opening Xcode project..."
open "$XCODE_PROJECT"

echo ""
echo "================================================"
echo "MANUAL STEPS REQUIRED IN XCODE"
echo "================================================"
echo ""
echo "1️⃣  ADD FILES TO PROJECT:"
echo "   • Right-click 'Models' folder → Add Files"
echo "   • Select: Models/Template.swift"
echo "   • ✓ Copy items if needed"
echo "   • ✓ Narration target"
echo ""
echo "   • Right-click 'Services' folder → Add Files"
echo "   • Select: Services/PersistenceController.swift"
echo "   • Select: Services/TemplateManager.swift"
echo ""
echo "   • Right-click 'Views' folder → Add Files"
echo "   • Select: Views/TemplateListView.swift"
echo "   • Select: Views/TemplateEditorView.swift"
echo ""
echo "   • Right-click 'Narration' folder → Add Files"
echo "   • Select: Narration.xcdatamodeld/ (folder)"
echo "   • Select: Info.plist"
echo ""
echo "2️⃣  ENABLE CLOUDKIT:"
echo "   • Select project in navigator"
echo "   • Select 'Narration' target"
echo "   • Go to 'Signing & Capabilities'"
echo "   • Click '+ Capability'"
echo "   • Add 'iCloud'"
echo "   • Check 'CloudKit'"
echo "   • Add container: iCloud.com.narration.app"
echo ""
echo "3️⃣  BUILD PROJECT:"
echo "   • Press Cmd+Shift+K (Clean)"
echo "   • Press Cmd+B (Build)"
echo ""
echo "================================================"
echo ""
echo "📖 For detailed instructions, see:"
echo "   TEMPLATE_SETUP_INSTRUCTIONS.md"
echo ""
