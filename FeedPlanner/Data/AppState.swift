import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var showSplash = true
    @Published var selectedTab = 0
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        withAnimation(.spring()) {
            hasCompletedOnboarding = true
        }
    }
    
    func hideSplash() {
        withAnimation(.easeOut(duration: 0.5)) {
            showSplash = false
        }
    }
}
