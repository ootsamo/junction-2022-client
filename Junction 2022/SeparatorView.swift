import UIKit

class SeparatorView: UIView {
	public enum Orientation {
		case horizontal, vertical
	}

	public init(orientation: Orientation) {
		super.init(frame: .zero)

		backgroundColor = .separator

		let anchor = orientation == .horizontal ? heightAnchor : widthAnchor
		anchor.constraint(equalToConstant: 1).isActive = true
	}

	required init?(coder: NSCoder) { unsupported() }
}
