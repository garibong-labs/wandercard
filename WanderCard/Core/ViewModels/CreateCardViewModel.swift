import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

enum CreationStep: Int, CaseIterable {
    case selectPhoto
    case inputText
    case chooseTemplate
    case preview
}

@MainActor
@Observable
final class CreateCardViewModel {
    var selectedPickerItem: PhotosPickerItem? {
        didSet {
            guard let selectedPickerItem else { return }
            Task { await loadPhoto(from: selectedPickerItem) }
        }
    }
    var selectedImage: UIImage?
    var text = ""
    var selectedTemplate: CardTemplateType = .light
    var currentStep: CreationStep = .selectPhoto
    var previewImage: UIImage?
    var isRendering = false
    var renderError: String?
    var sourceURL: URL?
    var locationName = "어딘가"

    private let renderer = CardRenderer()

    init() {}

    func loadPhoto(from item: PhotosPickerItem) async {
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedImage = image
            await renderPreview()
        }
    }

    func move(to step: CreationStep) {
        currentStep = step
    }

    func applySharedPayload(_ payload: SharedPayload) {
        if let text = payload.text, !text.isEmpty {
            self.text = text
        }
        if let url = payload.url {
            self.sourceURL = url
        }
        if let imagePath = payload.imagePath, let image = UIImage(contentsOfFile: imagePath) {
            self.selectedImage = image
        }
    }

    func renderPreview() async {
        guard let cgImage = selectedImage?.cgImage else { return }
        isRendering = true
        defer { isRendering = false }
        do {
            previewImage = try await renderer.renderPreview(
                photo: cgImage,
                text: text,
                location: locationName,
                date: .now,
                template: selectedTemplate
            )
            renderError = nil
        } catch {
            renderError = error.localizedDescription
        }
    }

    func save(trip: Trip, context: ModelContext) async throws -> TravelCard {
        guard let image = selectedImage, let cgImage = image.cgImage else {
            throw NSError(domain: "WanderCard", code: 1, userInfo: [NSLocalizedDescriptionKey: "사진을 먼저 선택해야 해."])
        }
        let rendered = try await renderer.render(
            photo: cgImage,
            text: text,
            location: locationName,
            date: .now,
            template: selectedTemplate
        )
        let fileURL = try renderer.exportPNG(rendered)
        let card = TravelCard(
            tripId: trip.id,
            photoLocalIdentifier: selectedPickerItem?.itemIdentifier ?? UUID().uuidString,
            textContent: text,
            sourceURL: sourceURL,
            locationName: locationName,
            templateType: selectedTemplate,
            renderedImageLocalPath: fileURL.path,
            createdAt: .now,
            sortOrder: trip.cards.count,
            trip: trip
        )
        trip.cards.append(card)
        trip.cardCount = trip.cards.count
        trip.updatedAt = .now
        context.insert(card)
        try context.save()
        previewImage = rendered
        return card
    }

    func exportCurrentPreview() throws -> URL {
        guard let previewImage else {
            throw NSError(domain: "WanderCard", code: 2, userInfo: [NSLocalizedDescriptionKey: "먼저 카드를 렌더링해야 해."])
        }
        return try renderer.exportPNG(previewImage)
    }
}
