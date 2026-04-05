import UIKit

enum DarkTemplate {
    static let style = CardTemplateStyle(
        backgroundTop: UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1),
        backgroundBottom: UIColor(red: 0.09, green: 0.13, blue: 0.24, alpha: 1),
        textColor: UIColor(red: 0.96, green: 0.94, blue: 0.92, alpha: 1),
        metadataColor: UIColor(red: 0.82, green: 0.82, blue: 0.85, alpha: 1),
        overlayColor: UIColor(white: 0, alpha: 0.55),
        captionBoxColor: nil,
        titleFontName: "AppleSDGothicNeo-Light",
        titleFontSize: 38,
        bodyFontName: "AppleSDGothicNeo-Regular",
        bodyFontSize: 28
    )
}
