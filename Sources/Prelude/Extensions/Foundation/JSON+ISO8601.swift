import Foundation

extension JSONDecoder {
	public static var iso8601: JSONDecoder {
		let jsonDecoder = JSONDecoder()
		jsonDecoder.dateDecodingStrategy = .iso8601
		return jsonDecoder
	}
}

extension JSONEncoder {
	public static var iso8601: JSONEncoder {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
		return encoder
	}
}
