import SwiftUI

struct ContentView: View {
    @StateObject private var data = FeedData()
    
    var body: some View {
        VStack {
            TabView {
                NormsScreen().tabItem { Label("Norms", systemImage: "chart.pie.fill") }.environmentObject(data)
                RationScreen().tabItem { Label("Ration", systemImage: "leaf.fill") }.environmentObject(data)
                ScheduleScreen().tabItem { Label("Schedule", systemImage: "bell.fill") }.environmentObject(data)
//                StatsScreen().tabItem { Label("Stats", systemImage: "chart.bar.fill") }.environmentObject(data)
                StockScreen().tabItem { Label("Stock", systemImage: "bag.fill") }.environmentObject(data)
            }
            .accentColor(.orangeBtn)
        }
    }
}

#Preview {
    ContentView()
}

struct GlossyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(
                LinearGradient(colors: [.yellowBtn, .shine], startPoint: .bottom, endPoint: .top)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
            )
            .overlay(
                LinearGradient(colors: [Color.white.opacity(0.6), Color.clear],
                               startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(3)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}


