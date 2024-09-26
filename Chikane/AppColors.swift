//
//  AppColors.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//


//
//  AppColors.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/15/24.
//

import SwiftUI

// MARK: - Color Scheme
struct AppColors {
    static let primary = Color(hex: "0A1828")  // Deep navy blue
    static let secondary = Color(hex: "C0C0C0")  // Silver
    static let accent = Color(hex: "FF4500")  // Bright orange-red
    static let background = Color.black  // Dark background for "cockpit" feel
    static let cardBackground = Color(hex: "1A2838")  // Slightly lighter than primary for cards
    static let text = Color.white  // White text for high contrast
    static let lightText = Color(hex: "A0A0A0")  // Light gray for secondary text
    static let fastestLap = Color(hex: "b125d2") // Purple for fastest lap 
    
    // Additional colors for variety
    static let highlightBlue = Color(hex: "007AFF")  // iOS blue for highlights
    static let warningYellow = Color(hex: "FFD60A")  // Bright yellow for warnings
    static let successGreen = Color(hex: "28A745")  // Green for success messages
}

// MARK: - Typography
struct AppFonts {
    static let titleFont = "Helvetica Neue"
    static let bodyFont = "Avenir"
    
    static let largeTitle = Font.custom(titleFont, size: 34).weight(.bold)
    static let title1 = Font.custom(titleFont, size: 28).weight(.semibold)
    static let title2 = Font.custom(titleFont, size: 22).weight(.semibold)
    static let title3 = Font.custom(titleFont, size: 18).weight(.semibold)
    static let headline = Font.custom(bodyFont, size: 17).weight(.semibold)
    static let body = Font.custom(bodyFont, size: 17)
    static let callout = Font.custom(bodyFont, size: 16)
    static let subheadline = Font.custom(bodyFont, size: 15)
    static let footnote = Font.custom(bodyFont, size: 13)
    static let caption = Font.custom(bodyFont, size: 12)
}

// MARK: - Common Components
struct AppButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.accent)
                .cornerRadius(10)
        }
    }
}

struct AppCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Layout Guidelines
struct AppSpacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
}

// MARK: - Helper Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
