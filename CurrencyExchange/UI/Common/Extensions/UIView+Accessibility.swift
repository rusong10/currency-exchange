import UIKit

extension UIView {
    func setupAccessibility(label: String, hint: String? = nil, traits: UIAccessibilityTraits = .none) {
        isAccessibilityElement = true
        accessibilityLabel = label
        accessibilityHint = hint
        accessibilityTraits = traits
    }
}
