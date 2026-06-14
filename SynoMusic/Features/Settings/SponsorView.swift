import SwiftUI

/// 一种赞助方式：链接 + 可选二维码图。
struct SponsorMethod: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let qrAssetName: String
    let urlString: String?

    var url: URL? { urlString.flatMap { URL(string: $0) } }

    /// 全部 5 种内置渠道。
    static let all: [SponsorMethod] = [
        .init(id: "paypal", title: "PayPal", subtitle: "paypal.me/zanwing",
              symbol: "p.circle.fill", tint: .blue,
              qrAssetName: "SponsorPayPal", urlString: "https://paypal.me/zanwing"),
        .init(id: "bmc", title: "Buy me a coffee", subtitle: "buymeacoffee.com/zanwing",
              symbol: "cup.and.saucer.fill", tint: .yellow,
              qrAssetName: "SponsorBMC", urlString: "https://buymeacoffee.com/zanwing"),
        .init(id: "wise", title: "Wise", subtitle: "wise.com/pay/me/zhenyingm1",
              symbol: "globe.asia.australia.fill", tint: .green,
              qrAssetName: "SponsorWise", urlString: "https://wise.com/pay/me/zhenyingm1"),
        .init(id: "wechat", title: "微信赞赏码", subtitle: "扫码赞助",
              symbol: "qrcode", tint: .mint,
              qrAssetName: "SponsorWeChat", urlString: nil),
        .init(id: "alipay", title: "支付宝", subtitle: "扫码赞助",
              symbol: "qrcode.viewfinder", tint: .cyan,
              qrAssetName: "SponsorAlipay", urlString: nil)
    ]
}

/// 赞助列表 sheet：点行进入对应的二维码详情。
struct SponsorListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: SponsorMethod?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SponsorMethod.all) { method in
                        Button {
                            Haptics.tap()
                            selected = method
                        } label: {
                            SponsorRow(method: method)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Metrics.l)
                .padding(.top, Metrics.m)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("赞助支持")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(item: $selected) { m in
                SponsorQRSheet(method: m)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

private struct SponsorRow: View {
    let method: SponsorMethod
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(method.tint.opacity(0.18)).frame(width: 42, height: 42)
                Image(systemName: method.symbol)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(method.tint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(method.title).font(.nocBody.weight(.semibold))
                Text(method.subtitle).font(.nocLabel).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .contentShape(Rectangle())
    }
}

/// 二维码详情 sheet：展示图 + 可选可点击链接。
private struct SponsorQRSheet: View {
    @Environment(\.dismiss) private var dismiss
    let method: SponsorMethod
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.l) {
                    Image(method.qrAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.08), radius: 18, y: 10)
                        )
                        .padding(.horizontal, Metrics.l)
                    if let url = method.url, let text = method.urlString {
                        Link(text, destination: url)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .padding(.vertical, Metrics.l)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle(method.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
