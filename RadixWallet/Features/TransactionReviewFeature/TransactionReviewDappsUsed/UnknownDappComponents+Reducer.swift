import ComposableArchitecture

public struct UnknownDappComponents: FeatureReducer {
	public struct State: Hashable, Sendable {
		let components: IdentifiedArrayOf<ComponentAddress>
	}

	public enum ViewAction {
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
