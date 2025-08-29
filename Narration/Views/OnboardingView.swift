//
//  OnboardingView.swift
//  Narration
//
//  Question preview and onboarding screen
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentQuestionIndex = 0
    @State private var showingQuestions = true
    let onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if showingQuestions {
                    // Question preview mode
                    VStack(spacing: 20) {
                        Text("Home Health Visit Questions")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("You'll be asked these 7 questions to create your clinical narrative:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                        
                        // Question card
                        VStack(spacing: 16) {
                            Text("Question \(currentQuestionIndex + 1) of 7")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(Question.homeHealthQuestions[currentQuestionIndex].prompt)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Text(Question.homeHealthQuestions[currentQuestionIndex].placeholder)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .italic()
                        }
                        .padding(20)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        
                        Spacer()
                        
                        // Navigation controls
                        HStack {
                            Button("Previous") {
                                if currentQuestionIndex > 0 {
                                    currentQuestionIndex -= 1
                                }
                            }
                            .disabled(currentQuestionIndex == 0)
                            
                            Spacer()
                            
                            if currentQuestionIndex < Question.homeHealthQuestions.count - 1 {
                                Button("Next") {
                                    currentQuestionIndex += 1
                                }
                                .buttonStyle(.borderedProminent)
                            } else {
                                Button("Start Visit Documentation") {
                                    onComplete()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    OnboardingView {
        // Preview completion
    }
}