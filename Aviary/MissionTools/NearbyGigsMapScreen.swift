import SwiftUI
import MapKit
import CoreLocation

// MARK: - Pin model

struct GigMapPin: Identifiable, Equatable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var label: String
    var title: String
    var subtitle: String
    var jobType: String
    var isPrimary: Bool

    static func == (lhs: GigMapPin, rhs: GigMapPin) -> Bool { lhs.id == rhs.id }
}

// MARK: - Map screen

/// Real MapKit-backed map of nearby gigs, tinted with the demo-mode color palette.
struct NearbyGigsMapScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var demoStore: DemoModeStore

    let activeJob: AviaryJob?

    @State private var camera: MapCameraPosition = .automatic
    @State private var pins: [GigMapPin] = []
    @State private var selectedPinID: UUID?
    @State private var loadState: LoadState = .loading
    @State private var filter: GigFilter = .all

    private enum LoadState { case loading, ready, failed(String) }
    private enum GigFilter: String, CaseIterable {
        case all = "All gigs"
        case realEstate = "Real estate"
        case inspection = "Inspections"
        case mapping = "Mapping"

        func matches(_ pin: GigMapPin) -> Bool {
            switch self {
            case .all: return true
            case .realEstate: return pin.jobType.lowercased().contains("real")
            case .inspection: return pin.jobType.lowercased().contains("inspect")
            case .mapping: return pin.jobType.lowercased().contains("map")
            }
        }
    }

    var body: some View {
        ZStack {
            mapLayer
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                filterChips
                    .padding(.top, 12)
                Spacer()
                bottomSheet
            }
        }
        .task { await loadPins() }
    }

    // MARK: - Map layer

    private var mapLayer: some View {
        Map(position: $camera, selection: $selectedPinID) {
            UserAnnotation()
            ForEach(filteredPins) { pin in
                Annotation(pin.title, coordinate: pin.coordinate, anchor: .bottom) {
                    pinView(pin: pin)
                        .onTapGesture { selectedPinID = pin.id }
                }
                .tag(pin.id)
            }
        }
        .mapStyle(.standard(elevation: .flat,
                            emphasis: .muted,
                            pointsOfInterest: .excludingAll))
        .mapControls { }
        .overlay(tintOverlay.allowsHitTesting(false))
    }

    @ViewBuilder
    private var tintOverlay: some View {
        if colorScheme == .light {
            // Warm beige multiply pulls the standard Apple map toward the demo palette.
            t.mapBg.opacity(0.42).blendMode(.multiply)
        } else {
            // Deep navy tint to deepen the dark map toward the demo's hangar palette.
            t.mapBg.opacity(0.38).blendMode(.multiply)
        }
    }

    private var filteredPins: [GigMapPin] {
        pins.filter { filter.matches($0) }
    }

    private var selectedPin: GigMapPin? {
        pins.first(where: { $0.id == selectedPinID }) ?? pins.first(where: \.isPrimary) ?? pins.first
    }

    // MARK: - Pin view (matches demo MapBackground pin style)

    @ViewBuilder
    private func pinView(pin: GigMapPin) -> some View {
        let isSelected = pin.id == selectedPinID || (selectedPinID == nil && pin.isPrimary)
        let color: Color = pin.isPrimary ? t.accent : (pin.jobType.lowercased().contains("event") ? t.good : t.accent)
        ZStack {
            if pin.isPrimary {
                Circle().fill(color.opacity(0.16)).frame(width: 56, height: 56)
                Circle().fill(color.opacity(0.28)).frame(width: 36, height: 36)
            }
            Capsule()
                .fill(color)
                .frame(width: max(34, CGFloat(pin.label.count) * 9 + 16),
                       height: 26)
                .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
            Text(pin.label)
                .font(AviaryFont.body(12, weight: .bold))
                .foregroundStyle(.white)
        }
        .scaleEffect(isSelected ? 1.08 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(t.surface)
                    AviaryIcon(name: "arrow-left", size: 18, color: t.ink)
                }
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(t.line))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 3)
            }
            .buttonStyle(PressableButtonStyle())

            HStack(spacing: 10) {
                AviaryIcon(name: "search", size: 18, color: t.ink3)
                Text("Search area, gig type…")
                    .font(AviaryFont.body(15))
                    .foregroundStyle(t.ink3)
                Spacer()
                AviaryIcon(name: "filter", size: 18, color: t.ink2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Capsule().fill(t.surface))
            .overlay(Capsule().strokeBorder(t.line))
            .shadow(color: .black.opacity(0.08), radius: 14, y: 4)

            Button {
                if let coord = currentRecenterTarget() {
                    withAnimation {
                        camera = .region(MKCoordinateRegion(center: coord,
                                                            latitudinalMeters: 1800,
                                                            longitudinalMeters: 1800))
                    }
                }
            } label: {
                ZStack {
                    Circle().fill(t.surface)
                    AviaryIcon(name: "navigation", size: 20, color: t.ink)
                }
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(t.line))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 3)
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    // MARK: - Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GigFilter.allCases, id: \.self) { f in
                    Button { filter = f } label: {
                        Chip(text: f.rawValue, style: f == filter ? .accent : .surface)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Bottom sheet

    private var bottomSheet: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(t.lineStrong)
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 14)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(headlineText)
                        .font(AviaryFont.display(20, weight: .bold))
                        .tracking(-0.02 * 20)
                        .foregroundStyle(t.ink)
                    Text(subheadlineText)
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(t.good).frame(width: 8, height: 8)
                    Text("Live")
                        .font(AviaryFont.body(13, weight: .semibold))
                        .foregroundStyle(t.good)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            switch loadState {
            case .loading:
                loadingCard
            case .failed(let message):
                errorCard(message: message)
            case .ready:
                if let pin = selectedPin {
                    selectedCard(pin: pin)
                } else {
                    emptyCard
                }
            }
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24,
                style: .continuous
            )
            .fill(t.surface)
            .shadow(color: .black.opacity(0.06), radius: 24, y: -8)
        )
    }

    private var headlineText: String {
        let n = filteredPins.count
        if n == 0 { return "No gigs in view" }
        return "\(n) gig\(n == 1 ? "" : "s") nearby"
    }

    private var subheadlineText: String {
        if demoStore.isOn { return "You're online · Berkeley, CA" }
        if activeJob != nil { return "You're online · pinned to active gig" }
        return "You're online · current area"
    }

    private func selectedCard(pin: GigMapPin) -> some View {
        AviaryCard(padding: 14, shadowed: true) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(t.surface2)
                    AviaryIcon(name: iconName(for: pin.jobType), size: 24, stroke: 2, color: t.accent)
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(pin.title)
                            .font(AviaryFont.body(15, weight: .semibold))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(pin.label)
                            .font(AviaryFont.mono(17, weight: .semibold))
                            .foregroundStyle(t.accent)
                    }
                    Text(pin.subtitle)
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        if pin.isPrimary {
                            Chip(text: "Active gig", style: .good)
                        } else {
                            Chip(text: pin.jobType, style: .surface)
                        }
                        Chip(text: "Pilot map view")
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var loadingCard: some View {
        AviaryCard(padding: 16, shadowed: true) {
            HStack(spacing: 12) {
                ProgressView().tint(t.accent)
                Text("Locating nearby gigs…")
                    .font(AviaryFont.body(14))
                    .foregroundStyle(t.ink3)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func errorCard(message: String) -> some View {
        AviaryCard(padding: 16, shadowed: true) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Couldn't load gigs")
                    .font(AviaryFont.body(14, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text(message)
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.ink3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var emptyCard: some View {
        AviaryCard(padding: 16, shadowed: true) {
            HStack(spacing: 10) {
                AviaryIcon(name: "compass", size: 18, color: t.ink3)
                Text("No gigs to show in this filter.")
                    .font(AviaryFont.body(13))
                    .foregroundStyle(t.ink3)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func iconName(for jobType: String) -> String {
        switch jobType.lowercased() {
        case let s where s.contains("inspect"): return "cert"
        case let s where s.contains("event"): return "star"
        case let s where s.contains("map"): return "altitude"
        default: return "camera"
        }
    }

    // MARK: - Loading

    private func currentRecenterTarget() -> CLLocationCoordinate2D? {
        if let pin = pins.first(where: \.isPrimary) { return pin.coordinate }
        return pins.first?.coordinate
    }

    private func loadPins() async {
        loadState = .loading
        var assembled: [GigMapPin] = []
        var center: CLLocationCoordinate2D?

        if demoStore.isOn {
            // Demo mode: scattered fictional gigs around Berkeley
            let berkeley = CLLocationCoordinate2D(latitude: 37.8716, longitude: -122.2727)
            assembled = demoPins(around: berkeley)
            center = berkeley
        } else if let job = activeJob {
            // Real mode with an active job: geocode address, scatter nearby gigs around it
            let geocoded = await geocode(job.displayAddress)
            if let coord = geocoded {
                assembled.append(GigMapPin(id: job.id,
                                           coordinate: coord,
                                           label: job.payoutText,
                                           title: job.displayTitle,
                                           subtitle: "\(job.displayAddress) · \(job.scheduledText)",
                                           jobType: job.displayType,
                                           isPrimary: true))
                assembled.append(contentsOf: demoPins(around: coord, excludingPrimary: true))
                center = coord
            }
        }

        // Fallback: try user location, then a default
        if center == nil {
            if let userCoord = try? await LocationProvider.shared.currentCoordinate() {
                assembled = demoPins(around: userCoord)
                center = userCoord
            } else {
                let fallback = CLLocationCoordinate2D(latitude: 37.8716, longitude: -122.2727)
                assembled = demoPins(around: fallback)
                center = fallback
            }
        }

        await MainActor.run {
            self.pins = assembled
            self.selectedPinID = assembled.first(where: \.isPrimary)?.id ?? assembled.first?.id
            if let center {
                self.camera = .region(MKCoordinateRegion(
                    center: center,
                    latitudinalMeters: 2400,
                    longitudinalMeters: 2400
                ))
            }
            self.loadState = .ready
        }
    }

    private func geocode(_ address: String) async -> CLLocationCoordinate2D? {
        guard !address.isEmpty, address != "Address not set" else { return nil }
        return await withCheckedContinuation { c in
            CLGeocoder().geocodeAddressString(address) { placemarks, _ in
                c.resume(returning: placemarks?.first?.location?.coordinate)
            }
        }
    }

    private func demoPins(around center: CLLocationCoordinate2D, excludingPrimary: Bool = false) -> [GigMapPin] {
        // Offsets ~ 0.005 degrees latitude ≈ 0.55 km
        let seeds: [(Double, Double, String, String, String, String, Bool)] = [
            (0.0035, -0.0042, "$340", "Real estate aerials",
             "1247 Vine St · Today, 3:30 PM", "Real estate", true),
            (-0.0044, 0.0058, "$185", "Roof inspection",
             "22 Hillside Ave · Today, 4:30 PM", "Inspection", false),
            (0.0061, 0.0034, "$520", "Wedding aerials",
             "Tilden Park · Sat, 5:00 PM", "Event", false),
            (-0.0058, -0.0049, "$95",  "Construction progress",
             "500 Folsom St · Tomorrow, 9:00 AM", "Inspection", false),
            (0.0009, 0.0072,  "$410", "Vineyard mapping",
             "Napa, CA · Wed, 8:00 AM", "Mapping", false),
        ]
        return seeds.compactMap { dLat, dLon, label, title, subtitle, jobType, primary in
            if excludingPrimary && primary { return nil }
            return GigMapPin(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(
                    latitude: center.latitude + dLat,
                    longitude: center.longitude + dLon
                ),
                label: label,
                title: title,
                subtitle: subtitle,
                jobType: jobType,
                isPrimary: primary && !excludingPrimary
            )
        }
    }
}
