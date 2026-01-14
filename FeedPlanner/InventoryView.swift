import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @State private var showAddItem = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Total Value Card
                        InfoCard(
                            title: "Total Inventory Value",
                            value: "$\(String(format: "%.2f", viewModel.totalValue))",
                            icon: "dollarsign.circle.fill",
                            color: .success
                        )
                        
                        // Warnings
                        if !viewModel.lowStockItems.isEmpty || !viewModel.expiringItems.isEmpty {
                            GlossyCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.warning)
                                        Text("Warnings")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.textPrimary)
                                    }
                                    
                                    ForEach(viewModel.getStockWarnings(), id: \.self) { warning in
                                        Text(warning)
                                            .font(.system(size: 14))
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                            }
                        }
                        
                        // Inventory Items
                        if viewModel.inventoryItems.isEmpty {
                            GlossyCard {
                                VStack(spacing: 12) {
                                    Image(systemName: "cube.box.circle")
                                        .font(.system(size: 50))
                                        .foregroundColor(.textSecondary.opacity(0.5))
                                    
                                    Text("No Inventory")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.vertical, 20)
                            }
                        } else {
                            ForEach(viewModel.inventoryItems) { item in
                                InventoryItemCard(item: item)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddItem = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentPrimary)
                    }
                }
            }
        }
    }
}

struct InventoryItemCard: View {
    let item: InventoryItem
    
    var body: some View {
        GlossyCard(padding: 16) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.textPrimary)
                        
                        Text("\(String(format: "%.1f", item.quantity)) \(item.unit)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(item.stockLevel.color)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(item.stockLevel.color.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("\(Int(item.stockLevel.percentage * 100))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(item.stockLevel.color)
                        )
                }
                
                // Stock level bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.textSecondary.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(item.stockLevel.color)
                            .frame(width: geometry.size.width * item.stockLevel.percentage, height: 8)
                    }
                }
                .frame(height: 8)
                
                if let days = item.daysUntilExpiration {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text("Expires in \(days) days")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }
}
