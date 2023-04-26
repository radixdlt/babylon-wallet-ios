import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - LegacyOlympiaBIP44LikeDerivationPath
/// A derivation path that looks like a BIP44 path, but does not follow the BIP44 standard
/// since the last component must be hardened, [contrary to the BIP44 standard][bip44]. The
/// path looks like this: `m/44'/1022'/2'/1/3'`
///
/// It was a mistake by me (Alexander Cyon) when I wrote the Radix Olympia wallet, [see Typescript SDK][radixJS], to
/// harden the `address_index`.
///
/// [cap26]: https://radixdlt.atlassian.net/l/cp/UNaBAGUC
/// [radixJS]: https://github.com/radixdlt/radixdlt-javascript/blob/main/packages/crypto/src/elliptic-curve/hd/bip32/bip44/bip44.ts#L81
/// [bip44]: https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki#user-content-Path_levels
///
public struct LegacyOlympiaBIP44LikeDerivationPath:
	DerivationPathProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDebugStringConvertible,
	CustomDumpStringConvertible
{
	public let fullPath: HD.Path.Full

	public init(
		index: Profile.Network.NextDerivationIndices.Index,
		shouldHardenAddressIndex: Bool = true
	) throws {
		let fullPath = try HD.Path.Full(
			children: [
				.bip44Purpose,
				.coinType,
				.init(nonHardenedValue: 0, isHardened: true),
				.init(nonHardenedValue: 0, isHardened: false),
				// Mistake by me, Alexander Cyon, in Olympia wallet I accidentally hardened the last
				// path component, it should NOT be haredned as per BIP44. Why we call this type
				// "BIP44 like". N.B. to make it extra confusing we only this last path component
				// for software wallets, since the Olympia Ledger app automatically unhardened
				// the path component (but that does not seem to be the case of the Babylon Ledger app).
				.init(nonHardenedValue: index, isHardened: shouldHardenAddressIndex),
			],
			onlyPublic: false
		)

		try self.init(fullPath: fullPath)
	}

	public init(fullPath: HD.Path.Full) throws {
		self.fullPath = try Self.validate(hdPath: fullPath)
	}

	public init(derivationPath: String) throws {
		try self.init(fullPath: .init(string: derivationPath))
	}

	public var derivationPath: String { fullPath.toString() }
}

extension HD.Path.Full {
	fileprivate subscript(index: BIP44LikePathComponentIndex) -> HD.Path.Component.Child {
		children[index.rawValue]
	}

	fileprivate subscript(index: BIP44LikePathComponentIndex) -> HD.Path.Component.Child.Value {
		self[index].nonHardenedValue
	}
}

// MARK: - BIP44LikePathComponentIndex
/// index after having removed `m` as path component, i.e. letting `purpose` have index 0.
private enum BIP44LikePathComponentIndex: Int, Sendable, Hashable, CaseIterable {
	case purpose
	case coinType
	case account
	case change
	case addressIndex
}

extension LegacyOlympiaBIP44LikeDerivationPath {
	fileprivate subscript(index: BIP44LikePathComponentIndex) -> HD.Path.Component.Child.Value {
		fullPath[index]
	}

	public var addressIndex: HD.Path.Component.Child.Value {
		self[.addressIndex]
	}

	public var debugDescription: String {
		derivationPath
	}

	/// includes counting `m` as a path component
	static var expectedComponentCount: Int {
		// children + component: `m`
		BIP44LikePathComponentIndex.allCases.count + 1
	}

	@discardableResult
	static func validate(hdPath: HD.Path.Full) throws -> HD.Path.Full {
		let components = hdPath.components
		guard components.count == Self.expectedComponentCount else {
			throw InvalidBIP44LikeDerivationPath.invalidComponentCount(got: components.count, expected: expectedComponentCount)
		}

		guard components.first!.isRoot else {
			throw InvalidBIP44LikeDerivationPath.invalidFirstComponentNotRoot
		}
		let children = components.dropFirst().compactMap(\.asChild)
		guard children.count == (Self.expectedComponentCount - 1) else {
			throw InvalidBIP44LikeDerivationPath.multipleRootsFound
		}

		guard hdPath[.purpose] == .bip44Purpose else {
			throw InvalidBIP44LikeDerivationPath.secondComponentIsNotBIP44
		}
		guard hdPath[.coinType] == .coinType else {
			throw InvalidBIP44LikeDerivationPath.invalidCoinType(got: children[1].nonHardenedValue)
		}

		guard hdPath[.account].isHardened else {
			throw InvalidBIP44LikeDerivationPath.thirdComponentIsNotHardened
		}

		guard !hdPath[.change].isHardened else {
			throw InvalidBIP44LikeDerivationPath.fourthComponentWasHardenedButExpectedItNotToBe
		}

		// Valid!
		return hdPath
	}

	enum InvalidBIP44LikeDerivationPath: Swift.Error {
		case invalidComponentCount(got: Int, expected: Int)
		case invalidFirstComponentNotRoot
		case multipleRootsFound
		case fourthComponentWasHardenedButExpectedItNotToBe
		case secondComponentIsNotBIP44
		case invalidCoinType(got: UInt32)
		case thirdComponentIsNotHardened
	}
}

extension LegacyOlympiaBIP44LikeDerivationPath {
	public static let purpose: DerivationPurpose = .publicKeyForAddress(kind: .account)
	public static let derivationScheme: DerivationScheme = .bip44
}

extension LegacyOlympiaBIP44LikeDerivationPath {
	public var _description: String {
		"LegacyOlympiaBIP44LikeDerivationPath(\(fullPath.toString()))"
	}

	public var customDumpDescription: String {
		_description
	}

	public var description: String {
		_description
	}
}

extension LegacyOlympiaBIP44LikeDerivationPath {
	/// Wraps this specific type of derivation path to the shared
	/// nominal type `DerivationPath` (enum)
	public func wrapAsDerivationPath() -> DerivationPath {
		try! .customPath(.init(path: fullPath))
	}

	/// Tries to unwraps the nominal type `DerivationPath` (enum)
	/// into this specific type.
	public static func unwrap(derivationPath: DerivationPath) -> Self? {
		try? derivationPath.asLegacyOlympiaBIP44LikePath()
	}
}
