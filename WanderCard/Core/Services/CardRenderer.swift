import Photos
import SwiftUI
import UIKit

enum CardRendererError: Error {
    case pngEncodingFailed
}

struct RenderedCardContent {
    let photo: CGImage
    let text: String?
    let location: String?
    let date: Date
    let template: CardTemplateType
}

@MainActor
final class CardRenderer {
    func render(
        photo: CGImage,
        text: String?,
        location: String? = nil,
        date: Date = .now,
        template: CardTemplateType,
        size: CGSize? = nil
    ) async throws -> UIImage {
        let content = RenderedCardContent(
            photo: photo,
            text: text,
            location: location,
            date: date,
            template: template
        )
        return draw(content: content, size: size ?? template.renderSize)
    }

    func renderPreview(
        photo: CGImage,
        text: String?,
        location: String? = nil,
        date: Date = .now,
        template: CardTemplateType,
        size: CGSize = CGSize(width: 390, height: 488)
    ) async throws -> UIImage {
        let content = RenderedCardContent(
            photo: photo,
            text: text,
            location: location,
            date: date,
            template: template
        )
        return draw(content: content, size: size)
    }

    func exportPNG(_ image: UIImage) throws -> URL {
        guard let data = image.pngData() else { throw CardRendererError.pngEncodingFailed }
        let directory = URL.temporaryDirectory.appendingPathComponent("WanderCardExports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("wandercard-\(UUID().uuidString).png")
        try data.write(to: fileURL)
        return fileURL
    }

    private func draw(content: RenderedCardContent, size: CGSize) -> UIImage {
        let style = content.template.style
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            drawBackground(style: style, in: CGRect(origin: .zero, size: size), context: cg)
            drawPhoto(content: content, size: size, context: cg)
            drawOverlay(style: style, size: size, context: cg)
            drawText(content: content, size: size, context: cg)
            drawMetadata(content: content, size: size, context: cg)
        }
    }

    private func drawBackground(style: CardTemplateStyle, in rect: CGRect, context: CGContext) {
        let colors = [style.backgroundTop.cgColor, style.backgroundBottom.cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: rect.origin, end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])
    }

    private func drawPhoto(content: RenderedCardContent, size: CGSize, context: CGContext) {
        let photoRect: CGRect
        if content.template == .minimal {
            photoRect = CGRect(x: 72, y: 160, width: size.width - 144, height: size.height * 0.48)
        } else {
            photoRect = CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.72)
        }
        context.saveGState()
        let image = UIImage(cgImage: content.photo)
        image.draw(in: photoRect)
        context.restoreGState()
    }

    private func drawOverlay(style: CardTemplateStyle, size: CGSize, context: CGContext) {
        if let overlay = style.overlayColor {
            context.setFillColor(overlay.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.72))
        }
    }

    private func drawText(content: RenderedCardContent, size: CGSize, context: CGContext) {
        let style = content.template.style
        let bodyFont = UIFont(name: style.bodyFontName, size: style.bodyFontSize) ?? UIFont.systemFont(ofSize: style.bodyFontSize, weight: .semibold)
        let text = (content.text?.isEmpty == false ? content.text : "여행의 한 줄을 남겨보세요.") ?? "여행의 한 줄을 남겨보세요."
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = bodyFont.pointSize * 0.18
        paragraph.alignment = .left
        let textRect: CGRect
        if content.template == .minimal {
            textRect = CGRect(x: 72, y: size.height * 0.68, width: size.width - 144, height: 260)
        } else {
            textRect = CGRect(x: 72, y: size.height * 0.53, width: size.width - 144, height: 220)
        }

        if let captionBoxColor = style.captionBoxColor {
            let captionRect = textRect.insetBy(dx: -24, dy: -20)
            let path = UIBezierPath(roundedRect: captionRect, cornerRadius: 28)
            captionBoxColor.setFill()
            path.fill()
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: style.textColor,
            .paragraphStyle: paragraph
        ]
        text.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
    }

    private func drawMetadata(content: RenderedCardContent, size: CGSize, context: CGContext) {
        let style = content.template.style
        let font = UIFont.systemFont(ofSize: 24, weight: .medium)
        let brandFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let info = "📍 \(content.location ?? "어딘가") · \(content.date.formattedCardDate())"
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: style.metadataColor
        ]
        let brandAttributes: [NSAttributedString.Key: Any] = [
            .font: brandFont,
            .foregroundColor: style.metadataColor
        ]
        let y = size.height - 76
        info.draw(at: CGPoint(x: 72, y: y), withAttributes: infoAttributes)
        "WANDERCARD".draw(at: CGPoint(x: size.width - 220, y: y + 4), withAttributes: brandAttributes)
    }
}
