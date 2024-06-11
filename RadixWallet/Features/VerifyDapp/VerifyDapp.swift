// MARK: - VerifyDapp

public struct VerifyDapp: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let dAppMetadata: DappMetadata

		init(dAppMetadata: DappMetadata) {
			self.dAppMetadata = dAppMetadata
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case continueTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case cancel
		case continueFlow
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueTapped:
			.send(.delegate(.continueFlow))
		}
	}
}
