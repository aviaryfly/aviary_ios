import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Pre-flight checklist

struct PreFlightScreen: View {
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore
    var onTakeoff: () -> Void = {}
    var onBack: () -> Void = {}
    @State private var autoTakeoffTask: Task<Void, Never>?
    @State private var showcaseTakeoffPressed = false

    private struct Item: Identifiable { let id = UUID(); var label: String; var value: String?; var done: Bool; var warn: Bool = false }
    private let aircraft: [Item] = [
        .init(label: "Drone battery", value: "98% · 2 spares charged", done: true),
        .init(label: "SD card · clean & seated", value: "128 GB free", done: true),
        .init(label: "Visual line of sight", value: "No obstructions", done: true),
        .init(label: "Airspace authorization", value: "LAANC granted · 200 ft AGL", done: true),
    ]
    private let conditions: [Item] = [
        .init(label: "Weather check", value: "Clear · 9 mph · gust 14", done: true),
        .init(label: "Bystanders briefed", value: "Confirmed with on-site contact", done: true),
    ]

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                progressBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionTitle(text: "Aircraft & site")
                            .padding(.bottom, 8)
                        ForEach(aircraft) { row(for: $0) }

                        SectionTitle(text: "Conditions")
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        ForEach(conditions) { row(for: $0) }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                footer
            }
        }
        .onAppear { startAutoTakeoffIfNeeded() }
        .onDisappear {
            autoTakeoffTask?.cancel()
            autoTakeoffTask = nil
            showcaseTakeoffPressed = false
        }
        .onChange(of: demoStore.showcaseStep) { _, _ in
            startAutoTakeoffIfNeeded()
        }
    }

    private func startAutoTakeoffIfNeeded() {
        guard demoStore.isOn,
              demoStore.showcaseStep == .pilotChecklist else { return }
        autoTakeoffTask?.cancel()
        autoTakeoffTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 1_900_000_000)
                guard !Task.isCancelled,
                      demoStore.showcaseStep == .pilotChecklist else { return }
                withAnimation(.easeInOut(duration: 0.18)) {
                    showcaseTakeoffPressed = true
                }
                try await Task.sleep(nanoseconds: 220_000_000)
                guard !Task.isCancelled,
                      demoStore.showcaseStep == .pilotChecklist else { return }
                onTakeoff()
            } catch {
                return
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                AviaryIcon(name: "arrow-left", size: 22, color: t.ink)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("EN ROUTE · 4 min away")
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.ink3)
                Text("Pre-flight checklist")
                    .font(AviaryFont.body(16, weight: .semibold))
                    .foregroundStyle(t.ink)
            }
            Spacer()
            Text("6 of 6")
                .font(AviaryFont.mono(13, weight: .semibold))
                .foregroundStyle(t.good)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(t.surface2).frame(height: 4)
            GeometryReader { geo in
                Capsule().fill(t.good)
                    .frame(width: geo.size.width, height: 4)
            }
            .frame(height: 4)
        }
    }

    private func row(for it: Item) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(it.done ? t.good : (it.warn ? t.warn : t.surface2))
                if it.done {
                    AviaryIcon(name: "check", size: 16, stroke: 3, color: .white)
                } else if it.warn {
                    Text("!")
                        .font(AviaryFont.body(14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(it.label)
                    .font(AviaryFont.body(14, weight: .medium))
                    .foregroundStyle(t.ink)
                if let v = it.value {
                    Text(v)
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink3)
                }
            }
            Spacer()
            AviaryIcon(name: "chevron-right", size: 16, color: t.ink4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14).strokeBorder(t.line)
        )
        .padding(.bottom, 8)
    }

    private var footer: some View {
        VStack {
            PrimaryButton(title: "Take off", systemTrailing: "arrow.right", action: onTakeoff)
                .scaleEffect(showcaseTakeoffPressed ? 0.96 : 1)
                .animation(.easeInOut(duration: 0.18), value: showcaseTakeoffPressed)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            t.surface
                .overlay(Rectangle().fill(t.line).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - In-flight HUD (forced cockpit dark)

struct InFlightScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var demoStore: DemoModeStore

    private let bg = Color(hex: 0x0B0E14)
    private let amber = Color(hex: 0xFFB23A)
    private let ink = Color(hex: 0xF4F5F7)
    private let dim = Color(hex: 0x8B92A0)
    private let good = Color(hex: 0x10A36F)

    @State private var stopButtonPressed = false
    @State private var autoEndTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            cameraFeed.ignoresSafeArea()

            recBar
            reticle
            telemetryStack
            batteryStack
            shotList
            controls
            closeButton
        }
        .preferredColorScheme(.dark)
        .onAppear { startAutoEndIfNeeded() }
        .onDisappear {
            autoEndTask?.cancel()
            autoEndTask = nil
            stopButtonPressed = false
        }
        .onChange(of: demoStore.showcaseStep) { _, _ in
            startAutoEndIfNeeded()
        }
    }

    /// In showcase mode, dwell on the HUD then visibly press the red stop button before
    /// the parent rolls the showcase to the deliverables step.
    private func startAutoEndIfNeeded() {
        guard demoStore.isOn,
              demoStore.showcaseStep == .pilotInFlight else { return }
        autoEndTask?.cancel()
        autoEndTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 3_500_000_000)
                guard !Task.isCancelled,
                      demoStore.showcaseStep == .pilotInFlight else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    stopButtonPressed = true
                }
                try await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled,
                      demoStore.showcaseStep == .pilotInFlight else { return }
                dismiss()
            } catch {
                return
            }
        }
    }

    private var cameraFeed: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RadialGradient(colors: [Color(hex: 0x1A2436), Color(hex: 0x060810)],
                               center: .init(x: 0.5, y: 0.3),
                               startRadius: 0, endRadius: max(w, h))

                Canvas { ctx, size in
                    let sx = size.width / 390
                    let sy = size.height / 700

                    var ground = Path()
                    ground.move(to: .init(x: 0, y: 500 * sy))
                    ground.addLine(to: .init(x: 130 * sx, y: 360 * sy))
                    ground.addLine(to: .init(x: 260 * sx, y: 360 * sy))
                    ground.addLine(to: .init(x: 390 * sx, y: 500 * sy))
                    ground.closeSubpath()
                    ctx.fill(ground, with: .color(Color(hex: 0x1F2A3D).opacity(0.6)))

                    var lower = Path()
                    lower.move(to: .init(x: 130 * sx, y: 360 * sy))
                    lower.addLine(to: .init(x: 260 * sx, y: 360 * sy))
                    lower.addLine(to: .init(x: 390 * sx, y: 500 * sy))
                    lower.addLine(to: .init(x: size.width, y: size.height))
                    lower.addLine(to: .init(x: 0, y: size.height))
                    lower.addLine(to: .init(x: 0, y: 500 * sy))
                    ctx.fill(lower, with: .color(Color(hex: 0x0E1521)))

                    let houses: [CGRect] = [
                        .init(x: 140, y: 380, width: 110, height: 40),
                        .init(x: 60,  y: 460, width: 120, height: 60),
                        .init(x: 270, y: 470, width: 90,  height: 70),
                    ]
                    for r in houses {
                        let scaled = CGRect(x: r.minX * sx, y: r.minY * sy,
                                            width: r.width * sx, height: r.height * sy)
                        ctx.fill(Path(scaled), with: .color(Color(hex: 0x2A3850).opacity(0.7)))
                        ctx.stroke(Path(scaled), with: .color(Color(hex: 0x3D4F6E)), lineWidth: 1)
                    }
                }
            }
        }
    }

    private var recBar: some View {
        VStack {
            HStack {
                HStack(spacing: 6) {
                    Text("● REC")
                        .font(AviaryFont.body(12, weight: .semibold))
                        .foregroundStyle(amber)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(amber.opacity(0.18)))
                        .overlay(Capsule().strokeBorder(amber))
                    Text("04:32")
                        .font(AviaryFont.mono(12, weight: .semibold))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                Spacer()
                Text("4K · 60 fps")
                    .font(AviaryFont.mono(12, weight: .semibold))
                    .foregroundStyle(ink)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            Spacer()
        }
    }

    private var reticle: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height * 0.38
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(amber.opacity(0.7), lineWidth: 1.5)
                    .frame(width: 80, height: 80)
                Group {
                    Rectangle().fill(amber).frame(width: 6, height: 1.5).offset(x: -45)
                    Rectangle().fill(amber).frame(width: 6, height: 1.5).offset(x: 45)
                    Rectangle().fill(amber).frame(width: 1.5, height: 6).offset(y: -45)
                    Rectangle().fill(amber).frame(width: 1.5, height: 6).offset(y: 45)
                }
            }
            .position(x: cx, y: cy)
        }
    }

    private var telemetryStack: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 12) {
                tile(label: "ALT", value: "127", unit: "ft")
                tile(label: "SPD", value: "12",  unit: "mph")
                tile(label: "DIST", value: "340", unit: "ft")
            }
            .position(x: 50, y: geo.size.height * 0.42)
        }
    }

    private func tile(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AviaryFont.body(10, weight: .semibold))
                .tracking(0.08 * 10)
                .foregroundStyle(dim)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AviaryFont.mono(18, weight: .semibold))
                    .foregroundStyle(ink)
                Text(unit)
                    .font(AviaryFont.body(10))
                    .foregroundStyle(dim)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: 0x0B0E14).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1))
        )
        .frame(minWidth: 64)
    }

    private var batteryStack: some View {
        GeometryReader { geo in
            VStack(spacing: 2) {
                AviaryIcon(name: "battery", size: 20, stroke: 2, color: good)
                Text("78%")
                    .font(AviaryFont.mono(18, weight: .semibold))
                    .foregroundStyle(good)
                Text("~14 min")
                    .font(AviaryFont.body(9))
                    .foregroundStyle(dim)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x0B0E14).opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1))
            )
            .position(x: geo.size.width - 46, y: geo.size.height * 0.42)
        }
    }

    private var shotList: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("SHOT LIST · 7 OF 12")
                    .font(AviaryFont.body(11, weight: .semibold))
                    .tracking(0.08 * 11)
                    .foregroundStyle(dim)
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(amber)
                        AviaryIcon(name: "camera", size: 14, stroke: 2.5, color: bg)
                    }
                    .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Front exterior · twilight")
                            .font(AviaryFont.body(14, weight: .semibold))
                            .foregroundStyle(ink)
                        Text("20 ft AGL · 30° pitch")
                            .font(AviaryFont.body(11))
                            .foregroundStyle(dim)
                    }
                    Spacer()
                    Text("Capture")
                        .font(AviaryFont.body(12, weight: .semibold))
                        .foregroundStyle(bg)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(amber))
                }
                HStack(spacing: 4) {
                    ForEach(0..<12, id: \.self) { i in
                        let fill: Color = i < 7 ? amber
                            : (i == 7 ? amber.opacity(0.4) : Color.white.opacity(0.1))
                        Capsule().fill(fill).frame(height: 4)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: 0x0B0E14).opacity(0.7))
                    .background(.ultraThinMaterial.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.1))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 124)
        }
    }

    private var controls: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    Circle().fill(Color.white.opacity(0.08))
                        .background(.ultraThinMaterial.opacity(0.5))
                        .clipShape(Circle())
                    AviaryIcon(name: "home", size: 20, color: ink)
                }
                .frame(width: 48, height: 48)
                Spacer()
                Circle().fill(Color(hex: 0xE5484D))
                    .frame(width: 72, height: 72)
                    .overlay(Circle().strokeBorder(ink, lineWidth: 4))
                    .scaleEffect(stopButtonPressed ? 0.92 : 1)
                    .animation(.easeInOut(duration: 0.15), value: stopButtonPressed)
                Spacer()
                ZStack {
                    Circle().fill(Color.white.opacity(0.08))
                        .background(.ultraThinMaterial.opacity(0.5))
                        .clipShape(Circle())
                    AviaryIcon(name: "x", size: 20, color: ink)
                }
                .frame(width: 48, height: 48)
                Spacer()
            }
            .padding(.bottom, 36)
        }
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    Text("Done")
                        .font(AviaryFont.body(14, weight: .semibold))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .padding(.leading, 16)
                .padding(.top, 16)
                Spacer()
            }
            Spacer()
        }
    }
}

