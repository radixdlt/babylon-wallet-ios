import Foundation

// MARK: - SigningPurpose
enum SigningPurpose: Sendable, Hashable {
	case signAuth
	case signTransaction(SignTransactionPurpose)
	enum SignTransactionPurpose: Sendable, Hashable {
		case manifestFromDapp
		case internalManifest(InternalTXSignPurpose)
		enum InternalTXSignPurpose: Sendable, Hashable {
			case transfer
			case uploadAuthKey(forEntityKind: EntityKind)
			#if DEBUG
			/// E.g. turn account into dapp definition account type (setting metadata)
			case debugModifyAccount
			#endif
		}
	}
}
