//
//  Storybank.Model.swift
//  Storyteller
//
//  Created by Andres Tapia on 04-09-26.
//
import Foundation
import SwiftData

@Model
final class Storybank {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var _didNameChange: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \ManuscriptGroup.storybank)
    var manuscriptGroups: [ManuscriptGroup] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ManuscriptDocument.storybank)
    var manuscriptDocuments: [ManuscriptDocument] = []
    
    init(name: String, _didNameChange: Bool = false) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self._didNameChange = _didNameChange
    }
}

extension Storybank {
    var manuscriptRoot: ManuscriptGroup? {
        manuscriptGroups.first { $0.group == nil }
    }
}
