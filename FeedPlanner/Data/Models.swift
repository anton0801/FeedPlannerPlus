import Foundation

struct FeedingNorm {
    let chickenCount: Int
    let feedPerChicken: Double
    let totalDailyFeed: Double
}

struct Ingredient {
    let name: String
    let icon: String // Use SF Symbols for simplicity
    var percentage: Double
}

struct ScheduleItem {
    let time: String
    let icon: String
}
