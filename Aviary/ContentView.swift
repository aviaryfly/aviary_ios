import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        Group {
            switch auth.state {
            case .loading:
                SplashView()
            case .signedOut:
                OnboardingFlow()
            case .signedIn(let signedInProfile):
                RootView(
                    themeManager: themeManager,
                    profile: auth.displayedProfile ?? signedInProfile
                )
            }
        }
        .environment(\.theme, themeManager.tokens)
        .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        .tint(themeManager.tokens.accent)
        .animation(.easeInOut(duration: 0.25), value: stateKey)
    }

    private var stateKey: String {
        switch auth.state {
        case .loading:   return "loading"
        case .signedOut: return "signedOut"
        case .signedIn:  return "signedIn:\(auth.displayedProfile?.id.uuidString ?? "?")"
        }
    }
}

private struct SplashView: View {
    @Environment(\.theme) private var t

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 14) {
                AviaryLogo(size: 56, color: t.accent)
                Text("aviary")
                    .font(AviaryFont.body(22, weight: .bold))
                    .tracking(-0.02 * 22)
                    .foregroundStyle(t.ink)
                ProgressView()
                    .tint(t.accent)
                    .padding(.top, 6)
            }
        }
    }
}

struct RootView: View {
    @ObservedObject var themeManager: ThemeManager
    let profile: UserProfile
    @Environment(\.theme) private var t

    var body: some View {
        switch profile.role {
        case .pilot:
            PilotRootView(themeManager: themeManager, profile: profile)
        case .customer:
            CustomerRootView(themeManager: themeManager, profile: profile)
        }
    }
}

// MARK: - Pilot root

struct PilotRootView: View {
    @ObservedObject var themeManager: ThemeManager
    let profile: UserProfile
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore
    @State private var tab: PilotTab = .home

    @State private var showAcceptPing: Bool = false
    @State private var showGigDetail: Bool = false
    @State private var showInFlight: Bool = false
    @State private var showMessages: Bool = false
    @State private var selectedGig: AviaryJob?

    var body: some View {
        Group {
            switch tab {
            case .home:
                HomeScreen(
                    profile: profile,
                    onOpenAcceptPing: { showAcceptPing = true },
                    onOpenGigDetail: {
                        selectedGig = nil
                        showGigDetail = true
                    }
                )
            case .gigs:
                GigListScreen(profile: profile, onOpenGig: { gig in
                    selectedGig = gig
                    showGigDetail = true
                })
            case .fly:
                FlyHubScreen(
                    profile: profile,
                    onBrowseGigs: { tab = .gigs },
                    onTakeoff: { showInFlight = true }
                )
            case .me:
                ProfileScreen(themeManager: themeManager,
                              profile: profile,
                              onOpenMessages: { showMessages = true })
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AviaryTabBar(selection: $tab)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAcceptPing) {
            HeroFlowView()
                .environment(\.theme, t)
                .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        }
        .sheet(isPresented: $showGigDetail) {
            GigDetailScreen(job: selectedGig, pilotProfile: profile, onAccept: {
                let acceptedBackendGig = selectedGig != nil && !demoStore.isOn
                showGigDetail = false
                if acceptedBackendGig {
                    tab = .fly
                    selectedGig = nil
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showAcceptPing = true
                    }
                }
            })
            .environment(\.theme, t)
            .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        }
        .fullScreenCover(isPresented: $showInFlight) {
            InFlightScreen()
        }
        .sheet(isPresented: $showMessages) {
            MessagesScreen(profile: profile, showsCloseButton: true)
                .environment(\.theme, t)
                .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        }
    }
}

// MARK: - Customer root

struct CustomerRootView: View {
    @ObservedObject var themeManager: ThemeManager
    let profile: UserProfile
    @Environment(\.theme) private var t
    @State private var tab: CustomerTab = .home
    @State private var showMessages: Bool = false

