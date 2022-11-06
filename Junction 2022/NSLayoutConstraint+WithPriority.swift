import UIKit

public extension NSLayoutConstraint {
	func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
		let constraint = NSLayoutConstraint(
			item: firstItem as Any,
			attribute: firstAttribute,
			relatedBy: relation,
			toItem: secondItem,
			attribute: secondAttribute,
			multiplier: multiplier,
			constant: constant
		)

		constraint.priority = priority
		return constraint
	}
}
