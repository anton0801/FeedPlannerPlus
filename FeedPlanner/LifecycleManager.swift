import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib
import FirebaseAuth

final class LifecycleMediator: UIResponder, UIApplicationDelegate {
    
    private let hub = EventHub()
    private let messageExtractor = MessageExtractor()
    private let attributionFacade = AttributionFacade()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        bootstrap()
        configureDelegates()
        enablePush()
        
        if let message = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            messageExtractor.extract(from: message)
        }
        
        attributionFacade.configure(
            onAttribution: { [weak self] data in
                self?.hub.publishAttribution(data)
            },
            onDeeplink: { [weak self] data in
                self?.hub.publishDeeplink(data)
            },
            onFailure: { [weak self] in
                self?.hub.publishAttribution([:])
            }
        )
        
        observeLifecycle()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func bootstrap() {
        FirebaseApp.configure()
        Auth.auth().signInAnonymously()
    }
    
    private func configureDelegates() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func enablePush() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func observeLifecycle() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleActivation() {
        attributionFacade.start()
    }
}

extension LifecycleMediator: MessagingDelegate {
    
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, error in
            guard error == nil, let token = token else { return }
            TokenRepository.shared.persist(token)
        }
    }
}

extension LifecycleMediator: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        messageExtractor.extract(from: notification.request.content.userInfo)
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        messageExtractor.extract(from: response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        messageExtractor.extract(from: userInfo)
        completionHandler(.newData)
    }
}

final class EventHub {
    
    private var attributionBuffer: [AnyHashable: Any] = [:]
    private var deeplinkBuffer: [AnyHashable: Any] = [:]
    private var timer: Timer?
    private let transmittedKey = "trackingDataSent"
    
    func publishAttribution(_ data: [AnyHashable: Any]) {
        attributionBuffer = data
        scheduleTransmission()
        
        if !deeplinkBuffer.isEmpty {
            transmit()
        }
    }
    
    func publishDeeplink(_ data: [AnyHashable: Any]) {
        guard !wasTransmitted() else { return }
        
        deeplinkBuffer = data
        broadcast(deeplink: data)
        cancelTimer()
        
        if !attributionBuffer.isEmpty {
            transmit()
        }
    }
    
    private func scheduleTransmission() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: 10.0,
            repeats: false
        ) { [weak self] _ in
            self?.transmit()
        }
    }
    
    private func cancelTimer() {
        timer?.invalidate()
    }
    
    private func transmit() {
        var merged = attributionBuffer
        
        deeplinkBuffer.forEach { key, value in
            if merged[key] == nil {
                merged[key] = value
            }
        }
        
        broadcast(attribution: merged)
        markTransmitted()
    }
    
    private func broadcast(attribution data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func broadcast(deeplink data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
    
    private func wasTransmitted() -> Bool {
        return UserDefaults.standard.bool(forKey: transmittedKey)
    }
    
    private func markTransmitted() {
        UserDefaults.standard.set(true, forKey: transmittedKey)
    }
}

final class AttributionFacade: NSObject {
    
    private var onAttribution: (([AnyHashable: Any]) -> Void)?
    private var onDeeplink: (([AnyHashable: Any]) -> Void)?
    private var onFailure: (() -> Void)?
    
    func configure(
        onAttribution: @escaping ([AnyHashable: Any]) -> Void,
        onDeeplink: @escaping ([AnyHashable: Any]) -> Void,
        onFailure: @escaping () -> Void
    ) {
        self.onAttribution = onAttribution
        self.onDeeplink = onDeeplink
        self.onFailure = onFailure
        
        setupSDK()
    }
    
    private func setupSDK() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = Config.appsFlyerKey
        sdk.appleAppID = Config.appsFlyerId
        sdk.delegate = self
        sdk.deepLinkDelegate = self
    }
    
    func start() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

extension AttributionFacade: AppsFlyerLibDelegate {
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        onAttribution?(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        onFailure?()
    }
}

extension AttributionFacade: DeepLinkDelegate {
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let link = result.deepLink else {
            return
        }
        
        onDeeplink?(link.clickEvent)
    }
}

final class MessageExtractor {
    
    func extract(from payload: [AnyHashable: Any]) {
        guard let url = parse(payload) else {
            return
        }
        
        UserDefaults.standard.set(url, forKey: "temp_url")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NotificationCenter.default.post(
                name: Notification.Name("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func parse(_ payload: [AnyHashable: Any]) -> String? {
        // Direct
        if let url = payload["url"] as? String {
            return url
        }
        
        // Nested
        if let data = payload["data"] as? [String: Any],
           let url = data["url"] as? String {
            return url
        }
        
        return nil
    }
}

final class TokenRepository {
    
    static let shared = TokenRepository()
    
    private init() {}
    
    func persist(_ token: String) {
        let storage = UserDefaults.standard
        storage.set(token, forKey: "fcm_token")
        storage.set(token, forKey: "push_token")
    }
    
    func retrieve() -> String? {
        return UserDefaults.standard.string(forKey: "push_token")
    }
}