// MARK: - Deliverables upload

struct UploadAsset: Identifiable {
    let id = UUID()
    var pickerItem: PhotosPickerItem?
    var fileURL: URL?
    var image: Image?
    var isVideo: Bool
    var sizeBytes: Int64
    var progress: Double
    var done: Bool
    var failed: Bool
}

struct UploadScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var demoStore: DemoModeStore

    let job: AviaryJob?
    var onSubmit: ([UploadAsset]) -> Void = { _ in }

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var assets: [UploadAsset] = []
    @State private var isPickerPresented: Bool = false
    @State private var isFileImporterPresented: Bool = false
    @State private var isSourceDialogPresented: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    @State private var showcaseUploadTask: Task<Void, Never>?

    private var deliverables: [String] {
        job?.displayDeliverables ?? [
            "12 exterior photos · 4K",
            "60-sec cinematic flyover",
            "Edited delivery set"
        ]
    }

    private var doneCount: Int { assets.filter(\.done).count }
    private var totalProgress: Double {
        assets.isEmpty ? 0 : assets.map(\.progress).reduce(0, +) / Double(assets.count)
    }
    private var totalBytes: Int64 { assets.map(\.sizeBytes).reduce(0, +) }
    private var canSubmit: Bool {
        !assets.isEmpty && doneCount == assets.count && !isSubmitting
    }

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 16)

                    Text("Hand off your work")
                        .font(AviaryFont.display(26, weight: .bold))
                        .tracking(-0.02 * 26)
                        .foregroundStyle(t.ink)
                        .padding(.bottom, 4)
                    Text(subtitleText)
                        .font(AviaryFont.body(14))
                        .foregroundStyle(t.ink3)
                        .padding(.bottom, 16)

                    if !assets.isEmpty {
                        progressCard
                            .padding(.bottom, 16)
                    }

                    if !deliverables.isEmpty {
                        SectionTitle(text: "Required deliverables")
                            .padding(.bottom, 6)
                        deliverablesList
                            .padding(.bottom, 18)
                    }

                    SectionTitle(text: assets.isEmpty ? "Add photos & videos" : "Selected · \(assets.count)")
                        .padding(.bottom, 6)
                    pickerArea
                        .padding(.bottom, 18)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AviaryFont.body(12))
                            .foregroundStyle(t.bad)
                            .padding(.bottom, 12)
                    }

                    PrimaryButton(title: submitButtonTitle,
                                  enabled: canSubmit,
                                  action: submit)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .photosPicker(isPresented: $isPickerPresented,
                      selection: $pickerItems,
                      maxSelectionCount: 20,
                      matching: .any(of: [.images, .videos]),
                      preferredItemEncoding: .compatible)
        .onChange(of: pickerItems) { _, new in
            ingest(new)
            pickerItems = []
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.image, .movie],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                ingestFiles(urls)
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .confirmationDialog("Add photos & videos",
                            isPresented: $isSourceDialogPresented,
                            titleVisibility: .visible) {
            Button("Photo Library") { isPickerPresented = true }
            Button("Files") { isFileImporterPresented = true }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            seedShowcaseAssetsIfNeeded()
        }
        .onChange(of: demoStore.showcaseStep) { _, _ in
            seedShowcaseAssetsIfNeeded()
        }
        .onDisappear {
            showcaseUploadTask?.cancel()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                AviaryIcon(name: "x", size: 22, color: t.ink)
            }
            Text("Deliverables")
                .font(AviaryFont.body(16, weight: .semibold))
                .foregroundStyle(t.ink)
            Spacer()
            Chip(text: "\(doneCount) of \(assets.count)", style: .accent)
        }
    }

    private var subtitleText: String {
        if assets.isEmpty {
            return "Pick photos and videos from your library — we'll auto-upload them once selected."
        }
        if doneCount < assets.count {
            return "Auto-uploading over Wi-Fi · \(formattedBytes(totalBytes)) staged"
        }
        return "All \(assets.count) ready · tap submit to wrap up the gig"
    }

    private var submitButtonTitle: String {
        if isSubmitting { return "Submitting…" }
        if assets.isEmpty { return "Add files to submit" }
        if doneCount < assets.count { return "Uploading \(doneCount)/\(assets.count)…" }
        return "Submit & finish gig"
    }

    private var progressCard: some View {
        AviaryCard(padding: 14, shadowed: true) {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    AviaryIcon(name: "upload", size: 18, color: t.accent)
                    Text("Uploading \(doneCount) / \(assets.count)")
                        .font(AviaryFont.body(13, weight: .semibold))
                        .foregroundStyle(t.ink)
                    Spacer()
                    Text("\(Int(totalProgress * 100))%")
                        .font(AviaryFont.mono(13, weight: .semibold))
                        .foregroundStyle(t.ink3)
                }
                ZStack(alignment: .leading) {
                    Capsule().fill(t.surface2).frame(height: 6)
                    GeometryReader { geo in
                        Capsule().fill(t.accent)
                            .frame(width: max(0, geo.size.width * totalProgress),
                                   height: 6)
                            .animation(.easeInOut(duration: 0.2), value: totalProgress)
                    }
                    .frame(height: 6)
                }
            }
        }
    }

    private var deliverablesList: some View {
        VStack(spacing: 8) {
            ForEach(deliverables, id: \.self) { item in
                HStack(spacing: 10) {
                    AviaryIcon(name: "check-circle", size: 16, color: t.ink3)
                    Text(item)
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink2)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(t.surface))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(t.line))
            }
        }
    }

    @ViewBuilder
    private var pickerArea: some View {
        if assets.isEmpty {
            Button { isSourceDialogPresented = true } label: {
                emptyDropzone
            }
            .buttonStyle(PressableButtonStyle())
        } else {
            VStack(spacing: 12) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4),
                          spacing: 6) {
                    ForEach(assets) { asset in thumb(asset: asset) }
                    addMoreTile
                }
            }
        }
    }

    private var emptyDropzone: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(t.accentSoft)
                AviaryIcon(name: "upload", size: 22, color: t.accent)
            }
            .frame(width: 56, height: 56)
            Text("Add photos & videos")
                .font(AviaryFont.body(15, weight: .semibold))
                .foregroundStyle(t.ink)
            Text("Tap to choose from your library")
                .font(AviaryFont.body(12))
                .foregroundStyle(t.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(t.lineStrong, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
    }

    private var addMoreTile: some View {
        Button { isSourceDialogPresented = true } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(t.surface)
                AviaryIcon(name: "plus", size: 22, color: t.ink3)
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(t.lineStrong, style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func thumb(asset: UploadAsset) -> some View {
        ZStack {
            if let image = asset.image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(colors: [t.accentSoft, t.surface2],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }

            // Dim overlay while uploading
            if !asset.done {
                Rectangle().fill(.black.opacity(0.25))
            }

            if !asset.done && !asset.failed {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView(value: asset.progress)
                            .progressViewStyle(.linear)
                            .tint(.white)
                            .padding(.horizontal, 6)
                            .padding(.bottom, 6)
                    }
                }
            }

            if asset.done {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle().fill(t.good)
                            AviaryIcon(name: "check", size: 11, stroke: 3.5, color: .white)
                        }
                        .frame(width: 18, height: 18)
                        .padding(4)
                    }
                    Spacer()
                }
            }
            if asset.failed {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle().fill(t.bad)
                            Text("!").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        }
                        .frame(width: 18, height: 18)
                        .padding(4)
                    }
                    Spacer()
                }
            }
            if asset.isVideo {
                VStack {
                    Spacer()
                    HStack {
                        AviaryIcon(name: "play", size: 11, color: .white)
                        Text("video")
                            .font(AviaryFont.mono(9, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(.black.opacity(0.6)))
                    .padding(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(t.line))
    }

    // MARK: - Actions

    private func ingest(_ items: [PhotosPickerItem]) {
        for item in items {
            let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) })
            let asset = UploadAsset(
                pickerItem: item,
                fileURL: nil,
                image: nil,
                isVideo: isVideo,
                sizeBytes: 0,
                progress: 0,
                done: false,
                failed: false
            )
            assets.append(asset)
            Task { await loadAndUpload(assetID: asset.id, item: item, isVideo: isVideo) }
        }
    }

    private func ingestFiles(_ urls: [URL]) {
        for url in urls {
            let isVideo = isVideoFile(url)
            let asset = UploadAsset(
                pickerItem: nil,
                fileURL: url,
                image: nil,
                isVideo: isVideo,
                sizeBytes: 0,
                progress: 0,
                done: false,
                failed: false
            )
            assets.append(asset)
            Task { await loadAndUploadFile(assetID: asset.id, url: url, isVideo: isVideo) }
        }
    }

    private func isVideoFile(_ url: URL) -> Bool {
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return type.conforms(to: .movie)
        }
        return UTType(filenameExtension: url.pathExtension)?.conforms(to: .movie) ?? false
    }

    private func loadAndUpload(assetID: UUID, item: PhotosPickerItem, isVideo: Bool) async {
        // Load thumbnail/preview
        if !isVideo, let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            await MainActor.run {
                update(id: assetID) {
                    $0.image = Image(uiImage: uiImage)
                    $0.sizeBytes = Int64(data.count)
                }
            }
        } else if isVideo, let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                update(id: assetID) { $0.sizeBytes = Int64(data.count) }
            }
        }

        // Simulate upload progress (real backend storage isn't wired yet)
        let steps = 18
        for i in 1...steps {
            try? await Task.sleep(nanoseconds: 90_000_000)
            await MainActor.run {
                update(id: assetID) { $0.progress = Double(i) / Double(steps) }
            }
        }
        await MainActor.run {
            update(id: assetID) {
                $0.progress = 1
                $0.done = true
            }
        }
    }

    private func loadAndUploadFile(assetID: UUID, url: URL, isVideo: Bool) async {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let data = try? Data(contentsOf: url)
        if !isVideo, let data, let uiImage = UIImage(data: data) {
            await MainActor.run {
                update(id: assetID) {
                    $0.image = Image(uiImage: uiImage)
                    $0.sizeBytes = Int64(data.count)
                }
            }
        } else if let data {
            await MainActor.run {
                update(id: assetID) { $0.sizeBytes = Int64(data.count) }
            }
        }

        let steps = 18
        for i in 1...steps {
            try? await Task.sleep(nanoseconds: 90_000_000)
            await MainActor.run {
                update(id: assetID) { $0.progress = Double(i) / Double(steps) }
            }
        }
        await MainActor.run {
            update(id: assetID) {
                $0.progress = 1
                $0.done = true
            }
        }
    }

    private func update(id: UUID, _ mutate: (inout UploadAsset) -> Void) {
        guard let idx = assets.firstIndex(where: { $0.id == id }) else { return }
        var copy = assets[idx]
        mutate(&copy)
        assets[idx] = copy
    }

    private func submit() {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        Task {
            // Persist deliverable count to the active job, if real
            if !demoStore.isOn, let job {
                let summary = describeDeliverables()
                do {
                    try await AviaryDataService.shared.recordHandoff(
                        jobID: job.id,
                        deliverables: summary
                    )
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        isSubmitting = false
                    }
                    return
                }
            }
            await MainActor.run {
                isSubmitting = false
                onSubmit(assets)
            }
        }
    }

    private func seedShowcaseAssetsIfNeeded() {
        guard demoStore.isOn,
              demoStore.showcaseStep == .pilotDeliverables,
              assets.isEmpty else { return }

        showcaseUploadTask?.cancel()
        assets = [
            UploadAsset(pickerItem: nil, fileURL: nil, image: nil,
                        isVideo: false, sizeBytes: 4_800_000, progress: 0, done: false, failed: false),
            UploadAsset(pickerItem: nil, fileURL: nil, image: nil,
                        isVideo: false, sizeBytes: 5_100_000, progress: 0, done: false, failed: false),
            UploadAsset(pickerItem: nil, fileURL: nil, image: nil,
                        isVideo: true, sizeBytes: 48_000_000, progress: 0, done: false, failed: false),
            UploadAsset(pickerItem: nil, fileURL: nil, image: nil,
                        isVideo: false, sizeBytes: 4_300_000, progress: 0, done: false, failed: false)
        ]

        let ids = assets.map(\.id)
        showcaseUploadTask = Task { @MainActor in
            do {
                for tick in 1...18 {
                    try await Task.sleep(nanoseconds: 120_000_000)
                    guard demoStore.showcaseStep == .pilotDeliverables else { return }
                    for (offset, id) in ids.enumerated() {
                        let progress = min(1, max(0, Double(tick - offset * 2) / 12))
                        update(id: id) {
                            $0.progress = progress
                            $0.done = progress >= 1
                        }
                    }
                }

                // After uploads complete, dwell briefly so the viewer reads "ready",
                // then auto-tap submit so the showcase advances to the rating step.
                try await Task.sleep(nanoseconds: 900_000_000)
                guard !Task.isCancelled,
                      demoStore.showcaseStep == .pilotDeliverables,
                      canSubmit else { return }
                submit()
            } catch {
                return
            }
        }
    }

    private func describeDeliverables() -> [String] {
        let photos = assets.filter { !$0.isVideo }.count
        let videos = assets.filter(\.isVideo).count
        var items: [String] = []
        if photos > 0 { items.append("\(photos) photo\(photos == 1 ? "" : "s") · 4K") }
        if videos > 0 { items.append("\(videos) video\(videos == 1 ? "" : "s")") }
        if items.isEmpty { items = deliverables }
        return items
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_000_000
        if mb < 1 { return String(format: "%.0f KB", Double(bytes) / 1_000) }
        if mb < 1000 { return String(format: "%.0f MB", mb) }
        return String(format: "%.1f GB", mb / 1000)
    }
}

