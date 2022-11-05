import CoreLocation
import Turf

class NetworkService {
	let host: String

	init(host: String) {
		self.host = host
	}

	func fetchScores(
		at coordinate: CLLocationCoordinate2D,
		transitTypes: [TransitType],
		transitDuration: Int
	) async throws -> Response {
		let query: [(String, String?)] = [
			("longitude", String(coordinate.longitude)),
			("latitude", String(coordinate.latitude)),
			("isochroneTransitModes", transitTypes.map(\.rawValue).joined(separator: ",")),
			("isochroneTimeRange", String(transitDuration))
		]

		let url = url(for: "/estimate", query: query)
		let request = URLRequest(url: url)
		//let (data, response) = try! await URLSession.shared.data(for: request)
		let sampleURL = Bundle.main.url(forResource: "SampleResponse", withExtension: "json")!
		let data = try! Data(contentsOf: sampleURL)


//		guard let httpResponse = response as? HTTPURLResponse else {
//			throw NetworkServiceError.invalidResponse
//		}
//
//		guard 200..<300 ~= httpResponse.statusCode else {
//			throw NetworkServiceError.httpError(resource: url.absoluteString, code: httpResponse.statusCode)
//		}

		return try JSONDecoder().decode(Response.self, from: data)
	}

	private func url(for path: String, query: [(String, String?)]) -> URL {
		var components = URLComponents()
		components.scheme = "https"
		components.host = host
		components.path = path
		components.queryItems = query.map(URLQueryItem.init)

		guard let url = components.url else {
			fatalError("Failed to create URL from components: \(components)")
		}

		return url
	}
}

enum NetworkServiceError: Error {
	case invalidResponse
	case httpError(resource: String, code: Int)
}

enum TransitType: String {
	case drive
	case truck
	case bicycle
	case walk
	case transit
}

struct Score {
	let description: String
	let value: Int
}

enum MarkerType {
	case cityBike
	case gasStation
	case vehicleCharging
}

struct Marker {
	let type: MarkerType
	let coordinate: CLLocationCoordinate2D
}

struct Response: Decodable {
//	let scores: [Score]
	let isochoroneGeoJson: GeoJSONObject
//	let markers: [Marker]
}
