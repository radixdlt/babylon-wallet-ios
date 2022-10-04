import Foundation

// MARK: - AccountDetails.Transfer
/// Namespace for TransferFeature
public extension AccountDetails {
	enum Transfer {}
}

// MARK: - AccountDetails.Transfer.State
public extension AccountDetails.Transfer {
	// MARK: State
	struct State: Equatable {
		public init() {}
	}
}
