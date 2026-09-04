//
//  Storybank+UTType.swift
//  Storyteller
//
//  Created by Andres Tapia on 04-09-26.
//

import UniformTypeIdentifiers

extension UTType {
    static var storybank: UTType {
        UTType(exportedAs: "com.storyteller.storybank", conformingTo: .package)
    }
}
