//
//  Main.Window.swift
//  Storyteller
//
//  Created by Andres Tapia on 04-09-26.
//
import SwiftData
import SwiftUI

struct MainWindow: View {
    @Environment(\.documentConfiguration)
    private var documentConfiguration
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Query var storybanks: [Storybank]
    
    @State private var selectedModule: StorytellerModule = .manuscript
    
    
    var body: some View {
        NavigationSplitView {
            if let storybank = storybanks.first {
                MainSidebarView(storybank: storybank, selectedModule: $selectedModule)
            } else {
                ProgressView()
            }
        } detail: {
            if let storybank = storybanks.first {
                MainWorkspaceView(storybank: storybank, selectedModule: selectedModule)
            } else {
                ProgressView()
            }
        }
            .onChange(of: documentConfiguration?.fileURL) {_, _ in
                updateTitleOnSave()
            }
    }
    
    
    private func updateTitleOnSave() {
        guard let storybank = storybanks.first else { return }
        guard !storybank._didNameChange else { return }
        guard let url = documentConfiguration?.fileURL else { return }
        
        let fileName = url.deletingPathExtension().lastPathComponent
        
        storybank.name = fileName
        storybank.manuscriptRoot?.name = fileName
        storybank._didNameChange = true
    }
}

private struct MainSidebarView: View {
    let storybank: Storybank
    
    @Binding var selectedModule: StorytellerModule
    
    
    var body: some View {
        List(selection: $selectedModule) {
            Section(header: Text(storybank.name)) {
                ForEach(StorytellerModule.allCases) { module in
                    Label(module.label, systemImage: module.icon)
                        .tag(module)
                }
            }
        }
        .navigationSplitViewColumnWidth(240)
    }
}

private struct MainWorkspaceView: View {
    let storybank: Storybank
    let selectedModule: StorytellerModule
    
    var body: some View {
        switch selectedModule {
        case .manuscript: ManuscriptView()
        case .characters: CharactersView()
        default: ContentUnavailableView("We are working on it!", systemImage: "hammer")
        }
    }
}

private enum StorytellerModule: String, Identifiable, CaseIterable {
    case manuscript
    case characters
    case worldbuilding
    
    var id: String {
        self.rawValue
    }
    
    var label: String {
        switch self {
        case .manuscript: "Manuscript"
        case .characters: "Characters"
        case .worldbuilding: "Worldbuilding"
        }
    }
    
    var icon: String {
        switch self {
        case .manuscript: "apple.books.pages"
        case .characters: "rectangle.stack.person.crop"
        case .worldbuilding: "globe.desk"
        }
    }
}
