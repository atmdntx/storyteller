//
//  TextEditorView.swift
//  Storyteller
//
//  Created by Andres Tapia on 04-09-26.
//

import SwiftData
import SwiftUI

struct ManuscriptTextEditor: View {
    @Bindable var document: ManuscriptDocument
    
    @State private var selection = AttributedTextSelection()
    @State private var defaultFont: Font.Design = .serif
    
    @State private var isSceneInfoPresent: Bool = false
    
    var isScene: Bool {
        document.kind == .scene
    }
    
    private var text: AttributedString {
        document.content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ManuscriptTextEditorToolbar(
                text: $document.content,
                selection: $selection,
                defaultFont: $defaultFont,
                isSceneInfoPresent: $isSceneInfoPresent,
                isScene: isScene
            )
            VStack(spacing: 12) {
                if isScene {
                    header
                }
                TextEditor(text: $document.content, selection: $selection)
                    .font(.system(size: 16, design: .serif))
                    .padding(.top, 24)
                    .onChange(of: document.content) {
                        document.updatedAt = .now
                    }
            }
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $isSceneInfoPresent, onDismiss: dismiss) {
            ManuscriptSceneDetailSheet(document: document, dismiss: dismiss)
        }
    }
    
    private func dismiss() {
        isSceneInfoPresent = false
    }
    
    @ViewBuilder
    private var header: some View {
        HStack {
            VStack {
                TextField("", text: $document.title)
                    .textFieldStyle(.plain)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .fontDesign(defaultFont)
                    
                if !document.subtitle.isEmpty {
                    TextField(
                        "",
                        text: $document.subtitle
                    )
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .fontDesign(defaultFont)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Button(document.wordCountLabel) {}
                    .buttonStyle(.plain)
                    .font(.callout.smallCaps()).fontWeight(.medium).foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.quinary, in: .capsule)

                if let status = document.status {
                    Menu {
                        Picker("Status", selection: $document.status) {
                            ForEach(ManuscriptDocumentStatus.allCases) { status in
                                Label(status.label, systemImage: status.icon)
                                    .tag(status)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        HStack {
                            Circle()
                                .fill(status.color)
                                .frame(width: 8, height: 8)
                                .glassEffect()
                            Text(status.label)
                                .font(.callout.smallCaps()).fontWeight(.medium).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quinary, in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .menuIndicator(.hidden)
                }
                Text("Last edited: \(document.updatedAtLabel)")
                    .font(.callout.smallCaps()).fontWeight(.medium).foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
    }
}
