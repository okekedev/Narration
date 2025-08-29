//
//  QuestionReferenceView.swift
//  Narration
//
//  Quick reference view for all 7 questions
//

import SwiftUI

struct QuestionReferenceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Home Health Visit Questions")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom)
                    
                    ForEach(Question.homeHealthQuestions) { question in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Question \(question.number)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Spacer()
                            }
                            
                            Text(question.prompt)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text(question.placeholder)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Question Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    QuestionReferenceView()
}