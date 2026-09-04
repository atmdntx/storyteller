//
//  Launcher.Window.swift
//  Storyteller
//
//  Created by Andres Tapia on 03-09-26.
//

import SwiftUI
import SwiftData

struct LauncherWindow: View {
    @Environment(\.newDocument)
    private var newDocument
    
    @Environment(\.openDocument)
    private var openDocument
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("Library")){
                    Label("Recent Storybanks", systemImage: "apple.books.pages")
                    Label("Templates", systemImage: "document.on.document")
                    Label("Archive", systemImage: "archivebox")
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 240)
            .toolbar(removing: .sidebarToggle)
        } content: {
            ZStack {
                Color(.secondarySystemFill)
                    .ignoresSafeArea()
            }
            .overlay {
                ContentUnavailableView("No Storybanks", systemImage: "book.badge.plus")
                    .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 240)
                    .scrollContentBackground(.hidden)
                    .presentationBackground(.fill)
            }
        } detail: {
            VStack {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                
                VStack {
                    LauncherButton(
                        title: "Create a new Storybank",
                        description: "Start a new Storybank and bring your story to life",
                        buttonLabel: "Create",
                        onPress: {
                            Task {
                                newDocument(contentType: .storybank)
                                dismiss()
                            }
                        }
                    )
                    .buttonStyle(.glassProminent)
                    
                    LauncherButton(
                        title: "Open an existing Storybank",
                        description: "Continue where you left off and keep writing.",
                        buttonLabel: "Open",
                        onPress: {}
                    )
                    .buttonStyle(.glass)
                }
            }
            .padding(32)
            .searchable(
                text: $searchText,
                placement: .toolbar,
                prompt: "Search storybanks...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
        .toolbarBackground(.hidden)
    }
}

private struct LauncherButton: View {
    let title: String
    let description: String
    let buttonLabel: String
    let onPress: () -> Void
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title3).fontWeight(.semibold)
                Text(description).font(.body).foregroundStyle(.secondary)
            }
            Spacer(minLength: 16)
            Button(buttonLabel) {
                onPress()
            }
            .controlSize(.extraLarge)
            .buttonBorderShape(.capsule)
        }
        .padding()
        .frame(maxWidth: 680)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        
        
    }
}
