import SwiftUI

struct NormsScreen: View {
    @EnvironmentObject var data: FeedData
    @State private var showingDetails = false
    
    var totalDaily: Double { Double(data.chickenCount) * data.feedPerChicken }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(LinearGradient(colors: [.yellowBtn, .shine], startPoint: .bottom, endPoint: .top))
                            .frame(height: 180)
                            .shadow(color: .black.opacity(0.2), radius: 12, y: 8)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("\(data.chickenCount) Chickens")
                                    .font(.title.bold())
                                Text("\(data.feedPerChicken * 1000, specifier: "%.0f") g per bird")
                                    .font(.title3)
                                Text("Daily total: \(totalDaily, specifier: "%.1f") kg")
                                    .font(.largeTitle.bold())
                            }
                            .foregroundColor(.textMain)
                            
                            Spacer()
                            
                            Image(systemName: "bag.circle.fill")
                                .font(.system(size: 90))
                                .foregroundColor(.icon)
                        }
                        .padding(30)
                    }
                    .padding(.horizontal)
                    
                    // Сегодня выдано
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today Fed")
                            .font(.title2.bold())
                            .foregroundColor(.textMain)
                        
                        Slider(value: $data.todayFed, in: 0...totalDaily, step: 0.1)
                            .accentColor(.orangeBtn)
                        
                        HStack {
                            Text("0 kg")
                            Spacer()
                            Text("\(data.todayFed, specifier: "%.1f") kg")
                                .font(.title.bold())
                                .foregroundColor(data.todayFed >= totalDaily * 0.95 ? .good : .warning)
                            Spacer()
                            Text("\(totalDaily, specifier: "%.1f") kg")
                        }
                        .foregroundColor(.textSec)
                    }
                    .padding(20)
                    .background(Color.card)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    Button("More Details") {
                        showingDetails = true
                    }
                    .buttonStyle(GlossyButtonStyle())
                    .padding(.horizontal, 60)
                    .sheet(isPresented: $showingDetails) {
                        DetailNormsView()
                            .environmentObject(data)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Feeding Norms")
        }
    }
}

#Preview {
    NormsScreen()
}

struct DetailNormsView: View {
    @EnvironmentObject var data: FeedData
    @Environment(\.dismiss) var dismiss
    
    var totalDaily: Double { Double(data.chickenCount) * data.feedPerChicken }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Current Settings") {
                    Stepper("Chickens: \(data.chickenCount)", value: $data.chickenCount, in: 1...1000)
                    HStack {
                        Text("Feed per bird")
                        Spacer()
                        TextField("g", value: $data.feedPerChicken, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .keyboardType(.decimalPad)
                        Text("kg")
                    }
                }
                Section("Daily Total") {
                    Text("\(totalDaily, specifier: "%.2f") kg")
                        .font(.title2.bold())
                }
            }
            .navigationTitle("Detailed Norms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
