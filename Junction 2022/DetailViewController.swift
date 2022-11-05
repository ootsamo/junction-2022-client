import UIKit

class DetailViewController: UIViewController {
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
	}

	private let subheadlineLabel = configure(UILabel()) {
		$0.font = .preferredFont(forTextStyle: .caption1)
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
		$0.textAlignment = .center
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

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nil, bundle: nil)
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

		mainStackView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(mainStackView)

		NSLayoutConstraint.activate([
			mainStackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
			mainStackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
			mainStackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
			mainStackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
		])
	}
}
