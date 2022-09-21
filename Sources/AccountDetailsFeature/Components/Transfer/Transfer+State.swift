import Foundation

// MARK: - Transfer
/// Namespace for TransferFeature
public extension AccountDetails {
	enum Transfer {}
}

public extension AccountDetails.Transfer {
	// MARK: State
	struct State: Equatable {
		public init() {}
	}
}
