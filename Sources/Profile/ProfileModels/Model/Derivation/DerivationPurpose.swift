import Prelude

// MARK: - DerivationPurpose
/// The purpose for deriving a key pair, e.g. to derive and `Address`, or
/// to create a cryptography based ID (e.g. Ledger Nano Device ID)
public enum DerivationPurpose:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	/// Purpose of deriving is a public key used for an address of `kind`
	case publicKeyForAddress(kind: AddressKind)

	/// Purpose is a stable ID, e.g. used to identify a Ledger Nano device.
	case hashOfPublicKeyAsID
}

public extension DerivationPurpose {
	var _description: String {
		switch self {
		case let .publicKeyForAddress(addressKind): return "DerivationPurpose(.publicKeyForAddress(\(addressKind))"
		case .hashOfPublicKeyAsID: return "DerivationPurpose(.hashOfPublicKeyAsID)"
		}
	}

	var customDumpDescription: String {
		_description
	}

	var description: String {
		_description
	}
}

public extension DerivationPurpose {
	static func publicKeyForAddressOfEntity<Entity: EntityProtocol>(type _: Entity.Type) -> Self {
		switch Entity.entityKind {
		case .account: return .publicKeyForAddress(kind: .account)
		case .identity: return .publicKeyForAddress(kind: .identity)
		}
	}
}
