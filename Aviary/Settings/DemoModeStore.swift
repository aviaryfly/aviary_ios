import Combine
import Foundation
import SwiftUI

enum DemoShowcaseFlow: String, CaseIterable, Identifiable {
    case pilot
    case customer

    var id: String { rawValue }

    var role: UserRole {
        switch self {
        case .pilot: return .pilot
        case .customer: return .customer
        }
    }

    var title: String {
        switch self {
        case .pilot: return "Pilot demo"
        case .customer: return "Customer demo"
        }
    }

    var subtitle: String {
        switch self {
        case .pilot:
            return "Browse gigs, accept a ping, fly the mission, deliver, and rate the client."
        case .customer:
            return "Post a job, watch it land in My Jobs, and message the pilot through completion."
        }
    }

    var script: [DemoShowcaseStep] {
        switch self {
        case .pilot: return DemoShowcaseStep.pilotScript
        case .customer: return DemoShowcaseStep.customerScript
        }
    }

    var totalDurationSeconds: Double {
        script.reduce(0) { $0 + $1.durationSeconds }
    }
}

enum DemoShowcaseStep: String, CaseIterable, Identifiable {
    // Pilot
    case pilotHome
    case pilotGigBoard
    case pilotGigDetail
    case pilotAcceptPing
    case pilotFly
    case pilotNearbyMap
    case pilotWeather
    case pilotChecklist
    case pilotInFlight
    case pilotDeliverables
    case pilotReview
    case pilotMessages
    case pilotProfile
    case pilotEarnings

    // Customer
    case customerHome
    case customerPostJob
    case customerMyJobs
    case customerJobDetail
    case customerMessages
    case customerProfile

    var id: String { rawValue }

    /// Pilot script — narrative flow: home → browse → accept → fly → deliver → rate → wrap up.
    static let pilotScript: [DemoShowcaseStep] = [
        .pilotHome,
        .pilotGigBoard,
        .pilotGigDetail,
        .pilotAcceptPing,
        .pilotFly,
        .pilotNearbyMap,
        .pilotWeather,
        .pilotChecklist,
        .pilotInFlight,
        .pilotDeliverables,
        .pilotReview,
        .pilotMessages,
        .pilotProfile,
        .pilotEarnings
    ]

    /// Customer script — narrative flow: home → post job → track → message pilot → profile.
    static let customerScript: [DemoShowcaseStep] = [
        .customerHome,
        .customerPostJob,
        .customerMyJobs,
        .customerJobDetail,
        .customerMessages,
        .customerProfile
    ]

    var role: UserRole {
        switch self {
        case .pilotHome, .pilotGigDetail, .pilotAcceptPing, .pilotGigBoard,
             .pilotNearbyMap, .pilotFly, .pilotChecklist, .pilotInFlight,
             .pilotWeather, .pilotDeliverables, .pilotReview, .pilotMessages,
             .pilotProfile, .pilotEarnings:
            return .pilot
        case .customerHome, .customerPostJob, .customerMyJobs, .customerJobDetail,
             .customerMessages, .customerProfile:
            return .customer
        }
    }

    /// Per-step duration in seconds — sized to fit the auto-actions inside.
    var durationSeconds: Double {
        switch self {
        // Pilot
        case .pilotHome:         return 3.0
        case .pilotGigBoard:     return 5.5  // scroll + sort cycle
        case .pilotGigDetail:    return 3.5
        case .pilotAcceptPing:   return 6.5  // HeroFlow auto-progresses 4 stages
        case .pilotFly:          return 3.5
        case .pilotNearbyMap:    return 4.5  // pin select + filter
        case .pilotWeather:      return 3.5
        case .pilotChecklist:    return 3.0  // dwell + auto-takeoff
        case .pilotInFlight:     return 4.5
        case .pilotDeliverables: return 6.0  // upload + auto-submit
        case .pilotReview:       return 5.5  // tags + note + submit
        case .pilotMessages:     return 4.0
        case .pilotProfile:      return 3.0
        case .pilotEarnings:     return 3.0
        // Customer
        case .customerHome:      return 3.0
        case .customerPostJob:   return 6.0  // type cycle + auto-post
        case .customerMyJobs:    return 4.5  // filter + scroll
        case .customerJobDetail: return 3.5
        case .customerMessages:  return 6.5  // open + auto-type + auto-send
        case .customerProfile:   return 3.0
        }
    }

