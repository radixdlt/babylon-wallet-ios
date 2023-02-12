import Cryptography
import EngineToolkitModels
import Prelude
import ProfileModels

extension Profile {
	/// Adds a new `FactorSource` to the profile, returns `nil` if it was not inserted (because already present).
	@discardableResult
	public mutating func addFactorSource(
		_ factorSource: any FactorSourceProtocol
	) -> FactorSource? {
		addFactorSource(factorSource: factorSource.wrapAsFactorSource())
	}

	/// Adds a new `FactorSource` to the profile, returns `nil` if it was not inserted (because already present).
	@discardableResult
	public mutating func addFactorSource(
		factorSource: FactorSource
	) -> FactorSource? {
		factorSources.add(factorSource: factorSource)
	}
}

extension FactorSources {
	/// Adds a new `FactorSource` to the profile, returns `nil` if it was not inserted (because already present).
	@discardableResult
	internal mutating func add(
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

extension NonEmpty where Collection == IdentifiedArrayOf<OnNetwork.Account> {
	// FIXME: uh terrible, please fix this.
	@discardableResult
	public mutating func appendAccount(_ account: OnNetwork.Account) -> OnNetwork.Account {
		var orderedSet = self.rawValue
		orderedSet.append(account)
		self = .init(rawValue: orderedSet)!
		return account
	}
}

extension NonEmpty where Collection == IdentifiedArrayOf<Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource> {
	// FIXME: uh terrible, please fix this.
	@discardableResult
	public mutating func appendFactorSource(_ factorSource: Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource) -> Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource? {
		var orderedSet = self.rawValue
		let (wasInserted, _) = orderedSet.append(factorSource)
		guard wasInserted else {
			return nil
		}
		self = .init(rawValue: orderedSet)!
		return factorSource
	}
}
