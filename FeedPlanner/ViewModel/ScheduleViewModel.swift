import Foundation
import Combine
import UserNotifications

class ScheduleViewModel: ObservableObject {
    @Published var schedules: [FeedingSchedule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var notificationsEnabled = false
    
    private let firebaseService = FirebaseService.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        checkNotificationPermission()
        loadSchedules()
    }
    
    func loadSchedules() {
        isLoading = true
        
        firebaseService.fetchSchedules { [weak self] schedules in
            self?.schedules = schedules
            self?.isLoading = false
        }
    }
    
    func checkNotificationPermission() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.notificationsEnabled = granted
                
                if !granted {
                    self?.errorMessage = "Notification permission denied"
                }
            }
        }
    }
    
    func addSchedule(time: Date, amount: Double) {
        let schedule = FeedingSchedule(time: time, amount: amount)
        
        firebaseService.saveSchedule(schedule) { [weak self] success in
            if success {
                self?.scheduleNotification(for: schedule)
                self?.loadSchedules()
            } else {
                self?.errorMessage = "Failed to save schedule"
            }
        }
    }
    
    func updateSchedule(_ schedule: FeedingSchedule) {
        // Cancel old notification
        if let notificationId = schedule.notificationId {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
        
        firebaseService.saveSchedule(schedule) { [weak self] success in
            if success {
                if schedule.isEnabled {
                    self?.scheduleNotification(for: schedule)
                }
                self?.loadSchedules()
            } else {
                self?.errorMessage = "Failed to update schedule"
            }
        }
    }
    
    func toggleSchedule(_ schedule: FeedingSchedule) {
        var updatedSchedule = schedule
        updatedSchedule.isEnabled.toggle()
        updateSchedule(updatedSchedule)
    }
    
    func deleteSchedule(_ schedule: FeedingSchedule) {
        // Cancel notification
        if let notificationId = schedule.notificationId {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
        
        firebaseService.saveSchedule(schedule) { [weak self] success in
            if success {
                self?.loadSchedules()
            }
        }
    }
    
    private func scheduleNotification(for schedule: FeedingSchedule) {
        guard notificationsEnabled, schedule.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Feeding Time!"
        content.body = "Time to feed the chickens. Amount: \(String(format: "%.1f", schedule.amount)) kg"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: schedule.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let notificationId = schedule.notificationId ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                print("Notification error: \(error)")
                self?.errorMessage = "Failed to schedule notification"
            } else {
                // Update schedule with notification ID
                var updatedSchedule = schedule
                updatedSchedule.notificationId = notificationId
                self?.firebaseService.saveSchedule(updatedSchedule) { _ in }
            }
        }
    }
    
    func getTodaySchedules() -> [FeedingSchedule] {
        schedules.filter { $0.isEnabled }
            .sorted { $0.time < $1.time }
    }
}
