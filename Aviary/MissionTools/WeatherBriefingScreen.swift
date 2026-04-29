import CoreLocation
import SwiftUI

struct WeatherBriefingScreen: View {
    let activeJob: AviaryJob?
    let demoMissionLabel: String?
    let demoMissionAddress: String?
    let demoMissionCoordinate: CLLocationCoordinate2D?

    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var demoStore: DemoModeStore

    @State private var currentBriefing: AviationBriefing?
    @State private var missionBriefing: AviationBriefing?
    @State private var currentError: String?
    @State private var missionError: String?
    @State private var isLoading: Bool = false
    @State private var lastRefreshed: Date?

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    legendCard

                    SectionTitle(text: "Current location")
                        .padding(.horizontal, 4)
                    sectionBody(briefing: currentBriefing,
                                error: currentError,
                                emptyTitle: "Locating you",
                                emptyMessage: "Waiting on your position to find the nearest reporting station.")

                    SectionTitle(text: missionSectionTitle)
                        .padding(.horizontal, 4)
                    sectionBody(briefing: missionBriefing,
                                error: missionError,
                                emptyTitle: missionEmptyTitle,
                                emptyMessage: missionEmptyMessage)

                    sourceFooter
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .task { await loadAll() }
        .refreshable { await loadAll(force: true) }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather briefing")
                    .font(AviaryFont.display(28, weight: .bold))
                    .tracking(-0.02 * 28)
                    .foregroundStyle(t.ink)
                if let lastRefreshed {
                    Text("Updated \(Self.relativeFormatter.localizedString(for: lastRefreshed, relativeTo: Date()))")
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink3)
                } else {
                    Text("METAR & TAF · aviationweather.gov")
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink3)
                }
            }
            Spacer()
            Button {
                Task { await loadAll(force: true) }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(t.ink2)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(t.ink2)
                    }
                }
                .frame(width: 36, height: 36)
                .background(Circle().fill(t.surface2))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(isLoading)
            Button {
                dismiss()
            } label: {
                AviaryIcon(name: "x", size: 18, color: t.ink2)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(t.surface2))
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    // MARK: - Section body

    @ViewBuilder
    private func sectionBody(briefing: AviationBriefing?,
                             error: String?,
                             emptyTitle: String,
                             emptyMessage: String) -> some View {
        if let briefing {
            BriefingCard(briefing: briefing)
        } else if let error {
            FeatureStateCard(icon: "cloud",
                             title: "Briefing unavailable",
                             message: error,
                             buttonTitle: "Try again",
                             action: { Task { await loadAll(force: true) } })
        } else if isLoading {
            FeatureStateCard(icon: "cloud",
                             title: "Loading briefing",
                             message: "Pulling METAR & TAF from the nearest station.")
        } else {
            FeatureStateCard(icon: "cloud",
                             title: emptyTitle,
                             message: emptyMessage)
        }
    }

    // MARK: - Legend

    private var legendCard: some View {
        AviaryCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Flight categories")
                    .font(AviaryFont.body(12, weight: .semibold))
                    .foregroundStyle(t.ink2)
                HStack(spacing: 8) {
                    legendChip("VFR", color: t.good)
                    legendChip("MVFR", color: t.accent)
                    legendChip("IFR", color: t.warn)
                    legendChip("LIFR", color: t.bad)
                }
            }
        }
    }

    private func legendChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AviaryFont.body(11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.14)))
    }

    private var sourceFooter: some View {
        Text("Source: aviationweather.gov · For situational awareness only. Confirm with an FAA-approved briefing before flight.")
            .font(AviaryFont.body(11))
            .foregroundStyle(t.ink4)
            .lineSpacing(2)
            .padding(.top, 6)
    }

    // MARK: - Loading

    private func loadAll(force: Bool = false) async {
        if isLoading { return }
        if !force, lastRefreshed != nil,
           Date().timeIntervalSince(lastRefreshed ?? .distantPast) < 60 {
            return
        }
        isLoading = true
        defer { isLoading = false }

        currentError = nil
        missionError = nil

        // In demo mode, serve canned METAR/TAF instead of hitting the network so
        // the demo doesn't depend on connectivity.
        if demoStore.isOn {
            currentBriefing = DemoWeatherBriefings.currentLocation
            missionBriefing = DemoWeatherBriefings.mission(label: missionDisplayName)
            lastRefreshed = Date()
            return
        }

        async let current = loadCurrent()
        async let mission = loadMission()
        let (cur, mis) = await (current, mission)
        currentBriefing = cur.briefing
        currentError = cur.error
        missionBriefing = mis.briefing
        missionError = mis.error
        lastRefreshed = Date()
    }

    private func loadCurrent() async -> (briefing: AviationBriefing?, error: String?) {
        do {
            let coord = try await LocationProvider.shared.currentCoordinate()
            let briefing = try await WeatherBriefingService.briefing(at: coord, label: "Your position")
            return (briefing, nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }

    private func loadMission() async -> (briefing: AviationBriefing?, error: String?) {
        if let coord = demoMissionCoordinate {
            do {
                let briefing = try await WeatherBriefingService.briefing(at: coord, label: missionDisplayName)
                return (briefing, nil)
            } catch {
                return (nil, error.localizedDescription)
            }
        }
        guard let address = nextMissionAddress, !address.isEmpty else {
            return (nil, nil)
        }
        do {
            guard let coord = try await geocode(address) else {
                return (nil, "Couldn't locate \(address).")
            }
            let briefing = try await WeatherBriefingService.briefing(at: coord, label: missionDisplayName)
            return (briefing, nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }

    private func geocode(_ address: String) async throws -> CLLocationCoordinate2D? {
        try await withCheckedThrowingContinuation { continuation in
            CLGeocoder().geocodeAddressString(address) { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: placemarks?.first?.location?.coordinate)
                }
            }
        }
    }

    // MARK: - Mission helpers

    private var nextMissionAddress: String? {
        if let activeJob {
            let address = activeJob.displayAddress
            return address == "Address not set" ? nil : address
        }
        return demoMissionAddress
    }

    private var missionDisplayName: String {
        if let activeJob { return activeJob.displayTitle }
        return demoMissionLabel ?? "Next mission"
    }

    private var missionSectionTitle: String {
        if activeJob != nil || demoMissionAddress != nil || demoMissionCoordinate != nil {
            return "Next mission"
        }
        return "No active mission"
    }

    private var missionEmptyTitle: String {
        "No mission scheduled"
    }

    private var missionEmptyMessage: String {
        "Accept a gig to see a destination weather briefing."
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}

// MARK: - Briefing card

private struct BriefingCard: View {
    let briefing: AviationBriefing
    @Environment(\.theme) private var t

    private var category: FlightCategory {
        briefing.metar?.flightCategory ?? .unknown
    }

    var body: some View {
        AviaryCard(padding: 18, shadowed: true) {
            VStack(alignment: .leading, spacing: 14) {
                headerRow
                Divider().background(t.line)
                metarSection
                if briefing.taf != nil {
                    Divider().background(t.line)
                    tafSection
                }
            }
        }
    }

    // MARK: header

    private var headerRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                categoryChip
                Spacer()
                if let metar = briefing.metar, let obs = metar.observationTime {
                    Text(Self.timeFormatter.string(from: obs))
                        .font(AviaryFont.mono(12, weight: .semibold))
                        .foregroundStyle(t.ink3)
                }
            }
            Text(briefing.label)
                .font(AviaryFont.body(13, weight: .semibold))
                .foregroundStyle(t.ink3)
            Text("\(briefing.station.icaoId) · \(briefing.station.name)")
                .font(AviaryFont.display(20, weight: .bold))
                .tracking(-0.02 * 20)
                .foregroundStyle(t.ink)
            Text(String(format: "%.1f mi from your point", briefing.distanceMiles))
                .font(AviaryFont.body(12))
                .foregroundStyle(t.ink3)
            Text(category.summary)
                .font(AviaryFont.body(12))
                .foregroundStyle(t.ink2)
                .lineSpacing(2)
        }
    }

    private var categoryChip: some View {
        Text(category.rawValue)
            .font(AviaryFont.body(12, weight: .semibold))
            .foregroundStyle(categoryColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(categoryColor.opacity(0.16)))
    }

    private var categoryColor: Color {
        switch category {
        case .vfr:  return t.good
        case .mvfr: return t.accent
        case .ifr:  return t.warn
        case .lifr: return t.bad
        case .unknown: return t.ink3
        }
    }

    // MARK: METAR

    private var metarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Current (METAR)")
                    .font(AviaryFont.body(13, weight: .semibold))
                    .foregroundStyle(t.ink2)
                Spacer()
            }
            if let metar = briefing.metar {
                let stats = metarStats(metar)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)],
                          spacing: 10) {
                    ForEach(stats) { stat in
                        statTile(stat: stat)
                    }
                }

                if !metar.cloudLayers.isEmpty {
                    Text("Clouds")
                        .font(AviaryFont.body(11, weight: .semibold))
                        .foregroundStyle(t.ink3)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(metar.cloudLayers) { layer in
                            Text(cloudLine(layer))
                                .font(AviaryFont.mono(12, weight: .semibold))
                                .foregroundStyle(t.ink2)
                        }
                    }
                }

                if let weather = metar.weather, !weather.isEmpty {
                    Text("Weather: \(weather)")
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink2)
                }

                if !metar.rawText.isEmpty {
                    rawBlock(title: "Raw METAR", text: metar.rawText)
                }
            } else {
                Text("No current observation available.")
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.ink3)
            }
        }
    }

    private func cloudLine(_ layer: CloudLayer) -> String {
        if let base = layer.baseFeetAGL {
            return "\(layer.cover) at \(Self.altitudeFormatter.string(from: NSNumber(value: base)) ?? "\(base)") ft"
        }
        return layer.cover
    }

    // MARK: TAF

    private var tafSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Forecast (TAF)")
                    .font(AviaryFont.body(13, weight: .semibold))
                    .foregroundStyle(t.ink2)
                Spacer()
                if let taf = briefing.taf, let from = taf.validFrom, let to = taf.validTo {
                    Text("\(Self.shortFormatter.string(from: from)) – \(Self.shortFormatter.string(from: to))")
                        .font(AviaryFont.mono(11, weight: .semibold))
                        .foregroundStyle(t.ink3)
                }
            }
            if let taf = briefing.taf {
                if taf.periods.isEmpty {
                    Text("No detailed periods.")
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink3)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(taf.periods.prefix(4)) { period in
                            tafPeriodRow(period)
                        }
                        if taf.periods.count > 4 {
                            Text("+ \(taf.periods.count - 4) more periods in raw text")
                                .font(AviaryFont.body(11))
                                .foregroundStyle(t.ink4)
                        }
                    }
                }
                if !taf.rawText.isEmpty {
                    rawBlock(title: "Raw TAF", text: taf.rawText)
                }
            } else {
                Text("No forecast available for this station.")
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.ink3)
            }
        }
    }

    private func tafPeriodRow(_ period: TafPeriod) -> some View {
        let hasChangeLabel = !(period.changeIndicator ?? "").isEmpty || period.probability != nil
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if hasChangeLabel {
                    Text(periodLabel(period))
                        .font(AviaryFont.body(11, weight: .bold))
                        .foregroundStyle(t.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(t.accentSoft))
                }
                if let from = period.from {
                    Text(Self.shortFormatter.string(from: from))
                        .font(AviaryFont.mono(12, weight: .semibold))
                        .foregroundStyle(t.ink2)
                }
                if let to = period.to {
                    Text("→ \(Self.shortFormatter.string(from: to))")
                        .font(AviaryFont.mono(12))
                        .foregroundStyle(t.ink3)
                }
                Spacer()
            }
            Text(periodSummary(period))
                .font(AviaryFont.body(12))
                .foregroundStyle(t.ink2)
                .lineSpacing(2)
        }
    }

    private func periodLabel(_ period: TafPeriod) -> String {
        var label = period.changeIndicator ?? ""
        if let prob = period.probability {
            label = label.isEmpty ? "PROB\(prob)" : "\(label) \(prob)%"
        }
        return label.isEmpty ? "FCST" : label
    }

    private func periodSummary(_ period: TafPeriod) -> String {
        var bits: [String] = []
        if let dir = period.windDirectionDeg, let spd = period.windSpeedKt {
            var wind = String(format: "Wind %03d° at %d kt", dir, spd)
            if let gust = period.windGustKt, gust > 0 {
                wind += " gust \(gust)"
            }
            bits.append(wind)
        } else if let spd = period.windSpeedKt {
            bits.append("Wind \(spd) kt")
        }
        if let visRaw = period.visibilityRaw {
            bits.append("Vis \(visRaw)")
        } else if let vis = period.visibilitySm {
            bits.append(String(format: "Vis %.1f SM", vis))
        }
        if let weather = period.weather, !weather.isEmpty {
            bits.append(weather)
        }
        if !period.cloudLayers.isEmpty {
            let cloud = period.cloudLayers.map { layer -> String in
                if let base = layer.baseFeetAGL {
                    return "\(layer.cover) \(base / 100)"
                }
                return layer.cover
            }.joined(separator: " · ")
            bits.append(cloud)
        }
        return bits.isEmpty ? "Conditions unchanged" : bits.joined(separator: " · ")
    }

    // MARK: Tiles

    private struct Stat: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let icon: String
    }

    private func metarStats(_ metar: MetarObservation) -> [Stat] {
        var stats: [Stat] = []

        let wind: String
        switch (metar.windDirectionDeg, metar.windSpeedKt) {
        case let (dir?, spd?):
            var s = String(format: "%03d° · %dkt", dir, spd)
            if let gust = metar.windGustKt, gust > 0 { s += "G\(gust)" }
            wind = s
        case (_, let spd?):
            wind = "\(spd)kt"
        default:
            wind = "—"
        }
        stats.append(Stat(label: "Wind", value: wind, icon: "wind"))

        let vis: String
        if let raw = metar.visibilityRaw {
            vis = raw
        } else if let v = metar.visibilityStatuteMiles {
            vis = String(format: "%.1f SM", v)
        } else {
            vis = "—"
        }
        stats.append(Stat(label: "Visibility", value: vis, icon: "compass"))

        let ceiling: String
        if let c = metar.ceilingFeet {
            ceiling = "\(Self.altitudeFormatter.string(from: NSNumber(value: c)) ?? "\(c)") ft"
        } else {
            ceiling = "Unlimited"
        }
        stats.append(Stat(label: "Ceiling", value: ceiling, icon: "altitude"))

        let temp: String
        if let tC = metar.temperatureC {
            let tF = tC * 9 / 5 + 32
            if let dC = metar.dewpointC {
                temp = String(format: "%.0f°F · dp %.0f°F", tF, dC * 9 / 5 + 32)
            } else {
                temp = String(format: "%.0f°F", tF)
            }
        } else {
            temp = "—"
        }
        stats.append(Stat(label: "Temp / Dew", value: temp, icon: "sun"))

        if let alt = metar.altimeterInHg {
            stats.append(Stat(label: "Altimeter", value: String(format: "%.2f inHg", alt), icon: "cert"))
        }

        return stats
    }

    private func statTile(stat: Stat) -> some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(t.surface2)
                AviaryIcon(name: stat.icon, size: 14, color: t.ink2)
            }
            .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.label)
                    .font(AviaryFont.body(11, weight: .semibold))
                    .foregroundStyle(t.ink3)
                Text(stat.value)
                    .font(AviaryFont.mono(13, weight: .semibold))
                    .foregroundStyle(t.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(t.line)
        )
    }

    // MARK: Raw

    private func rawBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AviaryFont.body(11, weight: .semibold))
                .foregroundStyle(t.ink3)
            Text(text)
                .font(AviaryFont.mono(12))
                .foregroundStyle(t.ink2)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous).fill(t.surface2)
                )
                .textSelection(.enabled)
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HHmm'Z'"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE HHmm'Z'"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let altitudeFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
}
