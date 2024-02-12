import Foundation

// MARK: - DummySargonCodable
public protocol DummySargonCodable: Codable {}
extension DummySargonCodable {
	public func encode(to encoder: Encoder) throws {
		sargon()
	}

	public init(from decoder: Decoder) throws {
		sargon()
	}
}
