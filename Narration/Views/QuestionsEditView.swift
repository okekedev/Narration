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
            List {
                ForEach(editedQuestions.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question \(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Question text", text: $editedQuestions[index].prompt, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...10)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Questions")
            .navigationBarTitleDisplayMode(.inline)
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