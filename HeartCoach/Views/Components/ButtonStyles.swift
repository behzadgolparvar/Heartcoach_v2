import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(configuration.isPressed ? Color.red.opacity(0.8) : Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Broadcast (Direction D) — square slabs for the Home action bar.

/// Full-width red slab, height 60, square corners. The label supplies its own content.
struct BroadcastPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(WT.red)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Full-width outlined surface slab, height 44, square corners (15-min minimum).
struct BroadcastSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(WT.surface)
            .overlay(Rectangle().strokeBorder(Color(hex: 0x3A3A3C), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