    var body: some View {
        Group {
            switch tab {
            case .home:
                CustomerHomeScreen(profile: profile,
                                   onPostJob: { tab = .postJob })
            case .postJob:
                ClientRequestScreen(profile: profile, onPosted: { _ in tab = .myJobs })
            case .myJobs:
                MyJobsScreen(profile: profile)
            case .messages:
                MessagesScreen(profile: profile, showsCloseButton: false)
            case .me:
                ProfileScreen(themeManager: themeManager,
                              profile: profile,
                              onOpenMessages: { showMessages = true })
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AviaryTabBar(selection: $tab)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showMessages) {
            MessagesScreen(profile: profile, showsCloseButton: true)
                .environment(\.theme, t)
                .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        }
    }
}

// MARK: - Fly hub screen (entry point for active gig flow)

struct FlyHubScreen: View {
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore
    let profile: UserProfile
    var onBrowseGigs: () -> Void = {}
    var onTakeoff: () -> Void

    @State private var showPreFlight: Bool = false
    @State private var showUpload: Bool = false
    @State private var showReview: Bool = false
    @State private var showMapHome: Bool = false
    @State private var activeJob: AviaryJob?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PageHeader(title: "Fly",
                               subtitle: demoStore.isOn
                                   ? "Active gig · Real estate · 1247 Vine St"
                                   : "No active gig")

                    if demoStore.isOn {
                        activeMissionCard(job: nil)
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
                    } else if isLoading {
                        FeatureStateCard(icon: "drone",
                                         title: "Loading active gig",
                                         message: "Checking whether a customer has a mission assigned to you.")
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                            .padding(.bottom, 24)
                    } else if let errorMessage {
                        FeatureStateCard(icon: "cloud",
                                         title: "Couldn't load active gig",
                                         message: errorMessage,
                                         buttonTitle: "Try again",
                                         action: { Task { await loadActiveJob() } })
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                            .padding(.bottom, 24)
                    } else if let activeJob {
                        activeMissionCard(job: activeJob)
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
                                    sub: activeJob.displayDeliverables.joined(separator: " · ")) { showUpload = true }
                            toolRow(icon: "check-circle", title: "Complete & rate",
                                    sub: "Wrap up \(activeJob.displayClient)") { showReview = true }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    } else {
                        FeatureStateCard(icon: "drone",
                                         title: "No active gig",
                                         message: "Accept a gig to unlock the pre-flight checklist, mission tools, upload flow, and completion review.",
                                         buttonTitle: "Browse gigs",
                                         action: onBrowseGigs)
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 24)
                    }
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
        .task(id: "\(profile.id.uuidString)-\(demoStore.isOn)") {
            await loadActiveJob()
        }
    }

    private func loadActiveJob() async {
        guard !demoStore.isOn else {
            activeJob = nil
            isLoading = false
            errorMessage = nil
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            activeJob = try await AviaryDataService.shared.activePilotJob(for: profile.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func activeMissionCard(job: AviaryJob?) -> some View {
        AviaryCard(padding: 18, shadowed: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Chip(text: job?.statusLabel.uppercased() ?? "EN ROUTE", style: .good)
                    Spacer()
                    Text(job?.durationText ?? "4 min")
                        .font(AviaryFont.mono(14, weight: .semibold))
                        .foregroundStyle(t.ink)
                }
                Text(job?.displayTitle ?? "Pre-flight ready")
                    .font(AviaryFont.display(22, weight: .bold))
                    .tracking(-0.02 * 22)
                    .foregroundStyle(t.ink)
                Text(job.map { "\($0.displayAddress) · \($0.scheduledText) · \($0.payoutText)" }
                     ?? "Battery, SD card, LAANC clearance — confirmed.")
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
    let demoStore = DemoModeStore()
    return ContentView()
        .environmentObject(AuthViewModel(demoStore: demoStore))
        .environmentObject(demoStore)
}
