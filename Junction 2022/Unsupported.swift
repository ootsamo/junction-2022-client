func unsupported(function: StaticString = #function, in file: StaticString = #file, line: UInt = #line) -> Never {
	fatalError("Unsupported function \(function) called", file: file, line: line)
}
