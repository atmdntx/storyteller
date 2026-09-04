//
//  StorytellerApp.swift
//  Storyteller
//
//  Created by Andres Tapia on 03-09-26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct StorytellerApp: App {
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    @State private var visibleDocumentCount = 0
    
    var body: some Scene {
        DocumentGroup(editing: .storybank, migrationPlan: StorytellerMigrationPlan.self) {
            MainWindow()
                .onAppear {
                    visibleDocumentCount += 1
                    dismissWindow(id: "launcher")
                }
                .onDisappear() {
                    visibleDocumentCount = max(0, visibleDocumentCount - 1)
                }
        } prepareDocument: { modelContext in
            let storybank = Storybank(name: "New Storybank")
            let manuscriptRoot = ManuscriptGroup(name: storybank.name, kind: .book)
            let openingScene = ManuscriptDocument(group: manuscriptRoot)

            manuscriptRoot.storybank = storybank
            openingScene.storybank = storybank

            modelContext.insert(storybank)
            modelContext.insert(manuscriptRoot)
            modelContext.insert(openingScene)
        }
        .windowIdealSize(.maximum)
        .defaultWindowPlacement { _, context in
            let visibleFrame = context.defaultDisplay.visibleRect
            return WindowPlacement(visibleFrame.origin, size: visibleFrame.size)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .onChange(of: visibleDocumentCount, initial: true) { _, count in
            guard count == 0 else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                guard visibleDocumentCount == 0 else { return }
                openWindow(id: "launcher")
            }
        }
        Window("Storyteller", id: "launcher") {
            LauncherWindow()
                .frame(minWidth: 1040, minHeight: 680)
                .frame(maxWidth: 1040, maxHeight: 680)
                .navigationTitle("")
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
    }
}

struct StorytellerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        StorytellerVersionedSchema.self,
    ]

    static var stages: [MigrationStage] = [
        // Stages of migration between VersionedSchema, if required.
    ]
}

struct StorytellerVersionedSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(0, 0, 1)

    static var models: [any PersistentModel.Type] = [
        Storybank.self,
        ManuscriptGroup.self,
        ManuscriptDocument.self
    ]
}
