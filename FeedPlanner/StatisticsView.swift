import SwiftUI

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Period Selector
                        HStack(spacing: 12) {
                            ForEach(StatisticsViewModel.Period.allCases, id: \.self) { period in
                                PeriodButton(
                                    title: period.rawValue,
                                    isSelected: viewModel.selectedPeriod == period
                                ) {
                                    viewModel.changePeriod(period)
                                }
                            }
                        }
                        
                        // Stats Cards
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Total Feed",
                                value: String(format: "%.1f kg", viewModel.totalFeedGiven / 1000),
                                subtitle: "This period",
                                trend: nil
                            )
                            
                            StatCard(
                                title: "Average Daily",
                                value: String(format: "%.1f kg", viewModel.averageDailyFeed / 1000),
                                subtitle: "Per day",
                                trend: nil
                            )
                        }
                        .frame(height: 120)
                        
                        // Cost Card
                        GlossyCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Total Cost")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                
                                Text("$\(String(format: "%.2f", viewModel.totalCost))")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                
                                Text("Projected monthly: $\(String(format: "%.2f", viewModel.projectedMonthCost))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        // Chart Placeholder
                        GlossyCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Consumption Trend")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                
                                Text("Chart will display consumption over time")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                    .frame(height: 150)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

struct PeriodButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? LinearGradient.primaryButton : LinearGradient(colors: [Color.white], startPoint: .top, endPoint: .bottom))
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}
