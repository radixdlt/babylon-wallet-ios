import Cryptography
import Prelude

// MARK: - FactorSource.Parameters
public extension FactorSource {
	struct Parameters: Sendable, Hashable, Codable {
		/// either Curve25519 or secp256k1 (or P256?)
		public let supportedCurves: NonEmpty<OrderedSet<Slip10Curve>>

		/// either BIP44 or CAP26 (SLIP10), empty if this factor source does not support HD derivation.
		public let supportedDerivationPathSchemes: OrderedSet<DerivationPathScheme>

		public init(
			supportedCurves: NonEmpty<OrderedSet<Slip10Curve>>,
			supportedDerivationPathSchemes: OrderedSet<DerivationPathScheme>
		) {
			self.supportedCurves = supportedCurves
			self.supportedDerivationPathSchemes = supportedDerivationPathSchemes
		}

		public static let babylon = Self(
			supportedCurves: .init(rawValue: [.curve25519])!,
			supportedDerivationPathSchemes: [.cap26]
		)

		public static let olympiaBackwardsCompatible = Self(
			supportedCurves: .init(rawValue: [.curve25519, .secp256k1])!,
			supportedDerivationPathSchemes: [.cap26, .bip44Olympia]
		)

		public static let `default` = Self.babylon

		public var supportsOlympia: Bool {
			supportedCurves.rawValue.contains(.secp256k1) &&
				supportedDerivationPathSchemes.contains(.bip44Olympia)
		}
	}
}
