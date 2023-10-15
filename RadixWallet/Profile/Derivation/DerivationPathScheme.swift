import EngineToolkit

// MARK: - DerivationPathScheme
public enum DerivationPathScheme: String, Sendable, Hashable, Codable {
	case cap26
	case bip44Olympia
}

extension DerivationPathScheme {
	public var curve: SLIP10.Curve {
		switch self {
		case .cap26:
			/// We always use `curve25519` for non Olympia factor instances,
			/// given that the scheme is `cap26` it means it is a non Olympia factor
			/// instance => thus OK to always use `curve25519`
			.curve25519
		case .bip44Olympia:
			/// Bip44 is only used with `secp256k1` and `secp256k1` is only used for `bip44`
			/// scheme, thus OK to return `secp256k1`.
			.secp256k1
		}
	}
}
