import EngineToolkit
import Foundation

// MARK: - TransactionManifest + Sendable
extension TransactionManifest: @unchecked Sendable {}

// MARK: - NonFungibleGlobalId + Sendable
extension NonFungibleGlobalId: @unchecked Sendable {}

// MARK: - Instructions + Sendable
extension Instructions: @unchecked Sendable {}

// MARK: - Instruction + Sendable
extension Instruction: @unchecked Sendable {}

// MARK: - EngineToolkit.Address + Sendable
extension EngineToolkit.Address: @unchecked Sendable {}

// MARK: - ManifestValue + Sendable
extension ManifestValue: @unchecked Sendable {}

// MARK: - MapEntry + Sendable
extension MapEntry: @unchecked Sendable {}

// MARK: - EngineToolkit.Decimal + Sendable
extension EngineToolkit.Decimal: @unchecked Sendable {}

// MARK: - PreciseDecimal + Sendable
extension PreciseDecimal: @unchecked Sendable {}

// MARK: - ManifestBlobRef + Sendable
extension ManifestBlobRef: @unchecked Sendable {}

// MARK: - Hash + Sendable
extension Hash: @unchecked Sendable {}

// MARK: - TransactionIntent + Sendable
extension TransactionIntent: @unchecked Sendable {}

// MARK: - ExecutionAnalysis + Sendable
extension ExecutionAnalysis: @unchecked Sendable {}

// MARK: - FeeLocks + Sendable
extension FeeLocks: @unchecked Sendable {}

// MARK: - FeeSummary + Sendable
extension FeeSummary: @unchecked Sendable {}

// MARK: - TransactionType + Sendable
extension TransactionType: @unchecked Sendable {}

// MARK: - ResourceSpecifier + Sendable
extension ResourceSpecifier: @unchecked Sendable {}

// MARK: - Resources + Sendable
extension Resources: @unchecked Sendable {}

// MARK: - ResourceTracker + Sendable
extension ResourceTracker: @unchecked Sendable {}

// MARK: - DecimalSource + Sendable
extension DecimalSource: @unchecked Sendable {}

// MARK: - MetadataValue + Sendable
extension MetadataValue: @unchecked Sendable {}

// MARK: - NonFungibleLocalId + Sendable
extension NonFungibleLocalId: @unchecked Sendable {}

// MARK: - NonFungibleLocalId + Codable
extension NonFungibleLocalId: Codable {
	enum CodingKeys: CodingKey {
		case integer
		case str
		case bytes
		case ruid
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		if let value = try? container.decode(UInt64.self, forKey: .integer) {
			self = .integer(value: value)
			return
		}
		if let value = try? container.decode(String.self, forKey: .str) {
			self = .str(value: value)
			return
		}
		if let value = try? container.decode([UInt8].self, forKey: .bytes) {
			self = .bytes(value: value)
			return
		}
		if let value = try? container.decode([UInt8].self, forKey: .ruid) {
			self = .ruid(value: value)
			return
		}
		throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode values."))
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .integer(value):
			try container.encode(value, forKey: .integer)
		case let .str(value):
			try container.encode(value, forKey: .str)
		case let .bytes(value):
			try container.encode(value, forKey: .bytes)
		case let .ruid(value):
			try container.encode(value, forKey: .ruid)
		}
	}
}
