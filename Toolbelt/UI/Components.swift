import SwiftUI

extension View {
    /// The rounded, lightly filled background shared by every panel tile.
    func tile() -> some View {
        background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.primary.opacity(0.08)))
    }
}

/// A small round icon-only button, used in the panel footer.
struct CircleIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.primary.opacity(0.1)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

/// A chunky Control Center-style slider: an orange fill with a round white knob.
struct ThickSlider: View {
    /// 0...1
    let value: Double
    /// Called continuously while dragging.
    let onChange: (Double) -> Void
    /// Called when the drag ends.
    let onCommit: () -> Void
    var height: CGFloat = 28

    var body: some View {
        GeometryReader { geometry in
            let travel = max(geometry.size.width - height, 1)
            let knobCenter = height / 2 + travel * value
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.15))
                Capsule().fill(Color.orange).frame(width: knobCenter + height / 2)
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
                    .frame(width: height, height: height)
                    .offset(x: knobCenter - height / 2)
            }
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        onChange(min(max((drag.location.x - height / 2) / travel, 0), 1))
                    }
                    .onEnded { _ in onCommit() }
            )
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onChange(min(value + 0.05, 1))
            case .decrement: onChange(max(value - 0.05, 0))
            @unknown default: return
            }
            onCommit()
        }
    }
}