// MARK: - Review / complete

struct ReviewCompleteScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var demoStore: DemoModeStore

    let job: AviaryJob?
    let pilotID: UUID?
    var onCompleted: () -> Void = {}

    @State private var stars: Int = 5
    @State private var tags: Set<String> = []
    @State private var note: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    @State private var showcaseTask: Task<Void, Never>?

    private let availableTags = ["Clear brief", "Fair pay", "Easy site", "Friendly", "On time", "Tough access"]
    private let showcaseTagPicks = ["Clear brief", "On time", "Friendly"]
    private let showcaseNote = "Easy access, friendly contact on site. Twilight set turned out beautifully."

    private var clientName: String { job?.displayClient ?? "Marin Realty Co." }
    private var payoutText: String {
        guard let cents = job?.payoutCents else { return "$340.00" }
        return String(format: "$%.2f", Double(cents) / 100)
    }

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        AviaryIcon(name: "x", size: 22, color: t.ink)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle().fill(t.good)
                                .frame(width: 76, height: 76)
                            AviaryIcon(name: "check", size: 38, stroke: 3, color: .white)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 18)

                        Text("GIG COMPLETE")
                            .font(AviaryFont.body(13, weight: .semibold))
                            .tracking(0.04 * 13)
                            .foregroundStyle(t.good)
                            .padding(.bottom, 6)
                        Text("Nice flying.")
                            .font(AviaryFont.display(28, weight: .bold))
                            .tracking(-0.025 * 28)
                            .foregroundStyle(t.ink)
                        Text("+\(payoutText)")
                            .font(AviaryFont.mono(36, weight: .semibold))
                            .foregroundStyle(t.accent)
                            .padding(.top, 6)
                        Text("Released after client review (24h)")
                            .font(AviaryFont.body(13))
                            .foregroundStyle(t.ink3)
                            .padding(.top, 4)

                        ratingCard
                            .padding(.top, 32)
                        noteCard
                            .padding(.top, 12)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(AviaryFont.body(12))
                                .foregroundStyle(t.bad)
                                .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                PrimaryButton(title: submitTitle,
                              enabled: !isSubmitting,
                              action: submit)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
        .onAppear { startShowcaseScriptIfNeeded() }
        .onDisappear {
            showcaseTask?.cancel()
            showcaseTask = nil
        }
        .onChange(of: demoStore.showcaseStep) { _, _ in
            startShowcaseScriptIfNeeded()
        }
    }

    /// Walks through the rating: highlight stars, tap a few tags one-by-one,
    /// type a short note character-by-character, then submit.
    private func startShowcaseScriptIfNeeded() {
        guard demoStore.isOn,
              demoStore.showcaseStep == .pilotReview else { return }
        showcaseTask?.cancel()
        // Reset so the script always starts from a clean slate.
        tags = []
        note = ""
        showcaseTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 700_000_000)
                guard demoStore.showcaseStep == .pilotReview else { return }
                for tag in showcaseTagPicks {
                    guard demoStore.showcaseStep == .pilotReview else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        _ = tags.insert(tag)
                    }
                    try await Task.sleep(nanoseconds: 380_000_000)
                }
                try await Task.sleep(nanoseconds: 250_000_000)
                guard demoStore.showcaseStep == .pilotReview else { return }
                for ch in showcaseNote {
                    guard demoStore.showcaseStep == .pilotReview else { return }
                    note.append(ch)
                    try await Task.sleep(nanoseconds: 28_000_000)
                }
                try await Task.sleep(nanoseconds: 500_000_000)
                guard demoStore.showcaseStep == .pilotReview, !isSubmitting else { return }
                submit()
            } catch {
                return
            }
        }
    }

    private var submitTitle: String {
        isSubmitting ? "Submitting…" : "Submit & find next gig"
    }

    private var ratingCard: some View {
        AviaryCard(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Avatar(size: 40, initials: initials(clientName), background: t.accentSoft)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Rate \(clientName)")
                            .font(AviaryFont.body(14, weight: .semibold))
                            .foregroundStyle(t.ink)
                        Text("Helps other pilots decide")
                            .font(AviaryFont.body(12))
                            .foregroundStyle(t.ink3)
                    }
                    Spacer()
                }
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { n in
                        Button { stars = n } label: {
                            AviaryIcon(name: n <= stars ? "star.fill" : "star",
                                       size: 36, stroke: 1.6,
                                       color: n <= stars ? t.warn : t.ink4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)

                FlowLayout(spacing: 6) {
                    ForEach(availableTags, id: \.self) { tag in
                        Button { toggle(tag) } label: {
                            Chip(text: tag, style: tags.contains(tag) ? .accent : .surface)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var noteCard: some View {
        AviaryCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add a note (optional)")
                    .font(AviaryFont.body(13, weight: .semibold))
                    .foregroundStyle(t.ink2)
                ZStack(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("Anything the client should know about the shoot…")
                            .font(AviaryFont.body(13))
                            .foregroundStyle(t.ink4)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 6)
                    }
                    TextEditor(text: $note)
                        .font(AviaryFont.body(13))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 70, maxHeight: 110)
                        .foregroundStyle(t.ink)
                }
            }
        }
    }

    private func toggle(_ tag: String) {
        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").compactMap(\.first).prefix(2)
        return parts.isEmpty ? "CL" : String(parts).uppercased()
    }

    private func submit() {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        Task {
            // Persist completion only when not in demo mode and we have a real job + pilot
            if !demoStore.isOn, let job, let pilotID {
                do {
                    try await AviaryDataService.shared.completeJob(
                        jobID: job.id,
                        pilotID: pilotID,
                        rating: stars,
                        tags: Array(tags).sorted(),
                        note: note.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        isSubmitting = false
                    }
                    return
                }
            }
            await MainActor.run {
                isSubmitting = false
                onCompleted()
                dismiss()
            }
        }
    }
}

// Simple flow layout for chip wrapping
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > width {
                x = 0; y += rowH + spacing; rowH = 0
            }
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
        return .init(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX {
                x = bounds.minX; y += rowH + spacing; rowH = 0
            }
            v.place(at: .init(x: x, y: y), proposal: .init(s))
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
    }
}
