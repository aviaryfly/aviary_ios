import SwiftUI

struct MyJobsScreen: View {
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore
    let profile: UserProfile
    @State private var filter: Filter = .open
    @State private var jobs: [AviaryJob] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedJob: AviaryJob?
    @State private var showcaseJobsTask: Task<Void, Never>?

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
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear.frame(height: 1).id("my-jobs-top")
                        PageHeader(title: "My jobs", subtitle: subtitle)

                        filterRow
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .padding(.bottom, 12)

                        content
                        Color.clear.frame(height: 1).id("my-jobs-bottom")
                    }
                }
                .onAppear {
                    applyShowcaseStep(proxy)
                }
                .onChange(of: demoStore.showcaseStep) { _, _ in
                    applyShowcaseStep(proxy)
                }
                .onDisappear {
                    showcaseJobsTask?.cancel()
                }
            }
        }
        .sheet(item: $selectedJob) { job in
            CustomerJobDetailScreen(job: job)
                .environment(\.theme, t)
        }
        .task(id: "\(profile.id.uuidString)-\(demoStore.isOn)") {
            await loadJobs()
        }
    }

    private func applyShowcaseStep(_ proxy: ScrollViewProxy) {
        showcaseJobsTask?.cancel()
        guard let step = demoStore.showcaseStep, step.role == .customer else {
            selectedJob = nil
            return
        }

        switch step {
        case .customerMyJobs:
            selectedJob = nil
            filter = .open
            showcaseJobsTask = Task { @MainActor in
                do {
                    try await Task.sleep(nanoseconds: 650_000_000)
                    guard demoStore.showcaseStep == .customerMyJobs else { return }
                    withAnimation(.easeInOut(duration: 1.0)) {
                        proxy.scrollTo("my-jobs-bottom", anchor: .bottom)
                    }
                    try await Task.sleep(nanoseconds: 1_150_000_000)
                    guard demoStore.showcaseStep == .customerMyJobs else { return }
                    filter = .completed
                    withAnimation(.easeInOut(duration: 0.65)) {
                        proxy.scrollTo("my-jobs-top", anchor: .top)
                    }
                    try await Task.sleep(nanoseconds: 850_000_000)
                    guard demoStore.showcaseStep == .customerMyJobs else { return }
                    withAnimation(.easeInOut(duration: 1.0)) {
                        proxy.scrollTo("my-jobs-bottom", anchor: .bottom)
                    }
                } catch {
                    return
                }
            }
        case .customerJobDetail:
            filter = .open
            selectedJob = sourceJobs.first(where: { !$0.isCompleted }) ?? sourceJobs.first
        default:
            selectedJob = nil
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
        FeatureStateCard(icon: "briefcase",
                         title: filter == .open ? "No open jobs" : "No completed jobs yet",
                         message: filter == .open
                            ? "Post a job from the Post Job tab and it will show up here while a pilot is on the way."
                            : "Once a pilot completes a job for you, you'll see it here with the deliverables.")
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            FeatureStateCard(icon: "briefcase",
                             title: "Loading jobs",
                             message: "Checking your customer requests and pilot assignments.")
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        } else if let errorMessage {
            FeatureStateCard(icon: "cloud",
                             title: "Couldn't load jobs",
                             message: errorMessage,
                             buttonTitle: "Try again",
                             action: { Task { await loadJobs() } })
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        } else if filteredJobs.isEmpty {
            emptyState
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        } else {
            LazyVStack(spacing: 10) {
                ForEach(filteredJobs) { job in
                    Button { selectedJob = job } label: {
                        jobCard(job)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var subtitle: String {
        let count = filteredJobs.count
        if isLoading { return "Loading" }
        if count == 0 { return filter == .open ? "No open jobs" : "No completed jobs" }
        return "\(count) \(filter == .open ? "open" : "completed")"
    }

    private var sourceJobs: [AviaryJob] {
        demoStore.isOn ? Self.demoJobs(customerID: profile.id) : jobs
    }

    private var filteredJobs: [AviaryJob] {
        sourceJobs.filter { filter == .completed ? $0.isCompleted : !$0.isCompleted }
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
            jobs = try await AviaryDataService.shared.customerJobs(for: profile.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func jobCard(_ job: AviaryJob) -> some View {
        AviaryCard(padding: 14, shadowed: true) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(t.accentSoft)
                    AviaryIcon(name: icon(for: job), size: 22, color: t.accent)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(job.displayTitle)
                            .font(AviaryFont.body(15, weight: .semibold))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(job.payoutText)
                            .font(AviaryFont.mono(15, weight: .semibold))
                            .foregroundStyle(t.ink)
                    }
                    Text(job.displayAddress)
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Chip(text: job.statusLabel, style: chipStyle(for: job))
                        Text(job.scheduledText)
                            .font(AviaryFont.body(12))
                            .foregroundStyle(t.ink4)
                            .lineLimit(1)
                    }
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

    private func chipStyle(for job: AviaryJob) -> Chip.Style {
        switch job.normalizedStatus {
        case "completed", "closed", "paid": return .good
        case "cancelled":                   return .neutral
        default:                            return .accent
        }
    }

    private static func demoJobs(customerID: UUID) -> [AviaryJob] {
        let pilotCasey = UUID(uuidString: "22222222-2222-4222-8222-222222222222")
        let pilotJamie = UUID(uuidString: "44444444-4444-4444-8444-444444444444")
        let pilotLin = UUID(uuidString: "55555555-5555-4555-8555-555555555555")
        return [
            AviaryJob(
                id: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
                customerId: customerID,
                pilotId: pilotCasey,
                status: "accepted",
                jobType: "real_estate",
                title: "Real estate listing",
                address: "1247 Vine St, Berkeley",
                clientName: "Marin Realty Co.",
                pilotName: "Casey Park",
                distanceMiles: 1.2,
                payoutCents: 34000,
                scheduledAt: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
                durationMinutes: 45,
                deliverables: ["12 exterior photos", "60-sec cinematic flyover", "Twilight shot"],
                createdAt: Date()
            ),
            AviaryJob(
                id: UUID(uuidString: "33333333-3333-4333-8333-333333333333")!,
                customerId: customerID,
                pilotId: pilotCasey,
                status: "completed",
                jobType: "inspection",
                title: "Roof inspection",
                address: "22 Hillside Ave, Berkeley",
                clientName: "Marin Realty Co.",
                pilotName: "Casey Park",
                distanceMiles: 2.4,
                payoutCents: 22000,
                scheduledAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
                durationMinutes: 30,
                deliverables: ["Roof overview photos", "Gutter close-ups", "Annotated damage notes"],
                createdAt: Date()
            ),
            AviaryJob(
                id: UUID(uuidString: "66666666-6666-4666-8666-666666666666")!,
                customerId: customerID,
                pilotId: pilotJamie,
                status: "in_progress",
                jobType: "event",
                title: "Wedding aerial coverage",
                address: "Tilden Park, Berkeley",
                clientName: "Hartley & Co.",
                pilotName: "Jamie Hartley",
                distanceMiles: 3.1,
                payoutCents: 78000,
                scheduledAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date()),
                durationMinutes: 120,
                deliverables: ["Ceremony aerial coverage", "Couple cinematic flyover", "60-sec highlight reel"],
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())
            ),
            AviaryJob(
                id: UUID(uuidString: "77777777-7777-4777-8777-777777777777")!,
                customerId: customerID,
                pilotId: nil,
                status: "open",
                jobType: "mapping",
                title: "Vineyard mapping flight",
                address: "Stags Leap District, Napa",
                clientName: "Stags Leap Vineyards",
                pilotName: nil,
                distanceMiles: 42,
                payoutCents: 125000,
                scheduledAt: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                durationMinutes: 240,
                deliverables: ["Orthomosaic at 2 cm/px", "Multispectral NDVI map", "Boundary KML overlay"],
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())
            ),
            AviaryJob(
                id: UUID(uuidString: "88888888-8888-4888-8888-888888888888")!,
                customerId: customerID,
                pilotId: pilotLin,
                status: "completed",
                jobType: "real_estate",
                title: "Listing reshoot — twilight",
                address: "880 Spruce St, Berkeley",
                clientName: "Bay Listing Group",
                pilotName: "Lin Park",
                distanceMiles: 1.8,
                payoutCents: 42000,
                scheduledAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
                durationMinutes: 60,
                deliverables: ["20 twilight exteriors", "Dawn flyover", "Aerial site plan"],
                createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())
            ),
            AviaryJob(
                id: UUID(uuidString: "99999999-9999-4999-8999-999999999999")!,
                customerId: customerID,
                pilotId: pilotJamie,
                status: "cancelled",
                jobType: "inspection",
                title: "Solar array inspection",
                address: "1500 Industrial Way, Richmond",
                clientName: "Greenline Solar",
                pilotName: "Jamie Hartley",
                distanceMiles: 6.7,
                payoutCents: 32000,
                scheduledAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
                durationMinutes: 45,
                deliverables: ["Thermal panel scan", "Defect call-outs"],
                createdAt: Calendar.current.date(byAdding: .day, value: -6, to: Date())
            )
        ]
    }
}

private struct CustomerJobDetailScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    let job: AviaryJob

    private var detailChipStyle: Chip.Style {
        switch job.normalizedStatus {
        case "completed", "closed", "paid": return .good
        case "cancelled":                   return .neutral
        default:                            return .accent
        }
    }

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Button { dismiss() } label: {
                            AviaryIcon(name: "arrow-left", size: 22, color: t.ink)
                        }
                        Text("Job details")
                            .font(AviaryFont.body(16, weight: .semibold))
                            .foregroundStyle(t.ink)
                        Spacer()
                        Chip(text: job.statusLabel, style: detailChipStyle)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                    AviaryCard(padding: 18, shadowed: true) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(job.displayTitle)
                                .font(AviaryFont.display(24, weight: .bold))
                                .tracking(-0.02 * 24)
                                .foregroundStyle(t.ink)
                            Text(job.displayAddress)
                                .font(AviaryFont.body(13))
                                .foregroundStyle(t.ink3)
                            HStack(spacing: 8) {
                                stat(label: "Pilot", value: job.displayPilot)
                                stat(label: "Payout", value: job.payoutText)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)

                    SectionTitle(text: "Deliverables")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)

                    AviaryCard(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(job.displayDeliverables.enumerated()), id: \.0) { idx, item in
                                HStack(spacing: 10) {
                                    AviaryIcon(name: idx == 1 ? "play" : "camera", size: 18, color: t.ink3)
                                    Text(item)
                                        .font(AviaryFont.body(14))
                                        .foregroundStyle(t.ink)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                                .overlay(
                                    idx < job.displayDeliverables.count - 1 ? Rectangle().fill(t.line).frame(height: 1) : nil,
                                    alignment: .bottom
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func stat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(AviaryFont.body(11))
                .foregroundStyle(t.ink3)
            Text(value)
                .font(AviaryFont.body(14, weight: .semibold))
                .foregroundStyle(t.ink)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(t.surface2))
    }
}
