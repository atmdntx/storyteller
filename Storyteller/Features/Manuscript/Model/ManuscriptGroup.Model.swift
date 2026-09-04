//
//  ManuscriptGroup.Model.swift
//  Storyteller
//
//  Created by Andres Tapia on 04-09-26.
//

import Foundation
import SwiftData

enum ManuscriptGroupKind: String, Codable, Identifiable, CaseIterable {
    case book
    case part
    case act
    case chapter
    case section
    case group
    
    var id: String {
        self.rawValue
    }
    
    var label: String {
        switch self {
        case .book: "Book"
        case .part: "Part"
        case .act: "Act"
        case .chapter: "Chapter"
        case .section: "Section"
        case .group: "Group"
        }
    }
}

@Model
final class ManuscriptGroup: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date?
    
    var storybank: Storybank?
    
    @Relationship(deleteRule: .cascade, inverse: \ManuscriptDocument.group)
    var documents: [ManuscriptDocument] = []
    
    var group: ManuscriptGroup?
    
    @Relationship(deleteRule: .cascade, inverse: \ManuscriptGroup.group)
    var subgroups: [ManuscriptGroup] = []
    
    /** METADATA **/
    
    var kind: ManuscriptGroupKind
    
    init(name: String = "New Group", sortOrder: Int = 0, group: ManuscriptGroup? = nil, kind: ManuscriptGroupKind = .chapter) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = .now
        self.group = group
        self.kind = kind
    }
}

extension ManuscriptGroup {
    var sortedSubgroups: [ManuscriptGroup] {
        subgroups.sorted(using: SortDescriptor(\.sortOrder))
    }
    
    var sortedDocuments: [ManuscriptDocument] {
        documents.sorted(using: SortDescriptor(\.sortOrder))
    }
}
