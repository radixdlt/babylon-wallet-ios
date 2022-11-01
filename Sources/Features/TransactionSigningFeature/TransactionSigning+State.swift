import EngineToolkit
import Foundation
import Profile

// MARK: - TransactionSigning.State
public extension TransactionSigning {
	struct State: Equatable {
		public var address: String
		public var transactionManifest: TransactionManifest

		public init(
			address: String,
			transactionManifest: TransactionManifest
		) {
			self.address = address
			self.transactionManifest = transactionManifest
		}
	}
}

#if DEBUG
public extension TransactionSigning.State {
//	static let placeholder: Self = .init()
}
#endif
