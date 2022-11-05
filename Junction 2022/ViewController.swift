import UIKit
import MapboxMaps

class ViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
	}

	var mapView: MapView!

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		let mapInitOptions = MapInitOptions(
			resourceOptions: ResourceOptions(
				accessToken: Secrets.mapboxPublicAccessToken
			),
			cameraOptions: CameraOptions(
				center: CLLocationCoordinate2D(latitude: 60.1816728, longitude: 24.9340785),
				zoom: 11
			)
		)

		mapView = MapView(frame: view.bounds, mapInitOptions: mapInitOptions)

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

	@objc
	private func handleLongPress(recognizer: UILongPressGestureRecognizer) {
		if recognizer.state == .began {
			let point = recognizer.location(in: mapView)
			let coords = mapView.mapboxMap.coordinate(for: point)

			let pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
			var customPointAnnotation = PointAnnotation(coordinate: coords)
			customPointAnnotation.image = .init(image: UIImage(named: "pin")!, name: "pin")
			pointAnnotationManager.annotations = [customPointAnnotation]
		}
	}
}
