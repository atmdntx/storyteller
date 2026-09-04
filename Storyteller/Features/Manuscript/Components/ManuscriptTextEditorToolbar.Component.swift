//
//  ManuscriptTextEditorToolbar.Component.swift
//  Storyteller
//
//  Created by Andres Tapia on 05-09-26.
//
import SwiftData
import SwiftUI

struct ManuscriptTextEditorToolbar: View {
    @Environment(\.fontResolutionContext) private var fontResolutionContext
    @Binding var text: AttributedString
    @Binding var selection: AttributedTextSelection
    @Binding var defaultFont: Font.Design

    @State private var fontDesign: FontDesign = .traditional
    
    @State private var foregroundColor: Color = .primary
    @State private var backgroundColor: Color = .clear
    
    @Binding var isSceneInfoPresent: Bool
    
    let isScene: Bool
    
    var body: some View {
        GlassEffectContainer {
            HStack(alignment: .center) {
                ControlGroup {
                    Menu("Text Format", systemImage: "textformat") {
                        Picker("Choose a text format", selection: $fontDesign) {
                            ForEach(FontDesign.allCases) { font in
                                Text(font.label)
                                    .tag(font)
                            }
                        }
                        .onChange(of: fontDesign) { _, newValue in
                            setFontDesign(newValue)
                        }
                        .pickerStyle(.inline)
                        .buttonBorderShape(.capsule)
                        .tint(Color.primary)
                        
                    }
                    
                    Menu("\(resolvedFontSize.formatted())") {
                        Picker(
                            "Choose a font size",
                            selection: Binding(
                                get: { resolvedFontSize },
                                set: { setFontSize($0) }
                            )
                        ) {
                            ForEach(Self.fontSizes, id: \.self) { size in
                                Text("\(size.formatted())")
                                    .tag(size)
                            }
                        }
                        .pickerStyle(.inline)
                        .buttonBorderShape(.capsule)
                        .tint(Color.primary)
                    }
                }
                .controlGroupStyle(GlassControlGroupStyle())
                
                ControlGroup {
                    Toggle("Bold", systemImage: "bold", isOn: Binding(
                        get: { isBold },
                        set: { setBold($0) }
                    ))
                    Toggle("Italic", systemImage: "italic", isOn: Binding(
                        get: { isItalic },
                        set: { setItalic($0) }
                    ))
                    Toggle("Underline", systemImage: "underline", isOn: Binding(
                        get: { isUnderline },
                        set: { setUnderline($0) }
                    ))
                    Toggle("Strikethrough", systemImage: "strikethrough", isOn: Binding(
                        get: { isStrikethrough },
                        set: { setStrikethrough($0) }
                    ))
                    Menu {
                        Picker("Text color styles", selection: $foregroundColor) {
                            ForEach(Self.textColors, id: \.self) { color in
                                if color == .clear {
                                    Label("ForegroundColor", systemImage: "circle.slash")
                                        .tag(color)
                                } else {
                                    Label("ForegroundColor", systemImage: "circle.fill")
                                        .tint(color)
                                        .tag(color)
                                }
                            }
                        }
                        .pickerStyle(.palette)
                        .onChange(of: foregroundColor) {_, newValue in
                            setForegroundColor(newValue)
                        }
                        
                        Picker("Text color styles", selection: $backgroundColor) {
                            ForEach(Self.textColors, id: \.self) { color in
                                if color == .clear {
                                    Label("ForegroundColor", systemImage: "circle.slash")
                                        .tag(color)
                                } else {
                                    Label("BackgroundColor", systemImage: "circle.fill")
                                        .tint(color.opacity(0.1))
                                        .tag(color)
                                }
                            }
                        }
                        .pickerStyle(.palette)
                        .onChange(of: backgroundColor) {_, newValue in
                            setBackgroundColor(newValue.opacity(0.1))
                        }
                        
                    } label: {
                        Label("Text color", systemImage: "paintbrush.pointed")
                    }
                }
                .controlGroupStyle(GlassControlGroupStyle())
                
                if isScene {
                    ControlGroup {
                        
                            Button("Scene Information", systemImage: "info.circle.text.page") {
                                isSceneInfoPresent = true
                            }
                        
                        
                    }
                    .controlGroupStyle(GlassControlGroupStyle())
                }
            }
            .padding()
        }
        .onChange(of: text.characters.isEmpty) { _, isEmpty in
            guard isEmpty else { return }
            fontDesign = .traditional
            defaultFont = .serif
        }
    }
    
    func didDismiss() {
        
    }
    
    private var defaultTextFont: Font {
        .system(size: 16, design: .serif)
    }
    
