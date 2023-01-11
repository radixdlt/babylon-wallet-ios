import CustomDump
import Foundation

// MARK: - DerivationScheme
/// A derivation scheme used to derive keys using some derivation path.
public enum DerivationScheme:
	String,
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpRepresentable
{
	/// SLIP-10 derivation scheme as detail in https://github.com/satoshilabs/slips/blob/master/slip-0010.md
	case slip10

	/// BIP-44 derivation scheme as detail in https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki
	case bip44
}

// MARK: - DerivationPathProtocol
/// A type which holds a `derivationPath` used for HD key derivation.
public protocol DerivationPathProtocol {
	var derivationPath: String { get }
	init(derivationPath: String) throws

	/// Wraps this specific type of derivation path to the shared
	/// nominal type `DerivationPath` (enum)
	func wrapAsDerivationPath() -> DerivationPath

	/// Tries to unwraps the nominal type `DerivationPath` (enum)
	/// into this specific type.
	static func unwrap(derivationPath: DerivationPath) -> Self?
}

public extension DerivationPathProtocol {
	init(path: HD.Path.Full) throws {
		try self.init(derivationPath: path.toString())
	}
}

// MARK: - DerivationPathSchemeProtocol
/// A type which holds a `derivationPath` acting as input for key derivation
/// using the `derivationScheme`.
public protocol DerivationPathSchemeProtocol: DerivationPathProtocol {
	static var derivationScheme: DerivationScheme { get }
}

// MARK: - DerivationPathPurposeProtocol
/// A type which has a purpose to derive keys at the `derivationPath`.
public protocol DerivationPathPurposeProtocol: DerivationPathProtocol {
	static var purpose: DerivationPurpose { get }
}

public extension DerivationPathProtocol where Self: Identifiable, ID == String {
	var id: String { derivationPath }
}

// MARK: - DerivationPath
/// A derivation path used to derive keys for Accounts and Identities for signing of
/// transactions and authentication.
public enum DerivationPath:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	/// The **default** derivation path for `Account`s.
	case accountPath(AccountHierarchicalDeterministicDerivationPath)

	/// The **default** derivation path for `Identities`s (Personas).
	case identityPath(IdentityHierarchicalDeterministicDerivationPath)

	/// A **custom** derivation path use to derive some keys.
	case customPath(CustomHierarchicalDeterministicDerivationPath)
}

public extension DerivationPath {
	static let getID: Self = try! .customPath(.init(path: .getID))
}

public extension DerivationPath {
	var derivationPath: String {
		switch self {
		case let .accountPath(path): return path.derivationPath
		case let .customPath(path): return path.derivationPath
		case let .identityPath(path): return path.derivationPath
		}
	}
}

public extension DerivationPath {
	enum Discriminator: String, Codable {
		case accountPath, identityPath, customPath
	}

	var discriminator: Discriminator {
		switch self {
		case .accountPath: return .accountPath
		case .identityPath: return .identityPath
		case .customPath: return .customPath
		}
	}

	private enum CodingKeys: String, CodingKey {
		case discriminator, derivationPath
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)
		try container.encode(derivationPath, forKey: .derivationPath)
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(Discriminator.self, forKey: .discriminator)
		let derivationPath = try container.decode(String.self, forKey: .derivationPath)
		switch discriminator {
		case .accountPath:
			self = try .accountPath(.init(derivationPath: derivationPath))
		case .identityPath:
			self = try .identityPath(.init(derivationPath: derivationPath))
		case .customPath:
			self = try .customPath(.init(derivationPath: derivationPath))
		}
	}
}

import SLIP10
public extension DerivationPath {
	func hdFullPath() throws -> HD.Path.Full {
		switch self {
		case let .customPath(path): return try HD.Path.Full(string: path.derivationPath)
		case let .identityPath(path): return path.fullPath
		case let .accountPath(path): return path.fullPath
		}
	}
}

public extension DerivationPath {
	var customDumpDescription: String {
		_description
	}

	var description: String {
		_description
	}

	var _description: String {
		derivationPath
	}
}
