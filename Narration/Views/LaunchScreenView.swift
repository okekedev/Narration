//
//  LaunchScreenView.swift
//  Narration
//
//  Launch screen with logo animation while WhisperKit loads
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var logoOpacity = 0.0
    @State private var isAnimating = false
    @Binding var isLoading: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Logo/Icon
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                    .opacity(logoOpacity)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                
                // App Name
                Text("Narration")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .opacity(logoOpacity)
                
                // Subtitle
                Text("Clinical Documentation")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .opacity(logoOpacity * 0.8)
                
                // Loading indicator
                if isAnimating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(0.8)
                        .opacity(logoOpacity * 0.5)
                        .padding(.top, 20)
                }
                
                // Skip button
                if isAnimating {
                    Button(action: skipAnimation) {
                        Text("Skip")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    .opacity(logoOpacity * 0.7)
                    .padding(.top, 40)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Fade in over 1.5 seconds
        withAnimation(.easeIn(duration: 1.5)) {
            logoOpacity = 1.0
            isAnimating = true
        }
        
        // Start fade out after 3.5 seconds (total 5 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 1.5)) {
                logoOpacity = 0.0
            }
        }
        
        // Complete loading after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            isLoading = false
        }
    }
    
    private func skipAnimation() {
        // Immediately skip to main app
        withAnimation(.easeOut(duration: 0.3)) {
            logoOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isLoading = false
        }
    }
}

#Preview {
    LaunchScreenView(isLoading: .constant(true))
}