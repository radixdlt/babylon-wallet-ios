import Foundation

// MARK: - TransactionManifest
public struct TransactionManifest: DummySargon {
	public func extractAddresses() -> [EntityType: [Address]] {
		sargon()
	}

	public func instructions() -> Instructions {
		sargon()
	}

	public init(instructions: Instructions, blobs: [Data]) {
		sargon()
	}

	public func blobs() -> [Data] {
		sargon()
	}

	public func summary(networkId: UInt8) -> ManifestSummary {
		sargon()
	}

	public func executionSummary(networkId: UInt8, encodedReceipt: Any) -> ExecutionSummary {
		sargon()
	}
}
