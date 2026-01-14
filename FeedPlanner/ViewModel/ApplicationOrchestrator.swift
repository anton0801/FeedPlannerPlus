import Foundation
import Combine
import Network
import UIKit
import UserNotifications
import AppsFlyerLib
import Firebase
import FirebaseDatabase
import FirebaseAuth

@MainActor
final class ApplicationOrchestrator: ObservableObject {
    
    @Published private(set) var viewState: ViewState = .initializing
    @Published private(set) var activeEndpoint: String?
    @Published private(set) var showAuthPrompt = false
    
    private let stateActor = StateActor()
    private let commandBus = CommandBus()
    private let queryBus = QueryBus()
    private let repository: Repository
    private let networkMonitor = NetworkMonitor()
    
    private var cancellables = Set<AnyCancellable>()
    private var timeoutTask: Task<Void, Never>?
    
    init(repository: Repository = RepositoryImplementation()) {
        self.repository = repository
        
        setupMonitoring()
        bootstrap()
    }
    
    func receive(attributionData: [String: Any]) {
        Task {
            await process(attributionData)
        }
    }
    
    func receive(deeplinkData: [String: Any]) {
        Task {
            await process(deeplink: deeplinkData)
        }
    }
    
    func dismissAuthPrompt() {
        repository.recordAuthDismissal(Date())
        showAuthPrompt = false
        finalizeActivation()
    }
    
    func acceptAuthPrompt() {
        requestAuthorization { [weak self] granted in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.repository.saveAuthStatus(granted: granted, denied: !granted)
                
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                self.showAuthPrompt = false
                self.finalizeActivation()
            }
        }
    }
    
    private func setupMonitoring() {
        networkMonitor.onChange = { [weak self] isConnected in
            Task { @MainActor in
                self?.handleConnectivity(isConnected)
            }
        }
        networkMonitor.start()
    }
    
    private func bootstrap() {
        Task {
            let command = InitializeCommand(stateActor: stateActor)
            try? await commandBus.execute(command)
            
            scheduleTimeout()
            observePhaseChanges()
        }
    }
    
    private func observePhaseChanges() {
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    guard let self = self else { return }
                    let phase = await self.stateActor.getPhase()
                    await self.updateViewState(for: phase)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateViewState(for phase: ApplicationPhase) async {
        switch phase {
        case .launching, .configuring, .validating:
            viewState = .initializing
            
        case .active(let endpoint):
            activeEndpoint = endpoint
            viewState = .operational
            
        case .standby:
            viewState = .idle
            
        case .unavailable:
            viewState = .offline
        }
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            let query = CheckDataQuery(repository: repository)
            if let hasData = try? await queryBus.fetch(query), !hasData {
                await stateActor.transition(to: .standby, reason: "Timeout")
            }
        }
    }
    
    private func process(_ data: [String: Any]) async {
        repository.storeAttribution(data)
        
        let validator = FirebaseAccessValidator()
        let command = ValidateAccessCommand(
            stateActor: stateActor,
            validator: validator
        )
        
        do {
            try await commandBus.execute(command)
            await continueProcessing()
        } catch {
            await stateActor.transition(to: .standby, reason: "Validation failed")
        }
    }
    
    private func process(deeplink data: [String: Any]) async {
        repository.storeDeeplink(data)
    }
    
    private func continueProcessing() async {
        guard !repository.getAttribution().isEmpty else {
            loadCached()
            return
        }
        
        if repository.getMode() == "Inactive" {
            await stateActor.transition(to: .standby, reason: "Inactive mode")
            return
        }
        
        if shouldExecuteFirstLaunch() {
            await executeFirstLaunch()
            return
        }
        
        if let temp = retrieveTemporary() {
            activateWith(endpoint: temp)
            return
        }
        
        await resolveEndpoint()
    }
    
    private func shouldExecuteFirstLaunch() -> Bool {
        return repository.isFirstLaunch() &&
               repository.getAttribution()["af_status"] as? String == "Organic"
    }
    
    private func executeFirstLaunch() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        let query = FetchOrganicDataQuery(
            repository: repository,
            connector: HTTPConnector()
        )
        
        if let combined = try? await queryBus.fetch(query) {
            repository.storeAttribution(combined)
            await resolveEndpoint()
        } else {
            await stateActor.transition(to: .standby)
        }
    }
    
    private func retrieveTemporary() -> String? {
        return UserDefaults.standard.string(forKey: "temp_url")
    }
    
    private func resolveEndpoint() async {
        let query = ResolveEndpointQuery(
            repository: repository,
            connector: HTTPConnector()
        )
        
        do {
            let endpoint = try await queryBus.fetch(query)
            repository.cacheEndpoint(endpoint)
            repository.setMode("Active")
            repository.markLaunchCompleted()
            
            activateWith(endpoint: endpoint)
        } catch {
            loadCached()
        }
    }
    
    private func loadCached() {
        if let cached = repository.getCachedEndpoint() {
            activateWith(endpoint: cached)
        } else {
            Task {
                await stateActor.transition(to: .standby)
            }
        }
    }
    
    private func activateWith(endpoint: String) {
        Task {
            let command = ActivateCommand(
                stateActor: stateActor,
                endpoint: endpoint
            )
            try? await commandBus.execute(command)
            
            if shouldPromptAuth() {
                showAuthPrompt = true
            }
        }
    }
    
    private func shouldPromptAuth() -> Bool {
        if repository.wasAuthGranted() || repository.wasAuthDenied() {
            return false
        }
        
        if let lastRequest = repository.getLastAuthRequest(),
           Date().timeIntervalSince(lastRequest) < 259200 {
            return false
        }
        
        return true
    }
    
    private func finalizeActivation() {
        guard let endpoint = activeEndpoint else { return }
        
        Task {
            let command = ActivateCommand(
                stateActor: stateActor,
                endpoint: endpoint
            )
            try? await commandBus.execute(command)
        }
    }
    
    private func handleConnectivity(_ isConnected: Bool) {
        Task {
            if !isConnected {
                await stateActor.transition(to: .unavailable, reason: "No network")
            } else {
                let current = await stateActor.getPhase()
                if case .unavailable = current {
                    await stateActor.transition(to: .standby, reason: "Network restored")
                }
            }
        }
    }
    
    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            completion(granted)
        }
    }
}

