import Foundation
import SwiftUI

extension Double {
    func formate(digits: Int) -> String {
        return String(format: "%.\(digits)f", self)
    }
}
