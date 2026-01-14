import Foundation
import FirebaseDatabase
import SwiftUI

struct ChickenFlock: Codable, Identifiable {
    var id: String
    var name: String
    var count: Int
    var feedPerChicken: Double // grams per day
    var createdAt: Date
    
    var totalDailyFeed: Double {
        return Double(count) * feedPerChicken
    }
    
    init(id: String = UUID().uuidString, name: String, count: Int, feedPerChicken: Double) {
        self.id = id
        self.name = name
        self.count = count
        self.feedPerChicken = feedPerChicken
        self.createdAt = Date()
    }
}

struct FeedRecord: Codable, Identifiable {
    var id: String
    var date: Date
    var amountGiven: Double // grams
    var flockId: String
    
    init(id: String = UUID().uuidString, date: Date = Date(), amountGiven: Double, flockId: String) {
        self.id = id
        self.date = date
        self.amountGiven = amountGiven
        self.flockId = flockId
    }
}

struct FeedIngredient: Identifiable, Codable {
    var id: String
    var name: String
    var percentage: Double
    var proteinContent: Double
    var energyContent: Double
    
    init(id: String = UUID().uuidString, name: String, percentage: Double = 0, proteinContent: Double, energyContent: Double) {
        self.id = id
        self.name = name
        self.percentage = percentage
        self.proteinContent = proteinContent
        self.energyContent = energyContent
    }
}

// MARK: - Feed Formula Model
struct FeedFormula: Codable, Identifiable {
    var id: String
    var name: String
    var ingredients: [FeedIngredient]
    var createdAt: Date
    var isActive: Bool
    
    var totalProtein: Double {
        ingredients.reduce(0) { $0 + ($1.percentage / 100.0 * $1.proteinContent) }
    }
    
    var totalEnergy: Double {
        ingredients.reduce(0) { $0 + ($1.percentage / 100.0 * $1.energyContent) }
    }
    
    var totalPercentage: Double {
        ingredients.reduce(0) { $0 + $1.percentage }
    }
    
    var balanceStatus: BalanceStatus {
        let protein = totalProtein
        let energy = totalEnergy
        let percentage = totalPercentage
        
        if abs(percentage - 100) > 1 {
            return .incomplete
        }
        
        if protein < 14 {
            return .lowProtein
        }
        
        if energy < 2700 {
            return .lowEnergy
        }
        
        if protein >= 16 && protein <= 18 && energy >= 2800 && energy <= 3000 {
            return .balanced
        }
        
        return .acceptable
    }
    
    enum BalanceStatus {
        case balanced
        case acceptable
        case lowProtein
        case lowEnergy
        case incomplete
        
        var message: String {
            switch self {
            case .balanced: return "Balanced"
            case .acceptable: return "Acceptable"
            case .lowProtein: return "Low Protein"
            case .lowEnergy: return "Low Energy"
            case .incomplete: return "Incomplete"
            }
        }
        
        var color: Color {
            switch self {
            case .balanced: return .success
            case .acceptable: return .golden
            case .lowProtein, .lowEnergy: return .warning
            case .incomplete: return .error
            }
        }
    }
    
    init(id: String = UUID().uuidString, name: String, ingredients: [FeedIngredient], isActive: Bool = false) {
        self.id = id
        self.name = name
        self.ingredients = ingredients
        self.createdAt = Date()
        self.isActive = isActive
    }
}

// MARK: - Feeding Schedule Model
struct FeedingSchedule: Codable, Identifiable {
    var id: String
    var time: Date
    var amount: Double
    var isEnabled: Bool
    var notificationId: String?
    
    enum FeedingTime: String, CaseIterable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        
        var icon: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .afternoon: return "sun.max.fill"
            case .evening: return "sunset.fill"
            }
        }
        
        var defaultHour: Int {
            switch self {
            case .morning: return 7
            case .afternoon: return 13
            case .evening: return 19
            }
        }
    }
    
    init(id: String = UUID().uuidString, time: Date, amount: Double, isEnabled: Bool = true) {
        self.id = id
        self.time = time
        self.amount = amount
        self.isEnabled = isEnabled
    }
}

// MARK: - Inventory Item Model
struct InventoryItem: Codable, Identifiable {
    var id: String
    var name: String
    var quantity: Double // kg
    var unit: String
    var expirationDate: Date?
    var purchaseDate: Date
    var pricePerKg: Double
    
    var daysUntilExpiration: Int? {
        guard let expiration = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiration).day
    }
    
    var stockLevel: StockLevel {
        if quantity <= 10 {
            return .critical
        } else if quantity <= 30 {
            return .low
        } else if quantity <= 100 {
            return .medium
        } else {
            return .high
        }
    }
    
    enum StockLevel {
        case critical, low, medium, high
        
        var color: Color {
            switch self {
            case .critical: return .error
            case .low: return .warning
            case .medium: return .golden
            case .high: return .success
            }
        }
        
        var percentage: Double {
            switch self {
            case .critical: return 0.15
            case .low: return 0.35
            case .medium: return 0.65
            case .high: return 1.0
            }
        }
    }
    
    init(id: String = UUID().uuidString, name: String, quantity: Double, unit: String = "kg", expirationDate: Date? = nil, purchaseDate: Date = Date(), pricePerKg: Double = 0) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.expirationDate = expirationDate
        self.purchaseDate = purchaseDate
        self.pricePerKg = pricePerKg
    }
}

// MARK: - Statistics Model
struct FeedingStatistics {
    var totalFeedGiven: Double
    var averageDailyFeed: Double
    var totalCost: Double
    var records: [FeedRecord]
    
    var dailyData: [(date: Date, amount: Double)] {
        let grouped = Dictionary(grouping: records) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.map { (date: $0.key, amount: $0.value.reduce(0) { $0 + $1.amountGiven }) }
            .sorted { $0.date < $1.date }
    }
}

struct Config {
    static let appsFlyerKey = "MLc5fs6DsfBCVqWGJDXSU4"
    static let appsFlyerId = "6757537866"
}
