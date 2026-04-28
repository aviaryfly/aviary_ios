import SwiftUI

struct MyJobsScreen: View {
    @Environment(\.theme) private var t
    @State private var filter: Filter = .open

    enum Filter: String, CaseIterable, Identifiable {
        case open, completed
        var id: String { rawValue }
        var label: String {
            switch self {
            case .open:      return "Open"
            case .completed: return "Completed"
            }
        }
    }

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PageHeader(title: "My jobs")

                    filterRow
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 12)

                    emptyState
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
        }
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            ForEach(Filter.allCases) { f in
                Button { filter = f } label: {
                    Text(f.label)
                        .font(AviaryFont.body(13, weight: .semibold))
                        .foregroundStyle(filter == f ? t.accentInk : t.ink2)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            Capsule().fill(filter == f ? t.accent : t.surface)
                        )
                        .overlay(Capsule().strokeBorder(t.line))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var emptyState: some View {
        AviaryCard(padding: 22) {
            VStack(alignment: .leading, spacing: 10) {
                AviaryIcon(name: "briefcase", size: 24, color: t.ink3)
                Text(filter == .open ? "No open jobs" : "No completed jobs yet")
                    .font(AviaryFont.body(17, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text(filter == .open
                     ? "Post a job from the Post Job tab and it will show up here while a pilot is on the way."
                     : "Once a pilot completes a job for you, you'll see it here with the deliverables.")
                    .font(AviaryFont.body(13))
                    .foregroundStyle(t.ink3)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
