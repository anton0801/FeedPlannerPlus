import Foundation
import Firebase
import FirebaseDatabase
import Combine
import FirebaseAuth

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let database = Database.database().reference()
    private var userId: String = ""
    
    @Published var isAuthenticated = false
    
    init() {
        userId = Auth.auth().currentUser?.uid ?? ""
        if userId.isEmpty {
            authenticateAnonymously()
        }
    }
    
    // MARK: - Authentication
    func authenticateAnonymously() {
        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error {
                print("Firebase Auth Error: \(error.localizedDescription)")
                return
            }
            
            if let userId = result?.user.uid {
                self?.userId = userId
                self?.isAuthenticated = true
                print("Authenticated with userId: \(userId)")
            }
        }
    }
    
    private func userRef() -> DatabaseReference {
        return database.child("users").child(userId)
    }
    
    // MARK: - Flock Operations
    func saveFlock(_ flock: ChickenFlock, completion: @escaping (Bool) -> Void) {
        guard !userId.isEmpty else {
            completion(false)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(flock)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            userRef().child("flocks").child(flock.id).setValue(dict) { error, _ in
                completion(error == nil)
            }
        } catch {
            print("Encoding error: \(error)")
            completion(false)
        }
    }
    
    func fetchFlocks(completion: @escaping ([ChickenFlock]) -> Void) {
        guard !userId.isEmpty else {
            completion([])
            return
        }
        
        userRef().child("flocks").observeSingleEvent(of: .value) { snapshot in
            var flocks: [ChickenFlock] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                   let flock = try? JSONDecoder().decode(ChickenFlock.self, from: jsonData) {
                    flocks.append(flock)
                }
            }
            
            completion(flocks)
        }
    }
    
    func deleteFlock(_ flockId: String, completion: @escaping (Bool) -> Void) {
        userRef().child("flocks").child(flockId).removeValue { error, _ in
            completion(error == nil)
        }
    }
    
    // MARK: - Feed Record Operations
    func saveFeedRecord(_ record: FeedRecord, completion: @escaping (Bool) -> Void) {
        guard !userId.isEmpty else {
            completion(false)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(record)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            userRef().child("feedRecords").child(record.id).setValue(dict) { error, _ in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func fetchFeedRecords(for flockId: String, completion: @escaping ([FeedRecord]) -> Void) {
        guard !userId.isEmpty else {
            completion([])
            return
        }
        
        userRef().child("feedRecords")
            .queryOrdered(byChild: "flockId")
            .queryEqual(toValue: flockId)
            .observeSingleEvent(of: .value) { snapshot in
                var records: [FeedRecord] = []
                
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let dict = snapshot.value as? [String: Any],
                       let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                       let record = try? JSONDecoder().decode(FeedRecord.self, from: jsonData) {
                        records.append(record)
                    }
                }
                
                completion(records.sorted { $0.date > $1.date })
            }
    }
    
    // MARK: - Formula Operations
    func saveFormula(_ formula: FeedFormula, completion: @escaping (Bool) -> Void) {
        guard !userId.isEmpty else {
            completion(false)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(formula)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            userRef().child("formulas").child(formula.id).setValue(dict) { error, _ in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func fetchFormulas(completion: @escaping ([FeedFormula]) -> Void) {
        guard !userId.isEmpty else {
            completion([])
            return
        }
        
        userRef().child("formulas").observeSingleEvent(of: .value) { snapshot in
            var formulas: [FeedFormula] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                   let formula = try? JSONDecoder().decode(FeedFormula.self, from: jsonData) {
                    formulas.append(formula)
                }
            }
            
            completion(formulas)
        }
    }
    
    func deleteFormula(_ formulaId: String, completion: @escaping (Bool) -> Void) {
        userRef().child("formulas").child(formulaId).removeValue { error, _ in
            completion(error == nil)
        }
    }
    
    // MARK: - Schedule Operations
    func saveSchedule(_ schedule: FeedingSchedule, completion: @escaping (Bool) -> Void) {
        guard !userId.isEmpty else {
            completion(false)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(schedule)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            userRef().child("schedules").child(schedule.id).setValue(dict) { error, _ in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func fetchSchedules(completion: @escaping ([FeedingSchedule]) -> Void) {
        guard !userId.isEmpty else {
            completion([])
            return
        }
        
        userRef().child("schedules").observeSingleEvent(of: .value) { snapshot in
            var schedules: [FeedingSchedule] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                   let schedule = try? JSONDecoder().decode(FeedingSchedule.self, from: jsonData) {
                    schedules.append(schedule)
                }
            }
            
            completion(schedules.sorted { $0.time < $1.time })
        }
    }
    
    // MARK: - Inventory Operations
    func saveInventoryItem(_ item: InventoryItem, completion: @escaping (Bool) -> Void) {
        guard !userId.isEmpty else {
            completion(false)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(item)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            userRef().child("inventory").child(item.id).setValue(dict) { error, _ in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func fetchInventory(completion: @escaping ([InventoryItem]) -> Void) {
        guard !userId.isEmpty else {
            completion([])
            return
        }
        
        userRef().child("inventory").observeSingleEvent(of: .value) { snapshot in
            var items: [InventoryItem] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                   let item = try? JSONDecoder().decode(InventoryItem.self, from: jsonData) {
                    items.append(item)
                }
            }
            
            completion(items)
        }
    }
    
    func deleteInventoryItem(_ itemId: String, completion: @escaping (Bool) -> Void) {
        userRef().child("inventory").child(itemId).removeValue { error, _ in
            completion(error == nil)
        }
    }
}
