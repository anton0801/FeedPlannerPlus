import SwiftUI
import Firebase
import FirebaseAuth

@main
struct FeedPlannerApp: App {
    
    @UIApplicationDelegateAdaptor(LifecycleMediator.self) var lifecycleMediator
    
    @StateObject var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            PlannerApplicationView()
                .environmentObject(appState)
        }
    }
    
}