final class CommandBus {
    
    func execute(_ command: Command) async throws {
        try await command.execute()
    }
}

final class QueryBus {
    
    func fetch<Q: Query>(_ query: Q) async throws -> Q.Result {
        return try await query.fetch()
    }
}

enum ViewState {
    case initializing
    case operational
    case idle
    case offline
}

final class NetworkMonitor {
    
    private let monitor = NWPathMonitor()
    var onChange: ((Bool) -> Void)?
    
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            self?.onChange?(isConnected)
        }
        monitor.start(queue: .global(qos: .background))
    }
    
    func stop() {
        monitor.cancel()
    }
}

struct CheckDataQuery: Query {
    let repository: Repository
    
    func fetch() async throws -> Bool {
        return !repository.getAttribution().isEmpty
    }
}

struct FetchOrganicDataQuery: Query {
    let repository: Repository
    let connector: HTTPConnector
    
    func fetch() async throws -> [String: Any] {
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        let attribution = try await connector.fetchAttribution(deviceID: deviceID)
        
        var combined = attribution
        let deeplink = repository.getDeeplink()
        deeplink.forEach { key, value in
            if combined[key] == nil {
                combined[key] = value
            }
        }
        
        return combined
    }
}

struct ResolveEndpointQuery: Query {
    let repository: Repository
    let connector: HTTPConnector
    
    func fetch() async throws -> String {
        let attribution = repository.getAttribution()
        return try await connector.resolveEndpoint(attributionData: attribution)
    }
}


enum ApplicationPhase: Equatable {
    case launching
    case configuring
    case validating
    case active(String)
    case standby
    case unavailable
}

struct PhaseTransition {
    let from: ApplicationPhase
    let to: ApplicationPhase
    let triggeredAt: Date
    let reason: String?
    
    init(from: ApplicationPhase, to: ApplicationPhase, reason: String? = nil) {
        self.from = from
        self.to = to
        self.triggeredAt = Date()
        self.reason = reason
    }
}

actor StateActor {
    
    private(set) var currentPhase: ApplicationPhase = .launching
    private(set) var history: [PhaseTransition] = []
    
    func transition(to newPhase: ApplicationPhase, reason: String? = nil) async {
        let transition = PhaseTransition(
            from: currentPhase,
            to: newPhase,
            reason: reason
        )
        
        history.append(transition)
        currentPhase = newPhase
        
        await notifyObservers(newPhase)
    }
    
    func getPhase() -> ApplicationPhase {
        return currentPhase
    }
    
    func getHistory() -> [PhaseTransition] {
        return history
    }
    
    private func notifyObservers(_ phase: ApplicationPhase) async {
        // Observers will be notified through Combine
    }
}

protocol Command {
    func execute() async throws
}

protocol Query {
    associatedtype Result
    func fetch() async throws -> Result
}

struct InitializeCommand: Command {
    let stateActor: StateActor
    
    func execute() async throws {
        await stateActor.transition(to: .configuring, reason: "App launched")
    }
}

struct ValidateAccessCommand: Command {
    let stateActor: StateActor
    let validator: AccessValidator
    
    func execute() async throws {
        let hasAccess = try await validator.validate()
        
        if hasAccess {
            await stateActor.transition(to: .validating, reason: "Access granted")
        } else {
            await stateActor.transition(to: .standby, reason: "Access denied")
            throw AccessDeni.deniError("Access denied")
        }
    }
}

enum AccessDeni: Error {
    case deniError(String)
}

struct ActivateCommand: Command {
    let stateActor: StateActor
    let endpoint: String
    
    func execute() async throws {
        await stateActor.transition(to: .active(endpoint), reason: "Endpoint resolved")
    }
}

protocol AccessValidator {
    func validate() async throws -> Bool
}

final class FirebaseAccessValidator: AccessValidator {
    
    private let path = "users/log/data"
    
    func validate() async throws -> Bool {
        return try await FirebaseGateway.shared.checkAccess(at: path)
    }
}

actor FirebaseGateway {
    
    static let shared = FirebaseGateway()
    
    private init() {}
    
    func checkAccess(at path: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            Database.database().reference().child(path)
                .observeSingleEvent(of: .value) { snapshot in
                    if let url = snapshot.value as? String,
                       !url.isEmpty,
                       URL(string: url) != nil {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    func retrieveURL(at path: String) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            Database.database().reference().child(path)
                .observeSingleEvent(of: .value) { snapshot in
                    continuation.resume(returning: snapshot.value as? String)
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
}
