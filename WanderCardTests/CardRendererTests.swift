import XCTest
@testable import WanderCard

@MainActor
final class CardRendererTests: XCTestCase {
    func testRendererReturnsImageForAllTemplates() async throws {
        let renderer = CardRenderer()
        let templateInputs: [(CardTemplateType, CGSize, UIColor)] = [
            (.light, CGSize(width: 1080, height: 1350), UIColor.systemOrange),
            (.dark, CGSize(width: 1080, height: 1350), UIColor(red: 0.16, green: 0.17, blue: 0.32, alpha: 1)),
            (.minimal, CGSize(width: 1080, height: 1350), UIColor.systemMint)
        ]

        for (template, sampleSize, color) in templateInputs {
            let cgImage = makeSampleImage(size: sampleSize, color: color)
            let image = try await renderer.render(
                photo: cgImage,
                text: "템플릿 \(template.rawValue)",
                location: "서울",
                template: template
            )

            XCTAssertNotNil(image.cgImage, "Expected rendered image for template \(template.rawValue)")
            XCTAssertEqual(image.size.width, template.renderSize.width, accuracy: 0.5)
            XCTAssertEqual(image.size.height, template.renderSize.height, accuracy: 0.5)
        }
    }

    func testRendererExportsPNGForAllTemplates() async throws {
        let renderer = CardRenderer()

        for template in CardTemplateType.allCases {
            let cgImage = makeSampleImage(
                size: CGSize(width: 1080, height: 1350),
                color: UIColor(red: 0.97, green: 0.35, blue: 0.57, alpha: 1)
            )
            let image = try await renderer.render(
                photo: cgImage,
                text: "PNG export \(template.rawValue)",
                location: "부산",
                template: template
            )
            let url = try renderer.exportPNG(image)

            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            XCTAssertEqual(url.pathExtension.lowercased(), "png")
        }
    }

    private func makeSampleImage(size: CGSize, color: UIColor) -> CGImage {
        CGImage.placeholder(
            size: size,
            topColor: color,
            bottomColor: color.withAlphaComponent(0.75)
        )
    }
}
