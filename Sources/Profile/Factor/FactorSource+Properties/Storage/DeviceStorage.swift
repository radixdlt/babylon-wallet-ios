import Foundation

// MARK: - NextDerivationIndicies
public struct NextDerivationIndicies: Sendable, Hashable, Codable {
	public var forAccount: UInt
	public var forIdentity: UInt
}

// MARK: - DeviceStorage
public struct DeviceStorage: Sendable, Hashable, Codable {
	public var nextDerivationIndicies: NextDerivationIndicies
}
