import UIKit
import MapboxMaps

class ViewController: UIViewController {
	private let mapView: MapView
	private let pinView = UIImageView(image: UIImage(systemName: "mappin"))
	private let pointAnnotationManager: PointAnnotationManager
	private let detailViewController = DetailViewController()
	private let networkService = NetworkService()
	private let isochroneSourceID = "isochrone-source"
	private let isochroneLayerID = "isochrone-layer"

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		let mapInitOptions = MapInitOptions(
			resourceOptions: ResourceOptions(
				accessToken: Secrets.mapboxPublicAccessToken
			),
			cameraOptions: CameraOptions(
				center: CLLocationCoordinate2D(latitude: 60.1816728, longitude: 24.9340785),
				zoom: 11
			)
		)

		mapView = MapView(
			frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)),
			mapInitOptions: mapInitOptions
		)

		pointAnnotationManager = mapView.annotations.makePointAnnotationManager()

		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) { unsupported() }
	
	override func viewDidLoad() {
		super.viewDidLoad()

		configure(mapView) {
			$0.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview($0)

			NSLayoutConstraint.activate([
				mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
				mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
				mapView.topAnchor.constraint(equalTo: view.topAnchor),
				mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			])
		}

		mapView.addGestureRecognizer(UILongPressGestureRecognizer(
			target: self,
			action: #selector(handleLongPress)
		))

		addChild(detailViewController)
		view.addSubview(detailViewController.view)
		detailViewController.didMove(toParent: self)

		let detailView: UIView = detailViewController.view
		detailView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			detailView.widthAnchor.constraint(equalToConstant: 400),
			detailView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
			detailView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor)
		])
	}

	private func addArea(from featureCollection: FeatureCollection) {
		var geoJSONSource = GeoJSONSource()
		geoJSONSource.data = .featureCollection(featureCollection)

		var layer = FillLayer(id: isochroneLayerID)
		layer.fillColor = .constant(StyleColor(red: 255, green: 0, blue: 0, alpha: 0.2)!)
		layer.source = isochroneSourceID

		do {
			let style = mapView.mapboxMap.style

			if style.layerExists(withId: isochroneLayerID) {
				try style.removeLayer(withId: isochroneLayerID)
			}

			if style.sourceExists(withId: isochroneSourceID) {
				try style.removeSource(withId: isochroneSourceID)
			}
			
			try style.addSource(geoJSONSource, id: isochroneSourceID)
			try style.addLayer(layer)
		} catch {
			assertionFailure("Failed to add line layer: \(error)")
		}
	}

	@objc
	private func handleLongPress(recognizer: UILongPressGestureRecognizer) {
		if recognizer.state == .began {
			let point = recognizer.location(in: mapView)
			let coordinate = mapView.mapboxMap.coordinate(for: point)

			do {
				let aspectRatio = pinView.image.map { $0.size.width / $0.size.height } ?? 1
				let height: CGFloat = 64
				let options = ViewAnnotationOptions(
					geometry: Point(coordinate),
					width: aspectRatio * height,
					height: height,
					anchor: .bottom
				)
				pinView.tintColor = .red
				if pinView.superview == nil {
					try mapView.viewAnnotations.add(pinView, options: options)
				} else {
					try mapView.viewAnnotations.update(pinView, options: options)
				}
			} catch {
				assertionFailure("Failed to add or update pin annotation: \(error)")
			}

//			var annotation = PointAnnotation(coordinate: coordinates)
//			annotation.image = .init(image: UIImage(systemName: "mappin")!, name: "pin")
//			pointAnnotationManager.annotations = [annotation]
//			mapView.annotations.makePointAnnotationManager()

			Task {
				let response = try await networkService.fetchScores(
					at: coordinate,
					transitType: .drive,
					transitDuration: 10
				)

				guard case .featureCollection(let featureCollection) = response.isochoroneGeoJson else {
					assertionFailure("Returned geojson was not a feature collection")
					return
				}

				addArea(from: featureCollection)
			}

			Task {
				let address = try await networkService.fetchAddress(at: coordinate)
				detailViewController.headline = address.primaryComponent ?? "No address"
				detailViewController.subheadline = address.secondaryComponent
			}
		}
	}
}
