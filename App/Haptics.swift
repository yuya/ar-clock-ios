import UIKit

/// 触覚（指に返す短い振動）
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let selection = UISelectionFeedbackGenerator()

    /// ボタンを押したとき
    static func tap() { light.impactOccurred(); light.prepare() }
    /// 映像に触れたとき（一時停止など）
    static func softTap() { soft.impactOccurred(); soft.prepare() }
    /// スライダーの端や選択の切り替え
    static func select() { selection.selectionChanged(); selection.prepare() }

    static func play(_ name: String) {
        switch name {
        case "soft": softTap()
        case "select": select()
        default: tap()
        }
    }
}
