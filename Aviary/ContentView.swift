import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    @State private var onboarded: Bool = false

    var body: some View {
        Group {
            if !onboarded {
                OnboardingFlow(done: $onboarded)
            } else {
                RootView(themeManager: themeManager)
            }
        }
        .environment(\.theme, themeManager.tokens)
        .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        .tint(themeManager.tokens.accent)
    }
}

struct RootView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.theme) private var t
    @State private var tab: AppTab = .home

    @State private var showAcceptPing: Bool = false
    @State private var showGigDetail: Bool = false
    @State private var showInFlight: Bool = false
    @State private var showMessages: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:
                    HomeScreen(
                        onOpenAcceptPing: { showAcceptPing = true },
                        onOpenGigDetail: { showGigDetail = true }
                    )
                case .gigs:
                    GigListScreen(onOpenGig: { showGigDetail = true })
                case .fly:
                    FlyHubScreen(onTakeoff: { showInFlight = true })
                case .earn:
                    EarningsScreen()
                case .me:
                    ProfileScreen(themeManager: themeManager,
                                  onOpenMessages: { showMessages = true })
                }
            }
            .padding(.bottom, 84)

            AviaryTabBar(selection: $tab)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAcceptPing) {
            HeroFlowView()
                .environment(\.theme, t)
                .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        }
        .sheet(isPresented: $showGigDetail) {
            GigDetailScreen(onAccept: {
                showGigDetail = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showAcceptPing = true
                }
            })
            .environment(\.theme, t)
            .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        }
        .fullScreenCover(isPresented: $showInFlight) {
            InFlightScreen()
        }
        .sheet(isPresented: $showMessages) {
            MessagesScreen()
                .environment(\.theme, t)
                .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        }
    }
}

// MARK: - Fly hub screen (entry point for active gig flow)

struct FlyHubScreen: View {
    @Environment(\.theme) private var t
    var onTakeoff: () -> Void

    @State private var showPreFlight: Bool = false
    @State private var showUpload: Bool = false
    @State private var showReview: Bool = false
    @State private var showMapHome: Bool = false

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PageHeader(title: "Fly", subtitle: "Active gig · Real estate · 1247 Vine St")

                    AviaryCard(padding: 18, shadowed: true) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Chip(text: "EN ROUTE", style: .good)
                                Spacer()
                                Text("4 min")
                                    .font(AviaryFont.mono(14, weight: .semibold))
                                    .foregroundStyle(t.ink)
                            }
                            Text("Pre-flight ready")
                                .font(AviaryFont.display(22, weight: .bold))
                                .tracking(-0.02 * 22)
                                .foregroundStyle(t.ink)
                            Text("Battery, SD card, LAANC clearance — confirmed.")
                                .font(AviaryFont.body(13))
                                .foregroundStyle(t.ink3)
                                .lineSpacing(2)
                            HStack(spacing: 10) {
                                SecondaryButton(title: "Checklist") { showPreFlight = true }
                                    .frame(maxWidth: 150)
                                PrimaryButton(title: "Take off",
                                              systemTrailing: "arrow.right",
                                              action: onTakeoff)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                    SectionTitle(text: "Mission tools")
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 8)

                    VStack(spacing: 10) {
                        toolRow(icon: "navigation", title: "Map of nearby gigs",
                                sub: "Pilot map view") { showMapHome = true }
                        toolRow(icon: "upload", title: "Hand off deliverables",
                                sub: "Auto-upload over Wi-Fi") { showUpload = true }
                        toolRow(icon: "check-circle", title: "Complete & rate",
                                sub: "Wrap up the gig") { showReview = true }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showPreFlight) {
            PreFlightScreen(onTakeoff: { showPreFlight = false; onTakeoff() },
                            onBack: { showPreFlight = false })
                .environment(\.theme, t)
        }
        .sheet(isPresented: $showUpload) {
            UploadScreen(onSubmit: {
                showUpload = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showReview = true
                }
            })
            .environment(\.theme, t)
        }
        .sheet(isPresented: $showReview) {
            ReviewCompleteScreen()
                .environment(\.theme, t)
        }
        .sheet(isPresented: $showMapHome) {
            MapHomeScreen()
                .environment(\.theme, t)
        }
    }

    private func toolRow(icon: String, title: String, sub: String,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(t.accentSoft)
                    AviaryIcon(name: icon, size: 20, color: t.accent)
                }
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(AviaryFont.body(14, weight: .semibold))
                        .foregroundStyle(t.ink)
                    Text(sub)
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink3)
                }
                Spacer()
                AviaryIcon(name: "chevron-right", size: 16, color: t.ink4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(t.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous).strokeBorder(t.line)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    ContentView()
}
