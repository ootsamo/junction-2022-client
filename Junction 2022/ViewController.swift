import UIKit
import MapboxMaps

class ViewController: UIViewController {
	private let mapView: MapView

	private let pinView = configure(UIImageView()) {
		$0.image = UIImage(named: "pin")
	}

	private let pinAnnotationManager: PointAnnotationManager
	private let markerAnnotationManager: PointAnnotationManager
	private var markerViews = [UIView]()
	private let detailViewController = DetailViewController()
	private let networkService = NetworkService()

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		let mapInitOptions = MapInitOptions(
			resourceOptions: ResourceOptions(
				accessToken: Secrets.mapboxPublicAccessToken
			),
			cameraOptions: CameraOptions(
				center: CLLocationCoordinate2D(latitude: 60.1816728, longitude: 24.9340785),
				zoom: 11
			),
			styleURI: StyleURI(rawValue: "mapbox://styles/hallitunkki/cla2wbi3s00mt14p09fdvkj47")
		)

		mapView = MapView(
			frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)),
			mapInitOptions: mapInitOptions
		)

		mapView.ornaments.scaleBarView.isHidden = true

		pinAnnotationManager = mapView.annotations.makePointAnnotationManager()
		markerAnnotationManager = mapView.annotations.makePointAnnotationManager()

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
			detailView.widthAnchor.constraint(equalToConstant: 320),
			detailView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
			detailView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor)
		])
	}

	@objc
	private func handleLongPress(recognizer: UILongPressGestureRecognizer) {
		if recognizer.state == .began {
			let point = recognizer.location(in: mapView)
			let coordinate = mapView.mapboxMap.coordinate(for: point)

			do {
				try updatePin(for: coordinate)
			} catch {
				assertionFailure("Failed to add or update pin annotation: \(error)")
			}

			Task {
				do {
					try await updateScores(for: coordinate)
				} catch {
					assertionFailure("Failed to update scores: \(error)")
				}
			}

			Task {
				do {
					let address = try await networkService.fetchAddress(at: coordinate)
					detailViewController.headline = address.primaryComponent ?? "No address"
					detailViewController.subheadline = address.secondaryComponent
				} catch {
					assertionFailure("Failed to update address: \(error)")
				}
			}
		}
	}

	private func updatePin(for coordinate: CLLocationCoordinate2D) throws {
		var pinAnnotation = PointAnnotation(coordinate: coordinate)
		pinAnnotation.image = .init(image: UIImage(named: "pin")!, name: "pin")
		pinAnnotationManager.annotations = [pinAnnotation]
	}

	private func addArea(from featureCollection: FeatureCollection) {
		let sourceID = "isochrone-source"
		let fillLayerID = "isochrone-fill-layer"
		let lineLayerID = "isochrone-line-layer"

		var geoJSONSource = GeoJSONSource()
		geoJSONSource.data = .featureCollection(featureCollection)

		var fillLayer = FillLayer(id: fillLayerID)
		fillLayer.fillColor = .constant(StyleColor(red: 255, green: 255, blue: 255, alpha: 0.4)!)
		fillLayer.source = sourceID

		var lineLayer = LineLayer(id: lineLayerID)
		lineLayer.lineWidth = .constant(4)
		lineLayer.lineColor = .constant(StyleColor(red: 255, green: 255, blue: 255, alpha: 1)!)
		lineLayer.source = sourceID

		do {
			let style = mapView.mapboxMap.style

			if style.layerExists(withId: fillLayerID) {
				try style.removeLayer(withId: fillLayerID)
			}

			if style.layerExists(withId: lineLayerID) {
				try style.removeLayer(withId: lineLayerID)
			}

			if style.sourceExists(withId: sourceID) {
				try style.removeSource(withId: sourceID)
			}
			
			try style.addSource(geoJSONSource, id: sourceID)
			try style.addLayer(fillLayer)
			try style.addLayer(lineLayer)
		} catch {
			assertionFailure("Failed to add line layer: \(error)")
		}
	}

	private func updateScores(for coordinate: CLLocationCoordinate2D) async throws {
		let response = try await networkService.fetchScores(
			at: coordinate,
			transitType: .transit,
			transitDuration: 5
		)

		updateScoreDetails(from: response)
		updateAttractionDetails(from: response)
		updateMarkers(from: response)
		updateAreas(from: response)
	}

	private func updateAreas(from response: Response) {
		guard case .featureCollection(let featureCollection) = response.isochoroneGeoJson else {
			assertionFailure("Returned geojson was not a feature collection")
			return
		}

		addArea(from: featureCollection)

		let points = featureCollection.features.map { feature -> [CLLocationCoordinate2D] in
			guard case .polygon(let polygon) = feature.geometry else { return [] }
			return polygon.coordinates.flatMap { $0 }
		}.flatMap { $0 }
		let padding = UIEdgeInsets(top: 64, left: 384, bottom: 64, right: 64)
		let cameraOptions = mapView.mapboxMap.camera(for: points, padding: padding, bearing: nil, pitch: nil)
		mapView.camera.fly(to: cameraOptions)
	}

	private func updateScoreDetails(from response: Response) {
		let reachablePopulationDetail = ScoreDetail(
			icon: UIImage(systemName: "person.2.circle"),
			value: Int(response.reachablePopulation.score)
		)
		let cityBikesDetail = ScoreDetail(
			icon: UIImage(systemName: "bicycle.circle"),
			value: Int(response.cityBikes.score)
		)
		let poisDetail = ScoreDetail(
			icon: UIImage(systemName: "star.circle"),
			value: Int(response.POIs.score ?? 1000)
		)
		detailViewController.setScoreDetails([reachablePopulationDetail, cityBikesDetail, poisDetail])
	}

	private func updateAttractionDetails(from response: Response) {
		let reachablePopulationDetail = AttractionDetail(
			icon: UIImage(systemName: "person.2.circle"),
			description: "Reachable population:",
			value: String(response.reachablePopulation.population)
		)
		let cityBikesDetail = AttractionDetail(
			icon: UIImage(systemName: "bicycle.circle"),
			description: "Nearest bike station:",
			value: response.cityBikes.distanceToNearest.map { String(format: "%.2f km", $0) } ?? "-"
		)
		let poisDetail = AttractionDetail(
			icon: UIImage(systemName: "star.circle"),
			description: "Nearby points of interest:",
			value: String(response.POIs.POIs.shops.featureCount + response.POIs.POIs.restaurants.featureCount + response.POIs.POIs.entertainment.featureCount)
		)
		detailViewController.setAttractionDetails([reachablePopulationDetail, cityBikesDetail, poisDetail])
	}

	private func updateMarkers(from response: Response) {
		markerViews.forEach(mapView.viewAnnotations.remove)
		markerViews.removeAll()
		markerAnnotationManager.annotations.removeAll()
		updateCityBikeMarkers(from: response)
		updatePOIMarkers(from: response)
	}

	private func updateCityBikeMarkers(from response: Response) {
		guard case .featureCollection(let featureCollection) = response.cityBikes.bikesInArea else {
			assertionFailure("City bikes was not a feature collection")
			return
		}

		let points = featureCollection.features.map { feature -> Point? in
			guard case .point(let point) = feature.geometry else { return nil }
			return point
		}.compactMap { $0 }

		markerAnnotationManager.annotations.append(contentsOf: points.map {
			var customPointAnnotation = PointAnnotation(coordinate: $0.coordinates)
			customPointAnnotation.image = .init(image: UIImage(named: "bike")!, name: "bike")
			return customPointAnnotation
		})
	}

	private func updatePOIMarkers(from response: Response) {
		let mapping: [(name: String, pois: GeoJSONObject)] = [
			("shop", response.POIs.POIs.shops),
			("restaurant", response.POIs.POIs.restaurants),
			("entertainment", response.POIs.POIs.entertainment)
		]

		for pair in mapping {
			guard case .featureCollection(let featureCollection) = pair.pois else {
				assertionFailure("POIs were not a feature collection")
				return
			}

			let points = featureCollection.features.map { feature -> Point? in
				guard case .point(let point) = feature.geometry else { return nil }
				return point
			}.compactMap { $0 }

			markerAnnotationManager.annotations.append(contentsOf: points.map {
				var customPointAnnotation = PointAnnotation(coordinate: $0.coordinates)
				customPointAnnotation.image = .init(image: UIImage(named: pair.name)!, name: pair.name)
				return customPointAnnotation
			})
		}
	}
}
