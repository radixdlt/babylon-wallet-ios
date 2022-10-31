import Foundation

// MARK: - TransactionSigning.State
public extension TransactionSigning {
	struct State: Equatable {
		public init() {}
	}
}

#if DEBUG
public extension TransactionSigning.State {
	static let placeholder: Self = .init()
}
#endif