    private func font(_ font: Font, design: FontDesign) -> Font {
        let resolved = font.resolve(in: fontResolutionContext)
        return Font.system(
            size: resolved.pointSize,
            weight: resolved.weight,
            design: design.value
        )
        .italic(resolved.isItalic)
    }
}

private struct GlassControlGroupStyle: ControlGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        ControlGroup(configuration)
        .menuIndicator(.visible)
        .controlSize(.extraLarge)
        .controlGroupStyle(.navigation)
        .glassEffect()
    }
}

// MARK: - Text

extension ManuscriptTextEditorToolbar {
    private var typingAttributes: AttributeContainer {
        selection.typingAttributes(in: text)
    }
    
    private var selectedFont: Font {
        typingAttributes.font ?? defaultTextFont
    }
    
    private var resolvedFont: Font.Resolved {
        selectedFont.resolve(in: fontResolutionContext)
    }
    
    private var hasSelection: Bool {
        let indices = selection.indices(in: text)
        switch indices {
        case .ranges(let range): return !range.isEmpty
        case .insertionPoint: return false
        @unknown default: return false
        }
    }
}

// MARK: - Font Design

extension ManuscriptTextEditorToolbar {
    enum FontDesign: String, CaseIterable, Identifiable {
        case traditional
        case modern
        case round
        case typewriter
        
        var id: Self {
            self
        }
        
        var label: String {
            switch self {
            case .traditional: "Traditional"
            case .modern: "Modern"
            case .round: "Rounded"
            case .typewriter: "Typewriter"
            }
        }
        
        var value: Font.Design {
            switch self {
            case .traditional: .serif
            case .modern: .default
            case .round: .rounded
            case .typewriter: .monospaced
            }
        }
    }
    
    private func setFontDesign(_ design: FontDesign) {
        if hasSelection {
            text.transformAttributes(in: &selection) { attributes in
                attributes.font = font(attributes.font ?? defaultTextFont, design: design)
            }
        } else {
            text = text.transformingAttributes(\.font) { font in
                font.value = self.font(font.value ?? defaultTextFont, design: design)
            }
        }
        
        defaultFont = design.value
    }
}

// MARK: - Font Size

extension ManuscriptTextEditorToolbar {
    static let fontSizes: [CGFloat] = [10, 11, 12, 13, 14, 16, 18, 20, 22, 24, 28, 32, 36, 48, 64]
    
    var resolvedFontSize: CGFloat {
        resolvedFont.pointSize
    }
    
    func setFontSize(_ size: CGFloat) {
        if hasSelection {
            text.transformAttributes(in: &selection) { attributes in
                let currentFont: Font = attributes.font ?? defaultTextFont
                attributes.font = currentFont.pointSize(size)
            }
        } else {
            text = text.transformingAttributes(\.font) { font in
                font.value = (font.value ?? defaultTextFont).pointSize(size)
            }
        }
    }
}

// MARK: - Font Style

extension ManuscriptTextEditorToolbar {
    var isBold: Bool {
        resolvedFont.isBold
    }
    
    var isItalic: Bool {
        resolvedFont.isItalic
    }
    
    var isUnderline: Bool {
        typingAttributes.underlineStyle != nil
    }
    
    var isStrikethrough: Bool {
        typingAttributes.strikethroughStyle != nil
    }
    
    func setBold(_ value: Bool) {
        text.transformAttributes(in: &selection) { attributes in
            attributes.font = (attributes.font ?? defaultTextFont).bold(value)
        }
    }
    
    func setItalic(_ value: Bool) {
        text.transformAttributes(in: &selection) { attributes in
            attributes.font = (attributes.font ?? defaultTextFont).italic(value)
        }
    }
    
    func setUnderline(_ value: Bool) {
        text.transformAttributes(in: &selection) { attributes in
            attributes.underlineStyle = value ? .single : nil
        }
    }
    
    func setStrikethrough(_ value: Bool) {
        text.transformAttributes(in: &selection) { attributes in
            attributes.strikethroughStyle = value ? .single : nil
        }
    }
}

// MARK: - Text Color

extension ManuscriptTextEditorToolbar {
    static let textColors: [Color] = [
        .primary,
        .gray,
        .brown,
        .orange,
        .yellow,
        .green,
        .teal,
        .blue,
        .purple,
        .pink,
        .red,
        .clear
    ]
    
    
    func setForegroundColor(_ color: Color) {
        text.transformAttributes(in: &selection) { attributes in
            attributes.foregroundColor = color
        }
    }
    func setBackgroundColor(_ color: Color) {
        text.transformAttributes(in: &selection) { attributes in
            attributes.backgroundColor = color
        }
    }
}
