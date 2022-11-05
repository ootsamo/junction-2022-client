import UIKit

struct AttractionDetail {
	let icon: UIImage?
	let description: String?
	let value: String?
}

class AttractionDetailView: UIStackView {
	private lazy var iconView = UIImageView()

	private let descriptionLabel = configure(UILabel()) {
		$0.font = .systemFont(ofSize: 18)
	}

	private let valueLabel = configure(UILabel()) {
		$0.font = .boldSystemFont(ofSize: 18)
	}

	init(attractionDetail: AttractionDetail) {
		super.init(frame: .zero)

		spacing = 8

		[iconView, descriptionLabel, valueLabel].forEach(addArrangedSubview)

		iconView.image = attractionDetail.icon
		iconView.tintColor = .label

		descriptionLabel.text = attractionDetail.description
		descriptionLabel.isHidden = attractionDetail.description == nil

		valueLabel.text = attractionDetail.value
		valueLabel.isHidden = attractionDetail.value == nil

		setupLayout()
	}

	required init(coder: NSCoder) { unsupported() }

	private func setupLayout() {
		valueLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)

		NSLayoutConstraint.activate([
			iconView.widthAnchor.constraint(equalToConstant: 32),
			iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor)
		])
	}
}
