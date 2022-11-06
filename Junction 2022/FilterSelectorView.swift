import UIKit

class FilterSelectorView<T: Equatable>: UIView {
	private let tiles: [(key: T, view: FilterTileView)]
	private let innerView = configure(UIStackView()) {
		$0.axis = .vertical
	}

	private var isActive = false
	private var selectedTileKey: T

	private lazy var topConstraint = innerView.topAnchor.constraint(equalTo: topAnchor)
	private lazy var heightConstraint = heightAnchor.constraint(equalToConstant: tiles.first?.view.size.height ?? 0)

	var onSelect: ((T) -> Void)?

	init(tiles: [(key: T, view: FilterTileView)]) {
		guard let firstTile = tiles.first else {
			fatalError("Can't create a FilterSelectorView with no tiles")
		}

		self.tiles = tiles
		self.selectedTileKey = firstTile.key

		super.init(frame: .zero)

		tiles.map(\.view).forEach(innerView.addArrangedSubview)

		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		addGestureRecognizer(tapRecognizer)

		setupView()
		setupLayout()
	}

	required init?(coder: NSCoder) { unsupported() }

	private func setupView() {
		backgroundColor = .systemBackground
		layer.masksToBounds = true
		layer.cornerRadius = 8
		layer.borderWidth = 1
		layer.borderColor = UIColor.label.cgColor
	}

	private func setupLayout() {
		innerView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(innerView)

		NSLayoutConstraint.activate([
			innerView.leadingAnchor.constraint(equalTo: leadingAnchor),
			innerView.trailingAnchor.constraint(equalTo: trailingAnchor),
			topConstraint,
			heightConstraint
		])
	}

	@objc
	private func handleTap(recognizer: UITapGestureRecognizer) {
		if isActive {
			let location = recognizer.location(in: recognizer.view)
			guard let tile = tiles.first(where: { $0.view.frame.contains(location) }) else { return }
			selectedTileKey = tile.key
			onSelect?(tile.key)
		}
		setActive(!isActive, animated: true)
	}

	func setActive(_ active: Bool, animated: Bool) {
		if active {
			heightConstraint.constant = tiles.reduce(into: 0, { $0 += $1.view.size.height })
			topConstraint.constant = 0
		} else {
			guard let selectedTile = tiles.first(where: { $0.key == selectedTileKey }) else { return }
			heightConstraint.constant = selectedTile.view.size.height
			topConstraint.constant = -selectedTile.view.frame.minY
		}
		isActive = active
		if animated {
			UIView.animate(withDuration: 0.2, delay: 0) {
				self.superview?.layoutIfNeeded()
			}
		}
	}
}

class FilterTileView: UIView {
	let size = CGSize(width: 72, height: 72)

	private let contentView: UIView

	init(title: String) {
		contentView = configure(UILabel()) {
			$0.font = .boldSystemFont(ofSize: 18)
			$0.textAlignment = .center
			$0.text = title
		}

		super.init(frame: .zero)

		setupLayout()
	}

	init(image: UIImage) {
		contentView = configure(UIImageView()) {
			$0.image = image
			$0.contentMode = .scaleToFill
		}

		super.init(frame: .zero)

		setupLayout()
	}

	private func setupLayout() {
		contentView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(contentView)

		NSLayoutConstraint.activate([
			heightAnchor.constraint(equalToConstant: size.height),
			widthAnchor.constraint(equalToConstant: size.width),

			contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
			contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
			contentView.topAnchor.constraint(equalTo: topAnchor),
			contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
	}

	required init?(coder: NSCoder) { unsupported() }
}
