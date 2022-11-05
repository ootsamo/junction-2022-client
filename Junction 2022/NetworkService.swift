import CoreLocation
import Turf
import MapboxSearch

class NetworkService {
	let appHost = "example.com"
	let mapboxHost = "api.mapbox.com"

	func fetchScores(
		at coordinate: CLLocationCoordinate2D,
		transitTypes: [TransitType],
		transitDuration: Int
	) async throws -> Response {
		let query = [
			("longitude", String(coordinate.longitude)),
			("latitude", String(coordinate.latitude)),
			("isochroneTransitModes", transitTypes.map(\.rawValue).joined(separator: ",")),
			("isochroneTimeRange", String(transitDuration))
		]

		let url = url(host: appHost, path: "/estimate", query: query)
		//let (data, response) = try! await URLSession.shared.data(from: url)
		let sampleURL = Bundle.main.url(forResource: "SampleResponse", withExtension: "json")!
		let data = try! Data(contentsOf: sampleURL)

		return try JSONDecoder().decode(Response.self, from: data)
	}

	func fetchAddress(at coordinates: CLLocationCoordinate2D) async throws -> String? {
		let engine = SearchEngine()
		let options = ReverseGeocodingOptions(point: coordinates, limit: 1, types: [.address])
		return try await withCheckedThrowingContinuation { continuation in
			DispatchQueue.main.async {
				engine.reverseGeocoding(options: options) { result in
					switch result {
					case .failure(let error): continuation.resume(throwing: error)
					case .success(let matches):
						continuation.resume(returning: matches.first?.address.map {
							[$0.street, $0.houseNumber].compactMap { $0 }.joined(separator: " ")
						})
					}
				}
			}
		}
	}

	private func validateResponse(_ response: URLResponse) throws {
		guard let httpResponse = response as? HTTPURLResponse else {
			throw NetworkServiceError.invalidResponse
		}

		guard 200..<300 ~= httpResponse.statusCode else {
			throw NetworkServiceError.httpError(resource: response.url?.absoluteString, code: httpResponse.statusCode)
		}
	}

	private func url(host: String, path: String, query: [(String, String?)]) -> URL {
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
	case httpError(resource: String?, code: Int)
	case other(message: String)
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
