import CoreLocation
import Turf
import MapboxSearch

class NetworkService {
	let appHost = "35.228.112.242"
	let mapboxHost = "api.mapbox.com"

	func fetchScores(
		at coordinate: CLLocationCoordinate2D,
		transitType: TransitType,
		transitDuration: Int
	) async throws -> Response {
		let query = [
			("longitude", String(coordinate.longitude)),
			("latitude", String(coordinate.latitude)),
			("isochroneTransitMode", transitType.rawValue),
			("isochroneTimeRange", String(transitDuration))
		]

		let url = url(host: appHost, path: "/estimate", query: query)
		var request = URLRequest(url: url)
		request.timeoutInterval = 120
		let (data, response) = try await URLSession.shared.data(for: request)
		try validateResponse(response)

//		let sampleURL = Bundle.main.url(forResource: "SampleResponse", withExtension: "json")!
//		let data = try! Data(contentsOf: sampleURL)

		return try JSONDecoder().decode(Response.self, from: data)
	}

	func fetchAddress(at coordinates: CLLocationCoordinate2D) async throws -> AddressResponse {
		let engine = SearchEngine()
		let options = ReverseGeocodingOptions(point: coordinates, limit: 1, types: [.address])
		return try await withCheckedThrowingContinuation { continuation in
			DispatchQueue.main.async {
				engine.reverseGeocoding(options: options) { result in
					switch result {
					case .failure(let error): continuation.resume(throwing: error)
					case .success(let matches):
						let address = matches.first?.address
						let primary = address.map {
							[$0.street, $0.houseNumber].compactMap { $0 }.joined(separator: " ")
						}
						let secondary = address.map {
							[$0.postcode, $0.place].compactMap { $0 }.joined(separator: " ")
						}
						let response = AddressResponse(primaryComponent: primary, secondaryComponent: secondary)
						continuation.resume(returning: response)
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
		components.scheme = host == appHost ? "http" : "https"
		components.host = host
		components.path = path
		components.queryItems = query.map(URLQueryItem.init)

		guard let url = components.url else {
			fatalError("Failed to create URL from components: \(components)")
		}

		return url
	}
}

struct AddressResponse {
	let primaryComponent: String?
	let secondaryComponent: String?
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

struct CityBikes: Decodable {
	let distanceToNearest: Double?
	let score: Double
	let bikesInArea: GeoJSONObject
}

struct ReachablePopulation: Decodable {
	let population: Int
	let score: Double
}

struct POIsSummary: Decodable {
	let POIs: POIs
	let score: Double?
}

struct POIs: Decodable {
	let shops: GeoJSONObject
	let restaurants: GeoJSONObject
	let entertainment: GeoJSONObject
}

struct Response: Decodable {
	let reachablePopulation: ReachablePopulation
	let isochoroneGeoJson: GeoJSONObject
	let cityBikes: CityBikes
	let POIs: POIsSummary
}
