import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var showPaywall = false

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            appearance.tabItem { Label("Appearance", systemImage: "paintpalette") }
            proTab.tabItem { Label("Pro", systemImage: "crown") }
            about.tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 460, height: 380)
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(model) }
    }

    // MARK: Umum
    private var general: some View {
        Form {
            Section {
                Toggle("Open ClipNest at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { value in
                        LoginItem.setEnabled(value)
                        launchAtLogin = LoginItem.isEnabled
                    }
                Toggle("Pause clipboard capture", isOn: Binding(
                    get: { model.monitor.isPaused },
                    set: { model.monitor.isPaused = $0 }
                ))
            } footer: {
                Text("ClipNest only reads the clipboard to save your history — locally. No Accessibility and no keyboard monitoring.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Shortcut") {
                HStack {
                    Text("Open ClipNest")
                    Spacer()
                    Text("⌘⇧V").font(.system(.body, design: .monospaced)).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Tampilan
    private var appearance: some View {
        Form {
            Section {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                    ForEach(AppTheme.allCases) { t in
                        themeSwatch(t)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Theme")
            } footer: {
                if !model.pro.isPro {
                    Text("Themes other than Nest are part of ClipNest Pro.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func themeSwatch(_ t: AppTheme) -> some View {
        let selected = model.settings.theme == t
        let locked = t.isProOnly && !model.pro.isPro
        return Button {
            if locked { showPaywall = true } else { model.settings.theme = t }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(t.accent.opacity(0.22))
                        .frame(height: 44)
                    Circle().fill(t.accent).frame(width: 18, height: 18)
                    if locked {
                        Image(systemName: "lock.fill").font(.caption).foregroundStyle(.white)
                            .padding(4).background(t.accent, in: Circle()).offset(x: 18, y: -12)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? t.accent : Color.clear, lineWidth: 2))
                Text(t.name).font(.caption)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Pro
    private var proTab: some View {
        VStack(spacing: 14) {
            Image(systemName: model.pro.isPro ? "crown.fill" : "crown")
                .font(.system(size: 44)).foregroundStyle(model.settings.theme.accent)
            if model.pro.isPro {
                Text("ClipNest Pro active 🎉").font(.title3.bold())
                Text("Thanks for supporting ClipNest!").foregroundStyle(.secondary)
            } else {
                Text("ClipNest Pro").font(.title3.bold())
                Text("Unlimited history, pinning, search, and all themes.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button { showPaywall = true } label: {
                    Text("See ClipNest Pro").bold().frame(maxWidth: 220)
                }.buttonStyle(.borderedProminent).tint(model.settings.theme.accent)
            }
            Button("Restore purchase") { Task { await model.pro.restore() } }
                .buttonStyle(.link)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Tentang
    private var about: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 40)).foregroundStyle(model.settings.theme.accent)
            Text("ClipNest").font(.title2.bold())
            Text("Version \(Bundle.main.shortVersion) (\(Bundle.main.buildVersion))")
                .font(.caption).foregroundStyle(.secondary)
            Text("A lightweight, private clipboard manager. All history is stored locally on your Mac — nothing is ever sent anywhere.")
                .font(.caption).multilineTextAlignment(.center).foregroundStyle(.secondary)
                .padding(.horizontal)
            HStack(spacing: 16) {
                Link("Privacy", destination: URL(string: "https://zachiesings.github.io/apps-support/mac-privacy.html")!)
                Link("Support", destination: URL(string: "https://zachiesings.github.io/apps-support/")!)
            }.font(.caption)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension Bundle {
    var shortVersion: String { (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0" }
    var buildVersion: String { (infoDictionary?["CFBundleVersion"] as? String) ?? "1" }
}
