//
//  UniversalContainer.swift
//  Chikane
//
//  Created by Ty Mitchell on 10/23/24.
//


import SwiftUI

struct UniversalContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            if UIDevice.current.userInterfaceIdiom == .pad {
                // For iPad: Center the content with iPhone-like width
                ScrollView {
                    content
                        .frame(width: min(geometry.size.width, 428)) // iPhone 12 Pro Max width
                        .frame(maxWidth: .infinity)
                }
            } else {
                // For iPhone: Regular full-width display
                content
            }
        }
    }
}

// Extension to apply universal container to any view
extension View {
    func universalLayout() -> some View {
        UniversalContainer {
            self
        }
    }
}

// Modifier for proper sheet presentation on iPad
struct UniversalSheetStyle: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .formStyle(.grouped)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}

extension View {
    func universalSheetStyle() -> some View {
        modifier(UniversalSheetStyle())
    }
}