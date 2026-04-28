import SwiftUI

struct AuthScreen: View {
    enum Mode { case signUp, signIn }

    var role: UserRole
    var onBack: () -> Void

    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.theme) private var t

    @State private var mode: Mode = .signUp
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var emailTouched: Bool = false
    @State private var passwordTouched: Bool = false
    @State private var firstNameTouched: Bool = false
    @State private var lastNameTouched: Bool = false
    @FocusState private var focused: Field?

    private enum Field { case firstName, lastName, email, password }

    var body: some View {
        Group {
            if let pending = auth.pendingVerification {
                VerifyEmailScreen(pending: pending)
            } else {
                formBody
            }
        }
    }

    private var formBody: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: onBack) {
                        AviaryIcon(name: "arrow-left", size: 24, color: t.ink)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)

                    Text(mode == .signUp ? "STEP 4 OF 4 · ACCOUNT" : "WELCOME BACK")
                        .font(AviaryFont.body(13, weight: .semibold))
                        .tracking(0.04 * 13)
                        .foregroundStyle(t.accent)
                        .padding(.bottom, 8)

                    Text(mode == .signUp ? "Create your account" : "Sign in")
                        .font(AviaryFont.display(30, weight: .bold))
                        .tracking(-0.025 * 30)
                        .foregroundStyle(t.ink)
                        .padding(.bottom, 8)

                    Text(subtitle)
                        .font(AviaryFont.body(15))
                        .foregroundStyle(t.ink3)
                        .lineSpacing(3)
                        .padding(.bottom, 24)

                    if mode == .signUp {
                        roleBadge
                            .padding(.bottom, 14)

                        HStack(spacing: 12) {
                            field(label: "FIRST NAME",
                                  text: $firstName,
                                  isSecure: false,
                                  contentType: .givenName,
                                  keyboard: .default,
                                  autocap: .words,
                                  field: .firstName,
                                  hasError: firstNameTouched && !isFirstNameValid)
                            field(label: "LAST NAME",
                                  text: $lastName,
                                  isSecure: false,
                                  contentType: .familyName,
                                  keyboard: .default,
                                  autocap: .words,
                                  field: .lastName,
                                  hasError: lastNameTouched && !isLastNameValid)
                        }
                        if (firstNameTouched && !isFirstNameValid) || (lastNameTouched && !isLastNameValid) {
                            inlineMessage("Please enter both your first and last name.", isError: true)
                                .padding(.bottom, 8)
                        }
                    }

                    field(label: "EMAIL",
                          text: $email,
                          isSecure: false,
                          contentType: .emailAddress,
                          keyboard: .emailAddress,
                          autocap: .never,
                          field: .email,
                          hasError: emailTouched && !isEmailValid)

                    if emailTouched && !email.isEmpty && !isEmailValid {
                        inlineMessage("Enter a valid email like name@example.com.", isError: true)
                            .padding(.bottom, 8)
                    } else if emailTouched && email.isEmpty {
                        inlineMessage("Email is required.", isError: true)
                            .padding(.bottom, 8)
                    }

                    field(label: "PASSWORD",
                          text: $password,
                          isSecure: true,
                          contentType: mode == .signUp ? .newPassword : .password,
                          keyboard: .default,
                          autocap: .never,
                          field: .password,
                          hasError: passwordTouched && !isPasswordValid)

                    if mode == .signUp {
                        passwordRequirementsList
                            .padding(.top, 4)
                            .padding(.bottom, 8)
                    } else if passwordTouched && password.isEmpty {
                        inlineMessage("Password is required.", isError: true)
                            .padding(.bottom, 8)
                    }

                    if let error = auth.errorMessage {
                        inlineMessage(error, isError: true)
                            .padding(.top, 4)
                            .padding(.bottom, 8)
                    }

                    PrimaryButton(
                        title: mode == .signUp ? "Create account" : "Sign in",
                        systemTrailing: "arrow.right",
                        enabled: canSubmit && !auth.isWorking,
                        action: submit
                    )
                    .padding(.top, 16)

                    if !canSubmit {
                        Text(missingRequirementsHint)
                            .font(AviaryFont.body(12))
                            .foregroundStyle(t.ink3)
                            .padding(.top, 8)
                    }

                    HStack(spacing: 6) {
                        Text(mode == .signUp ? "Already have an account?" : "New to Aviary?")
                            .font(AviaryFont.body(13))
                            .foregroundStyle(t.ink3)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                mode = (mode == .signUp) ? .signIn : .signUp
                                auth.errorMessage = nil
                                resetTouched()
                            }
                        } label: {
                            Text(mode == .signUp ? "Sign in" : "Create one")
                                .font(AviaryFont.body(13, weight: .semibold))
                                .foregroundStyle(t.accent)
                        }
                        Spacer()
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .onChange(of: mode) { _, _ in
            password = ""
            passwordTouched = false
        }
        .onChange(of: focused) { old, _ in
            switch old {
            case .firstName: firstNameTouched = true
            case .lastName: lastNameTouched = true
            case .email: emailTouched = true
            case .password: passwordTouched = true
            case .none: break
            }
        }
    }

    private var subtitle: String {
        switch mode {
        case .signUp:
            return "You'll sign in with this email next time. Pick a password that meets every rule below."
        case .signIn:
            return "Use the email and password you signed up with."
        }
    }

    // MARK: - Validation

    private var trimmedFirstName: String { firstName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedLastName: String { lastName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var isFirstNameValid: Bool { trimmedFirstName.count >= 1 }
    private var isLastNameValid: Bool { trimmedLastName.count >= 1 }

    private var isEmailValid: Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return trimmedEmail.range(of: pattern, options: .regularExpression) != nil
    }

    private var hasMinLength: Bool { password.count >= 8 }
    private var hasLetter: Bool { password.range(of: "[A-Za-z]", options: .regularExpression) != nil }
    private var hasNumber: Bool { password.range(of: "[0-9]", options: .regularExpression) != nil }
    private var hasNoSpaces: Bool { !password.contains(" ") && !password.isEmpty }

    private var isPasswordValid: Bool {
        if mode == .signIn { return !password.isEmpty }
        return hasMinLength && hasLetter && hasNumber && hasNoSpaces
    }

    private var canSubmit: Bool {
        switch mode {
        case .signUp:
            return isFirstNameValid && isLastNameValid && isEmailValid && isPasswordValid
        case .signIn:
            return isEmailValid && !password.isEmpty
        }
    }

    private var missingRequirementsHint: String {
        var missing: [String] = []
        if mode == .signUp {
            if !isFirstNameValid { missing.append("first name") }
            if !isLastNameValid { missing.append("last name") }
        }
        if !isEmailValid { missing.append("a valid email") }
        if mode == .signUp {
            if !isPasswordValid { missing.append("a strong password") }
        } else if password.isEmpty {
            missing.append("your password")
        }
        if missing.isEmpty { return "" }
        return "Still needed: " + missing.joined(separator: ", ") + "."
    }

    // MARK: - Subviews

    private var passwordRequirementsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            requirementRow("At least 8 characters", met: hasMinLength)
            requirementRow("Includes a letter", met: hasLetter)
            requirementRow("Includes a number", met: hasNumber)
            requirementRow("No spaces", met: hasNoSpaces)
        }
    }

    private func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(met ? t.accent : t.ink4)
            Text(text)
                .font(AviaryFont.body(12))
                .foregroundStyle(met ? t.ink2 : t.ink3)
        }
    }

    private func inlineMessage(_ message: String, isError: Bool) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isError ? t.warn : t.ink3)
                .padding(.top, 1)
            Text(message)
                .font(AviaryFont.body(13))
                .foregroundStyle(isError ? t.warn : t.ink3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    private var roleBadge: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(t.accentSoft)
                AviaryIcon(name: role == .pilot ? "drone" : "briefcase",
                           size: 18, stroke: 2, color: t.accent)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text("Signing up as")
                    .font(AviaryFont.body(11))
                    .foregroundStyle(t.ink3)
                Text(role.displayName)
                    .font(AviaryFont.body(15, weight: .semibold))
                    .foregroundStyle(t.ink)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(t.line)
        )
    }

    private func field(label: String,
                       text: Binding<String>,
                       isSecure: Bool,
                       contentType: UITextContentType,
                       keyboard: UIKeyboardType,
                       autocap: TextInputAutocapitalization,
                       field: Field,
                       hasError: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AviaryFont.body(12, weight: .semibold))
                .tracking(0.04 * 12)
                .foregroundStyle(t.ink3)
            Group {
                if isSecure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                        .textInputAutocapitalization(autocap)
                        .autocorrectionDisabled(true)
                }
            }
            .focused($focused, equals: field)
            .textContentType(contentType)
            .keyboardType(keyboard)
            .font(AviaryFont.body(16))
            .foregroundStyle(t.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(t.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor(for: field, hasError: hasError),
                                  lineWidth: focused == field || hasError ? 2 : 1)
            )
        }
        .padding(.bottom, 12)
    }

    private func borderColor(for field: Field, hasError: Bool) -> Color {
        if hasError { return t.warn }
        if focused == field { return t.accent }
        return t.line
    }

    private func resetTouched() {
        firstNameTouched = false
        lastNameTouched = false
        emailTouched = false
        passwordTouched = false
    }

    private func submit() {
        focused = nil
        firstNameTouched = true
        lastNameTouched = true
        emailTouched = true
        passwordTouched = true
        guard canSubmit else { return }
        let emailValue = trimmedEmail
        let firstNameValue = trimmedFirstName
        let lastNameValue = trimmedLastName
        Task {
            switch mode {
            case .signUp:
                await auth.signUp(
                    email: emailValue,
                    password: password,
                    firstName: firstNameValue,
                    lastName: lastNameValue,
                    role: role
                )
            case .signIn:
                await auth.signIn(email: emailValue, password: password)
            }
        }
    }
}
