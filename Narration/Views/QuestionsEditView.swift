//
//  QuestionsEditView.swift
//  Narration
//
//  View for editing question prompts
//

import SwiftUI

struct QuestionsEditView: View {
    @ObservedObject var session: VisitSession
    @Environment(\.dismiss) private var dismiss
    @State private var editedQuestions: [Question] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(editedQuestions.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 16) {
                            TextField("Patient Information", text: $editedQuestions[index].sectionTitle)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color.blue)
                                .cornerRadius(12)
                            
                            TextField("Who did you visit and what was their condition?", text: $editedQuestions[index].prompt, axis: .vertical)
                                .font(.body)
                                .padding(16)
                                .cornerRadius(12)
                                .lineLimit(3...8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            
                            HStack {
                                Spacer()
                                
                                Text("\(index + 1) of \(editedQuestions.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(24)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        session.questions = editedQuestions
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            editedQuestions = session.questions
        }
    }
}