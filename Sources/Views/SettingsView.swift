import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var showPaywall = false

    var body: some View {
        TabView {
            general.tabItem { Label("Umum", systemImage: "gearshape") }
            appearance.tabItem { Label("Tampilan", systemImage: "paintpalette") }
            proTab.tabItem { Label("Pro", systemImage: "crown") }
            about.tabItem { Label("Tentang", systemImage: "info.circle") }
        }
        .frame(width: 460, height: 380)
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(model) }
    }

    // MARK: Umum
    private var general: some View {
        Form {
            Section {
                Toggle("Buka ClipNest saat login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, value in
                        LoginItem.setEnabled(value)
                        launchAtLogin = LoginItem.isEnabled
                    }
                Toggle("Jeda perekaman clipboard", isOn: Binding(
                    get: { model.monitor.isPaused },
                    set: { model.monitor.isPaused = $0 }
                ))
            } footer: {
                Text("ClipNest hanya membaca clipboard untuk menyimpan riwayatmu — secara lokal. Tidak ada Accessibility atau pemantauan keyboard.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Pintasan") {
                HStack {
                    Text("Buka ClipNest")
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
            Section("Tema") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                    ForEach(AppTheme.allCases) { t in
                        themeSwatch(t)
                    }
                }
                .padding(.vertical, 4)
            } footer: {
                if !model.pro.isPro {
                    Text("Tema selain Nest termasuk ClipNest Pro.").font(.caption).foregroundStyle(.secondary)
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
                Text("ClipNest Pro aktif 🎉").font(.title3.bold())
                Text("Terima kasih sudah mendukung ClipNest!").foregroundStyle(.secondary)
            } else {
                Text("ClipNest Pro").font(.title3.bold())
                Text("Riwayat tak terbatas, sematkan, pencarian, dan semua tema.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button { showPaywall = true } label: {
                    Text("Lihat ClipNest Pro").bold().frame(maxWidth: 220)
                }.buttonStyle(.borderedProminent).tint(model.settings.theme.accent)
            }
            Button("Pulihkan pembelian") { Task { await model.pro.restore() } }
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
            Text("Versi \(Bundle.main.shortVersion) (\(Bundle.main.buildVersion))")
                .font(.caption).foregroundStyle(.secondary)
            Text("Pengelola clipboard yang ringan & privat. Semua riwayat tersimpan lokal di Mac-mu — tidak ada yang dikirim ke mana pun.")
                .font(.caption).multilineTextAlignment(.center).foregroundStyle(.secondary)
                .padding(.horizontal)
            HStack(spacing: 16) {
                Link("Privasi", destination: URL(string: "https://zachiesings.github.io/apps-support/clipnest-privacy.html")!)
                Link("Dukungan", destination: URL(string: "https://zachiesings.github.io/apps-support/")!)
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
