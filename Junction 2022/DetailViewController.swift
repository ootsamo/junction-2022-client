import UIKit

class DetailViewController: UIViewController {
	private lazy var mainStackView = configure(UIStackView()) {
		$0.axis = .vertical
		[titleLabel].forEach($0.addArrangedSubview)
	}

	private let titleLabel = configure(UILabel()) {
		$0.font = .preferredFont(forTextStyle: .headline)
		$0.text = "Arkadiankatu 6"
	}

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) { unsupported() }

	var headline: String? {
		get { titleLabel.text }
		set { titleLabel.text = newValue }
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
		view.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

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