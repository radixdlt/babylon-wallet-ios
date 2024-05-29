import Foundation
import OrderedCollections
import Sargon

// MARK: - CannotBeEmpty
struct CannotBeEmpty: Swift.Error {}
extension Array {
	public init(notEmpty elements: some Collection<Element>) throws {
		guard !elements.isEmpty else {
			throw CannotBeEmpty()
		}
		self = Array(elements)
	}
}

extension FactorSourceCryptoParameters {
	/// Appends  `supportedCurves` and `supportedDerivationPathSchemes` from `other`. This is used if a user tries to
	/// add an Olympia Factor Source from Manual Account Recovery Scan where the mnemonic already existed as BDFS => append
	/// (`secp256k1, bip44Olympia)` parameters to this BDFS, and analogously the reversed for Babylon params -> existing Olympia
	/// DeviceFactorSource.
	public mutating func append(_ other: Self) {
		guard self != other else {
			return
		}
		var curves = supportedCurves
		var derivationSchemes = supportedDerivationPathSchemes
		curves.append(contentsOf: other.supportedCurves)
		derivationSchemes.append(contentsOf: other.supportedDerivationPathSchemes)

		curves = OrderedSet(
			uncheckedUniqueElements: curves.sorted(by: \.preference)
		).elements

		derivationSchemes = OrderedSet(
			uncheckedUniqueElements: derivationSchemes.sorted(by: \.preference)
		).elements

		self.supportedCurves = try! .init(notEmpty: curves)
		self.supportedDerivationPathSchemes = derivationSchemes
	}
}

extension Slip10Curve {
	/// Higher means more preferrable, we prefer `curve25519` over `secp256k1`
	public var preference: Int {
		switch self {
		case .curve25519: 1
		case .secp256k1: 0
		}
	}
}

extension DerivationPathScheme {
	/// Higher means more preferrable, we prefer `cap26` over `bip44Olympia`
	public var preference: Int {
		switch self {
		case .cap26: 1
		case .bip44Olympia: 0
		}
	}
}
