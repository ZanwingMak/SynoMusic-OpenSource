import WidgetKit
import SwiftUI

/// Widget Extension 入口。仅承载 Live Activity（灵动岛 + 锁屏胶囊）。
@main
struct NocturneLiveBundle: WidgetBundle {
    var body: some Widget {
        NocturneLiveActivity()
    }
}
