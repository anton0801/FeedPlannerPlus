import SwiftUI

struct GlossyButton: View {
    let title: String
    var icon: String? = nil
    var style: ButtonStyle = .primary
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary, secondary, compact
        
        var gradient: LinearGradient {
            switch self {
            case .primary, .compact:
                return LinearGradient.primaryButton
            case .secondary:
                return LinearGradient.secondaryButton
            }
        }
        
        var height: CGFloat {
            switch self {
            case .primary: return 56
            case .secondary: return 56
            case .compact: return 44
            }
        }
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Action
            action()
        }) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: style == .compact ? 16 : 18, weight: .semibold, design: .rounded))
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: style == .compact ? 16 : 18, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: style == .compact ? nil : .infinity)
            .frame(height: style.height)
            .padding(.horizontal, style == .compact ? 20 : 0)
            .background(
                ZStack {
                    // Main gradient
                    RoundedRectangle(cornerRadius: style == .compact ? 22 : 28)
                        .fill(style.gradient)
                    
                    // Gloss overlay
                    RoundedRectangle(cornerRadius: style == .compact ? 22 : 28)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    
                    // Border highlight
                    RoundedRectangle(cornerRadius: style == .compact ? 22 : 28)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        .blur(radius: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PressButtonStyle(isPressed: $isPressed))
    }
}

struct PressButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = newValue
                }
            }
    }
}
