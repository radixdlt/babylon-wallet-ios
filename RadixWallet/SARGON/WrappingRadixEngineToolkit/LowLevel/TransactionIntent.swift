import Foundation

public struct TransactionIntent: DummySargon {
	public init(header: Any, manifest: Any, message: Any) {
		sargon()
	}

	public func header() -> TransactionHeader {
		sargon()
	}

	public func description(lookupNetworkName: (NetworkID) throws -> Void) rethrows -> String {
		sargon()
	}

	public func manifest() -> TransactionManifest {
		sargon()
	}

	public func intentHash() throws -> TransactionHash {
		sargon()
	}

	public func compile() throws -> Data {
		sargon()
	}
}
