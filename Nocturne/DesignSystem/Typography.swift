import SwiftUI

/// 字体规范：基于 SF Pro Rounded，使用语义化文本风格保证 Dynamic Type 兼容。
extension Font {
    /// 全屏播放器歌曲标题。
    static let nocTitleHero = Font.system(size: 28, weight: .bold, design: .rounded)
    /// 页面标题。
    static let nocTitle = Font.system(.title2, design: .rounded).weight(.bold)
    /// 节标题。
    static let nocSection = Font.system(.title3, design: .rounded).weight(.semibold)
    /// 列表主文本。
    static let nocBody = Font.system(.body, design: .rounded)
    /// 列表副文本。
    static let nocCaption = Font.system(.subheadline, design: .rounded)
    /// 计数 / 时间 / 标签等小字。
    static let nocLabel = Font.system(.caption, design: .rounded).weight(.medium)
}
