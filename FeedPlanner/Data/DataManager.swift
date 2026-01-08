import Foundation
import SwiftUI

class FeedData: ObservableObject {
    @AppStorage("chickenCount")      var chickenCount: Int = 50
    @AppStorage("feedPerChicken")    var feedPerChicken: Double = 0.15
    @AppStorage("todayFed")          var todayFed: Double = 0.0
    
    @AppStorage("cornP")    var cornP: Double = 40
    @AppStorage("wheatP")  var wheatP: Double = 30
    @AppStorage("mixP")     var mixP: Double = 20
    @AppStorage("chalkP")   var chalkP: Double = 5
    @AppStorage("proteinP") var proteinP: Double = 5
    
    @AppStorage("notificationsOn") var notificationsOn = true
    @AppStorage("vibrationOn")     var vibrationOn = true
    
    var morning = Date()
    var noon = Date()
    var evening = Date()
    
    @AppStorage("stockCorn")  var stockCorn: Double = 120
    @AppStorage("stockWheat") var stockWheat: Double = 80
    @AppStorage("stockMix")   var stockMix: Double = 50
    
    // История расхода за последние 30 дней (для графика)
    @AppStorage("feedHistory") var feedHistory: Data = {
        let values = Array(repeating: 7.5, count: 30)
        return try! JSONEncoder().encode(values)
    }()
    
    var history: [Double] {
        get { try! JSONDecoder().decode([Double].self, from: feedHistory) }
        set { feedHistory = try! JSONEncoder().encode(newValue) }
    }
    
    @AppStorage("customFeedings") var customFeedingsData = Data()
    var customFeedings: [Date] {
        get { (try? JSONDecoder().decode([Date].self, from: customFeedingsData)) ?? [] }
        set { customFeedingsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}
