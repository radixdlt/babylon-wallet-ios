import Foundation
import Sargon

extension FactorSourceCryptoParameters {
	public var supportsOlympia: Bool {
		supportedCurves.contains(.secp256k1) &&
			supportedDerivationPathSchemes.contains(.bip44Olympia)
	}

	public var supportsBabylon: Bool {
		supportedCurves.contains(.curve25519) &&
			supportedDerivationPathSchemes.contains(.cap26)
	}

	public static let olympiaOnly = Self(
		supportedCurves: .init(element: .secp256k1),
		supportedDerivationPathSchemes: [.bip44Olympia]
	)

	/// Appends  `supportedCurves` and `supportedDerivationPathSchemes` from `other`. This is used if a user tries to
	/// add an Olympia Factor Source from Manual Account Recovery Scan where the mnemonic already existed as BDFS => append
	/// (`secp256k1, bip44Olympia)` parameters to this BDFS, and analogously the reversed for Babylon params -> existing Olympia
	/// DeviceFactorSource.
	public mutating func append(_ other: Self) {
		guard self != other else {
			loggerGlobal.debug("NOOP, crypto parameters are the same.")
			return
		}
		var curves = supportedCurves.elements
		var derivationSchemes = supportedDerivationPathSchemes
		curves.append(contentsOf: other.supportedCurves.elements)
		derivationSchemes.append(contentsOf: other.supportedDerivationPathSchemes)
		loggerGlobal.notice("🔮 `curves` BEFORE sorting: \(curves)")
		curves = OrderedSet(uncheckedUniqueElements: curves.sorted(by: \.preference)).elements
		loggerGlobal.notice("🔮 `curves` AFTER sorting: \(curves)")

		loggerGlobal.notice("🔮 `derivationSchemes` BEFORE sorting: \(derivationSchemes)")
		derivationSchemes = OrderedSet(uncheckedUniqueElements: derivationSchemes.sorted(by: \.preference)).elements
		loggerGlobal.notice("🔮 `derivationSchemes` AFTER sorting: \(derivationSchemes)")

		self.supportedCurves = try! .init(curves)
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
