import UIKit

enum MinimalTemplate {
    static let style = CardTemplateStyle(
        backgroundTop: UIColor.white,
        backgroundBottom: UIColor(white: 0.98, alpha: 1),
        textColor: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1),
        metadataColor: UIColor(red: 0.45, green: 0.45, blue: 0.47, alpha: 1),
        overlayColor: nil,
        captionBoxColor: nil,
        titleFontName: "SFProRounded-Bold",
        titleFontSize: 36,
        bodyFontName: "SFProRounded-Regular",
        bodyFontSize: 28
    )
}
