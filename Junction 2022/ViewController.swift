import UIKit
import MapboxMaps

class ViewController: UIViewController {
	private let mapView: MapView
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
			let coordinates = mapView.mapboxMap.coordinate(for: point)

			let pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
			var customPointAnnotation = PointAnnotation(coordinate: coordinates)
			customPointAnnotation.image = .init(image: UIImage(named: "pin")!, name: "pin")
			pointAnnotationManager.annotations = [customPointAnnotation]

			Task {
				let response = try await networkService.fetchScores(
					at: coordinates,
					transitTypes: [.drive],
					transitDuration: 10
				)
				let address = try await networkService.fetchAddress(at: coordinates)
				print("Address: \(address!)")
				

				guard case .featureCollection(let featureCollection) = response.isochoroneGeoJson else {
					assertionFailure("Returned geojson was not a feature collection")
					return
				}

				addArea(from: featureCollection)
			}
		}
	}
}
