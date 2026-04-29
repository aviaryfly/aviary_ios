import SwiftUI

/// Customer-side rate-the-pilot screen — the symmetric counterpart to
/// `ReviewCompleteScreen`. Auto-fills stars, tags, and a tip while the
/// `customerRate` showcase step is active.
struct CustomerRateScreen: View {
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore

    @State private var stars: Int = 5
    @State private var tags: Set<String> = []
    @State private var tipIdx: Int? = nil
    @State private var note: String = ""
    @State private var hasSubmitted: Bool = false
    @State private var showcaseTask: Task<Void, Never>?

    private let availableTags = ["Smooth flight", "On time", "Great photos", "Communicative", "Easy reschedule"]
    private let tipOptions = [(idx: 0, label: "$0", cents: 0),
                              (idx: 1, label: "$5", cents: 500),
                              (idx: 2, label: "$10", cents: 1000),
                              (idx: 3, label: "$20", cents: 2000)]

    private let pilotName = "Casey Park"
    private let pilotRating = "★ 4.94"
    private let payoutText = "$340.00"

    private let showcaseTagPicks = ["Smooth flight", "Great photos", "On time"]

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle().fill(t.good)
                                .frame(width: 76, height: 76)
                            AviaryIcon(name: "check", size: 38, stroke: 3, color: .white)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 18)

                        Text("DELIVERABLES READY")
                            .font(AviaryFont.body(13, weight: .semibold))
                            .tracking(0.04 * 13)
                            .foregroundStyle(t.good)
                            .padding(.bottom, 6)
                        Text("Job complete.")
                            .font(AviaryFont.display(28, weight: .bold))
                            .tracking(-0.025 * 28)
                            .foregroundStyle(t.ink)
                        Text(payoutText + " released to \(pilotName)")
                            .font(AviaryFont.body(13))
                            .foregroundStyle(t.ink3)
                            .padding(.top, 4)

                        ratingCard
                            .padding(.top, 28)
                        tipCard
                            .padding(.top, 12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                PrimaryButton(title: hasSubmitted ? "Submitted" : "Submit rating",
                              enabled: !hasSubmitted,
                              action: submit)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
        .onAppear { startShowcaseScriptIfNeeded() }
        .onDisappear {
            showcaseTask?.cancel()
            showcaseTask = nil
        }
        .onChange(of: demoStore.showcaseStep) { _, _ in
            startShowcaseScriptIfNeeded()
        }
    }

    private var ratingCard: some View {
        AviaryCard(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Avatar(size: 40, initials: "CP", background: t.accentSoft)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Rate \(pilotName)")
                            .font(AviaryFont.body(14, weight: .semibold))
                            .foregroundStyle(t.ink)
                        Text(pilotRating + " · DJI Mavic 3")
                            .font(AviaryFont.body(12))
                            .foregroundStyle(t.ink3)
                    }
                    Spacer()
                }
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { n in
                        Button { stars = n } label: {
                            AviaryIcon(name: n <= stars ? "star.fill" : "star",
                                       size: 36, stroke: 1.6,
                                       color: n <= stars ? t.warn : t.ink4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)

                FlowLayout(spacing: 6) {
                    ForEach(availableTags, id: \.self) { tag in
                        Button { toggle(tag) } label: {
                            Chip(text: tag, style: tags.contains(tag) ? .accent : .surface)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var tipCard: some View {
        AviaryCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Add a tip (optional)")
                    .font(AviaryFont.body(13, weight: .semibold))
                    .foregroundStyle(t.ink2)
                HStack(spacing: 8) {
                    ForEach(tipOptions, id: \.idx) { option in
                        Button {
                            tipIdx = (tipIdx == option.idx) ? nil : option.idx
                        } label: {
                            Text(option.label)
                                .font(AviaryFont.body(14, weight: .semibold))
                                .foregroundStyle(tipIdx == option.idx ? t.accentInk : t.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(tipIdx == option.idx ? t.accent : t.surface2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(tipIdx == option.idx ? t.accent : t.line)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func toggle(_ tag: String) {
        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
    }

    private func submit() {
        hasSubmitted = true
    }

    private func startShowcaseScriptIfNeeded() {
        guard demoStore.isOn,
              demoStore.showcaseStep == .customerRate else { return }
        showcaseTask?.cancel()
        tags = []
        tipIdx = nil
        hasSubmitted = false
        showcaseTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 700_000_000)
                guard demoStore.showcaseStep == .customerRate else { return }
                for tag in showcaseTagPicks {
                    guard demoStore.showcaseStep == .customerRate else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        _ = tags.insert(tag)
                    }
                    try await Task.sleep(nanoseconds: 360_000_000)
                }
                try await Task.sleep(nanoseconds: 280_000_000)
                guard demoStore.showcaseStep == .customerRate else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    tipIdx = 2 // $10
                }
                try await Task.sleep(nanoseconds: 700_000_000)
                guard demoStore.showcaseStep == .customerRate, !hasSubmitted else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    submit()
                }
            } catch {
                return
            }
        }
    }
}
