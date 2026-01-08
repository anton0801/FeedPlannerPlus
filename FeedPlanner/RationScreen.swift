import SwiftUI

struct RationScreen: View {
    @EnvironmentObject var data: FeedData
    
    var total: Double { data.cornP + data.wheatP + data.mixP + data.chalkP + data.proteinP }
    
    var status: (String, Color) {
        abs(total - 100) < 3 ? ("Balanced", .good) :
        total < 95 ? ("Low Protein", .warning) : ("Too Much", .error)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    RationRow(name: "Corn",     icon: "leaf.fill",         value: $data.cornP)
                    RationRow(name: "Wheat",    icon: "leaf.fill",         value: $data.wheatP)
                    RationRow(name: "Feed Mix", icon: "bag.fill",          value: $data.mixP)
                    RationRow(name: "Chalk",    icon: "circle.grid.2x2",   value: $data.chalkP)
                    RationRow(name: "Protein",  icon: "bolt.fill",         value: $data.proteinP)
                    
                    Text(status.0)
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(status.1)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    
                    HStack {
                        Button("Save") { }.buttonStyle(GlossyButtonStyle())
                        Button("Apply") { }.buttonStyle(GlossyButtonStyle())
                    }
                }
                .padding(.vertical)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Feed Ration")
        }
    }
}

struct RationRow: View {
    let name: String
    let icon: String
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.icon)
                .frame(width: 50)
            Text(name).font(.title3).foregroundColor(.textMain)
            Spacer()
            Text("\(Int(value))%").font(.title2.bold())
            Slider(value: $value, in: 0...100, step: 1)
                .frame(width: 130)
                .accentColor(.orangeBtn)
        }
        .padding()
        .background(Color.card)
        .cornerRadius(18)
        .padding(.horizontal)
    }
}

#Preview {
    RationScreen()
}
