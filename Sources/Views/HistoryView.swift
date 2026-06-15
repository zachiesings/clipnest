import SwiftUI

/// Isi popover menu bar: pencarian + daftar riwayat clipboard.
struct HistoryView: View {
    @EnvironmentObject var model: AppModel
    @State private var query = ""
    @State private var showPaywall = false
    @State private var copiedID: UUID?

    var onClose: () -> Void = {}

    private var theme: AppTheme { model.settings.theme }
    private var items: [ClipItem] {
        model.history.filtered(model.pro.isPro ? query : "")
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(items) { item in
                            row(item)
                        }
                    }
                    .padding(8)
                }
            }
            Divider()
            footer
        }
        .frame(width: 380, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(model)
        }
    }

    // MARK: header
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard.fill").foregroundStyle(theme.accent)
            Text("ClipNest").font(.headline)
            if model.pro.isPro {
                Text("PRO")
                    .font(.system(size: 9, weight: .heavy))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(theme.accent.opacity(0.18), in: Capsule())
                    .foregroundStyle(theme.accent)
            }
            Spacer()
            Button { openSettings() } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .overlay(alignment: .bottom) { searchBar.offset(y: 38).padding(.horizontal, 12) }
        .padding(.bottom, 40)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            if model.pro.isPro {
                TextField("Search history…", text: $query)
                    .textFieldStyle(.plain)
            } else {
                Text("Search history (Pro)")
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "lock.fill").font(.caption).foregroundStyle(theme.accent)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture { if !model.pro.isPro { showPaywall = true } }
    }

    // MARK: row
    private func row(_ item: ClipItem) -> some View {
        Button {
            copy(item)
        } label: {
            HStack(spacing: 10) {
                icon(item)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.preview)
                        .lineLimit(2)
                        .font(.system(size: 12.5))
                        .foregroundStyle(.primary)
                    Text(relative(item.date))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                if copiedID == item.id {
                    Text("Copied ✓").font(.caption2).foregroundStyle(theme.accent)
                }
                pinButton(item)
                deleteButton(item)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.pinned ? theme.accent.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func icon(_ item: ClipItem) -> some View {
        Group {
            if item.kind == .image, let img = item.image {
                Image(nsImage: img).resizable().scaledToFill()
                    .frame(width: 34, height: 34).clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6).fill(theme.accent.opacity(0.14))
                    .frame(width: 34, height: 34)
                    .overlay(Image(systemName: "text.alignleft").foregroundStyle(theme.accent).font(.system(size: 13)))
            }
        }
    }

    private func pinButton(_ item: ClipItem) -> some View {
        Button {
            if model.pro.isPro { model.history.togglePin(item) } else { showPaywall = true }
        } label: {
            Image(systemName: item.pinned ? "pin.fill" : "pin")
                .font(.system(size: 11))
                .foregroundStyle(item.pinned ? theme.accent : .secondary)
        }
        .buttonStyle(.borderless)
        .help(model.pro.isPro ? "Pin" : "Pin (Pro)")
    }

    private func deleteButton(_ item: ClipItem) -> some View {
        Button { model.history.delete(item) } label: {
            Image(systemName: "xmark").font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .help("Delete")
    }

    // MARK: footer
    private var footer: some View {
        HStack {
            Text("\(model.history.items.count) items")
                .font(.caption).foregroundStyle(.secondary)
            if !model.pro.isPro {
                Text("· max \(model.history.freeLimit)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !model.pro.isPro {
                Button { showPaywall = true } label: {
                    Label("Upgrade to Pro", systemImage: "crown.fill").font(.caption.bold())
                }
                .buttonStyle(.borderless)
                .foregroundStyle(theme.accent)
            } else {
                Button("Clear") { model.history.clearUnpinned() }
                    .buttonStyle(.borderless).font(.caption)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "tray").font(.system(size: 40)).foregroundStyle(.secondary)
            Text("No history yet").font(.headline)
            Text("Copy something (⌘C) and it'll appear here.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: actions
    private func copy(_ item: ClipItem) {
        model.history.copyToPasteboard(item)
        model.monitor.acknowledgeOwnChange()
        copiedID = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if copiedID == item.id { copiedID = nil }
            onClose()
        }
    }

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
