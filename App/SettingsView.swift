import SwiftUI

/// 設定画面。中身は Web 側の一覧（Schema）をそのまま描くだけなので、Web に設定を足せばここにも出る
struct SettingsView: View {
    @ObservedObject var bridge: WebBridge
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    ForEach(Array((bridge.schema?.groups ?? []).enumerated()), id: \.offset) { _, group in
                        GroupView(group: group, bridge: bridge)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle(bridge.schema?.title ?? "Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(bridge.schema?.close ?? "Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

private struct GroupView: View {
    let group: Schema.Group
    let bridge: WebBridge

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !group.title.isEmpty {
                Text(group.title.uppercased())
                    .font(.caption.weight(.semibold))
                    .kerning(1.2)
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(group.items.enumerated()), id: \.offset) { _, item in
                ItemView(item: item, bridge: bridge)
            }
        }
    }
}

private struct ItemView: View {
    let item: Schema.Item
    let bridge: WebBridge

    var body: some View {
        switch item.t {
        case "buttons":
            let cols = item.cols ?? 0
            let columns = cols > 0
                ? Array(repeating: GridItem(.flexible(), spacing: 8), count: cols)
                : [GridItem(.adaptive(minimum: 104), spacing: 8)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(item.buttons ?? []) { b in
                    Button { bridge.tap(b.id) } label: {
                        Text(b.label)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .foregroundStyle(b.on ? Color.black : Color.white)
                    .background(b.on ? Color.white : Color.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityAddTraits(b.on ? .isSelected : [])
                }
            }
        case "label":
            Text(item.text ?? "")
                .font(.footnote.weight(.semibold))
                .padding(.top, 2)
        case "slider":
            SliderRow(item: item, bridge: bridge)
        case "note":
            Text(item.text ?? "")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        default:
            EmptyView()
        }
    }
}

private struct SliderRow: View {
    let item: Schema.Item
    let bridge: WebBridge
    @State private var local: Double?

    var body: some View {
        let lo = item.min ?? 0
        let hi = Swift.max(item.max ?? 1, lo + 0.0001)
        HStack(spacing: 10) {
            Text(item.lo ?? "").font(.caption).foregroundStyle(.secondary)
            Slider(
                value: Binding(
                    get: { local ?? item.value ?? lo },
                    set: { v in
                        local = v
                        if let id = item.id { bridge.slide(id, v) }
                    }
                ),
                in: lo...hi
            )
            .tint(.white)
            Text(item.hi ?? "").font(.caption).foregroundStyle(.secondary)
        }
    }
}
