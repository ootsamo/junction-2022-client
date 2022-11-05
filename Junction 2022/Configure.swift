@discardableResult
func configure<T>(_ object: T, with f: (inout T) -> Void) -> T {
	var object = object
	f(&object)
	return object
}
