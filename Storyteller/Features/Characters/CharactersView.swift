//
//  CharactersView.swift
//  Storyteller
//
//  Created by Andres Tapia on 06-09-26.
//

import SwiftData
import SwiftUI

struct CharactersView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var characters: [Character]
    
    var body: some View {
        VStack {
            Button("Add Character") {
                let character = Character(
                    name: "New Character"
                )
                modelContext.insert(character)
            }
            List {
                ForEach(characters) { character in
                    TextField("", text: Binding(
                        get: {character.name},
                        set: {character.name = $0}
                    ))
                }
            }
            .listStyle(.bordered)
        }
    }
}
