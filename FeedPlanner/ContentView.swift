import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            if !appState.hasCompletedOnboarding {
                OnboardingView(isPresented: Binding(
                    get: { !appState.hasCompletedOnboarding },
                    set: { if !$0 { appState.completeOnboarding() } }
                ))
            } else {
                MainTabView()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            
            FormulaView()
                .tabItem {
                    Label("Formula", systemImage: "slider.horizontal.3")
                }
                .tag(1)
            
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "clock.fill")
                }
                .tag(2)
            
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "cube.box.fill")
                }
                .tag(3)
            
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
                .tag(4)
        }
        .accentColor(.accentPrimary)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.backgroundSecondary)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
