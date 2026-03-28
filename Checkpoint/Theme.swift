//
//  Theme.swift
//  Checkpoint
//
//  Shared color palette and reusable UI components.
//

import SwiftUI

// MARK: - App Color Palette

extension Color {
    static let appBackground  = Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255)
    static let appSurface     = Color(red: 0x18/255, green: 0x21/255, blue: 0x30/255)
    static let appAccent      = Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255)
    static let appAccentLight = Color(red: 0xa0/255, green: 0xd0/255, blue: 0xee/255)
    static let appAccentDeep  = Color(red: 0x4a/255, green: 0x94/255, blue: 0xd0/255)
    static let appMuted       = Color(red: 0x6c/255, green: 0x7a/255, blue: 0x8d/255)
    static let appTextPrimary = Color.white.opacity(0.88)
    static let appTextMuted   = Color.white.opacity(0.38)
    static let appDivider     = Color.white.opacity(0.07)
}

// MARK: - Reusable Components

struct SettingsGroup<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Color.appTextMuted)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
