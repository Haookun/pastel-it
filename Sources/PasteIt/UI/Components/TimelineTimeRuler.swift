import SwiftUI
import PasteItCore

struct TimelineTimeRuler: View {
    let scale: TimelineTimeScale
    let selectedID: UUID?
    let onSelect: (UUID) -> Void
    @State private var hoverX: CGFloat?

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, geometry.size.width)
            let tickCount = max(2, Int(width / 12))
            let hovered = hoverX.flatMap { scale.nearest(to: Double($0 / width)) }
            let selected = scale.entries.first { $0.id == selectedID }
            ZStack(alignment: .topLeading) {
                Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1).offset(y: 24)
                ForEach(0...tickCount, id: \.self) { tick in
                    let x = width * CGFloat(tick) / CGFloat(tickCount)
                    let proximity = hoverX.map { max(0, 1 - abs($0 - x) / 60) } ?? 0
                    Capsule()
                        .fill(proximity > 0.6 ? Color.accentColor : Color.secondary.opacity(0.45))
                        .frame(width: 2 + proximity, height: (tick % 5 == 0 ? 12 : 6) + proximity * 12)
                        .position(x: x, y: 24)
                }
                if let selected {
                    Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                        .position(x: width * scale.fraction(for: selected.date), y: 24)
                }
                if let hovered, let hoverX {
                    Text(hovered.date.formatted(date: .numeric, time: .standard))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.regularMaterial, in: Capsule())
                        .fixedSize()
                        .position(x: min(max(hoverX, min(100, width / 2)), max(width / 2, width - 100)), y: 5)
                        .allowsHitTesting(false)
                }
                HStack {
                    if let date = scale.entries.first?.date { Text(date, format: .dateTime.month().day().hour().minute()) }
                    Spacer()
                    if let date = scale.entries.last?.date { Text(date, format: .dateTime.month().day().hour().minute()) }
                }
                .font(.system(size: 10)).foregroundStyle(.secondary).offset(y: 38)
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location): hoverX = min(width, max(0, location.x))
                case .ended: hoverX = nil
                }
            }
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                hoverX = min(width, max(0, value.location.x))
                if let entry = scale.nearest(to: Double(value.location.x / width)) { onSelect(entry.id) }
            })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.tr("timeline.timeRuler", default: "Copy time navigation"))
            .accessibilityValue(selected?.date.formatted(date: .numeric, time: .standard) ?? "")
            .accessibilityAdjustableAction { direction in
                let index = selected.flatMap { scale.entries.firstIndex(of: $0) } ?? 0
                let next = direction == .increment ? index + 1 : index - 1
                if scale.entries.indices.contains(next) { onSelect(scale.entries[next].id) }
            }
            .help(L10n.tr("timeline.timeRulerHelp", default: "Hover to magnify copy time. Click or drag to jump to the nearest visible clip."))
        }
        .frame(height: 54)
        .padding(.horizontal, 22)
        .padding(.bottom, 6)
    }
}
