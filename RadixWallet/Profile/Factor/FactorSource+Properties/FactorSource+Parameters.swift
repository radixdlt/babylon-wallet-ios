import EngineToolkit

// MARK: - FactorSource.CryptoParameters
extension FactorSource {
	public struct CryptoParameters: Sendable, Hashable, Codable {
		/// either Curve25519 or secp256k1 (or P256?)
		public let supportedCurves: NonEmpty<OrderedSet<SLIP10.Curve>>

		/// either BIP44 or CAP26 (SLIP10), empty if this factor source does not support HD derivation.
		public let supportedDerivationPathSchemes: OrderedSet<DerivationPathScheme>

		public init(
			supportedCurves: NonEmpty<OrderedSet<SLIP10.Curve>>,
			supportedDerivationPathSchemes: OrderedSet<DerivationPathScheme>
		) {
			self.supportedCurves = supportedCurves
			self.supportedDerivationPathSchemes = supportedDerivationPathSchemes
		}
	}
}

extension FactorSource.CryptoParameters {
	public static let `default` = Self.babylon
	public static let babylon = Preset.babylonOnly.cryptoParameters
	public static let olympiaOnly = Preset.olympiaOnly.cryptoParameters
	public static let babylonWithOlympiaCompatability = Preset.babylonWithOlympiaCompatability.cryptoParameters
}

extension FactorSource.CryptoParameters {
	public static let trustedEntity = Self(
		supportedCurves: .init(rawValue: [.curve25519])!, // keys are Curve25519 but we do not derive anything..
		supportedDerivationPathSchemes: [] // no derivation
	)
}

extension FactorSource.CryptoParameters {
	public var supportsOlympia: Bool {
		supportedCurves.rawValue.contains(.secp256k1) &&
			supportedDerivationPathSchemes.contains(.bip44Olympia)
	}

	public var supportsBabylon: Bool {
		supportedCurves.rawValue.contains(.curve25519) &&
			supportedDerivationPathSchemes.contains(.cap26)
	}
}

// MARK: - FactorSource.CryptoParameters.Preset
extension FactorSource.CryptoParameters {
	public enum Preset: Sendable, Hashable {
		case babylonOnly
		case olympiaOnly
		case babylonWithOlympiaCompatability
	}
}

extension FactorSource.CryptoParameters.Preset {
	public var cryptoParameters: FactorSource.CryptoParameters {
		switch self {
		case .babylonOnly:
			FactorSource.CryptoParameters(
				supportedCurves: .init(rawValue: [.curve25519])!,
				supportedDerivationPathSchemes: [.cap26]
			)
		case .olympiaOnly:
			FactorSource.CryptoParameters(
				supportedCurves: .init(rawValue: [.secp256k1])!,
				supportedDerivationPathSchemes: [.bip44Olympia]
			)
		case .babylonWithOlympiaCompatability:
			FactorSource.CryptoParameters(
				supportedCurves: .init(rawValue: [.curve25519, .secp256k1])!,
				supportedDerivationPathSchemes: [.cap26, .bip44Olympia]
			)
		}
	}
}
