import Foundation

// MARK: - VersionedCodable
protocol VersionedCodable: Codable {
	static var minVersion: Int { get }
	var version: Int { get }
}