    var title: String {
        switch self {
        case .pilotHome: return "Pilot home"
        case .pilotGigDetail: return "Gig details"
        case .pilotAcceptPing: return "Accept ping"
        case .pilotGigBoard: return "Gig board"
        case .pilotNearbyMap: return "Nearby gigs"
        case .pilotFly: return "Active mission"
        case .pilotChecklist: return "Pre-flight"
        case .pilotInFlight: return "In flight"
        case .pilotWeather: return "Weather briefing"
        case .pilotDeliverables: return "Deliver work"
        case .pilotReview: return "Rate the client"
        case .pilotMessages: return "Pilot messages"
        case .pilotProfile: return "Pilot profile"
        case .pilotEarnings: return "Earnings"
        case .customerHome: return "Customer home"
        case .customerPostJob: return "Post a job"
        case .customerMyJobs: return "My jobs"
        case .customerJobDetail: return "Job details"
        case .customerMessages: return "Customer messages"
        case .customerProfile: return "Customer profile"
        }
    }

    var subtitle: String {
        switch self {
        case .pilotHome:
            return "Today's gig and quick actions"
        case .pilotGigBoard:
            return "Sort and scan available gigs"
        case .pilotGigDetail:
            return "Map, payout, deliverables, client"
        case .pilotAcceptPing:
            return "Accept the ping and lock it in"
        case .pilotFly:
            return "Active mission and tools"
        case .pilotNearbyMap:
            return "Map of nearby gigs"
        case .pilotWeather:
            return "METAR & TAF for the next mission"
        case .pilotChecklist:
            return "Confirm preflight and take off"
        case .pilotInFlight:
            return "Recording HUD and telemetry"
        case .pilotDeliverables:
            return "Hand off photos and video"
        case .pilotReview:
            return "Rating, tags, and a note"
        case .pilotMessages:
            return "Live thread with the client"
        case .pilotProfile:
            return "Credentials and equipment"
        case .pilotEarnings:
            return "Weekly earnings and history"
        case .customerHome:
            return "Recent activity and post a job"
        case .customerPostJob:
            return "Pick a job type and post"
        case .customerMyJobs:
            return "Open and completed jobs"
        case .customerJobDetail:
            return "Pilot, payout, deliverables"
        case .customerMessages:
            return "Type a message to the pilot"
        case .customerProfile:
            return "Billing, addresses, settings"
        }
    }
}

@MainActor
final class DemoModeStore: ObservableObject {
    static let defaultsKey = "demoMode.isOn"
    static let roleOverrideKey = "demoMode.roleOverride"

    @Published private(set) var showcaseStep: DemoShowcaseStep?
    @Published private(set) var currentFlow: DemoShowcaseFlow?
    @Published private(set) var showcaseRunID = UUID()
    @Published private(set) var elapsedSeconds: Double = 0
    @Published private(set) var isPaused: Bool = false

    @Published var isOn: Bool {
        didSet {
            guard oldValue != isOn else { return }
            defaults.set(isOn, forKey: Self.defaultsKey)
        }
    }

    @Published var roleOverride: UserRole? {
        didSet {
            guard oldValue != roleOverride else { return }
            if let role = roleOverride {
                defaults.set(role.rawValue, forKey: Self.roleOverrideKey)
            } else {
                defaults.removeObject(forKey: Self.roleOverrideKey)
            }
        }
    }

