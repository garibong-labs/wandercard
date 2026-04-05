import SwiftUI
import UIKit

struct SettingsView: View {
    @AppStorage("isOnboardingShown") private var isOnboardingShown = true

    var body: some View {
        List {
            Section("권한") {
                Button("온보딩 다시 보기") {
                    isOnboardingShown = false
                }
                Button("앱 설정 열기") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            Section("기본 템플릿") {
                Text("라이트 / 다크 / 미니멀")
                    .foregroundStyle(.secondary)
            }

            Section("Share Extension") {
                Text("공유 시트에서 WanderCard를 선택하면 텍스트, URL, 이미지 초안을 받아와.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("설정")
    }
}
