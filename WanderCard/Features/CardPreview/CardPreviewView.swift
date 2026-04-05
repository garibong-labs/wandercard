import Photos
import SwiftUI

struct CardPreviewView: View {
    let card: TravelCard
    @State private var isSharing = false
    @State private var shareItems: [Any] = []
    @State private var saveMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ImageLoaderView(path: card.renderedImageLocalPath)
                .aspectRatio(card.templateType.previewAspectRatio, contentMode: .fit)
                .frame(maxWidth: 320)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.18), radius: 24, y: 12)

            HStack(spacing: 12) {
                ForEach(CardTemplateType.allCases) { template in
                    VStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(template.style.backgroundTop))
                            .frame(width: 56, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(card.templateType == template ? Color.white : Color.white.opacity(0.25), lineWidth: 2)
                            )
                        Text(template.displayName)
                            .font(.caption2.weight(.semibold))
                    }
                }
            }
            .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text(card.textContent ?? "메모 없음")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("📍 \(card.locationName ?? "위치 없음") · \(card.createdAt.formattedCardDate())")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            Spacer()

            HStack(spacing: 12) {
                Button("저장") {
                    saveToPhotos()
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)

                Button("공유하기") {
                    if let path = card.renderedImageLocalPath {
                        shareItems = [URL(fileURLWithPath: path)]
                        isSharing = true
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.black.opacity(0.82).ignoresSafeArea())
        .navigationTitle("카드 미리보기")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isSharing) {
            ActivityView(items: shareItems)
        }
        .alert("저장 결과", isPresented: Binding(get: { saveMessage != nil }, set: { if !$0 { saveMessage = nil } })) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private func saveToPhotos() {
        guard let path = card.renderedImageLocalPath,
              let image = UIImage(contentsOfFile: path) else {
            saveMessage = "저장할 이미지가 없어."
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        saveMessage = "사진 앱에 저장 요청을 보냈어."
    }
}
