import Turf

extension GeoJSONObject {
	var featureCount: Int {
		switch self {
		case .feature: return 1
		case .featureCollection(let collection): return collection.features.count
		case .geometry: return 0
		}
	}
}
