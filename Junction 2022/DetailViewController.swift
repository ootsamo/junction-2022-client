import UIKit

class DetailViewController: UIViewController {
	enum State {
		case nothingSelected
		case loading
		case loaded
	}

	private lazy var rootStackView = configure(UIStackView()) {
		$0.axis = .vertical
	}

	private lazy var mainStackView = configure(UIStackView()) {
		$0.axis = .vertical
		$0.spacing = 16
		let subviews = [
			headlineStackView,
			attractionDetailsStackView,
			SeparatorView(orientation: .horizontal),
			scoreDetailsStackView,
			totalScoreStackView
		]
		subviews.forEach($0.addArrangedSubview)
	}

	private lazy var headlineStackView = configure(UIStackView()) {
		$0.axis = .vertical
		$0.spacing = 4
		[headlineLabel, subheadlineLabel].forEach($0.addArrangedSubview)
	}

	private let headlineLabel = configure(UILabel()) {
		$0.font = .preferredFont(forTextStyle: .headline)
		$0.setContentCompressionResistancePriority(.required, for: .vertical)
	}

	private let subheadlineLabel = configure(UILabel()) {
		$0.font = .preferredFont(forTextStyle: .caption1)
		$0.setContentCompressionResistancePriority(.required, for: .vertical)
	}

	private lazy var totalScoreStackView = configure(UIStackView()) {
		$0.spacing = 16
		[equalsLabel, scoreLabel].forEach($0.addArrangedSubview)
	}

	private let equalsLabel = configure(UILabel()) {
		$0.font = .boldSystemFont(ofSize: 20)
		$0.text = "TOTAL\nSCORE"
		$0.numberOfLines = 0
	}

	private let scoreLabel = configure(UILabel()) {
		$0.font = .systemFont(ofSize: 64, weight: .black)
		$0.textAlignment = .right
		$0.adjustsFontSizeToFitWidth = true
	}

	private let scoreDetailsStackView = configure(UIStackView()) {
		$0.axis = .horizontal
		$0.distribution = .equalSpacing
		$0.spacing = 4
	}

	private let attractionDetailsStackView = configure(UIStackView()) {
		$0.axis = .vertical
		$0.spacing = 4
	}

	var state: State = .nothingSelected {
		didSet {
			guard oldValue != state else { return }
			let temporaryHeightConstraint = view.heightAnchor.constraint(equalToConstant: view.bounds.height)
			temporaryHeightConstraint.isActive = true
			refreshState()
			view.layoutIfNeeded()
			temporaryHeightConstraint.isActive = false
			UIView.animate(withDuration: 0.2, delay: 0) {
				self.view.superview?.layoutIfNeeded()
			}
		}
	}

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nil, bundle: nil)
		refreshState()
	}

	required init?(coder: NSCoder) { unsupported() }

	var headline: String? {
		get { headlineLabel.text }
		set { headlineLabel.text = newValue }
	}

	var subheadline: String? {
		get { subheadlineLabel.text }
		set {
			subheadlineLabel.text = newValue
			subheadlineLabel.isHidden = newValue == nil
		}
	}

	func setScoreDetails(_ details: [ScoreDetail]) {
		scoreDetailsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
		details
			.map(ScoreDetailView.init)
			.forEach(scoreDetailsStackView.addArrangedSubview)
		scoreLabel.text = String(details.map(\.value).reduce(0, +))
	}

	func setAttractionDetails(_ details: [AttractionDetail]) {
		attractionDetailsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
		details
			.map(AttractionDetailView.init)
			.forEach(attractionDetailsStackView.addArrangedSubview)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		setupView()
		setupLayout()
	}

	private func setupView() {
		view.backgroundColor = .systemBackground
		view.layer.masksToBounds = true
		view.layer.cornerRadius = 20
	}

	private func setupLayout() {
		view.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

		rootStackView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(rootStackView)

		NSLayoutConstraint.activate([
			rootStackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
			rootStackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
			rootStackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
			rootStackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).withPriority(.defaultHigh)
		])
	}

	private func refreshState() {
		rootStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
		switch state {
		case .nothingSelected:
			let nothingSelectedLabel = configure(UILabel()) {
				$0.text = "Long press on the map to select a location"
				$0.textAlignment = .center
				$0.numberOfLines = 0
			}
			rootStackView.addArrangedSubview(nothingSelectedLabel)
		case .loading:
			let loadingIndicator = UIActivityIndicatorView(style: .large)
			loadingIndicator.startAnimating()
			rootStackView.addArrangedSubview(loadingIndicator)
		case .loaded:
			rootStackView.addArrangedSubview(mainStackView)
		}
	}
}
