import SwiftUI

struct FormulaView: View {
    @StateObject private var viewModel = FormulaViewModel()
    @State private var showSaveSheet = false
    @State private var formulaName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if let formula = viewModel.currentFormula {
                            BalanceStatusCard(status: formula.balanceStatus)
                            
                            ForEach(formula.ingredients) { ingredient in
                                IngredientCard(
                                    ingredient: ingredient,
                                    onPercentageChange: { newValue in
                                        viewModel.updateIngredientPercentage(ingredientId: ingredient.id, percentage: newValue)
                                    }
                                )
                            }
                        }
                        
                        VStack(spacing: 12) {
                            GlossyButton(title: "Save Formula", icon: "square.and.arrow.down") {
                                showSaveSheet = true
                            }
                            
                            GlossyButton(title: "Apply to Flock", icon: "checkmark.circle", style: .secondary) {
                                viewModel.applyFormula(to: [])
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Feed Formula")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.resetToDefault() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.accentSecondary)
                    }
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                SaveFormulaSheet(formulaName: $formulaName) {
                    viewModel.saveFormula(name: formulaName)
                    showSaveSheet = false
                }
            }
        }
    }
}

struct BalanceStatusCard: View {
    let status: FeedFormula.BalanceStatus
    
    var body: some View {
        GlossyCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(status.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 24))
                        .foregroundColor(status.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Balance Status")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Text(status.message)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(status.color)
                }
                
                Spacer()
            }
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .balanced: return "checkmark.seal.fill"
        case .acceptable: return "checkmark.circle.fill"
        case .lowProtein, .lowEnergy: return "exclamationmark.triangle.fill"
        case .incomplete: return "xmark.circle.fill"
        }
    }
}

struct IngredientCard: View {
    let ingredient: FeedIngredient
    let onPercentageChange: (Double) -> Void
    
    var body: some View {
        GlossyCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(ingredient.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(ingredient.percentage))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.accentPrimary)
                }
                
                Slider(value: Binding(
                    get: { ingredient.percentage },
                    set: { onPercentageChange($0) }
                ), in: 0...100)
                .accentColor(.accentPrimary)
                
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.accentSecondary)
                        Text("Protein: \(String(format: "%.1f", ingredient.proteinContent))%")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.golden)
                        Text("Energy: \(Int(ingredient.energyContent)) kcal")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }
}

struct SaveFormulaSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var formulaName: String
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    CustomTextField(
                        title: "Formula Name",
                        text: $formulaName,
                        placeholder: "My Formula"
                    )
                    .padding(.horizontal)
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    GlossyButton(title: "Save", icon: "checkmark") {
                        onSave()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Save Formula")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }
}
