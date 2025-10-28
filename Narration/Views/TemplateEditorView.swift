//
//  TemplateEditorView.swift
//  Narration
//
//  Created by Claude on 10/28/25.
//

import SwiftUI

struct TemplateEditorView: View {
    enum Mode {
        case create
        case edit(Template)

        var title: String {
            switch self {
            case .create: return "New Template"
            case .edit: return "Edit Template"
            }
        }
    }

    @Environment(\.dismiss) var dismiss
    @State private var templateManager = TemplateManager.shared
    let mode: Mode

    @State private var name: String = ""
    @State private var questions: [Question] = []
    @State private var isDefault: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Template Info")) {
                    TextField("Template Name", text: $name)

                    Toggle("Set as Default", isOn: $isDefault)
                        .disabled(isEdit && isDefault) // Can't unset default without setting another
                }

                Section {
                    ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Spacer()
                                if questions.count > 1 {
                                    Button(role: .destructive) {
                                        questions.remove(at: index)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }

                            TextField("Title", text: Binding(
                                get: { questions[index].sectionTitle },
                                set: { questions[index].sectionTitle = $0 }
                            ))
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                            Divider()

                            TextField("Enter your question here", text: Binding(
                                get: { questions[index].prompt },
                                set: { questions[index].prompt = $0 }
                            ), axis: .vertical)
                            .font(.body)
                            .lineLimit(3...8)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }

                    Button(action: {
                        let newQuestion = Question(
                            id: UUID(),
                            number: questions.count + 1,
                            prompt: "",
                            sectionTitle: ""
                        )
                        questions.append(newQuestion)
                    }) {
                        Label("Add Question", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Questions")
                } footer: {
                    Text("Swipe to delete questions. You can reorder them by editing the numbers.")
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(name.isEmpty || questions.isEmpty)
                }
            }
        }
        .onAppear {
            switch mode {
            case .create:
                // Start with one empty question
                questions = [Question(
                    id: UUID(),
                    number: 1,
                    prompt: "",
                    sectionTitle: ""
                )]
            case .edit(let template):
                name = template.name
                questions = template.questions
                isDefault = template.isDefault
            }
        }
    }

    private var isEdit: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }

    private func saveTemplate() {
        // Update question numbers to match array order
        let numberedQuestions = questions.enumerated().map { index, question in
            var q = question
            q.number = index + 1
            return q
        }

        switch mode {
        case .create:
            templateManager.createTemplate(
                name: name,
                questions: numberedQuestions,
                isDefault: isDefault
            )
        case .edit(let template):
            var updated = template
            updated.name = name
            updated.questions = numberedQuestions
            updated.isDefault = isDefault
            templateManager.updateTemplate(updated)
        }

        dismiss()
    }
}
