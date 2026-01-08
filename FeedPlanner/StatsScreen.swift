import SwiftUI

struct StatsScreen: View {
    @EnvironmentObject var data: FeedData
    
    var totalDaily: Double { Double(data.chickenCount) * data.feedPerChicken }
    var weekTotal: Double { data.history.suffix(7).reduce(0, +) }
    var monthTotal: Double { data.history.reduce(0, +) }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Круговая диаграмма рациона
                    PieChartView(values: [data.cornP, data.wheatP, data.mixP, data.chalkP, data.proteinP],
                                 colors: [.gold, .yellowBtn, .orangeBtn, Color.gray, .good])
                        .frame(height: 220)
                        .padding()
                    
                    // Линейный график расхода за 30 дней
                    VStack(alignment: .leading) {
                        Text("Feed Consumption (kg)").font(.headline)
                        SimpleBarChart(data: data.history)
                            .frame(height: 200)
                    }
                    .padding()
                    .background(Color.card)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Карточки с цифрами
                    HStack(spacing: 16) {
                        StatCard(title: "Week", value: "\(weekTotal.formate(digits: 1)) kg", color: .yellowBtn)
                        StatCard(title: "Month", value: "\(monthTotal.formate(digits: 1)) kg", color: .orangeBtn)
                        StatCard(title: "Cost (est.)", value: "£\((monthTotal * 0.4).formate(digits: 0))", color: .good)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Statistics")
        }
    }
}

// Простая круговая диаграмма
struct PieChartView: View {
    let values: [Double]
    let colors: [Color]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<values.count, id: \.self) { i in
                    let start = values.prefix(i).reduce(0, +) / 100 * 360
                    let end = values.prefix(i+1).reduce(0, +) / 100 * 360
                    PieSlice(startAngle: .degrees(start-90), endAngle: .degrees(end-90))
                        .fill(colors[i])
                }
                Circle()
                    .fill(Color.bg)
                    .frame(width: geo.size.width * 0.45)
            }
        }
    }
}

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        p.move(to: center)
        p.addArc(center: center, radius: rect.width/2, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return p
    }
}

// Простой столбчатый график
struct SimpleBarChart: View {
    let data: [Double]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(data, id: \.self) { value in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orangeBtn)
                    .frame(width: 8, height: CGFloat(value) * 15)
            }
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(title).font(.caption).foregroundColor(.textSec)
            Text(value).font(.title2.bold())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color, lineWidth: 2))
    }
}

#Preview {
    StatsScreen()
}
