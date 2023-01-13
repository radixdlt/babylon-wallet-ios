import Cryptography
import EngineToolkitModels
import Prelude
import ProfileModels

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

public extension NonEmpty where Collection == OrderedSet<OnNetwork.Account> {
	// FIXME: uh terrible, please fix this.
	@discardableResult
	mutating func appendAccount(_ account: OnNetwork.Account) -> OnNetwork.Account {
		var orderedSet = self.rawValue
		orderedSet.append(account)
		self = .init(rawValue: orderedSet)!
		return account
	}
}

public extension NonEmpty where Collection == OrderedSet<Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource> {
	// FIXME: uh terrible, please fix this.
	@discardableResult
	mutating func appendFactorSource(_ factorSource: Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource) -> Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource? {
		var orderedSet = self.rawValue
		let (wasInserted, _) = orderedSet.append(factorSource)
		guard wasInserted else {
			return nil
		}
		self = .init(rawValue: orderedSet)!
		return factorSource
	}
}
