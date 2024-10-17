
extension Date {
	// FIXME: Date differs when encoded and decoded, by some nanoseconds or something.. cleanup
	var stableEquatableAfterJSONRoundtrip: Self {
		let jsonEncoder = JSONEncoder()
		jsonEncoder.dateEncodingStrategy = .iso8601
		let jsonDecoder = JSONDecoder()
		jsonDecoder.dateDecodingStrategy = .iso8601
		let data = try! jsonEncoder.encode(self)
		let persistable = try! jsonDecoder.decode(Self.self, from: data)
		return persistable
	}
}
