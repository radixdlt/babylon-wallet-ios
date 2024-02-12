import Foundation

// MARK: - TransactionManifest
public struct TransactionManifest: DummySargon {
	public init(
		instructionsString: String,
		networkID: NetworkID,
		blobs: [Data]
	) {
		sargon()
	}

	public func extractAddresses() -> [EntityType: [Address]] {
		sargon()
	}

	public func instructionsString() -> String {
		sargon()
	}

	public func blobs() -> [Data] {
		sargon()
	}

	public func summary(networkId: NetworkID) -> ManifestSummary {
		sargon()
	}

	public func executionSummary(
		networkId: NetworkID,
		encodedReceipt: Data // TODO: Replace with TYPE - read from GW.
	) -> ExecutionSummary {
		sargon()
	}
}
