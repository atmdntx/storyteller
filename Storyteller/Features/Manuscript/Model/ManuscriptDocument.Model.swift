//
//  ManuscriptScene.swift
//  Storyteller
//
//  Created by Andres Tapia on 04-09-26.
//
import Foundation
import SwiftUI
import SwiftData

enum ManuscriptDocumentKind: String, Codable, Identifiable, CaseIterable {
    case document
    case scene
    
    var id: String {
        self.rawValue
    }
    
    var label: String {
        switch self {
        case .document: "Document"
        case .scene: "Scene"
        }
    }
}

enum ManuscriptDocumentStatus: String, Codable, Identifiable, CaseIterable {
    case idea
    case outline
    case draft
    case revision
    case final
    
    var id: String {
        self.rawValue
    }
    
    var label: String {
        switch self {
        case .idea: "Idea"
        case .outline: "Outline"
        case .draft: "Draft"
        case .revision: "Revision"
        case .final: "Final"
        }
    }
    
    var icon: String {
        switch self {
        case .idea: "lightbulb.max"
        case .outline: "pencil.and.outline"
        case .draft: "long.text.page.and.pencil"
        case .revision: "text.page"
        case .final: "checkmark.seal.text.page"
        }
    }
    
    var color: Color {
        switch self {
        case .idea: Color.yellow
        case .outline: Color.brown
        case .draft: Color.purple
        case .revision: Color.blue
        case .final: Color.green
        }
    }
}

@Model
final class ManuscriptDocument: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var subtitle: String = ""
    
    @Attribute(.externalStorage) var content: AttributedString
    
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    
    var storybank: Storybank?
    
    var group: ManuscriptGroup?
    
    /*METADATA*/
    var kind: ManuscriptDocumentKind
    
    var status: ManuscriptDocumentStatus?
    
    var purpose: String = ""
    var synopsis: String = ""
    var pov: Character? = nil
    var location: String = ""
    var characters: [Character] = []
    var plotlines: String = ""
    var notes: String = ""
    
    
    init(sortOrder: Int = 0, kind: ManuscriptDocumentKind = .scene, group: ManuscriptGroup? = nil) {
        self.id = UUID()
        self.title = "New Scene"
        self.content = AttributedString()
        self.sortOrder = sortOrder
        self.group = group
        self.createdAt = .now
        self.updatedAt = .now
        
        self.kind = kind
        self.status = .draft
        
    }
}

extension ManuscriptDocument {
    var wordCount: Int {
        self.content.characters.split(whereSeparator: {$0.isWhitespace || $0.isNewline }).count
    }
    
    var wordCountLabel: String {
        self.wordCount == 1 ? "1 word" : "\(self.wordCount.formatted()) words"
    }
    
    var updatedAtLabel: String {
        let now = Date()
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.hour], from: self.updatedAt, to: now)
        
        guard let hours = components.hour, hours >= 1 else {
            return "just now"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .numeric
        return formatter.localizedString(for: self.updatedAt, relativeTo: Date())
    }
}
