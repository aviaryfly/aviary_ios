import CoreLocation
import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var demoStore: DemoModeStore

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
        .overlay(alignment: .top) {
            if let step = demoStore.showcaseStep {
                DemoShowcaseHUD(step: step,
                                progressText: demoStore.showcaseProgressText,
                                stepProgress: demoStore.progressInStep,
                                totalProgress: demoStore.totalProgress,
                                upcomingStep: demoStore.upcomingStep,
                                isPaused: demoStore.isPaused,
                                onTogglePause: { demoStore.togglePause() },
                                onStop: { demoStore.stopShowcase() })
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: stateKey)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: demoStore.showcaseStep)
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
        ZStack {
            switch profile.role {
            case .pilot:
                PilotRootView(themeManager: themeManager, profile: profile)
                    .transition(.opacity)
            case .customer:
                CustomerRootView(themeManager: themeManager, profile: profile)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: profile.role)
    }
}

private struct DemoShowcaseHUD: View {
    @Environment(\.theme) private var t
    let step: DemoShowcaseStep
    let progressText: String?
    let stepProgress: Double
    let totalProgress: Double
    let upcomingStep: DemoShowcaseStep?
    let isPaused: Bool
    var onTogglePause: () -> Void
    var onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(t.accent)
                    AviaryIcon(name: step.role == .pilot ? "drone" : "briefcase",
                               size: 16,
                               color: t.accentInk)
                }
                .frame(width: 32, height: 32)
                .opacity(isPaused ? 0.55 : 1)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(progressText ?? "Demo")
                            .font(AviaryFont.mono(11, weight: .semibold))
                            .foregroundStyle(t.accent)
                        if isPaused {
                            Text("PAUSED")
                                .font(AviaryFont.mono(10, weight: .heavy))
                                .foregroundStyle(t.accentInk)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(t.accent))
                        }
                        Text(step.title)
                            .font(AviaryFont.body(13, weight: .semibold))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                    }
                    Text(secondaryLine)
                        .font(AviaryFont.body(11))
                        .foregroundStyle(t.ink3)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button(action: onTogglePause) {
                    AviaryIcon(name: isPaused ? "play" : "pause",
                               size: 14,
                               color: t.ink2)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(t.surface2))
                }
                .buttonStyle(.plain)

                Button(action: onStop) {
                    AviaryIcon(name: "x", size: 15, color: t.ink2)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(t.surface2))
                }
                .buttonStyle(.plain)
            }

            DemoProgressBar(stepProgress: stepProgress,
                            totalProgress: totalProgress,
                            tint: t.accent,
                            track: t.line)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(t.surface.opacity(0.96))
                .shadow(color: .black.opacity(0.12), radius: 18, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(t.lineStrong)
        )
    }

    private var secondaryLine: String {
        if let upcomingStep, stepProgress > 0.7 {
            return "Up next · \(upcomingStep.title)"
        }
        return step.subtitle
    }
}

private struct DemoProgressBar: View {
    let stepProgress: Double
    let totalProgress: Double
    let tint: Color
    let track: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(track.opacity(0.45))
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, width * CGFloat(totalProgress)))
                    .animation(.linear(duration: 0.12), value: totalProgress)
            }
        }
        .frame(height: 3)
        .clipShape(Capsule())
    }
}

// MARK: - Pilot root

struct PilotRootView: View {
    @ObservedObject var themeManager: ThemeManager
    let profile: UserProfile
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore
    @State private var tab: PilotTab

    @State private var showAcceptPing: Bool
    @State private var showGigDetail: Bool
    @State private var showInFlight: Bool
    @State private var showMessages: Bool = false
    @State private var showNearbyGigsMap: Bool
    @State private var selectedGig: AviaryJob?
    @State private var selectedDemoGig: DemoGig?

    init(themeManager: ThemeManager, profile: UserProfile) {
        self.themeManager = themeManager
        self.profile = profile
        let env = ProcessInfo.processInfo.environment
        let initialTab = env["AVIARY_DEMO_TAB"].flatMap(PilotTab.init(rawValue:)) ?? .home
        let sheet = env["AVIARY_DEMO_SHEET"]
        _tab = State(initialValue: initialTab)
        _showAcceptPing = State(initialValue: sheet == "heroFlow")
        _showGigDetail = State(initialValue: sheet == "gigDetail")
        _showInFlight = State(initialValue: sheet == "inFlight")
        _showNearbyGigsMap = State(initialValue: sheet == "nearbyMap")
    }

