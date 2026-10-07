import Foundation
import SwiftData

// Compile alongside the actual production models; no substitute model schema.
@main
struct ScenePersistenceCheck {
    @MainActor
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = directory.appendingPathComponent("manuscript.store")
        let id = try createAndEdit(store: store)
        try reopen(store: store, documentID: id)
        print("PASS: scene ownership, tree membership, title/content, and reopen persistence")
    }

    @MainActor
    static func container(at url: URL) throws -> ModelContainer {
        let schema = Schema([
            Storybank.self, ManuscriptGroup.self, ManuscriptDocument.self, Character.self
        ])
        return try ModelContainer(for: schema, configurations: [ModelConfiguration(url: url)])
    }

    @MainActor
    static func createAndEdit(store: URL) throws -> UUID {
        let container = try container(at: store)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let storybank = Storybank(name: "Workflow check")
        let root = ManuscriptGroup(name: storybank.name, kind: .book)
        root.storybank = storybank
        context.insert(storybank)
        context.insert(root)
        let scene = ManuscriptDocument(sortOrder: 0, group: root)
        scene.storybank = storybank
        context.insert(scene)
        try context.save()
        precondition(storybank.manuscriptDocuments.count == 1)
        precondition(root.sortedDocuments.first?.id == scene.id)
        let selectedID = scene.id
        let selected = try requireValue(storybank.manuscriptDocuments.first { $0.id == selectedID })
        selected.title = "Opening scene"
        selected.content = AttributedString("The first scene survives reopening.")
        selected.updatedAt = .now
        try context.save()
        return selectedID
    }

    @MainActor
    static func reopen(store: URL, documentID: UUID) throws {
        let container = try container(at: store)
        let context = ModelContext(container)
        let storybank = try requireValue(context.fetch(FetchDescriptor<Storybank>()).first)
        let scene = try requireValue(storybank.manuscriptDocuments.first { $0.id == documentID })
        precondition(storybank.manuscriptDocuments.count == 1)
        precondition(scene.title == "Opening scene")
        precondition(scene.content == AttributedString("The first scene survives reopening."))
        precondition(scene.kind == .scene)
        precondition(scene.storybank?.id == storybank.id)
        precondition(scene.group?.id == storybank.manuscriptRoot?.id)
        precondition(storybank.manuscriptRoot?.sortedDocuments.first?.id == documentID)
    }

    static func requireValue<T>(_ value: T?) throws -> T {
        guard let value else { throw CheckError.missingRecord }
        return value
    }

    enum CheckError: Error { case missingRecord }
}
