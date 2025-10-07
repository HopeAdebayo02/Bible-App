import SwiftUI

struct ColorPickerView: View {
    let colors: [String] = [
        "#FFFF00", // Yellow
        "#00FF00", // Green
        "#0000FF", // Blue
        "#FF69B4", // Pink
        "#FFA500", // Orange
        "#800080", // Purple
        "#FF0000", // Red
        "#00FFFF"  // Cyan
    ]

    let onColorSelected: (String?) -> Void
    let onCancel: () -> Void

    @State private var selectedColor: String?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Choose Highlight Color")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(colors, id: \.self) { colorHex in
                    Button(action: {
                        selectedColor = colorHex
                        onColorSelected(colorHex)
                    }) {
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.3), lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // No color option
                Button(action: {
                    onColorSelected(nil)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.3), lineWidth: 2)
                            )
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
            }

            Text("Tap a color to apply highlight, or X to remove")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 10)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
