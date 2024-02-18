public struct UnknownDappComponents: FeatureReducer, Sendable {
	public struct State: Hashable, Sendable {
		let title: String
		let rowHeading: String
		let addresses: [LedgerIdentifiable.Address]
	}

	public enum ViewAction: Sendable {
		case closeButtonTapped
	}

	@Dependency(\.dismiss) var dismiss

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.run { _ in
				await dismiss()
			}
		}
	}
}
