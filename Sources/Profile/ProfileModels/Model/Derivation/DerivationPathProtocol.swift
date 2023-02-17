import Cryptography
import Prelude

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

extension DerivationPathProtocol {
	public init(path: HD.Path.Full) throws {
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

extension DerivationPathProtocol where Self: Identifiable, ID == String {
	public var id: String { derivationPath }
}

// MARK: - DerivationPath
/// A derivation path used to derive keys for Accounts and Identities for signing of
/// transactions and authentication.
public struct DerivationPath:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	public let scheme: DerivationPathScheme
	public let path: String
	fileprivate init(scheme: DerivationPathScheme, path: String) {
		self.scheme = scheme
		self.path = path
	}
}

extension DerivationPath {
	//    static let getID = Self(scheme: .cap26, path: "m/1022H/365H")
	public static let getID: Self = try! .customPath(.init(path: .getID))

	/// The **default** derivation path for `Account`s.
	public static func accountPath(_ path: AccountHierarchicalDeterministicDerivationPath) -> Self {
		Self(scheme: .cap26, path: path.derivationPath)
	}

	/// The **default** derivation path for `Identities`s (Personas).
	public static func identityPath(_ path: IdentityHierarchicalDeterministicDerivationPath) -> Self {
		Self(scheme: .cap26, path: path.derivationPath)
	}

	/// A **custom** derivation path use to derive some keys.
	public static func customPath(_ path: CustomHierarchicalDeterministicDerivationPath) -> Self {
		Self(scheme: .cap26, path: path.derivationPath)
	}
}

extension DerivationPath {
	// FIXME: Multifactor remove
	@available(*, deprecated, message: "Use 'path' instead")
	public var derivationPath: String {
		path
	}

	public func asIdentityPath() throws -> IdentityHierarchicalDeterministicDerivationPath {
		try IdentityHierarchicalDeterministicDerivationPath(derivationPath: path)
	}

	public func asAccountPath() throws -> AccountHierarchicalDeterministicDerivationPath {
		try AccountHierarchicalDeterministicDerivationPath(derivationPath: path)
	}

	public func asCustomPath() throws -> CustomHierarchicalDeterministicDerivationPath {
		try CustomHierarchicalDeterministicDerivationPath(derivationPath: path)
	}
}

// extension DerivationPath {
//	public enum Discriminator: String, Codable {
//		case accountPath, identityPath, customPath
//	}
//
//	public var discriminator: Discriminator {
//		switch self {
//		case .accountPath: return .accountPath
//		case .identityPath: return .identityPath
//		case .customPath: return .customPath
//		}
//	}
//
//	private enum CodingKeys: String, CodingKey {
//		case discriminator, derivationPath
//	}
//
//	public func encode(to encoder: Encoder) throws {
//		var container = encoder.container(keyedBy: CodingKeys.self)
//		try container.encode(discriminator, forKey: .discriminator)
//		try container.encode(derivationPath, forKey: .derivationPath)
//	}
//
//	public init(from decoder: Decoder) throws {
//		let container = try decoder.container(keyedBy: CodingKeys.self)
//		let discriminator = try container.decode(Discriminator.self, forKey: .discriminator)
//		let derivationPath = try container.decode(String.self, forKey: .derivationPath)
//		switch discriminator {
//		case .accountPath:
//			self = try .accountPath(.init(derivationPath: derivationPath))
//		case .identityPath:
//			self = try .identityPath(.init(derivationPath: derivationPath))
//		case .customPath:
//			self = try .customPath(.init(derivationPath: derivationPath))
//		}
//	}
// }

extension DerivationPath {
	public func hdFullPath() throws -> HD.Path.Full {
//		switch self {
//		case let .customPath(path): return try HD.Path.Full(string: path.derivationPath)
//		case let .identityPath(path): return path.fullPath
//		case let .accountPath(path): return path.fullPath
//		}
		try .init(string: path)
	}
}

extension DerivationPath {
	public var customDumpDescription: String {
		_description
	}

	public var description: String {
		_description
	}

	public var _description: String {
		path
	}
}
