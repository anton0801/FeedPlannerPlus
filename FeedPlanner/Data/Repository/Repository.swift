import Foundation
import Firebase
import FirebaseMessaging

protocol Repository {
    func storeAttribution(_ data: [String: Any])
    func storeDeeplink(_ data: [String: Any])
    func getAttribution() -> [String: Any]
    func getDeeplink() -> [String: Any]
    func cacheEndpoint(_ endpoint: String)
    func getCachedEndpoint() -> String?
    func setMode(_ mode: String)
    func getMode() -> String?
    func isFirstLaunch() -> Bool
    func markLaunchCompleted()
    func recordAuthDismissal(_ date: Date)
    func getLastAuthRequest() -> Date?
    func saveAuthStatus(granted: Bool, denied: Bool)
    func wasAuthGranted() -> Bool
    func wasAuthDenied() -> Bool
}

private enum Key {
    static let attribution = "stored_attribution_data"
    static let deeplink = "stored_deeplink_data"
    static let endpoint = "cached_endpoint"
    static let mode = "app_status"
    static let firstLaunch = "launchedBefore"
    static let authRequest = "permission_request_time"
    static let authGranted = "permissions_accepted"
    static let authDenied = "permissions_denied"
}

final class RepositoryImplementation: Repository {
    
    private let storage: UserDefaults
    private var attributionCache: [String: Any] = [:]
    private var deeplinkCache: [String: Any] = [:]
    
    init(storage: UserDefaults = .standard) {
        self.storage = storage
    }
    
    func storeAttribution(_ data: [String: Any]) {
        attributionCache = data
    }
    
    func storeDeeplink(_ data: [String: Any]) {
        deeplinkCache = data
    }
    
    func getAttribution() -> [String: Any] {
        return attributionCache
    }
    
    func getDeeplink() -> [String: Any] {
        return deeplinkCache
    }
    
    func cacheEndpoint(_ endpoint: String) {
        storage.set(endpoint, forKey: Key.endpoint)
    }
    
    func getCachedEndpoint() -> String? {
        return storage.string(forKey: Key.endpoint)
    }
    
    func setMode(_ mode: String) {
        storage.set(mode, forKey: Key.mode)
    }
    
    func getMode() -> String? {
        return storage.string(forKey: Key.mode)
    }
    
    func isFirstLaunch() -> Bool {
        return !storage.bool(forKey: Key.firstLaunch)
    }
    
    func markLaunchCompleted() {
        storage.set(true, forKey: Key.firstLaunch)
    }
    
    func recordAuthDismissal(_ date: Date) {
        storage.set(date, forKey: Key.authRequest)
    }
    
    func getLastAuthRequest() -> Date? {
        return storage.object(forKey: Key.authRequest) as? Date
    }
    
    func saveAuthStatus(granted: Bool, denied: Bool) {
        storage.set(granted, forKey: Key.authGranted)
        storage.set(denied, forKey: Key.authDenied)
    }
    
    func wasAuthGranted() -> Bool {
        return storage.bool(forKey: Key.authGranted)
    }
    
    func wasAuthDenied() -> Bool {
        return storage.bool(forKey: Key.authDenied)
    }
}

struct DeviceInfo {

    static func firebaseProject() -> String? {
        return FirebaseApp.app()?.options.gcmSenderID
    }
    
    static func storeID() -> String {
        return "id\(Config.appsFlyerId)"
    }
    
    static func pushToken() -> String? {
        if let saved = UserDefaults.standard.string(forKey: "push_token") {
            return saved
        }
        return Messaging.messaging().fcmToken
    }
    
    static func locale() -> String {
        return Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
    }
    
    static func bundleID() -> String {
        return "com.plannerforfeed.FeedPlanner"
    }
    
    static func platform() -> String {
        return "iOS"
    }
}
