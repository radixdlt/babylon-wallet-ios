import Dependencies
import Foundation

// MARK: - JSONDecoder + DependencyKey
extension JSONDecoder: DependencyKey {
	public typealias Value = JSONDecoder

	public static let liveValue = {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder
	}()

	public static var previewValue: JSONDecoder { liveValue }
	public static var testValue: JSONDecoder { liveValue }
}

// MARK: - JSONDecoder + Sendable
extension JSONDecoder: @unchecked Sendable {}

public extension DependencyValues {
	var jsonDecoder: JSONDecoder {
		self[JSONDecoder.self]
	}
}
