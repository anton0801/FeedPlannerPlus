import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var flocks: [ChickenFlock] = []
    @Published var todayRecords: [FeedRecord] = []
    @Published var weekRecords: [FeedRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties
    var totalChickens: Int {
        flocks.reduce(0) { $0 + $1.count }
    }
    
    var totalDailyNorm: Double {
        flocks.reduce(0) { $0 + $1.totalDailyFeed }
    }
    
    var todayGiven: Double {
        todayRecords.reduce(0) { $0 + $1.amountGiven }
    }
    
    var remainingToday: Double {
        max(0, totalDailyNorm - todayGiven)
    }
    
    var completionPercentage: Double {
        guard totalDailyNorm > 0 else { return 0 }
        return min(1.0, todayGiven / totalDailyNorm)
    }
    
    var weeklyData: [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var data: [(date: Date, amount: Double)] = []
        
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dayRecords = weekRecords.filter {
                    calendar.isDate($0.date, inSameDayAs: date)
                }
                let total = dayRecords.reduce(0) { $0 + $1.amountGiven }
                data.append((date: date, amount: total))
            }
        }
        
        return data
    }
    
    init() {
        loadData()
        
        // Observe authentication state
        firebaseService.$isAuthenticated
            .sink { [weak self] isAuth in
                if isAuth {
                    self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        isLoading = true
        
        let group = DispatchGroup()
        
        // Load flocks
        group.enter()
        firebaseService.fetchFlocks { [weak self] flocks in
            self?.flocks = flocks
            
            // Load feed records for each flock
            let recordGroup = DispatchGroup()
            var allRecords: [FeedRecord] = []
            
            for flock in flocks {
                recordGroup.enter()
                self?.firebaseService.fetchFeedRecords(for: flock.id) { records in
                    allRecords.append(contentsOf: records)
                    recordGroup.leave()
                }
            }
            
            recordGroup.notify(queue: .main) {
                self?.filterRecords(allRecords)
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
    
    private func filterRecords(_ records: [FeedRecord]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        todayRecords = records.filter {
            calendar.isDate($0.date, inSameDayAs: Date())
        }
        
        weekRecords = records.filter {
            if let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) {
                return $0.date >= weekAgo
            }
            return false
        }
    }
    
    func addFeedRecord(amount: Double, flockId: String) {
        let record = FeedRecord(amountGiven: amount, flockId: flockId)
        
        firebaseService.saveFeedRecord(record) { [weak self] success in
            if success {
                self?.loadData()
            } else {
                self?.errorMessage = "Failed to save record"
            }
        }
    }
    
    func addFlock(name: String, count: Int, feedPerChicken: Double) {
        let flock = ChickenFlock(name: name, count: count, feedPerChicken: feedPerChicken)
        
        firebaseService.saveFlock(flock) { [weak self] success in
            if success {
                self?.loadData()
            } else {
                self?.errorMessage = "Failed to save flock"
            }
        }
    }
}
