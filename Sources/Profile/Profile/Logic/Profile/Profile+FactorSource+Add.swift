import Foundation

public extension Profile {
	/// Adds a new `FactorSource` to the profile, returns `nil` if it was not inserted (because already present).
	@discardableResult
	mutating func addFactorSource(
		_ factorSource: any FactorSourceProtocol
	) -> FactorSource? {
		addFactorSource(factorSource: factorSource.wrapAsFactorSource())
	}

	/// Adds a new `FactorSource` to the profile, returns `nil` if it was not inserted (because already present).
	@discardableResult
	mutating func addFactorSource(
		factorSource: FactorSource
	) -> FactorSource? {
		factorSources.add(factorSource: factorSource)
	}
}

internal extension FactorSources {
	/// Adds a new `FactorSource` to the profile, returns `nil` if it was not inserted (because already present).
	@discardableResult
	mutating func add(
		factorSource: FactorSource
	) -> FactorSource? {
		switch factorSource {
		case let .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource(source):
			guard self.secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources.updateOrAppend(source) == nil else {
				return nil
			}
			return factorSource
		case let .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(source):
			return self.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.appendFactorSource(source)?.wrapAsFactorSource()
		}
	}
}
