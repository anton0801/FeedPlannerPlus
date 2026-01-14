import SwiftUI
import Combine

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var particles: [Particle] = []
    @State private var showTitle = false
    @State private var rotation: Double = 0
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.backgroundPrimary, Color.backgroundSecondary, Color.golden],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Image("main_back")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(0.85)
                
                
                if g.size.width < g.size.height {
                    VStack {
                        Spacer()
                        
                        Image("chick")
                            .resizable()
                            .frame(width: g.size.width, height: g.size.width + 70)
                    }
                }
                
                VStack {
                    if g.size.width > g.size.height {
                        Image("app_logo")
                            .resizable()
                            .frame(width: g.size.height - 130, height: g.size.height - 130)
                            .padding(.bottom, 120)
                    } else {
                        Image("app_logo")
                            .resizable()
                            .frame(width: g.size.width, height: g.size.width)
                        
                        Spacer()
                        
                        Image("load_icon")
                            .resizable()
                            .frame(width: 150, height: 45)
                            .padding(.bottom)
                    }
                }
                
                // Animated particles
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .blur(radius: particle.blur)
                }
                
                VStack(spacing: 20) {
                    // Animated logo
                    ZStack {
                        // Rotating outer ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.accentPrimary, Color.accentSecondary, Color.golden],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(rotation))
                        
                        // Main icon container
                        Circle()
                            .fill(LinearGradient.cardGradient)
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.shadow.opacity(0.3), radius: 15, x: 0, y: 10)
                        
                        // Feed bucket icon
                        ZStack {
                            // Bucket body
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.iconColor)
                                .frame(width: 50, height: 55)
                                .offset(y: 5)
                            
                            // Bucket rim
                            Ellipse()
                                .fill(Color.accentPrimary)
                                .frame(width: 60, height: 15)
                                .offset(y: -20)
                            
                            // Feed grains
                            HStack(spacing: 4) {
                                ForEach(0..<3) { _ in
                                    Circle()
                                        .fill(Color.golden)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .offset(y: 30)
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .padding(.top, g.size.width > g.size.height ? 140 : 0)
                }
            }
            .onAppear {
                startAnimations()
            }
        }
        .ignoresSafeArea()
    }
    
    private func startAnimations() {
        // Generate particles
        generateParticles()
        
        // Animate particles
        withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
            animateParticles()
        }
        
        // Animate logo
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Rotate outer ring
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Show title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showTitle = true
            }
        }
    }
    
    private func generateParticles() {
        let colors: [Color] = [.accentPrimary, .golden, .accentSecondary, .iconColor]
        
        for _ in 0..<30 {
            let particle = Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 4...12),
                color: colors.randomElement()!.opacity(0.6),
                opacity: Double.random(in: 0.3...0.8),
                blur: CGFloat.random(in: 1...3)
            )
            particles.append(particle)
        }
    }
    
    private func animateParticles() {
        for index in particles.indices {
            particles[index].position.y -= CGFloat.random(in: 50...150)
            particles[index].opacity = 0
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
    var blur: CGFloat
}

struct PlannerApplicationView: View {
    
    @EnvironmentObject var appState: AppState
    @StateObject private var orchestrator = ApplicationOrchestrator()
    @State private var subscriptions: Set<AnyCancellable> = []
    
    var body: some View {
        ZStack {
            contentView
            
            if orchestrator.showAuthPrompt {
                AuthPromptOverlay()
                    .environmentObject(orchestrator)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            
            NotificationCenter.default
                .publisher(for: Notification.Name("deeplink_values"))
                .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
                .sink { data in
                    orchestrator.receive(deeplinkData: data)
                }
                .store(in: &subscriptions)
            
            registerNotificationObservers()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if orchestrator.viewState == .initializing {
            SplashScreenView()
        } else if orchestrator.viewState == .operational {
            if orchestrator.activeEndpoint != nil {
                FeedDisplayView()
            } else {
                ContentView()
                    .environmentObject(AppState())
            }
        } else if orchestrator.viewState == .idle {
            ContentView()
                .environmentObject(AppState())
        } else if orchestrator.viewState == .offline {
            OfflineView()
        } else {
            EmptyView()
        }
    }
    
    private func registerNotificationObservers() {
        NotificationCenter.default
            .publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                orchestrator.receive(attributionData: data)
            }
            .store(in: &subscriptions)
    }
}

struct InitializingView: View {
    var body: some View {
        Color.white
            .ignoresSafeArea()
    }
}

struct AuthPromptOverlay: View {
    
    @EnvironmentObject var orchestrator: ApplicationOrchestrator
    @State private var animate = false
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                Image(g.size.width > g.size.height ? "sback2" : "s_back")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(1)
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    messageSection
                    actionsSection
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea()
    }
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            
            Button(action: {
                orchestrator.acceptAuthPrompt()
            }) {
                Image("sbtn")
                    .resizable()
                    .frame(width: 310, height: 55)
            }
            
            Button(action: {
                orchestrator.dismissAuthPrompt()
            }) {
                Text("Skip")
                    .font(.custom("BagelFatOne-Regular", size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 52)
                    .multilineTextAlignment(.center)
            }
            
        }
    }
    
    private var messageSection: some View {
        VStack(spacing: 14) {
            Text("Allow notifications about bonuses and promos")
                .font(.custom("BagelFatOne-Regular", size: 24))
                .foregroundColor(.white)
                .padding(.horizontal, 52)
                .multilineTextAlignment(.center)
            
            Text("Stay tuned with best offers from our casino")
                .font(.custom("BagelFatOne-Regular", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 52)
                .multilineTextAlignment(.center)
        }
    }
    
}

struct OfflineView: View {
    var body: some View {
        GeometryReader { g in
            ZStack {
                Image("second_back")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(1)
                
                VStack(spacing: 22) {
                    Image("warning")
                        .resizable()
                        .frame(width: 300, height: 250)
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
    }
}