    var body: some View {
        Group {
            switch tab {
            case .home:
                HomeScreen(
                    profile: profile,
                    onOpenAcceptPing: { showAcceptPing = true },
                    onOpenGigDetail: {
                        selectedGig = nil
                        selectedDemoGig = nil
                        showGigDetail = true
                    },
                    onOpenNearbyGigs: { showNearbyGigsMap = true }
                )
            case .gigs:
                GigListScreen(
                    profile: profile,
                    onOpenGig: { gig in
                        selectedGig = gig
                        selectedDemoGig = nil
                        showGigDetail = true
                    },
                    onOpenDemoGig: { demo in
                        selectedGig = nil
                        selectedDemoGig = demo
                        showGigDetail = true
                    }
                )
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
                .environmentObject(demoStore)
                .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        }
        .sheet(isPresented: $showGigDetail) {
            GigDetailScreen(job: selectedGig,
                            demoGig: selectedDemoGig,
                            pilotProfile: profile,
                            onAccept: {
                let acceptedBackendGig = selectedGig != nil && !demoStore.isOn
                showGigDetail = false
                if acceptedBackendGig {
                    tab = .fly
                    selectedGig = nil
                    selectedDemoGig = nil
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
                .environmentObject(demoStore)
        }
        .sheet(isPresented: $showMessages) {
            MessagesScreen(profile: profile, showsCloseButton: true)
                .environment(\.theme, t)
                .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        }
        .sheet(isPresented: $showNearbyGigsMap) {
            NearbyGigsMapScreen(activeJob: nil)
                .environment(\.theme, t)
                .environmentObject(demoStore)
                .preferredColorScheme(themeManager.theme == .hangar ? .dark : .light)
        }
        .onAppear {
            applyShowcaseStep(demoStore.showcaseStep)
        }
        .onChange(of: demoStore.showcaseStep) { _, step in
            applyShowcaseStep(step)
        }
        .onChange(of: demoStore.showcaseRunID) { _, _ in
            applyShowcaseStep(demoStore.showcaseStep)
        }
    }

    private enum PilotShowcaseSheet {
        case acceptPing, gigDetail, inFlight, messages, nearbyMap
    }

    private func applyShowcaseStep(_ step: DemoShowcaseStep?) {
        guard let step else {
            setShowcaseSheet(nil)
            return
        }
        guard step.role == .pilot else {
            setShowcaseSheet(nil)
            return
        }

        switch step {
        case .pilotHome:
            setShowcaseSheet(nil)
            tab = .home
        case .pilotGigDetail:
            selectedGig = nil
            selectedDemoGig = nil
            // Detail opens as if tapped from the gig board the previous step left us on,
            // so don't yank the user back to home.
            setShowcaseSheet(.gigDetail)
        case .pilotAcceptPing:
            setShowcaseSheet(.acceptPing)
        case .pilotGigBoard:
            setShowcaseSheet(nil)
            tab = .gigs
        case .pilotNearbyMap:
            // FlyHubScreen owns its own NearbyGigsMap sheet via its showMapHome state.
            setShowcaseSheet(nil)
            tab = .fly
        case .pilotFly, .pilotChecklist, .pilotWeather, .pilotDeliverables, .pilotReview:
            setShowcaseSheet(nil)
            tab = .fly
        case .pilotInFlight:
            setShowcaseSheet(.inFlight)
            tab = .fly
        case .pilotMessages:
            setShowcaseSheet(.messages)
            tab = .me
        case .pilotProfile, .pilotEarnings:
            setShowcaseSheet(nil)
            tab = .me
        default:
            setShowcaseSheet(nil)
        }
    }

    /// Idempotent sheet selector — only flips bools whose desired value differs,
    /// avoiding sheet dismiss/present flicker when an in-screen auto-action already set state.
    private func setShowcaseSheet(_ which: PilotShowcaseSheet?) {
        let wantAcceptPing = (which == .acceptPing)
        let wantGigDetail = (which == .gigDetail)
        let wantInFlight = (which == .inFlight)
        let wantMessages = (which == .messages)
        let wantNearbyMap = (which == .nearbyMap)

        if showAcceptPing != wantAcceptPing { showAcceptPing = wantAcceptPing }
        if showGigDetail != wantGigDetail { showGigDetail = wantGigDetail }
        if showInFlight != wantInFlight { showInFlight = wantInFlight }
        if showMessages != wantMessages { showMessages = wantMessages }
        if showNearbyGigsMap != wantNearbyMap { showNearbyGigsMap = wantNearbyMap }

        if which != .gigDetail {
            if selectedGig != nil { selectedGig = nil }
            if selectedDemoGig != nil { selectedDemoGig = nil }
        }
    }
}

// MARK: - Customer root

struct CustomerRootView: View {
    @ObservedObject var themeManager: ThemeManager
    let profile: UserProfile
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore
    @State private var tab: CustomerTab
    @State private var showMessages: Bool = false
    @State private var showMatching: Bool = false
    @State private var showRate: Bool = false

    init(themeManager: ThemeManager, profile: UserProfile) {
        self.themeManager = themeManager
        self.profile = profile
        let env = ProcessInfo.processInfo.environment
        let initialTab = env["AVIARY_DEMO_TAB"].flatMap(CustomerTab.init(rawValue:)) ?? .home
        _tab = State(initialValue: initialTab)
    }

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
        .fullScreenCover(isPresented: $showMatching) {
            CustomerMatchingScreen()
                .environment(\.theme, t)
                .environmentObject(demoStore)
        }
        .fullScreenCover(isPresented: $showRate) {
            CustomerRateScreen()
                .environment(\.theme, t)
                .environmentObject(demoStore)
        }
        .onAppear {
            applyShowcaseStep(demoStore.showcaseStep)
        }
        .onChange(of: demoStore.showcaseStep) { _, step in
            applyShowcaseStep(step)
        }
        .onChange(of: demoStore.showcaseRunID) { _, _ in
            applyShowcaseStep(demoStore.showcaseStep)
        }
    }

    private func applyShowcaseStep(_ step: DemoShowcaseStep?) {
        guard let step else {
            setCustomerOverlays(messages: false, matching: false, rate: false)
            return
        }
        guard step.role == .customer else {
            setCustomerOverlays(messages: false, matching: false, rate: false)
            return
        }

        switch step {
        case .customerHome:
            setCustomerOverlays(messages: false, matching: false, rate: false)
            tab = .home
        case .customerPostJob:
            setCustomerOverlays(messages: false, matching: false, rate: false)
            tab = .postJob
        case .customerMatching:
            // Stay on .postJob underneath so the matching cover layers over the
            // posting context the user just left.
            tab = .postJob
            setCustomerOverlays(messages: false, matching: true, rate: false)
        case .customerMyJobs, .customerJobDetail:
            setCustomerOverlays(messages: false, matching: false, rate: false)
            tab = .myJobs
        case .customerMessages:
            setCustomerOverlays(messages: false, matching: false, rate: false)
            tab = .messages
        case .customerRate:
            tab = .myJobs
            setCustomerOverlays(messages: false, matching: false, rate: true)
        case .customerProfile:
            setCustomerOverlays(messages: false, matching: false, rate: false)
            tab = .me
        default:
            break
        }
    }

    private func setCustomerOverlays(messages: Bool, matching: Bool, rate: Bool) {
        if showMessages != messages { showMessages = messages }
        if showMatching != matching { showMatching = matching }
        if showRate != rate { showRate = rate }
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
    @State private var showWeatherBriefing: Bool = false
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
                                   : nil)

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
                            toolRow(icon: "cloud", title: "Weather briefing",
                                    sub: "METAR & TAF for here and your next gig") { showWeatherBriefing = true }
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
                            toolRow(icon: "cloud", title: "Weather briefing",
                                    sub: "METAR & TAF for here and \(activeJob.displayClient)") { showWeatherBriefing = true }
                            toolRow(icon: "upload", title: "Hand off deliverables",
                                    sub: activeJob.displayDeliverables.joined(separator: " · ")) { showUpload = true }
                            toolRow(icon: "check-circle", title: "Complete & rate",
                                    sub: "Wrap up \(activeJob.displayClient)") { showReview = true }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    } else {
                        noActiveGigCard
                            .padding(.horizontal, 16)
                            .padding(.top, 6)

                        SectionTitle(text: "Mission tools")
                            .padding(.horizontal, 20)
                            .padding(.top, 22)
                            .padding(.bottom, 8)

                        VStack(spacing: 10) {
                            toolRow(icon: "navigation", title: "Map of nearby gigs",
                                    sub: "Pilot map view") { showMapHome = true }
                            toolRow(icon: "cloud", title: "Weather briefing",
                                    sub: "METAR & TAF for your current location") { showWeatherBriefing = true }
                            toolRow(icon: "upload", title: "Hand off deliverables",
                                    sub: "Available once you have an active gig") { showUpload = true }
                            toolRow(icon: "check-circle", title: "Complete & rate",
                                    sub: "Available once you have an active gig") { showReview = true }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .sheet(isPresented: $showPreFlight) {
            PreFlightScreen(onTakeoff: { showPreFlight = false; onTakeoff() },
                            onBack: { showPreFlight = false })
                .environment(\.theme, t)
                .environmentObject(demoStore)
        }
        .sheet(isPresented: $showUpload) {
            UploadScreen(job: activeJob, onSubmit: { _ in
                showUpload = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showReview = true
                }
            })
            .environment(\.theme, t)
            .environmentObject(demoStore)
        }
        .sheet(isPresented: $showReview) {
            ReviewCompleteScreen(job: activeJob,
                                 pilotID: profile.id,
                                 onCompleted: {
                                     activeJob = nil
                                     Task { await loadActiveJob() }
                                 })
                .environment(\.theme, t)
                .environmentObject(demoStore)
        }
        .sheet(isPresented: $showMapHome) {
            NearbyGigsMapScreen(activeJob: activeJob)
                .environment(\.theme, t)
                .environmentObject(demoStore)
        }
        .sheet(isPresented: $showWeatherBriefing) {
            WeatherBriefingScreen(
                activeJob: demoStore.isOn ? nil : activeJob,
                demoMissionLabel: demoStore.isOn ? "Real estate · 1247 Vine St" : nil,
                demoMissionAddress: demoStore.isOn ? "1247 Vine St, Berkeley, CA" : nil,
                demoMissionCoordinate: demoStore.isOn
                    ? CLLocationCoordinate2D(latitude: 37.8814, longitude: -122.2683)
                    : nil
            )
            .environment(\.theme, t)
            .environmentObject(demoStore)
        }
        .task(id: "\(profile.id.uuidString)-\(demoStore.isOn)") {
            await loadActiveJob()
        }
        .onAppear {
            applyShowcaseStep(demoStore.showcaseStep)
        }
        .onChange(of: demoStore.showcaseStep) { _, step in
            applyShowcaseStep(step)
        }
        .onChange(of: demoStore.showcaseRunID) { _, _ in
            applyShowcaseStep(demoStore.showcaseStep)
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

    private enum FlyHubShowcaseSheet {
        case preflight, upload, review, mapHome, weather
    }

    private func applyShowcaseStep(_ step: DemoShowcaseStep?) {
        guard let step else {
            setMissionSheet(nil)
            return
        }
        guard step.role == .pilot else {
            setMissionSheet(nil)
            return
        }

        switch step {
        case .pilotFly:
            setMissionSheet(nil)
        case .pilotChecklist:
            setMissionSheet(.preflight)
        case .pilotWeather:
            setMissionSheet(.weather)
        case .pilotNearbyMap:
            setMissionSheet(.mapHome)
        case .pilotDeliverables:
            setMissionSheet(.upload)
        case .pilotReview:
            setMissionSheet(.review)
        default:
            setMissionSheet(nil)
        }
    }

    private func setMissionSheet(_ which: FlyHubShowcaseSheet?) {
        let wantPreflight = (which == .preflight)
        let wantUpload = (which == .upload)
        let wantReview = (which == .review)
        let wantMap = (which == .mapHome)
        let wantWeather = (which == .weather)

        if showPreFlight != wantPreflight { showPreFlight = wantPreflight }
        if showUpload != wantUpload { showUpload = wantUpload }
        if showReview != wantReview { showReview = wantReview }
        if showMapHome != wantMap { showMapHome = wantMap }
        if showWeatherBriefing != wantWeather { showWeatherBriefing = wantWeather }
    }

    private func closeMissionSheets() {
        showPreFlight = false
        showUpload = false
        showReview = false
        showMapHome = false
        showWeatherBriefing = false
    }

    private var noActiveGigCard: some View {
        AviaryCard(padding: 18, shadowed: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Chip(text: "NO ACTIVE GIG", style: .neutral)
                    Spacer()
                }
                Text("Ready to fly?")
                    .font(AviaryFont.display(22, weight: .bold))
                    .tracking(-0.02 * 22)
                    .foregroundStyle(t.ink)
                Text("Accept a gig to unlock the pre-flight checklist and take-off flow.")
                    .font(AviaryFont.body(13))
                    .foregroundStyle(t.ink3)
                    .lineSpacing(2)
                PrimaryButton(title: "Browse gigs",
                              systemTrailing: "arrow.right",
                              action: onBrowseGigs)
                    .padding(.top, 4)
            }
        }
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
                    SecondaryButton(title: "Checklist", fullWidth: true) { showPreFlight = true }
                        .frame(maxWidth: .infinity)
                    PrimaryButton(title: "Take off",
                                  systemTrailing: "arrow.right",
                                  action: onTakeoff)
                        .frame(maxWidth: .infinity)
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
