import Foundation
import Combine

class FormulaViewModel: ObservableObject {
    @Published var formulas: [FeedFormula] = []
    @Published var currentFormula: FeedFormula?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    
    // Default ingredients
    let defaultIngredients: [FeedIngredient] = [
        FeedIngredient(name: "Corn", percentage: 40, proteinContent: 8.5, energyContent: 3350),
        FeedIngredient(name: "Wheat", percentage: 30, proteinContent: 11.5, energyContent: 3100),
        FeedIngredient(name: "Soybean Meal", percentage: 20, proteinContent: 40.0, energyContent: 2500),
        FeedIngredient(name: "Limestone", percentage: 5, proteinContent: 0.0, energyContent: 0),
        FeedIngredient(name: "Protein Supplements", percentage: 5, proteinContent: 45.0, energyContent: 2200)
    ]
    
    init() {
        loadFormulas()
        setupDefaultFormula()
    }
    
    func loadFormulas() {
        isLoading = true
        
        firebaseService.fetchFormulas { [weak self] formulas in
            self?.formulas = formulas
            
            // Set active formula if exists
            if let activeFormula = formulas.first(where: { $0.isActive }) {
                self?.currentFormula = activeFormula
            }
            
            self?.isLoading = false
        }
    }
    
    private func setupDefaultFormula() {
        if currentFormula == nil {
            currentFormula = FeedFormula(
                name: "New Formula",
                ingredients: defaultIngredients
            )
        }
    }
    
    func updateIngredientPercentage(ingredientId: String, percentage: Double) {
        guard var formula = currentFormula else { return }
        
        if let index = formula.ingredients.firstIndex(where: { $0.id == ingredientId }) {
            formula.ingredients[index].percentage = percentage
            currentFormula = formula
        }
    }
    
    func saveFormula(name: String) {
        guard var formula = currentFormula else { return }
        
        formula.name = name
        
        firebaseService.saveFormula(formula) { [weak self] success in
            if success {
                self?.loadFormulas()
            } else {
                self?.errorMessage = "Failed to save formula"
            }
        }
    }
    
    func applyFormula(to flocks: [ChickenFlock]) {
        guard let formula = currentFormula else { return }
        
        // Mark formula as active
        var updatedFormula = formula
        updatedFormula.isActive = true
        
        firebaseService.saveFormula(updatedFormula) { [weak self] success in
            if success {
                // Deactivate other formulas
                for oldFormula in self?.formulas ?? [] where oldFormula.id != formula.id {
                    var deactivated = oldFormula
                    deactivated.isActive = false
                    self?.firebaseService.saveFormula(deactivated) { _ in }
                }
                
                self?.loadFormulas()
            }
        }
    }
    
    func deleteFormula(_ formula: FeedFormula) {
        firebaseService.deleteFormula(formula.id) { [weak self] success in
            if success {
                self?.loadFormulas()
            } else {
                self?.errorMessage = "Failed to delete formula"
            }
        }
    }
    
    func resetToDefault() {
        currentFormula = FeedFormula(
            name: "New Formula",
            ingredients: defaultIngredients
        )
    }
}
