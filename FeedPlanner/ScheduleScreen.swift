import SwiftUI

struct ScheduleScreen: View {
    @EnvironmentObject var data: FeedData
    @State private var showingAddFeeding = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Main Feedings") {
                    TimeRow(title: "Morning",   icon: "sunrise.fill", time: $data.morning)
                    TimeRow(title: "Noon",      icon: "sun.max.fill", time: $data.noon)
                    TimeRow(title: "Evening",   icon: "sunset.fill",  time: $data.evening)
                }
                
                Section("Settings") {
                    Toggle("Notifications", isOn: $data.notificationsOn)
                    Toggle("Vibration", isOn: $data.vibrationOn)
                }
                
                Section("Custom Feedings") {
                    ForEach(data.customFeedings, id: \.self) { date in
                        HStack {
                            Image(systemName: "bell.fill")
                            Text(date, style: .time)
                            Spacer()
                            Button("Delete") {
                                data.customFeedings.removeAll { $0 == date }
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Schedule")
            .toolbar {
                Button("Add") {
                    showingAddFeeding = true
                }
            }
            .sheet(isPresented: $showingAddFeeding) {
                AddFeedingView()
                    .environmentObject(data)
            }
        }
    }
}

struct TimeRow: View {
    let title: String
    let icon: String
    @Binding var time: Date
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.icon)
            Text(title)
            Spacer()
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
    }
}

struct AddFeedingView: View {
    @EnvironmentObject var data: FeedData
    @Environment(\.dismiss) var dismiss
    @State private var selectedTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
            }
            .navigationTitle("New Feeding")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        data.customFeedings.append(selectedTime)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ScheduleScreen()
        .environmentObject(FeedData())
}
