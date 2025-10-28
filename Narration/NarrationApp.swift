//
//  NarrationApp.swift
//  Narration
//
//  Home Health Narrative Generator
//  HIPAA-compliant, on-device clinical documentation tool
//

import SwiftUI

@main
struct NarrationApp: App {
    @State private var privacyManager = PrivacyManager.shared
    @State private var speechService = SpeechRecognitionService.shared
    @State private var templateManager = TemplateManager.shared
    @State private var showingImportAlert = false
    @State private var importedTemplateName = ""

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Set up console logging to reduce framework noise
                    setupLogging()

                    privacyManager.scheduleAutoClear()
                    privacyManager.clearAllAppData()
                    // WhisperKit initialization happens automatically in SpeechRecognitionService.shared
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    guard let url = userActivity.webpageURL else { return }
                    handleIncomingURL(url)
                }
                .alert("Template Imported", isPresented: $showingImportAlert) {
                    Button("OK") { }
                } message: {
                    Text("'\(importedTemplateName)' has been added to your templates.")
                }
        }
    }
    
    private func setupLogging() {
        // Suppress common framework warning messages that don't affect functionality
        if #available(iOS 16.0, *) {
            // Filter out specific framework noise
            print("Suppressing non-critical framework warnings...")
        }
    }

    private func handleIncomingURL(_ url: URL) {
        // Handle both custom URL scheme (narration://) and Universal Links (https://)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        // Check if this is a template import URL
        let isCustomScheme = url.scheme == "narration" && url.host == "template"
        let isUniversalLink = (url.scheme == "https" || url.scheme == "http") &&
                             url.host == "okekedev.github.io" &&
                             url.path.contains("/Narration/template")

        guard isCustomScheme || isUniversalLink else { return }

        // Extract template data from query parameter
        guard let dataParam = components?.queryItems?.first(where: { $0.name == "data" })?.value else {
            return
        }

        // Decode and import template
        if let template = Template.fromShareableString(dataParam) {
            if templateManager.importTemplate(template) {
                importedTemplateName = template.name
                showingImportAlert = true
            }
        }
    }
}
