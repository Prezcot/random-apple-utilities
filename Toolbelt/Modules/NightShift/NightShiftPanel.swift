import SwiftUI

/// Night Shift Forever's controls in the menu-bar panel: a tile to toggle it and a warmth slider.
struct NightShiftPanel: View {
    let module: NightShiftModule

    var body: some View {
        if module.isSupported {
            VStack(spacing: 10) {
                toggleTile
                warmthTile
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Night Shift isn't available")
                    .font(.system(size: 14, weight: .semibold))
                Text("This Mac or its display doesn't support Night Shift.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .tile()
        }
    }

    private var toggleTile: some View {
        Button(action: module.toggle) {
            HStack(spacing: 12) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(module.isOn ? Color.black : Color.primary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(module.isOn ? Color.orange : Color.primary.opacity(0.15)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Night Shift Forever")
                        .font(.system(size: 14, weight: .semibold))
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .tile()
        .accessibilityAddTraits(module.isOn ? .isSelected : [])
    }

    private var warmthTile: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Warmth")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(Int((module.strength * 100).rounded()))%")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ThickSlider(value: module.strength, onChange: module.previewStrength, onCommit: module.commitStrength)
                .accessibilityLabel("Warmth")
        }
        .padding(12)
        .tile()
    }

    private var statusText: String {
        if module.isOn { return "On · until you turn it off" }
        return module.isPreviewing ? "Off · previewing warmth" : "Off · click to turn on"
    }
}
