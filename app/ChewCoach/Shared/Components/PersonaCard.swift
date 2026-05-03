import SwiftUI

struct PersonaCard: View {
    let persona: Persona
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Text(persona.emoji)
                    .font(.system(size: 28))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(persona.title)
                        .font(.headlineS)
                        .foregroundStyle(.primary)
                    Text(persona.subtitle)
                        .font(.calloutR)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.brandPrimary)
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.lg)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(isSelected ? Color.brandPrimary : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(persona.title), \(persona.subtitle)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    VStack(spacing: 12) {
        PersonaCard(persona: .gastric, isSelected: true, onTap: {})
        PersonaCard(persona: .diet, isSelected: false, onTap: {})
        PersonaCard(persona: .curious, isSelected: false, onTap: {})
    }
    .padding()
}
