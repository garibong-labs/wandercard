import PhotosUI
import SwiftData
import SwiftUI

struct CreateCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SharedPendingStore.self) private var store
    let trip: Trip?
    @State private var viewModel = CreateCardViewModel()
    @State private var shareItems: [Any] = []
    @State private var isSharing = false
    @State private var savedCard: TravelCard?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                previewArea
                photoSection
                textSection
                templateSection
                actionSection
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .navigationTitle("카드 만들기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("닫기") { dismiss() }
            }
        }
        .task {
            hydrateSharedPayload()
            await viewModel.renderPreview()
        }
        .onChange(of: viewModel.selectedTemplate) { _, _ in
            Task { await viewModel.renderPreview() }
        }
        .onChange(of: viewModel.text) { _, _ in
            Task { await viewModel.renderPreview() }
        }
        .sheet(isPresented: $isSharing) {
            ActivityView(items: shareItems)
        }
        .sheet(item: $savedCard) { card in
            NavigationStack {
                CardPreviewView(card: card)
            }
        }
    }

    private var previewArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader("Step 1-4", "렌더링 미리보기")
            Group {
                if let previewImage = viewModel.previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.quaternary)
                        .overlay {
                            Text("사진을 고르면 여기에서 카드가 보여.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 320)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader("Step 1", "사진 선택")
            PhotosPicker(selection: $viewModel.selectedPickerItem, matching: .images) {
                Label("사진 라이브러리에서 선택", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader("Step 2", "메모 입력")
            TextEditor(text: Binding(
                get: { String(viewModel.text.prefix(200)) },
                set: { viewModel.text = String($0.prefix(200)) }
            ))
            .frame(height: 120)
            .padding(8)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
            HStack {
                Text("공유 텍스트나 직접 적은 메모가 카드 본문에 들어가.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.text.count)/200")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader("Step 3", "템플릿 선택")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CardTemplateType.allCases) { template in
                        Button {
                            viewModel.selectedTemplate = template
                        } label: {
                            TemplatePreviewCard(template: template, isSelected: viewModel.selectedTemplate == template)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader("Step 4", "저장/공유")
            Button {
                Task { await saveCard() }
            } label: {
                Label("Trip에 저장", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(trip == nil || viewModel.selectedImage == nil)

            Button {
                if let url = try? viewModel.exportCurrentPreview() {
                    shareItems = [url]
                    isSharing = true
                }
            } label: {
                Label("PNG 공유", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.previewImage == nil)
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }

    private func stepHeader(_ overline: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(overline.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
        }
    }

    private func hydrateSharedPayload() {
        viewModel.applySharedPayload(store.consume())
    }

    private func saveCard() async {
        guard let trip else { return }
        do {
            savedCard = try await viewModel.save(trip: trip, context: modelContext)
        } catch {
            viewModel.renderError = error.localizedDescription
        }
    }
}
