import SwiftUI

struct ShareRootView: View {
    @State private var viewModel: ShareViewModel

    init(extensionContext: NSExtensionContext?) {
        _viewModel = State(initialValue: ShareViewModel(extensionContext: extensionContext))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("WanderCard로 보내기")
                    .font(.title2.bold())
                Text("텍스트, 링크, 이미지를 받아서 카드 초안으로 넘겨.")
                    .foregroundStyle(.secondary)

                GroupBox("감지된 내용") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.sharedText ?? "텍스트 없음")
                        Text(viewModel.sharedURL?.absoluteString ?? "URL 없음")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if let image = viewModel.sharedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                Button("WanderCard에서 열기") {
                    Task { await viewModel.openMainApp() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(20)
            .task {
                await viewModel.loadItems()
            }
        }
    }
}
