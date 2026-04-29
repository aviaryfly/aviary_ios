import SwiftUI
import MapKit
import CoreLocation

// MARK: - Demo gig payload (drives demo-mode list + detail)

struct DemoGig: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var address: String
    var distance: String
    var payout: String
    var schedule: String
    var jobType: String
    var duration: String
    var startText: String
    var deliverables: [String]
    var client: String
    var clientMeta: String
    var icon: String
    var iconUsesGood: Bool = false
    var coordinate: CLLocationCoordinate2D

    var priceValue: Int { Int(payout.filter(\.isNumber)) ?? 0 }
    var distanceValue: Double {
        Double(distance.replacingOccurrences(of: " mi", with: "")) ?? .greatestFiniteMagnitude
    }

    static func == (lhs: DemoGig, rhs: DemoGig) -> Bool { lhs.id == rhs.id }
}

// MARK: - Gig list

struct GigListScreen: View {
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore
    let profile: UserProfile
    @State private var sortIdx: Int = 0
    @State private var jobs: [AviaryJob] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showcaseScrollTask: Task<Void, Never>?
    var onOpenGig: (AviaryJob?) -> Void = { _ in }
    var onOpenDemoGig: (DemoGig) -> Void = { _ in }

    private let sorts = ["Best match", "Highest pay", "Closest", "Soonest"]
    private let demoGigs: [DemoGig] = [
        DemoGig(
            title: "Construction site progress",
            address: "500 Folsom St, San Francisco",
            distance: "0.8 mi",
            payout: "$485",
            schedule: "Tomorrow · 9:00am · 90 min",
            jobType: "Construction",
            duration: "90 min",
            startText: "Tomorrow, 9:00 AM",
            deliverables: [
                "20 progress photos · 4K",
                "Top-down site map",
                "Edited flyover (45 sec)"
            ],
            client: "BuildCo Inc.",
            clientMeta: "★ 4.7 · 12 gigs posted",
            icon: "briefcase",
            coordinate: CLLocationCoordinate2D(latitude: 37.7853, longitude: -122.3941)
        ),
        DemoGig(
            title: "Roof inspection — duplex",
            address: "22 Hillside Ave, Berkeley",
            distance: "2.4 mi",
            payout: "$220",
            schedule: "Today · 4:30pm · 30 min",
            jobType: "Inspection",
            duration: "30 min",
            startText: "Today, 4:30 PM",
            deliverables: [
                "Tight roof orbit (4K)",
                "Close-up shingle detail shots",
                "Damage call-outs (PDF)"
            ],
            client: "Hillside Homeowners",
            clientMeta: "★ 4.8 · 6 gigs posted",
            icon: "cert",
            coordinate: CLLocationCoordinate2D(latitude: 37.8849, longitude: -122.2517)
        ),
        DemoGig(
            title: "Wedding aerial coverage",
            address: "Tilden Park, Berkeley",
            distance: "3.1 mi",
            payout: "$780",
            schedule: "Sat · 5:00pm · 2 hr",
            jobType: "Event",
            duration: "2 hr",
            startText: "Saturday, 5:00 PM",
            deliverables: [
                "Ceremony aerial coverage",
                "Couple cinematic flyover",
                "Edited 60-sec highlight reel"
            ],
            client: "Hartley & Co.",
            clientMeta: "★ 4.9 · Premium client",
            icon: "star",
            iconUsesGood: true,
            coordinate: CLLocationCoordinate2D(latitude: 37.8956, longitude: -122.2429)
        ),
        DemoGig(
            title: "Real estate listing",
            address: "1247 Vine St, Berkeley",
            distance: "1.2 mi",
            payout: "$340",
            schedule: "Today · 3:30pm · 45 min",
            jobType: "Real estate",
            duration: "45 min",
            startText: "Today, 3:30 PM",
            deliverables: [
                "12 exterior photos · 4K",
                "60-sec cinematic flyover",
                "Twilight shot (post-sunset)"
            ],
            client: "Marin Realty Co.",
            clientMeta: "★ 4.9 · 28 gigs posted",
            icon: "camera",
            coordinate: CLLocationCoordinate2D(latitude: 37.8814, longitude: -122.2683)
        ),
        DemoGig(
            title: "Vineyard mapping",
            address: "Stags Leap District, Napa",
            distance: "42 mi",
            payout: "$1,250",
            schedule: "Wed · 8:00am · 4 hr",
            jobType: "Mapping",
            duration: "4 hr",
            startText: "Wednesday, 8:00 AM",
            deliverables: [
                "Orthomosaic at 2 cm/px",
                "Multispectral NDVI map",
                "Boundary overlay (KML)"
            ],
            client: "Stags Leap Vineyards",
            clientMeta: "★ 5.0 · Enterprise client",
            icon: "altitude",
            coordinate: CLLocationCoordinate2D(latitude: 38.4090, longitude: -122.3206)
        ),
        DemoGig(
            title: "Solar array inspection",
            address: "1820 Edgewater Dr, Oakland",
            distance: "5.6 mi",
            payout: "$310",
            schedule: "Sat · 11:00am · 45 min",
            jobType: "Inspection",
            duration: "45 min",
            startText: "Saturday, 11:00 AM",
            deliverables: [
                "Thermal sweep of 240 panels",
                "Hotspot call-outs (PDF)",
                "Pre/post imagery"
            ],
            client: "Sunhouse Energy",
            clientMeta: "★ 4.8 · 9 gigs posted",
            icon: "altitude",
            coordinate: CLLocationCoordinate2D(latitude: 37.7942, longitude: -122.2510)
        ),
        DemoGig(
            title: "Real estate twilight set",
            address: "910 Bay St, Sausalito",
            distance: "8.2 mi",
            payout: "$295",
            schedule: "Tomorrow · 6:45pm · 40 min",
            jobType: "Real estate",
            duration: "40 min",
            startText: "Tomorrow, 6:45 PM",
            deliverables: [
                "Twilight exterior photos",
                "30-sec dusk flyover",
                "Edited delivery set"
            ],
            client: "Bay Studios Realty",
            clientMeta: "★ 4.7 · 14 gigs posted",
            icon: "camera",
            coordinate: CLLocationCoordinate2D(latitude: 37.8590, longitude: -122.4853)
        ),
        DemoGig(
            title: "Pier time-lapse setup",
            address: "Embarcadero, San Francisco",
            distance: "4.0 mi",
            payout: "$410",
            schedule: "Friday · 7:00am · 90 min",
            jobType: "Construction",
            duration: "90 min",
            startText: "Friday, 7:00 AM",
            deliverables: [
                "Site overview at golden hour",
                "Top-down dock map",
                "30-sec edited reveal"
            ],
            client: "Pier 39 Holdings",
            clientMeta: "★ 4.9 · Premium client",
            icon: "briefcase",
            coordinate: CLLocationCoordinate2D(latitude: 37.8087, longitude: -122.4098)
        )
    ]

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                PageHeader(title: "Gigs", subtitle: subtitle) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(t.surface2)
                            .frame(width: 40, height: 40)
                        AviaryIcon(name: "sliders", size: 20, color: t.ink)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(sorts.enumerated()), id: \.0) { idx, label in
                            Button { sortIdx = idx } label: {
                                Text(label)
                                    .font(AviaryFont.body(12, weight: .semibold))
                                    .foregroundStyle(idx == sortIdx ? t.bg : t.ink2)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule().fill(idx == sortIdx ? t.ink : t.surface)
                                    )
                                    .overlay(
                                        Capsule().strokeBorder(idx == sortIdx ? .clear : t.line)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        Color.clear.frame(height: 1).id("gig-list-top")
                        content
                        Color.clear.frame(height: 1).id("gig-list-bottom")
                    }
                    .onAppear {
                        runShowcaseScroll(proxy)
                    }
                    .onChange(of: demoStore.showcaseStep) { _, _ in
                        runShowcaseScroll(proxy)
                    }
                    .onDisappear {
                        showcaseScrollTask?.cancel()
                    }
                }
            }
        }
        .task(id: "\(profile.id.uuidString)-\(demoStore.isOn)") {
            await loadJobs()
        }
    }

    private func runShowcaseScroll(_ proxy: ScrollViewProxy) {
        showcaseScrollTask?.cancel()
        guard demoStore.showcaseStep == .pilotGigBoard else { return }
        showcaseScrollTask = Task { @MainActor in
            sortIdx = 0
            do {
                try await Task.sleep(nanoseconds: 600_000_000)
                guard demoStore.showcaseStep == .pilotGigBoard else { return }
                withAnimation(.easeInOut(duration: 1.25)) {
                    proxy.scrollTo("gig-list-bottom", anchor: .bottom)
                }
                try await Task.sleep(nanoseconds: 1_500_000_000)
                guard demoStore.showcaseStep == .pilotGigBoard else { return }
                sortIdx = 1
                withAnimation(.easeInOut(duration: 0.9)) {
                    proxy.scrollTo("gig-list-top", anchor: .top)
                }
                try await Task.sleep(nanoseconds: 900_000_000)
                guard demoStore.showcaseStep == .pilotGigBoard else { return }
                sortIdx = 2
            } catch {
                return
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if demoStore.isOn {
            LazyVStack(spacing: 10) {
                ForEach(sortedDemoGigs) { gig in
                    Button { onOpenDemoGig(gig) } label: {
                        gigCard(gig)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        } else if isLoading {
            FeatureStateCard(icon: "compass",
                             title: "Loading nearby gigs",
                             message: "Checking open customer requests that match your service area.")
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        } else if let errorMessage {
            FeatureStateCard(icon: "cloud",
                             title: "Couldn't load gigs",
                             message: errorMessage,
                             buttonTitle: "Try again",
                             action: { Task { await loadJobs() } })
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        } else if sortedJobs.isEmpty {
            emptyState
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        } else {
            LazyVStack(spacing: 10) {
                ForEach(sortedJobs) { job in
                    Button { onOpenGig(job) } label: {
                        gigCard(job)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var subtitle: String {
        if demoStore.isOn {
            let nearby = demoGigs.filter { $0.distanceValue < 10 }.count
            return "\(nearby) within 10 mi · \(demoGigs.count) open"
        }
        if isLoading { return "Loading nearby requests" }
        if jobs.isEmpty { return "0 open requests" }
        return "\(jobs.count) open request\(jobs.count == 1 ? "" : "s")"
    }

    private var sortedJobs: [AviaryJob] {
        switch sortIdx {
        case 1:
            return jobs.sorted { ($0.payoutCents ?? 0) > ($1.payoutCents ?? 0) }
        case 2:
            return jobs.sorted { ($0.distanceMiles ?? .greatestFiniteMagnitude) < ($1.distanceMiles ?? .greatestFiniteMagnitude) }
        case 3:
            return jobs.sorted { $0.sortDate < $1.sortDate }
        default:
            return jobs.sorted { lhs, rhs in
                let lhsPayout = lhs.payoutCents ?? 0
                let rhsPayout = rhs.payoutCents ?? 0
                if lhsPayout != rhsPayout { return lhsPayout > rhsPayout }
                return (lhs.distanceMiles ?? 999) < (rhs.distanceMiles ?? 999)
            }
        }
    }

    private var sortedDemoGigs: [DemoGig] {
        switch sortIdx {
        case 1:
            return demoGigs.sorted { $0.priceValue > $1.priceValue }
        case 2:
            return demoGigs.sorted { $0.distanceValue < $1.distanceValue }
        case 3:
            return Array(demoGigs.reversed())
        default:
            return demoGigs
        }
    }

    private func loadJobs() async {
        guard !demoStore.isOn else {
            jobs = []
            isLoading = false
            errorMessage = nil
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            jobs = try await AviaryDataService.shared.availableGigs()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var emptyState: some View {
        FeatureStateCard(icon: "compass",
                         title: "No gigs nearby right now",
                         message: "Check back later or expand your search radius. We'll send a push when something matches.")
    }

    private func gigCard(_ g: DemoGig) -> some View {
        AviaryCard(padding: 14, shadowed: true) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(t.surface2)
                    AviaryIcon(name: g.icon, size: 22, stroke: 2,
                               color: g.iconUsesGood ? t.good : t.accent)
                }
                .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(g.title)
                            .font(AviaryFont.body(15, weight: .semibold))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(g.payout)
                            .font(AviaryFont.mono(16, weight: .semibold))
                            .foregroundStyle(t.ink)
                    }
                    Text("\(g.address) · \(g.distance)")
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                        .lineLimit(1)
                    Text(g.schedule)
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink4)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func gigCard(_ job: AviaryJob) -> some View {
        AviaryCard(padding: 14, shadowed: true) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(t.surface2)
                    AviaryIcon(name: icon(for: job), size: 22, stroke: 2, color: t.accent)
                }
                .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(job.displayTitle)
                            .font(AviaryFont.body(15, weight: .semibold))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(job.payoutText)
                            .font(AviaryFont.mono(16, weight: .semibold))
                            .foregroundStyle(t.ink)
                    }
                    Text("\(job.displayAddress) · \(job.distanceText)")
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                        .lineLimit(1)
                    Text("\(job.scheduledText) · \(job.durationText)")
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink4)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func icon(for job: AviaryJob) -> String {
        switch job.jobType?.lowercased() {
        case "inspection": return "cert"
        case "event": return "star"
        case "mapping": return "altitude"
        default: return "camera"
        }
    }

}

// MARK: - Gig detail

struct GigDetailScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let job: AviaryJob?
    let demoGig: DemoGig?
    let pilotProfile: UserProfile?
    @State private var isAccepting: Bool = false
    @State private var errorMessage: String?
    @State private var camera: MapCameraPosition = .automatic
    @State private var resolvedCoordinate: CLLocationCoordinate2D?
    var onAccept: () -> Void = {}

    init(job: AviaryJob?,
         demoGig: DemoGig? = nil,
         pilotProfile: UserProfile?,
         onAccept: @escaping () -> Void = {}) {
        self.job = job
        self.demoGig = demoGig
        self.pilotProfile = pilotProfile
        self.onAccept = onAccept
    }

    var body: some View {
        ZStack(alignment: .top) {
            t.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    mapHeader
                        .frame(height: 260)
                    HStack {
                        circleBtn(icon: "arrow-left") { dismiss() }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                ScrollView {
                    bodyContent
                        .padding(.horizontal, 22)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 28, bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0, topTrailingRadius: 28,
                                style: .continuous
                            )
                            .fill(t.surface)
                        )
                }
                .padding(.top, -24)
            }
        }
    }

    private var bodyContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Chip(text: chipText, style: .accent)
                    Text(titleText)
                        .font(AviaryFont.display(22, weight: .bold))
                        .tracking(-0.02 * 22)
                        .foregroundStyle(t.ink)
                    Text("\(addressText) · \(distanceText)")
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(payoutText)
                        .font(AviaryFont.mono(28, weight: .semibold))
                        .foregroundStyle(t.accent)
                    Text("est. payout")
                        .font(AviaryFont.body(11))
                        .foregroundStyle(t.ink4)
                }
            }
            .padding(.bottom, 18)

            HStack(spacing: 8) {
                stat(label: "Duration", value: durationStat, color: t.ink)
                stat(label: "Start", value: startStat, color: t.ink)
                stat(label: "Airspace", value: "Class G ✓", color: t.good)
            }
            .padding(.bottom, 18)

            SectionTitle(text: "Deliverables")
                .padding(.bottom, 4)

            ForEach(displayDeliverables.indices, id: \.self) { i in
                let d = displayDeliverables[i]
                HStack(spacing: 12) {
                    AviaryIcon(name: d.icon, size: 18, color: t.ink3)
                    Text(d.label)
                        .font(AviaryFont.body(14))
                        .foregroundStyle(t.ink)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    Rectangle().fill(t.line).frame(height: 1),
                    alignment: .bottom
                )
                .opacity(1)
            }
            .padding(.bottom, 6)

            HStack(spacing: 10) {
                Avatar(size: 36, initials: initials(for: clientText), background: t.accentSoft)
                VStack(alignment: .leading, spacing: 1) {
                    Text(clientText)
                        .font(AviaryFont.body(14, weight: .semibold))
                        .foregroundStyle(t.ink)
                    Text(clientMetaText)
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink3)
                }
                Spacer()
                ZStack {
                    Circle().fill(t.surface2)
                    AviaryIcon(name: "message", size: 18, color: t.ink)
                }
                .frame(width: 36, height: 36)
            }
            .padding(.top, 12)

            if let errorMessage {
                Text(errorMessage)
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.warn)
                    .padding(.top, 14)
            }

            PrimaryButton(title: isAccepting ? "Accepting..." : "Accept gig",
                          systemTrailing: "arrow.right",
                          enabled: !isAccepting,
                          action: acceptGig)
                .padding(.top, 20)
        }
    }

    private struct Deliverable { var label: String; var icon: String }

    private var displayDeliverables: [Deliverable] {
        let labels: [String]
        if let job {
            labels = job.displayDeliverables
        } else if let demoGig {
            labels = demoGig.deliverables
        } else {
            labels = [
                "12 exterior photos · 4K",
                "60-sec cinematic flyover",
                "Twilight shot (post-sunset)"
            ]
        }
        return labels.enumerated().map { idx, label in
            switch idx {
            case 1: return .init(label: label, icon: "play")
            case 2: return .init(label: label, icon: "sun")
            default: return .init(label: label, icon: "camera")
            }
        }
    }

    // MARK: - Derived display values

    private var chipText: String {
        if let job { return job.displayType }
        if let demoGig { return demoGig.jobType }
        return "Premium gig"
    }

    private var titleText: String {
        if let job { return job.displayTitle }
        if let demoGig { return demoGig.title }
        return "Real estate aerials"
    }

    private var addressText: String {
        if let job { return job.displayAddress }
        if let demoGig { return demoGig.address }
        return "1247 Vine St, Berkeley"
    }

    private var distanceText: String {
        if let job { return job.distanceText }
        if let demoGig { return demoGig.distance }
        return "1.2 mi"
    }

    private var payoutText: String {
        if let job { return job.payoutText }
        if let demoGig { return demoGig.payout }
        return "$340"
    }

    private var durationStat: String {
        if let job { return job.durationText }
        if let demoGig { return demoGig.duration }
        return "~45 min"
    }

    private var startStat: String {
        if let job { return job.scheduledText }
        if let demoGig { return demoGig.startText }
        return "3:30 PM"
    }

    private var clientText: String {
        if let job { return job.displayClient }
        if let demoGig { return demoGig.client }
        return "Marin Realty Co."
    }

    private var clientMetaText: String {
        if let job { return "\(job.statusLabel) · customer request" }
        if let demoGig { return demoGig.clientMeta }
        return "★ 4.9 · 28 gigs posted"
    }

    // MARK: - Map header

    private var headerCoordinate: CLLocationCoordinate2D {
        if let demoGig { return demoGig.coordinate }
        if let resolvedCoordinate { return resolvedCoordinate }
        // Default: Berkeley center for real jobs until geocoded.
        return CLLocationCoordinate2D(latitude: 37.8716, longitude: -122.2727)
    }

    private var mapHeader: some View {
        Map(position: $camera) {
            Annotation(titleText, coordinate: headerCoordinate, anchor: .bottom) {
                payoutPin
            }
        }
        .mapStyle(.standard(elevation: .flat,
                            emphasis: .muted,
                            pointsOfInterest: .excludingAll))
        .mapControls { }
        .overlay(mapTintOverlay.allowsHitTesting(false))
        .onAppear {
            recenterCamera()
            geocodeIfNeeded()
        }
        .onChange(of: headerCoordinate.latitude) { _, _ in recenterCamera() }
        .onChange(of: headerCoordinate.longitude) { _, _ in recenterCamera() }
    }

    private var payoutPin: some View {
        ZStack {
            Circle().fill(t.accent.opacity(0.16)).frame(width: 56, height: 56)
            Circle().fill(t.accent.opacity(0.28)).frame(width: 36, height: 36)
            Capsule()
                .fill(t.accent)
                .frame(width: max(34, CGFloat(payoutText.count) * 9 + 16), height: 26)
                .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
            Text(payoutText)
                .font(AviaryFont.body(12, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var mapTintOverlay: some View {
        if colorScheme == .light {
            t.mapBg.opacity(0.42).blendMode(.multiply)
        } else {
            t.mapBg.opacity(0.38).blendMode(.multiply)
        }
    }

    private func recenterCamera() {
        camera = .region(MKCoordinateRegion(
            center: headerCoordinate,
            latitudinalMeters: 1400,
            longitudinalMeters: 1400
        ))
    }

    private func geocodeIfNeeded() {
        guard demoGig == nil, resolvedCoordinate == nil,
              let address = job?.address, !address.isEmpty else { return }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, _ in
            if let coord = placemarks?.first?.location?.coordinate {
                Task { @MainActor in
                    self.resolvedCoordinate = coord
                }
            }
        }
    }

    private func acceptGig() {
        guard let job, let pilotProfile else {
            onAccept()
            return
        }
        isAccepting = true
        errorMessage = nil
        Task {
            do {
                try await AviaryDataService.shared.accept(job: job, pilotID: pilotProfile.id)
                await MainActor.run {
                    isAccepting = false
                    onAccept()
                }
            } catch {
                await MainActor.run {
                    isAccepting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func initials(for name: String) -> String {
        let initials = name
            .split(separator: " ")
            .compactMap(\.first)
            .prefix(2)
        return initials.isEmpty ? "CL" : String(initials).uppercased()
    }

    private func stat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AviaryFont.body(11))
                .foregroundStyle(t.ink3)
            Text(value)
                .font(AviaryFont.body(14, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(t.surface2)
        )
    }

    private func circleBtn(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle().fill(t.surface)
                AviaryIcon(name: icon, size: 18, color: t.ink)
            }
            .frame(width: 40, height: 40)
            .overlay(Circle().strokeBorder(t.line))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