    private let defaults: UserDefaults
    private var timer: Timer?
    private static let tickInterval: Double = 0.1

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let env = ProcessInfo.processInfo.environment
        if let envOn = env["AVIARY_DEMO_ON"] {
            self.isOn = (envOn as NSString).boolValue
        } else {
            self.isOn = defaults.bool(forKey: Self.defaultsKey)
        }
        if let envRole = env["AVIARY_DEMO_ROLE"], let role = UserRole(rawValue: envRole) {
            self.roleOverride = role
        } else if let raw = defaults.string(forKey: Self.roleOverrideKey),
           let role = UserRole(rawValue: raw) {
            self.roleOverride = role
        } else {
            self.roleOverride = nil
        }
    }

    deinit {
        timer?.invalidate()
    }

    var isShowcaseRunning: Bool {
        showcaseStep != nil
    }

    /// Active script for the running flow, or pilot script as a default.
    private var activeScript: [DemoShowcaseStep] {
        currentFlow?.script ?? DemoShowcaseStep.pilotScript
    }

    var showcaseProgressText: String? {
        guard let showcaseStep,
              let index = activeScript.firstIndex(of: showcaseStep) else {
            return nil
        }
        return "\(index + 1)/\(activeScript.count)"
    }

    /// Cumulative seconds before this step within the active script.
    private func startOffset(of step: DemoShowcaseStep) -> Double {
        var sum = 0.0
        for s in activeScript {
            if s == step { return sum }
            sum += s.durationSeconds
        }
        return sum
    }

    /// Locally-elapsed seconds within the current step.
    var elapsedInStep: Double {
        guard let step = showcaseStep else { return 0 }
        return max(0, elapsedSeconds - startOffset(of: step))
    }

    /// Progress (0...1) within the current step.
    var progressInStep: Double {
        guard let step = showcaseStep else { return 0 }
        guard step.durationSeconds > 0 else { return 1 }
        return max(0, min(1, elapsedInStep / step.durationSeconds))
    }

    /// Progress (0...1) across the entire active flow.
    var totalProgress: Double {
        guard let flow = currentFlow else { return 0 }
        let total = flow.totalDurationSeconds
        guard total > 0 else { return 0 }
        return max(0, min(1, elapsedSeconds / total))
    }

    /// The step queued after the current one, useful for previewing in the HUD.
    var upcomingStep: DemoShowcaseStep? {
        guard let step = showcaseStep,
              let idx = activeScript.firstIndex(of: step),
              idx + 1 < activeScript.count else {
            return nil
        }
        return activeScript[idx + 1]
    }

    func startShowcase(flow: DemoShowcaseFlow) {
        stopTimer()
        isOn = true
        currentFlow = flow
        showcaseRunID = UUID()
        elapsedSeconds = 0
        isPaused = false

        let firstStep = flow.script.first
        roleOverride = flow.role
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            showcaseStep = firstStep
        }

        startTimer()
    }

    func stopShowcase() {
        stopTimer()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showcaseStep = nil
        }
        currentFlow = nil
        elapsedSeconds = 0
        isPaused = false
    }

    func togglePause() {
        guard isShowcaseRunning else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            isPaused.toggle()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Self.tickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard !isPaused, isShowcaseRunning, currentFlow != nil else { return }
        elapsedSeconds += Self.tickInterval

        let nextStep = stepForElapsed(elapsedSeconds)
        if nextStep == nil {
            stopShowcase()
            return
        }

        if nextStep != showcaseStep {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                if let role = nextStep?.role, roleOverride != role {
                    roleOverride = role
                }
                showcaseStep = nextStep
            }
        }
    }

    private func stepForElapsed(_ elapsed: Double) -> DemoShowcaseStep? {
        guard elapsed >= 0 else { return activeScript.first }
        var sum = 0.0
        for s in activeScript {
            sum += s.durationSeconds
            if elapsed < sum { return s }
        }
        return nil
    }
}
