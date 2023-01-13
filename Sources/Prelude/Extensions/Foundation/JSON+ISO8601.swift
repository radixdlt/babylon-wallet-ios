import Foundation

public extension JSONDecoder {
	static var iso8601: JSONDecoder {
		let jsonDecoder = JSONDecoder()
		jsonDecoder.dateDecodingStrategy = .iso8601
		return jsonDecoder
	}
}

public extension JSONEncoder {
	static var iso8601: JSONEncoder {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
		return encoder
	}
}
