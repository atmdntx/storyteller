//
//  ManuscriptSceneDetailsSheet.Component.swift
//  Storyteller
//
//  Created by Andres Tapia on 06-09-26.
//
import SwiftData
import SwiftUI

struct ManuscriptSceneDetailSheet: View {
    @Query private var characters: [Character]
    
    @Bindable var document: ManuscriptDocument
    
    @State private var isCharacterPickerPresented = false
    
    let dismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $document.title)
                    TextField(
                        "Subtitle",
                        text: $document.subtitle
                    )
                    TextField("Purpose", text: $document.purpose, axis: .vertical)
                    .lineLimit(2)
                }
                
                Section {
                    TextField("Synopsis", text: $document.synopsis, axis: .vertical)
                    .lineLimit(8)
                }
                
                Section {
                    Picker("POV", selection: $document.pov) {
                        Text("None").tag(nil as Character?)
                        ForEach(characters) { character in
                            Text(character.name)
                                .tag(character)
                        }
                    }
                    
                    LabeledContent("Characters") {
                        Menu(
                            document.characters.isEmpty
                                ? "None"
                                : document.characters.map(\.name).joined(separator: ", ")
                        ) {
                            ForEach(characters) { character in
                                Toggle(character.name, isOn: $document.characters[contains: character])
                            }
                        }
                    }
                }
                
                Section {
                    TextField("Location", text: $document.location)
                    TextField("Plotlines", text: $document.plotlines)
                    TextField("Notes", text: $document.notes)
                }

            }
            .padding(0)
            .formStyle(.grouped)
            .safeAreaInset(edge: .top) {
                VStack(alignment: .leading) {
                    Text("Scene Details").font(.title).fontWeight(.bold)
                }
                .padding()
                .padding(.bottom, 0)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .trailing, spacing: 0) {
                    Button("OK") {
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                }
                .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                .padding()
            }
        }
    }
}
private extension Array where Element: Identifiable {
    subscript(contains element: Element) -> Bool {
        get {
            contains { $0.id == element.id }
        }
        set {
            if newValue {
                guard !contains(where: { $0.id == element.id }) else { return }
                append(element)
            } else {
                removeAll { $0.id == element.id }
            }
        }
    }
}

