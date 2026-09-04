//
//  Character.Model.swift
//  Storyteller
//
//  Created by Andres Tapia on 05-09-26.
//
import Foundation
import SwiftData

@Model
final class Character {
    @Attribute(.unique) var id: UUID
    
    var createdAt: Date
    
    var name: String
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
    }
}
