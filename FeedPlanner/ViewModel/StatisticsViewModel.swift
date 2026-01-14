import Foundation
import Combine

class StatisticsViewModel: ObservableObject {
    @Published var feedRecords: [FeedRecord] = []
    @Published var inventoryItems: [InventoryItem] = []
    @Published var isLoading = false
    @Published var selectedPeriod: Period = .week
    
    private let firebaseService = FirebaseService.shared
    
    enum Period: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        
        var daysCount: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    var filteredRecords: [FeedRecord] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.daysCount, to: Date()) ?? Date()
        
        return feedRecords.filter { $0.date >= startDate }
    }
    
    var totalFeedGiven: Double {
        filteredRecords.reduce(0) { $0 + $1.amountGiven }
    }
    
    var averageDailyFeed: Double {
        guard selectedPeriod.daysCount > 0 else { return 0 }
        return totalFeedGiven / Double(selectedPeriod.daysCount)
    }
    
    var totalCost: Double {
        let avgPricePerKg = inventoryItems.isEmpty ? 0 : inventoryItems.reduce(0) { $0 + $1.pricePerKg } / Double(inventoryItems.count)
        return totalFeedGiven * avgPricePerKg
    }
    
    var dailyData: [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.daysCount, to: endDate) ?? endDate
        
        var data: [(date: Date, amount: Double)] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayRecords = filteredRecords.filter {
                calendar.isDate($0.date, inSameDayAs: currentDate)
            }
            let total = dayRecords.reduce(0) { $0 + $1.amountGiven }
            data.append((date: currentDate, amount: total))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return data
    }
    
    var ingredientDistribution: [(name: String, percentage: Double)] {
        // This would come from active formula in real implementation
        return [
            ("Corn", 40),
            ("Wheat", 30),
            ("Soybean", 20),
            ("Other", 10)
        ]
    }
    
    var projectedMonthCost: Double {
        return averageDailyFeed * 30 * (inventoryItems.isEmpty ? 0 : inventoryItems.reduce(0) { $0 + $1.pricePerKg } / Double(inventoryItems.count))
    }
    
    init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        let group = DispatchGroup()
        
        // Load all flocks to get their records
        group.enter()
        firebaseService.fetchFlocks { [weak self] flocks in
            var allRecords: [FeedRecord] = []
            let recordGroup = DispatchGroup()
            
            for flock in flocks {
                recordGroup.enter()
                self?.firebaseService.fetchFeedRecords(for: flock.id) { records in
                    allRecords.append(contentsOf: records)
                    recordGroup.leave()
                }
            }
            
            recordGroup.notify(queue: .main) {
                self?.feedRecords = allRecords
                group.leave()
            }
        }
        
        // Load inventory
        group.enter()
        firebaseService.fetchInventory { [weak self] items in
            self?.inventoryItems = items
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
    
    func changePeriod(_ period: Period) {
        selectedPeriod = period
    }
}
