import Foundation

public struct TransactionIntent: DummySargon {
	public init(header: Any, manifest: Any, message: Any) {
		panic()
	}

	public func header() -> TransactionHeader {
		panic()
	}

	public func description(lookupNetworkName: (NetworkID) throws -> Void) rethrows -> String {
		panic()
	}

	public func manifest() -> TransactionManifest {
		panic()
	}

	public func intentHash() throws -> TransactionHash {
		panic()
	}

	public func compile() throws -> Data {
		panic()
	}
}
