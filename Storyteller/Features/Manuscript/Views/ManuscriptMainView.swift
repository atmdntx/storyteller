//
//  ManuscriptMainView.swift
//  Storyteller
//
//  Created by Andres Tapia on 06-09-26.
//
import SwiftData
import SwiftUI

struct ManuscriptMainView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("Manuscript").font(.largeTitle).fontWeight(.bold)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
