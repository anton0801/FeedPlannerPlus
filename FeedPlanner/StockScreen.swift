import SwiftUI

struct StockScreen: View {
    @EnvironmentObject var data: FeedData
    @State private var showingAddStock = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    StockItem(name: "Corn",      amount: data.stockCorn,  color: .gold)
                    StockItem(name: "Wheat",     amount: data.stockWheat, color: .yellowBtn)
                    StockItem(name: "Feed Mix",  amount: data.stockMix,   color: .orangeBtn)
                    
//                    ForEach(data.customFeedingsData) { feed in
//                        
//                    }
                    
                    Button("Add New Stock") {
                        showingAddStock = true
                    }
                        .buttonStyle(GlossyButtonStyle())
                        .padding(.top, 20)
                }
                .padding()
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Stock")
            .sheet(isPresented: $showingAddStock) {
                AddStockView()
                    .environmentObject(data)
            }
        }
    }
}

struct StockItem: View {
    let name: String
    let amount: Double
    let color: Color
    
    var levelColor: Color {
        amount > 50 ? .good : amount > 20 ? .warning : .error
    }
    
    var body: some View {
        HStack {
            Image(systemName: "bag.fill")
                .font(.system(size: 50))
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(name).font(.title2.bold())
                Text("\(amount, specifier: "%.1f") kg").foregroundColor(.textSec)
            }
            
            Spacer()
            
            VStack {
                Text("\(Int(amount))%")
                    .font(.title.bold())
                Circle().fill(levelColor).frame(width: 20, height: 20)
            }
        }
        .padding()
        .background(Color.card)
        .cornerRadius(20)
    }
}

#Preview {
    StockScreen()
        .environmentObject(FeedData())
}

struct AddStockView: View {
    @EnvironmentObject var data: FeedData
    @Environment(\.dismiss) var dismiss
    @State private var selectedFeed = "Corn"
    @State private var quantity = 50.0
    
    let feeds = ["Corn", "Wheat", "Feed Mix"]
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Feed Type", selection: $selectedFeed) {
                    ForEach(feeds, id: \.self) { Text($0) }
                }
                HStack {
                    Text("Quantity (kg)")
                    Spacer()
                    TextField("50", value: $quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 100)
                }
            }
            .navigationTitle("Add Stock")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        switch selectedFeed {
                        case "Corn": data.stockCorn += quantity
                        case "Wheat": data.stockWheat += quantity
                        default: data.stockMix += quantity
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
