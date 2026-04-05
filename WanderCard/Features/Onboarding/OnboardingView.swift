import Photos
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @StateObject private var photoService = PhotoLibraryService()
    @State private var page = 0
    @State private var showSettingsAlert = false

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $page) {
                OnboardingPage(
                    title: "여행 사진을 예쁜 카드로",
                    subtitle: "라이트, 다크, 미니멀 템플릿으로 사진과 메모를 바로 공유 카드로 바꿔.",
                    colors: [.orange, .pink]
                )
                .tag(0)

                OnboardingPage(
                    title: "공유 시트에서 쉽게",
                    subtitle: "Safari, 카카오맵, 메시지에서 텍스트와 링크를 바로 받아서 카드 초안으로 이어가.",
                    colors: [.mint, .cyan]
                )
                .tag(1)

                permissionsPage
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page == 2 ? "시작하기" : "다음") {
                Task { await advance() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .alert("사진 권한이 필요해", isPresented: $showSettingsAlert) {
            Button("설정 열기") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("닫기", role: .cancel) {}
        } message: {
            Text("선택한 여행 사진만 읽고, 원본은 수정하거나 업로드하지 않아.")
        }
    }

    private var permissionsPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("사진 접근이 필요해요")
                .font(.largeTitle.bold())
            Text("권한 요청 전에 이유를 먼저 보여줄게.")
                .font(.title3)
                .foregroundStyle(.secondary)
            permissionRow("여행 날짜와 위치 기준으로 사진을 그룹핑해.")
            permissionRow("원본 사진은 수정하거나 업로드하지 않아.")
            permissionRow("Selected Photos도 바로 지원해.")
            permissionRow("모든 데이터는 기기에만 저장돼.")
            Spacer()
        }
        .padding(.top, 40)
    }

    private func permissionRow(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.seal.fill")
            .font(.body.weight(.medium))
            .foregroundStyle(.primary)
    }

    private func advance() async {
        guard page == 2 else {
            withAnimation { page += 1 }
            return
        }
        let status = await photoService.requestAuthorization()
        switch status {
        case .authorized, .limited:
            isPresented = false
            dismiss()
        case .denied, .restricted:
            showSettingsAlert = true
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

private struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let colors: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 280)
                .overlay(alignment: .bottomLeading) {
                    Text("WanderCard")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .padding(24)
                }
            Text(title)
                .font(.largeTitle.bold())
            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 40)
    }
}
