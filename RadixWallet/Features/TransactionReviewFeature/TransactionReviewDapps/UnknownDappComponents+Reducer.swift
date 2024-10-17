struct UnknownDappComponents: FeatureReducer, Sendable {
	struct State: Hashable, Sendable {
		let title: String
		let rowHeading: String
		let addresses: [LedgerIdentifiable.Address]
	}

	enum ViewAction: Sendable {
		case closeButtonTapped
	}

	@Dependency(\.dismiss) var dismiss

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.run { _ in
				await dismiss()
			}
		}
	}
}
