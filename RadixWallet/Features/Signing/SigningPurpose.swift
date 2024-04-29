import Foundation

// MARK: - SigningPurpose
public enum SigningPurpose: Sendable, Hashable {
	case signAuth
	case signTransaction(SignTransactionPurpose)
	public enum SignTransactionPurpose: Sendable, Hashable {
		case manifestFromDapp
		case internalManifest(InternalTXSignPurpose)
		public enum InternalTXSignPurpose: Sendable, Hashable {
			case transfer
			case uploadAuthKey(forEntityKind: EntityKind)
			#if DEBUG
			/// E.g. turn account into dapp definition account type (setting metadata)
			case debugModifyAccount
			#endif
		}
	}
}
