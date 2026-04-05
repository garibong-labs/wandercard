import SwiftUI
import UIKit

enum CardTemplateType: String, CaseIterable, Codable, Identifiable {
    case light
    case dark
    case minimal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: "라이트"
        case .dark: "다크"
        case .minimal: "미니멀"
        }
    }

    var previewAspectRatio: CGFloat {
        self == .minimal ? (9.0 / 16.0) : (4.0 / 5.0)
    }

    var renderSize: CGSize {
        self == .minimal ? CGSize(width: 1080, height: 1920) : CGSize(width: 1080, height: 1350)
    }

    var style: CardTemplateStyle {
        switch self {
        case .light: LightTemplate.style
        case .dark: DarkTemplate.style
        case .minimal: MinimalTemplate.style
        }
    }
}

struct CardTemplateStyle {
    let backgroundTop: UIColor
    let backgroundBottom: UIColor
    let textColor: UIColor
    let metadataColor: UIColor
    let overlayColor: UIColor?
    let captionBoxColor: UIColor?
    let titleFontName: String
    let titleFontSize: CGFloat
    let bodyFontName: String
    let bodyFontSize: CGFloat
}
