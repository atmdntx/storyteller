//
//  ManuscriptView.swift
//  Storyteller
//
//  Created by Andres Tapia on 04-09-26.
//
import SwiftData
import SwiftUI

struct ManuscriptView: View {
    @Query var storybanks: [Storybank]
    
    @State private var openInspector: Bool = true
    @State private var selectedNode: SelectedNode?

    var body: some View {
        HStack {
            if let selectedNode,
               case .document(let documentID) = selectedNode,
               let document = storybanks
               .flatMap(\.manuscriptDocuments)
               .first(where: { $0.id == documentID })
            {
                ManuscriptTextEditor(document: document)
            } else {
                ManuscriptMainView()
            }
        }
        .onTapGesture {
            /*selectedNode = nil*/
        }
        .inspector(isPresented: $openInspector) {
            if let storybank = storybanks.first {
                FileTreeInspectorView(storybank: storybank, selectedNode: $selectedNode)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Show/Hide Inspector", systemImage: "sidebar.right") {
                    openInspector.toggle()
                }
            }
        }
    }
}
