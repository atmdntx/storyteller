//
//  ManuscriptView.swift
//  Storyteller
//
//  Created by Andres Tapia on 04-09-26.
//
import SwiftData
import SwiftUI

struct ManuscriptView: View {
    let storybank: Storybank

    @Environment(\.modelContext) private var modelContext
    @State private var openInspector: Bool = true
    @State private var selectedNode: SelectedNode?
    @State private var saveError: String?

    // Observe both editor and inline tree title edits, including unselected scenes.
    private var documentEdits: [DocumentEdit] {
        storybank.manuscriptDocuments.map {
            DocumentEdit(id: $0.id, title: $0.title, content: $0.content)
        }
    }

    var body: some View {
        HStack {
            if let selectedNode,
               case .document(let documentID) = selectedNode,
               let document = storybank.manuscriptDocuments.first(where: { $0.id == documentID }) {
                ManuscriptTextEditor(document: document)
                    .id(document.id)
            } else {
                ManuscriptMainView()
            }
        }
        .onAppear {
            guard selectedNode == nil else { return }
            if let document = storybank.manuscriptDocuments.sorted(using: SortDescriptor(\.sortOrder)).first {
                selectedNode = .document(document.id)
            }
        }
        .onChange(of: documentEdits) { oldEdits, newEdits in
            for edit in newEdits where oldEdits.contains(where: {
                $0.id == edit.id && $0 != edit
            }) {
                storybank.manuscriptDocuments.first(where: { $0.id == edit.id })?.updatedAt = .now
            }
            saveChanges()
        }
        .inspector(isPresented: $openInspector) {
            FileTreeInspectorView(storybank: storybank, selectedNode: $selectedNode)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Show/Hide Inspector", systemImage: "sidebar.right") {
                    openInspector.toggle()
                }
            }
        }
        .alert("Could not save manuscript", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("Retry") { saveChanges() }
            Button("Dismiss", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private func saveChanges() {
        do {
            try modelContext.save()
            saveError = nil
        } catch {
            saveError = error.localizedDescription
        }
    }
}

private struct DocumentEdit: Equatable {
    let id: UUID
    let title: String
    let content: AttributedString
}
