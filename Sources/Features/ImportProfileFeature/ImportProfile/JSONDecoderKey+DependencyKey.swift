import Dependencies
import Foundation

// MARK: - JSONDecoderKey
private enum JSONDecoderKey: DependencyKey {
	typealias Value = JSONDecoder
	static let liveValue = {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder
	}()
}

// MARK: - JSONDecoder + Sendable
@available(iOS 15, macOS 12, *) extension JSONDecoder: @unchecked Sendable {}

public extension DependencyValues {
	var jsonDecoder: JSONDecoder {
		get { self[JSONDecoderKey.self] }
		set { self[JSONDecoderKey.self] = newValue }
	}
}
