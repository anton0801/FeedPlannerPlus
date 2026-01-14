import SwiftUI

struct ScheduleView: View {
    @StateObject private var viewModel = ScheduleViewModel()
    @State private var showAddSchedule = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Notification Permission Card
                        if !viewModel.notificationsEnabled {
                            GlossyCard {
                                VStack(spacing: 12) {
                                    Image(systemName: "bell.slash.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.warning)
                                    
                                    Text("Enable Notifications")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("Get reminders for feeding times")
                                        .font(.system(size: 14))
                                        .foregroundColor(.textSecondary)
                                        .multilineTextAlignment(.center)
                                    
                                    GlossyButton(title: "Enable", icon: "bell.fill", style: .compact) {
                                        viewModel.requestNotificationPermission()
                                    }
                                }
                                .padding()
                            }
                        }
                        
                        // Schedules List
                        if viewModel.schedules.isEmpty {
                            GlossyCard {
                                VStack(spacing: 12) {
                                    Image(systemName: "clock.circle")
                                        .font(.system(size: 50))
                                        .foregroundColor(.textSecondary.opacity(0.5))
                                    
                                    Text("No Schedules")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.vertical, 20)
                            }
                        } else {
                            ForEach(viewModel.schedules) { schedule in
                                ScheduleCard(schedule: schedule, viewModel: viewModel)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSchedule = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentPrimary)
                    }
                }
            }
        }
    }
}

struct ScheduleCard: View {
    let schedule: FeedingSchedule
    @ObservedObject var viewModel: ScheduleViewModel
    
    var body: some View {
        GlossyCard(padding: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(timeFormatter.string(from: schedule.time))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("\(String(format: "%.1f", schedule.amount)) kg")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { schedule.isEnabled },
                    set: { _ in viewModel.toggleSchedule(schedule) }
                ))
                .labelsHidden()
                .tint(.accentPrimary)
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}
