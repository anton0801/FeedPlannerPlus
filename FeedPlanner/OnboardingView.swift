import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Manage Feeding",
            description: "Track daily norms, record consumption and monitor your flock's health",
            icon: "chart.bar.fill",
            color: .accentPrimary,
            illustration: .dashboard
        ),
        OnboardingPage(
            title: "Create Balanced Rations",
            description: "Mix ingredients with automatic nutritional balance calculation",
            icon: "slider.horizontal.3",
            color: .accentSecondary,
            illustration: .formula
        ),
        OnboardingPage(
            title: "Set Feed Times",
            description: "Get reminders for feeding times and never forget to feed your birds",
            icon: "clock.fill",
            color: .golden,
            illustration: .schedule
        ),
        OnboardingPage(
            title: "Control Stock",
            description: "Monitor feed inventory, expiration dates and plan purchases",
            icon: "cube.box.fill",
            color: .chartLine,
            illustration: .inventory
        ),
        OnboardingPage(
            title: "Analyze Trends",
            description: "Study consumption charts, optimize costs and increase efficiency",
            icon: "chart.line.uptrend.xyaxis",
            color: .success,
            illustration: .statistics
        )
    ]
    
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.accentPrimary : Color.textSecondary.opacity(0.3))
                            .frame(width: index == currentPage ? 30 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], pageIndex: index, currentPage: $currentPage)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Bottom buttons
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        GlossyButton(title: "Get Started", icon: "arrow.right") {
                            withAnimation(.spring()) {
                                isPresented = false
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        HStack {
                            Button(action: {
                                withAnimation(.spring()) {
                                    isPresented = false
                                }
                            }) {
                                Text("Skip")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            GlossyButton(title: "Next", icon: "arrow.right", style: .compact) {
                                withAnimation(.spring()) {
                                    currentPage += 1
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let illustration: IllustrationType
    
    enum IllustrationType {
        case dashboard, formula, schedule, inventory, statistics
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let pageIndex: Int
    @Binding var currentPage: Int
    
    @State private var illustrationScale: CGFloat = 0.8
    @State private var illustrationOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Illustration
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.color.opacity(0.2), page.color.opacity(0.05)],
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .frame(width: 280, height: 280)
                
                // Main illustration
                illustrationView
                    .scaleEffect(illustrationScale)
                    .opacity(illustrationOpacity)
            }
            .frame(height: 300)
            
            // Content
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(page.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: page.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(page.color)
                }
                
                // Title
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(page.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            .offset(y: textOffset)
            .opacity(textOpacity)
            
            Spacer()
        }
        .onChange(of: currentPage) { newValue in
            if newValue == pageIndex {
                animateIn()
            }
        }
        .onAppear {
            if currentPage == pageIndex {
                animateIn()
            }
        }
    }
    
    private var illustrationView: some View {
        Group {
            switch page.illustration {
            case .dashboard:
                DashboardIllustration(color: page.color)
            case .formula:
                FormulaIllustration(color: page.color)
            case .schedule:
                ScheduleIllustration(color: page.color)
            case .inventory:
                InventoryIllustration(color: page.color)
            case .statistics:
                StatisticsIllustration(color: page.color)
            }
        }
    }
    
    private func animateIn() {
        // Reset
        illustrationScale = 0.8
        illustrationOpacity = 0
        textOffset = 30
        textOpacity = 0
        
        // Animate illustration
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            illustrationScale = 1.0
            illustrationOpacity = 1.0
        }
        
        // Animate text
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            textOffset = 0
            textOpacity = 1.0
        }
    }
}

// MARK: - Illustrations
struct DashboardIllustration: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // Chart bars
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(Double(index + 1) * 0.2))
                        .frame(width: 30, height: CGFloat(40 + index * 20))
                }
            }
            
            // Chicken icon overlay
            Image(systemName: "bird.fill")
                .font(.system(size: 50))
                .foregroundColor(color)
                .offset(y: -60)
        }
    }
}

struct FormulaIllustration: View {
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            // Ingredient cards
            ForEach(0..<3) { index in
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.3))
                        .frame(width: 100, height: 40)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(color)
                        .frame(width: 120, height: 8)
                }
            }
        }
    }
}

struct ScheduleIllustration: View {
    let color: Color
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Clock face
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 8)
                .frame(width: 150, height: 150)
            
            // Clock hands
            VStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 6, height: 50)
                    .offset(y: -25)
                Spacer()
            }
            .rotationEffect(.degrees(rotation))
            
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct InventoryIllustration: View {
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            ForEach(0..<3) { index in
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(Double(3 - index) * 0.3))
                        .frame(width: 50, height: 70)
                    
                    Text("\(index + 1)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(color)
                }
            }
        }
    }
}

struct StatisticsIllustration: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // Line chart
            Path { path in
                path.move(to: CGPoint(x: 0, y: 80))
                path.addLine(to: CGPoint(x: 40, y: 60))
                path.addLine(to: CGPoint(x: 80, y: 70))
                path.addLine(to: CGPoint(x: 120, y: 40))
                path.addLine(to: CGPoint(x: 160, y: 50))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            
            // Data points
            ForEach([CGPoint(x: 0, y: 80), CGPoint(x: 40, y: 60), CGPoint(x: 80, y: 70), CGPoint(x: 120, y: 40), CGPoint(x: 160, y: 50)], id: \.x) { point in
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .position(point)
            }
        }
        .frame(width: 160, height: 100)
    }
}

