import Foundation
import Combine

class InventoryViewModel: ObservableObject {
    @Published var inventoryItems: [InventoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    
    var lowStockItems: [InventoryItem] {
        inventoryItems.filter { $0.stockLevel == .critical || $0.stockLevel == .low }
    }
    
    var expiringItems: [InventoryItem] {
        inventoryItems.filter {
            if let days = $0.daysUntilExpiration {
                return days <= 7 && days >= 0
            }
            return false
        }
    }
    
    var totalValue: Double {
        inventoryItems.reduce(0) { $0 + ($1.quantity * $1.pricePerKg) }
    }
    
    init() {
        loadInventory()
    }
    
    func loadInventory() {
        isLoading = true
        
        firebaseService.fetchInventory { [weak self] items in
            self?.inventoryItems = items.sorted { $0.quantity < $1.quantity }
            self?.isLoading = false
        }
    }
    
    func addItem(name: String, quantity: Double, unit: String, expirationDate: Date?, pricePerKg: Double) {
        let item = InventoryItem(
            name: name,
            quantity: quantity,
            unit: unit,
            expirationDate: expirationDate,
            pricePerKg: pricePerKg
        )
        
        firebaseService.saveInventoryItem(item) { [weak self] success in
            if success {
                self?.loadInventory()
            } else {
                self?.errorMessage = "Failed to add item"
            }
        }
    }
    
    func updateItem(_ item: InventoryItem) {
        firebaseService.saveInventoryItem(item) { [weak self] success in
            if success {
                self?.loadInventory()
            } else {
                self?.errorMessage = "Failed to update item"
            }
        }
    }
    
    func deleteItem(_ item: InventoryItem) {
        firebaseService.deleteInventoryItem(item.id) { [weak self] success in
            if success {
                self?.loadInventory()
            } else {
                self?.errorMessage = "Failed to delete item"
            }
        }
    }
    
    func consumeFeed(itemId: String, amount: Double) {
        guard let index = inventoryItems.firstIndex(where: { $0.id == itemId }) else { return }
        
        var item = inventoryItems[index]
        item.quantity = max(0, item.quantity - amount)
        
        updateItem(item)
    }
    
    func getStockWarnings() -> [String] {
        var warnings: [String] = []
        
        for item in lowStockItems {
            warnings.append("\(item.name): \(String(format: "%.1f", item.quantity)) \(item.unit) remaining")
        }
        
        for item in expiringItems {
            if let days = item.daysUntilExpiration {
                warnings.append("\(item.name): expires in \(days) days")
            }
        }
        
        return warnings
    }
}
