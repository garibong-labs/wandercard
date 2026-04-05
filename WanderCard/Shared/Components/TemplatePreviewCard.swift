import SwiftUI

struct TemplatePreviewCard: View {
    let template: CardTemplateType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 14)
                .fill(previewGradient)
                .frame(width: 88, height: 64)
                .overlay(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(template == .dark ? .black.opacity(0.45) : .white.opacity(0.72))
                        .frame(height: 24)
                        .overlay(alignment: .leading) {
                            Text("Aa")
                                .font(.caption.bold())
                                .foregroundStyle(template == .dark ? .white : .primary)
                                .padding(.leading, 8)
                        }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
            Text(template.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        }
    }

    private var previewGradient: LinearGradient {
        let style = template.style
        return LinearGradient(
            colors: [Color(style.backgroundTop), Color(style.backgroundBottom)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
