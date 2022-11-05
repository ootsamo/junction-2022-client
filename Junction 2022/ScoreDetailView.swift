import UIKit

struct ScoreDetail {
	let icon: UIImage?
	let value: Int
}

class ScoreDetailView: UIStackView {
	private lazy var iconView = UIImageView()

	private let valueLabel = configure(UILabel()) {
		$0.font = .systemFont(ofSize: 18)
	}

	init(scoreDetail: ScoreDetail) {
		super.init(frame: .zero)

		alignment = .center
		axis = .vertical
		spacing = 8

		[iconView, valueLabel].forEach(addArrangedSubview)

		iconView.image = scoreDetail.icon
		iconView.tintColor = .label

		valueLabel.text = String(scoreDetail.value)

		setupLayout()
	}

	required init(coder: NSCoder) { unsupported() }

	private func setupLayout() {
		valueLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)

		NSLayoutConstraint.activate([
			iconView.widthAnchor.constraint(equalToConstant: 52),
			iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor)
		])
	}
}
