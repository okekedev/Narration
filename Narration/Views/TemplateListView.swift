//
//  TemplateListView.swift
//  Narration
//
//  Created by Claude on 10/28/25.
//

import SwiftUI

struct TemplateListView: View {
    @Environment(\.dismiss) var dismiss
    @State private var templateManager = TemplateManager.shared
    @State private var showingCreateTemplate = false
    @State private var showingEditTemplate: Template?
    @State private var showingDeleteAlert: Template?

    var body: some View {
        NavigationView {
            List {
                ForEach(templateManager.templates) { template in
                    TemplateRow(
                        template: template,
                        isSelected: templateManager.selectedTemplate?.id == template.id,
                        onSelect: {
                            templateManager.selectTemplate(template)
                        },
                        onEdit: {
                            showingEditTemplate = template
                        },
                        onDelete: {
                            showingDeleteAlert = template
                        },
                        onShare: {
                            shareTemplate(template)
                        }
                    )
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateTemplate = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                TemplateEditorView(mode: .create)
            }
            .sheet(item: $showingEditTemplate) { template in
                TemplateEditorView(mode: .edit(template))
            }
            .alert("Delete Template", isPresented: .constant(showingDeleteAlert != nil)) {
                Button("Cancel", role: .cancel) {
                    showingDeleteAlert = nil
                }
                Button("Delete", role: .destructive) {
                    if let template = showingDeleteAlert {
                        templateManager.deleteTemplate(template)
                        showingDeleteAlert = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete '\(showingDeleteAlert?.name ?? "")'? This action cannot be undone.")
            }
        }
    }

    private func shareTemplate(_ template: Template) {
        guard let shareString = templateManager.exportTemplate(template) else { return }

        // Use Universal Link (works even if app not installed)
        let url = URL(string: "https://okekedev.github.io/Narration/template?data=\(shareString)")!

        let message = "Check out this clinical documentation template for Narration!"

        let activityVC = UIActivityViewController(
            activityItems: [message, url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct TemplateRow: View {
    let template: Template
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(template.name)
                        .font(.headline)

                    if template.isDefault {
                        Text("DEFAULT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }

                Text("\(template.questions.count) questions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !isSelected {
                Button {
                    onSelect()
                } label: {
                    Label("Select", systemImage: "checkmark.circle")
                }
                .tint(.green)
            }
        }
    }
}
