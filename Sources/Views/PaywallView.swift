import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    private var theme: AppTheme { model.settings.theme }

    private let benefits: [(String, String, String)] = [
        ("infinity", "Unlimited history", "Keep thousands of copies, not just the last 25"),
        ("pin.fill", "Pin items", "Lock important text and links so they never disappear"),
        ("magnifyingglass", "Fast search", "Find anything you've ever copied"),
        ("paintpalette.fill", "All themes", "Midnight, Sakura, Forest, Mono & more"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill").font(.system(size: 40)).foregroundStyle(.white)
                    Text("ClipNest Pro").font(.title.bold()).foregroundStyle(.white)
                    Text("One-time purchase — unlock everything, forever")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .background(LinearGradient(colors: [theme.accent, theme.accent.opacity(0.7)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.85))
                }.buttonStyle(.plain).padding(12)
            }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(benefits, id: \.0) { b in
                    HStack(spacing: 12) {
                        Image(systemName: b.0).foregroundStyle(theme.accent).frame(width: 26)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(b.1).font(.system(size: 13, weight: .semibold))
                            Text(b.2).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .padding(20)

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                if model.pro.product == nil {
                    Text("In-App Purchases are temporarily unavailable. Please try again later.")
                        .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                Button {
                    Task { await model.pro.purchase(); if model.pro.isPro { dismiss() } }
                } label: {
                    HStack {
                        if model.pro.purchasing { ProgressView().controlSize(.small) }
                        Text(buyLabel).bold()
                    }.frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(theme.accent).controlSize(.large)
                .disabled(model.pro.purchasing || model.pro.product == nil)

                Button("Restore purchase") { Task { await model.pro.restore(); if model.pro.isPro { dismiss() } } }
                    .buttonStyle(.link).font(.caption)

                Text("One-time payment (non-subscription), billed to your App Store account.")
                    .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20).padding(.bottom, 18)
        }
        .frame(width: 380, height: 520)
    }

    private var buyLabel: String {
        let price = model.pro.priceText
        return price.isEmpty ? "Unlock ClipNest Pro" : "Unlock Pro · \(price)"
    }
}
