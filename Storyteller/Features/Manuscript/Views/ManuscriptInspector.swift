//
//  ManuscriptInspector.swift
//  Storyteller
//
//  Created by Andres Tapia on 04-09-26.
//
import SwiftData
import SwiftUI

enum SelectedNode: Hashable {
    case group(UUID)
    case document(UUID)
}

private enum TreeNode: Identifiable {
    case group(ManuscriptGroup)
    case document(ManuscriptDocument)
    
    var id: UUID {
        switch self {
        case .group(let group): group.id
        case .document(let document): document.id
        }
    }
    
    var children: [TreeNode]? {
        guard case .group(let group) = self else {
            return nil
        }
        
        let children = group.sortedSubgroups.map(TreeNode.group) + group.sortedDocuments.map(TreeNode.document)
        return children.isEmpty ? nil : children
    }
}

struct FileTreeInspectorView: View {
    let storybank: Storybank
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \ManuscriptGroup.sortOrder) private var groups: [ManuscriptGroup]
    
    @Binding var selectedNode: SelectedNode?
    
    @State private var renamingGroup: ManuscriptGroup?
    @State private var renmateText = ""
    @State private var dropTargetGroupID: ManuscriptGroup.ID?
    
    private var rootGroups: [ManuscriptGroup] {
        storybank.manuscriptGroups
            .filter { $0.group == nil }
            .sorted(using: SortDescriptor(\.sortOrder))
    }

    private var rootDocuments: [ManuscriptDocument] {
        storybank.manuscriptDocuments
            .filter { $0.group == nil }
            .sorted(using: SortDescriptor(\.sortOrder))
    }

    private var rootNodes: [TreeNode] {
        rootGroups.map(TreeNode.group) + rootDocuments.map(TreeNode.document)
    }
    
    private var selectedGroup: ManuscriptGroup? {
        switch selectedNode {
        case .group(let id):
            groups.first { $0.id == id }
        case .document(let id):
            groups.flatMap(\.documents).first { $0.id == id }?.group
        case nil:
            nil
        }
    }
    
    var body: some View {
        VStack {
            List(selection: $selectedNode) {
                OutlineGroup(rootNodes, children: \.children) { node in
                    Group {
                        switch node {
                        case .group(let group): GroupNode(
                            node: group,
                            isManuscriptRoot: group.id == storybank.manuscriptRoot?.id,
                            rootName: storybank.name,
                            onHandleDrop: handleDrop,
                            dropTargetGroupID: $dropTargetGroupID
                        )
                        case .document(let document): DocumentNode(node: document)
                        }
                    }
                }
            }
            .listStyle(.sidebar)


            .toolbar {
                ToolbarItemGroup {
                    Button("Create Group", systemImage: "rectangle.stack.badge.plus") {
                        createGroup(in: storybank, parent: selectedGroup ?? storybank.manuscriptRoot)
                    }
                    .help("Create Group")
                    Button("Create Document", systemImage: "long.text.page.and.pencil") {
                        createDocument(in: storybank, parent: selectedGroup ?? storybank.manuscriptRoot)
                    }
                    .help("Create Document")
                }
            }
            
           
        }
    }
    
    private func createGroup(
        in storybank: Storybank,
        parent: ManuscriptGroup?
    ) {
        let group = ManuscriptGroup(
            sortOrder: nextGroupSortOrder(in: parent),
            group: parent
        )

        group.storybank = storybank
        modelContext.insert(group)
        saveChanges()
        selectedNode = .group(group.id)
    }
    
    private func createDocument(
        in storybank: Storybank,
        parent: ManuscriptGroup?
    ) {
        let document = ManuscriptDocument(
            sortOrder: nextDocumentSortOrder(in: parent),
            group: parent
        )
        document.storybank = storybank
        
        modelContext.insert(document)
        saveChanges()
        selectedNode = .document(document.id)
    }

    private func nextGroupSortOrder(in parent: ManuscriptGroup?) -> Int {
        let siblings = parent?.subgroups ?? rootGroups
        return (siblings.map(\.sortOrder).max() ?? -1) + 1
    }

    private func nextDocumentSortOrder(in parent: ManuscriptGroup?) -> Int {
        let siblings = parent?.documents ?? rootDocuments
        return (siblings.map(\.sortOrder).max() ?? -1) + 1
    }
    
    private func handleDropOutside(_ payloads: [String]) -> Bool {
        defer { dropTargetGroupID = nil }
        var didMoveOutside = false
        
        if let id = payloads.first {
            didMoveOutside = moveOutside(id) || didMoveOutside
        }
        
        if didMoveOutside {
            saveChanges()
        }
        
        return didMoveOutside
    }
    
    private func handleDrop(_ payloads: [String], on destination: ManuscriptGroup) -> Bool {
        defer { dropTargetGroupID = nil }
        var didMoveNode = false
        for payload in payloads {
            if let id = payloadID(payload, prefix: "document:") {
                didMoveNode = moveDocument(id, to: destination) || didMoveNode
            } else if let id = payloadID(payload, prefix: "group:") {
                didMoveNode = moveGroup(id, to: destination) || didMoveNode
            }
        }
        
        if didMoveNode {
            saveChanges()
        }
        return didMoveNode
    }
    
    private func payloadID(_ payload: String, prefix: String) -> UUID? {
        guard payload.hasPrefix(prefix) else { return nil }
        return UUID(uuidString: String(payload.dropFirst(prefix.count)))
    }
    
    private func moveOutside(_ payload: String) -> Bool {
        if let id = payloadID(payload, prefix: "document:"),
           let document = storybank.manuscriptDocuments.first(where: { $0.id == id }),
           let source = document.group {
            source.documents.removeAll { $0.id == document.id }
            renumberDocuments(in: source)

            document.sortOrder = nextDocumentSortOrder(in: nil)
            document.group = nil
            selectedNode = .document(document.id)
            return true
        }

        if let id = payloadID(payload, prefix: "group:"),
           let group = storybank.manuscriptGroups.first(where: { $0.id == id }),
           let source = group.group {
            source.subgroups.removeAll { $0.id == group.id }
            renumberSubgroups(in: source)

            group.sortOrder = nextGroupSortOrder(in: nil)
            group.group = nil
            selectedNode = .group(group.id)
            return true
        }

        return false
    }
    
    private func moveDocument(_ id: UUID, to destination: ManuscriptGroup) -> Bool {
        guard let document = storybank.manuscriptDocuments.first(where: { $0.id == id }),
              document.group?.id != destination.id
        else {
            return false
        }
        let source = document.group
        let destinationSortOrder = nextDocumentSortOrder(in: destination)
        
        source?.documents.removeAll { $0.id == document.id }
        if let source {
            renumberDocuments(in: source)
        } else {
            renumberRootDocuments(excluding: document.id)
        }
        
        document.sortOrder = destinationSortOrder
        document.group = destination
        if !destination.documents.contains(where: { $0.id == document.id }) {
            destination.documents.append(document)
        }
        
        selectedNode = .document(document.id)
        return true
    }
    
    private func moveGroup(_ id: UUID, to destination: ManuscriptGroup) -> Bool {
        guard let group = groups.first(where: { $0.id == id }),
              group.group != nil,
              group.id != destination.id,
              group.group?.id != destination.id,
              !isDescendant(destination, of: group)
        else {
            return false
        }
        
        let oldGroup = group.group
        let destinationSortOrder = nextGroupSortOrder(in: destination)
        oldGroup?.subgroups.removeAll { $0.id == group.id }
        renumberSubgroups(in: oldGroup)
        
        group.sortOrder = destinationSortOrder
        group.group = destination
        if !destination.subgroups.contains(where: { $0.id == group.id }) {
            destination.subgroups.append(group)
        }
        renumberRootGroups(excluding: group.id)
        selectedNode = .group(group.id)
        return true
    }
    
    private func isDescendant(_ candidate: ManuscriptGroup, of group: ManuscriptGroup) -> Bool {
        var current: ManuscriptGroup? = candidate
        while let node = current {
            if node.id == group.id {
                return true
            }
            current = node.group
        }
        return false
    }
    
    private func renumberDocuments(in group: ManuscriptGroup?) {
        guard let group else { return }
        for (index, document) in group.sortedDocuments.enumerated() {
            document.sortOrder = index
        }
    }
    
    private func renumberSubgroups(in group: ManuscriptGroup?) {
        guard let group else { return }
        for (index, child) in group.sortedSubgroups.enumerated() {
            child.sortOrder = index
        }
    }

    private func renumberRootDocuments(excluding excludedID: ManuscriptDocument.ID) {
        for (index, document) in rootDocuments.filter({ $0.id != excludedID }).enumerated() {
            document.sortOrder = index
        }
    }
    
    private func renumberRootGroups(excluding excludedID: ManuscriptGroup.ID) {
        for (index, group) in rootGroups.filter({ $0.id != excludedID }).enumerated() {
            group.sortOrder = index
        }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save changes:", error)
        }
    }
}


