import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - AccountDerivationPath
public enum AccountDerivationPath: DerivationPathProtocol, Sendable, Hashable, Codable, Identifiable, CustomStringConvertible, CustomDumpStringConvertible {
	public var derivationPath: String {
		switch self {
		case let .babylon(babylon): return babylon.derivationPath
		case let .olympia(olympia): return olympia.derivationPath
		}
	}

	public func wrapAsDerivationPath() -> DerivationPath {
		switch self {
		case let .babylon(babylon): return .init(scheme: .cap26, path: babylon.derivationPath)
		case let .olympia(olympia): return .init(scheme: .bip44Olympia, path: olympia.derivationPath)
		}
	}

	public init(derivationPath: String) throws {
		do {
			self = try .babylon(.init(derivationPath: derivationPath))
		} catch {
			self = try .olympia(.init(derivationPath: derivationPath))
		}
	}

	public static func unwrap(derivationPath: DerivationPath) -> Self? {
		try? derivationPath.asAccountPath()
	}

	public var description: String {
		switch self {
		case let .babylon(babylon): return babylon.description
		case let .olympia(olympia): return olympia.description
		}
	}

	public var customDumpDescription: String {
		switch self {
		case let .babylon(babylon): return babylon.customDumpDescription
		case let .olympia(olympia): return olympia.customDumpDescription
		}
	}

	case babylon(AccountBabylonDerivationPath)
	case olympia(LegacyOlympiaBIP44LikeDerivationPath)
}

// MARK: - AccountBabylonDerivationPath
/// The **default** derivation path used to derive `Account` keys for signing of
/// transactions or for signing authentication, at a certain account index (`ENTITY_INDEX`)
/// and **unique per network** (`NETWORK_ID`) as per [CAP-26][cap26].
///
/// Note that users can chose to use custom derivation path instead of this default
/// one when deriving keys for accounts.
///
/// The format is:
///
///     `m/44'/1022'/<NETWORK_ID>'/525'/<KEY_TYPE>'/<ENTITY_INDEX>'`
///
/// Where `'` denotes hardened path, which is **required** as per [SLIP-10][slip10],
/// where `525` is ASCII sum of `"ACCOUNT"`, i.e. `"ACCOUNT".map{ $0.asciiValue! }.reduce(0, +)`
///
/// [cap26]: https://radixdlt.atlassian.net/l/cp/UNaBAGUC
/// [slip10]: https://github.com/satoshilabs/slips/blob/master/slip-0010.md
///
public struct AccountBabylonDerivationPath:
	EntityDerivationPathProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	public typealias Entity = Profile.Network.Account
	public let fullPath: HD.Path.Full

	public init(
		networkID: NetworkID,
		index: Profile.Network.NextDerivationIndices.Index,
		keyKind: KeyKind
	) throws {
		try self.init(fullPath: HD.Path.Full.account(
			networkID: networkID,
			index: index,
			keyKind: keyKind
		))
	}

	public init(fullPath: HD.Path.Full) throws {
		self.fullPath = try Self.validate(hdPath: fullPath)
	}
}

extension AccountBabylonDerivationPath {
	public var customDumpDescription: String {
		"AccountBabylonDerivationPath(\(derivationPath))"
	}

	public var description: String {
		"""
		AccountBabylonDerivationPath: \(derivationPath),
		"""
	}
}

extension AccountBabylonDerivationPath {
	/// Wraps this specific type of derivation path to the shared
	/// nominal type `DerivationPath` (enum)
	public func wrapAsDerivationPath() -> DerivationPath {
		.accountPath(.babylon(self))
	}

	/// Tries to unwraps the nominal type `DerivationPath` (enum)
	/// into this specific type.
	public static func unwrap(derivationPath: DerivationPath) -> Self? {
		guard case let .babylon(babylon) = try? derivationPath.asAccountPath() else {
			return nil
		}
		return babylon
	}
}
