import UIKit

enum LightTemplate {
    static let style = CardTemplateStyle(
        backgroundTop: UIColor(red: 0.96, green: 0.94, blue: 0.92, alpha: 1),
        backgroundBottom: UIColor.white,
        textColor: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1),
        metadataColor: UIColor(red: 0.42, green: 0.42, blue: 0.44, alpha: 1),
        overlayColor: nil,
        captionBoxColor: UIColor(white: 1, alpha: 0.85),
        titleFontName: "AppleSDGothicNeo-Bold",
        titleFontSize: 42,
        bodyFontName: "AppleSDGothicNeo-Regular",
        bodyFontSize: 30
    )
}
