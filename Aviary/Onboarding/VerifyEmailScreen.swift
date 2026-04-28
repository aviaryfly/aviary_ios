import SwiftUI

struct VerifyEmailScreen: View {
    let pending: AuthViewModel.PendingVerification

    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.theme) private var t

    @State private var code: String = ""
    @State private var resendCooldown: Int = 0
    @FocusState private var focused: Bool

    private let codeLength = 6
    private let resendCooldownSeconds = 60

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        auth.cancelVerification()
                    } label: {
                        AviaryIcon(name: "arrow-left", size: 24, color: t.ink)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)

                    Text("STEP 4 OF 4 · VERIFY")
                        .font(AviaryFont.body(13, weight: .semibold))
                        .tracking(0.04 * 13)
                        .foregroundStyle(t.accent)
                        .padding(.bottom, 8)

                    Text("Check your email")
                        .font(AviaryFont.display(30, weight: .bold))
                        .tracking(-0.025 * 30)
                        .foregroundStyle(t.ink)
                        .padding(.bottom, 8)

                    Text("We sent a 6-digit code to \(pending.email). Enter it below to confirm your account.")
                        .font(AviaryFont.body(15))
                        .foregroundStyle(t.ink3)
                        .lineSpacing(3)
                        .padding(.bottom, 24)

                    codeBoxes
                        .padding(.bottom, 16)

                    if let error = auth.errorMessage {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(t.warn)
                                .padding(.top, 1)
                            Text(error)
                                .font(AviaryFont.body(13))
                                .foregroundStyle(t.warn)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, 8)
                    }

                    PrimaryButton(
                        title: "Verify and continue",
                        systemTrailing: "arrow.right",
                        enabled: code.count == codeLength && !auth.isWorking,
                        action: submit
                    )
                    .padding(.top, 4)

                    HStack(spacing: 6) {
                        Text("Didn't get the email?")
                            .font(AviaryFont.body(13))
                            .foregroundStyle(t.ink3)
                        Button(action: resend) {
                            Text(resendCooldown > 0 ? "Resend in \(resendCooldown)s" : "Resend code")
                                .font(AviaryFont.body(13, weight: .semibold))
                                .foregroundStyle(resendCooldown > 0 ? t.ink4 : t.accent)
                        }
                        .disabled(resendCooldown > 0 || auth.isWorking)
                        Spacer()
                    }
                    .padding(.top, 16)

                    Text("The code expires after a short time. Check your spam folder if you don't see it within a minute.")
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink3)
                        .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            focused = true
        }
        .onChange(of: code) { _, newValue in
            let digits = newValue.filter { $0.isNumber }
            let trimmed = String(digits.prefix(codeLength))
            if trimmed != newValue {
                code = trimmed
            }
        }
    }

    private var codeBoxes: some View {
        ZStack(alignment: .leading) {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .accentColor(.clear)
                .frame(height: 56)
                .background(Color.clear)

            HStack(spacing: 10) {
                ForEach(0..<codeLength, id: \.self) { index in
                    digitBox(at: index)
                }
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
    }

    private func digitBox(at index: Int) -> some View {
        let chars = Array(code)
        let char = index < chars.count ? String(chars[index]) : ""
        let isActive = focused && index == chars.count
        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(t.surface)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isActive ? t.accent : t.line,
                              lineWidth: isActive ? 2 : 1)
            Text(char)
                .font(AviaryFont.display(24, weight: .semibold))
                .foregroundStyle(t.ink)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
    }

    private func submit() {
        focused = false
        Task {
            await auth.verifyEmailCode(code)
        }
    }

    private func resend() {
        guard resendCooldown == 0 else { return }
        Task {
            await auth.resendVerificationCode()
            await runCooldown()
        }
    }

    private func runCooldown() async {
        resendCooldown = resendCooldownSeconds
        while resendCooldown > 0 {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            resendCooldown -= 1
        }
    }
}
