import XCTest
@testable import WanderCard

@MainActor
final class CardRendererTests: XCTestCase {
    func testRendererExportsPNG() async throws {
        let renderer = CardRenderer()
        let cgImage = CGImage.placeholder(
            size: CGSize(width: 1080, height: 1350),
            topColor: .orange,
            bottomColor: UIColor(red: 0.97, green: 0.35, blue: 0.57, alpha: 1)
        )
        let image = try await renderer.render(photo: cgImage, text: "테스트 카드", location: "서울", template: .dark)
        let url = try renderer.exportPNG(image)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
}