private struct GroupNode: View {
    @Bindable var node: ManuscriptGroup
    let isManuscriptRoot: Bool
    let rootName: String
    let onHandleDrop: (_ payloads: [String], _ destination: ManuscriptGroup) -> Bool
    @Binding var dropTargetGroupID: ManuscriptGroup.ID?
    
    var body: some View {
        Label {
            if isManuscriptRoot {
                Text(rootName)
            } else {
                TextField("", text: $node.name)
                    .textFieldStyle(.plain)
                    .onChange(of: node.name) { _, newValue in
                        if newValue.isEmpty {
                            node.name = "Untitled Group"
                        }
                    }
            }
        } icon: {
            Image(systemName: "rectangle.stack")
        }
        .badge(node.kind.label)
        .tag(SelectedNode.group(node.id))
        .draggable("group:\(node.id.uuidString)")
        .dropDestination(for: String.self) { payloads, _ in
            onHandleDrop(payloads, node)
        } isTargeted: { isTargeted in
            dropTargetGroupID = isTargeted ? node.id : nil
        }
        .contextMenu {
            Picker("Group format", selection: $node.kind) {
                ForEach(ManuscriptGroupKind.allCases, id: \.self) {
                    Text($0.label).tag($0)
                }
            }
            .pickerStyle(.inline)
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) {
                
            }
            .tint(.red)
            .labelStyle(.titleAndIcon)
        }
    }
}

private struct DocumentNode: View {
    @Bindable var node: ManuscriptDocument
    
    var body: some View {
        Label {
            TextField("", text: $node.title)
                .textFieldStyle(.plain)
                .onChange(of: node.title) {_, newValue in
                    if newValue.isEmpty {
                        node.title = "Untitled Document"
                    }
                }
        } icon: {
            Image(systemName: "text.page")
        }
        .badge(node.kind.label)
        .tag(SelectedNode.document(node.id))
        .draggable("document:\(node.id.uuidString)")
        .contextMenu {
            Picker("File format", selection: $node.kind) {
                ForEach(ManuscriptDocumentKind.allCases, id: \.self) {
                    Text($0.label).tag($0)
                }
            }
            .pickerStyle(.inline)
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) {
                
            }
            .tint(.red)
            .labelStyle(.titleAndIcon)
        }
    }
}

