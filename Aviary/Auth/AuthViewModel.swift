import Combine
import Foundation
import Supabase
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    enum AuthState: Equatable {
        case loading
        case signedOut
        case signedIn(UserProfile)
    }

    struct PendingVerification: Equatable {
        let email: String
        let firstName: String
        let lastName: String
        let role: UserRole
    }

    @Published private(set) var state: AuthState = .loading
    @Published var errorMessage: String?
    @Published private(set) var isWorking: Bool = false
    @Published var pendingVerification: PendingVerification?
    @Published private(set) var displayedProfile: UserProfile?

    private let client = Backend.client
    private var stateChangesTask: Task<Void, Never>?
    private let demoStore: DemoModeStore
    private var demoCancellable: AnyCancellable?
    private var realProfile: UserProfile?

    init(demoStore: DemoModeStore) {
        self.demoStore = demoStore
        let isOnUpdates = demoStore.$isOn.removeDuplicates().map { _ in () }
        let roleUpdates = demoStore.$roleOverride.removeDuplicates().map { _ in () }
        self.demoCancellable = isOnUpdates.merge(with: roleUpdates)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    await self.recomputeDisplayedProfile()
                }
            }
    }

    deinit {
        stateChangesTask?.cancel()
        demoCancellable?.cancel()
    }

    func bootstrap() async {
        if !SupabaseConfig.isConfigured {
            state = .signedOut
            return
        }
        do {
            let session = try await client.auth.session
            await fetchAndSetProfile(for: session.user.id, fallbackEmail: session.user.email)
        } catch {
            state = .signedOut
        }
        startListening()
    }

    func signUp(email: String, password: String, firstName: String, lastName: String, role: UserRole) async {
        errorMessage = nil
        if !SupabaseConfig.isConfigured {
            errorMessage = "Supabase isn't configured yet. Add your project URL and anon key to Aviary/Secrets.plist."
            return
        }
        isWorking = true
        defer { isWorking = false }
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            switch response {
            case .session(let session):
                try await insertProfile(
                    userId: session.user.id,
                    email: email,
                    firstName: trimmedFirst,
                    lastName: trimmedLast,
                    role: role
                )
                await fetchAndSetProfile(for: session.user.id, fallbackEmail: email)
            case .user:
                pendingVerification = PendingVerification(
                    email: email,
                    firstName: trimmedFirst,
                    lastName: trimmedLast,
                    role: role
                )
                state = .signedOut
            }
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func verifyEmailCode(_ code: String) async {
        guard let pending = pendingVerification else { return }
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let response = try await client.auth.verifyOTP(
                email: pending.email,
                token: trimmedCode,
                type: .signup
            )
            let userId: UUID
            switch response {
            case .session(let session):
                userId = session.user.id
            case .user(let user):
                userId = user.id
            }
            try await insertProfile(
                userId: userId,
                email: pending.email,
                firstName: pending.firstName,
                lastName: pending.lastName,
                role: pending.role
            )
            pendingVerification = nil
            await fetchAndSetProfile(for: userId, fallbackEmail: pending.email)
        } catch {
            errorMessage = verificationFriendlyMessage(for: error)
        }
    }

    func resendVerificationCode() async {
        guard let pending = pendingVerification else { return }
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try await client.auth.resend(email: pending.email, type: .signup)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func cancelVerification() {
        pendingVerification = nil
        errorMessage = nil
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        if !SupabaseConfig.isConfigured {
            errorMessage = "Supabase isn't configured yet. Add your project URL and anon key to Aviary/Secrets.plist."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await client.auth.signIn(email: email, password: password)
            let session = try await client.auth.session
            await fetchAndSetProfile(for: session.user.id, fallbackEmail: email)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func requestPasswordReset(email: String) async -> Bool {
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Enter your email above first."
            return false
        }
        if !SupabaseConfig.isConfigured {
            errorMessage = "Supabase isn't configured yet. Add your project URL and anon key to Aviary/Secrets.plist."
            return false
        }
        isWorking = true
        defer { isWorking = false }
        do {
            try await client.auth.resetPasswordForEmail(trimmedEmail)
            return true
        } catch {
            errorMessage = friendlyMessage(for: error)
            return false
        }
    }

    func signOut() async {
        errorMessage = nil
        do {
            try await client.auth.signOut()
            realProfile = nil
            displayedProfile = nil
            DemoProfileService.shared.clearCache()
            state = .signedOut
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func refreshProfile() async {
        guard let userID = realProfile?.id else { return }
        await fetchAndSetProfile(for: userID, fallbackEmail: realProfile?.email)
    }

    private func recomputeDisplayedProfile() async {
        guard let real = realProfile else {
            displayedProfile = nil
            return
        }
        if !demoStore.isOn {
            displayedProfile = real
            return
        }
        let role = demoStore.roleOverride ?? real.role
        do {
            let demo = try await DemoProfileService.shared.demoProfile(for: role)
            displayedProfile = demo
        } catch {
            displayedProfile = real
            errorMessage = "Couldn't load demo data, showing your account."
        }
    }

    private func insertProfile(userId: UUID,
                               email: String,
                               firstName: String,
                               lastName: String,
                               role: UserRole) async throws {
        let row = ProfileInsert(
            id: userId,
            email: email,
            role: role.rawValue,
            first_name: firstName.isEmpty ? nil : firstName,
            last_name: lastName.isEmpty ? nil : lastName
        )
        try await client.from("profiles").insert(row).execute()
    }

    private func fetchAndSetProfile(for userId: UUID, fallbackEmail: String?) async {
        do {
            let profile: UserProfile = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            realProfile = profile
            state = .signedIn(profile)
            await recomputeDisplayedProfile()
        } catch {
            errorMessage = "We couldn't load your profile. Please sign in again."
            try? await client.auth.signOut()
            realProfile = nil
            displayedProfile = nil
            state = .signedOut
        }
    }

    private func startListening() {
        stateChangesTask?.cancel()
        let stream = client.auth.authStateChanges
        stateChangesTask = Task { [weak self] in
            for await change in stream {
                guard let self else { return }
                if Task.isCancelled { return }
                if change.event == .signedOut {
                    await MainActor.run { self.state = .signedOut }
                }
            }
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        let raw = error.localizedDescription
        if raw.localizedCaseInsensitiveContains("invalid login") ||
           raw.localizedCaseInsensitiveContains("invalid credentials") {
            return "Email or password is incorrect."
        }
        if raw.localizedCaseInsensitiveContains("already registered") ||
           raw.localizedCaseInsensitiveContains("already exists") ||
           raw.localizedCaseInsensitiveContains("user already") {
            return "An account with that email already exists. Try signing in."
        }
        if raw.localizedCaseInsensitiveContains("weak password") ||
           raw.localizedCaseInsensitiveContains("at least") {
            return "Password is too weak. Use at least 8 characters with a letter and a number."
        }
        return raw
    }

    private func verificationFriendlyMessage(for error: Error) -> String {
        let raw = error.localizedDescription
        if raw.localizedCaseInsensitiveContains("expired") {
            return "That code has expired. Tap Resend to get a new one."
        }
        if raw.localizedCaseInsensitiveContains("invalid") ||
           raw.localizedCaseInsensitiveContains("token") {
            return "That code didn't match. Double-check the email and try again."
        }
        return friendlyMessage(for: error)
    }

    private struct ProfileInsert: Encodable {
        let id: UUID
        let email: String
        let role: String
        let first_name: String?
        let last_name: String?
    }
}
