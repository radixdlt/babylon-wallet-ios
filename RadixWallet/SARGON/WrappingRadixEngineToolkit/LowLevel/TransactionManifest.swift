import Foundation

// MARK: - TransactionManifest
public struct TransactionManifest: DummySargon {
	public func extractAddresses() -> [EntityType: [Address]] {
		panic()
	}

	public func instructions() -> Instructions {
		panic()
	}

	public init(instructions: Instructions, blobs: [Data]) {
		panic()
	}

	public func blobs() -> [Data] {
		panic()
	}

	public func summary(networkId: UInt8) -> ManifestSummary {
		panic()
	}

	public func executionSummary(networkId: UInt8, encodedReceipt: Any) -> ExecutionSummary {
		panic()
	}
}
