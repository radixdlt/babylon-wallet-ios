import FeaturePrelude

extension PoolUnitsList.State {
	var viewState: PoolUnitsList.ViewState {
		.init(lsuComponents: nil)
	}
}

// MARK: - PoolUnitsList.View
extension PoolUnitsList {
	public struct ViewState: Equatable {
		let lsuComponents: NonEmpty<IdentifiedArrayOf<LSUComponent.ViewState>>?

		init(
			lsuComponents: NonEmpty<IdentifiedArrayOf<LSUComponent.ViewState>>?
		) {
			self.lsuComponents = lsuComponents
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store<PoolUnitsList.ViewState, PoolUnitsList.ViewAction>

		public init(store: Store<PoolUnitsList.ViewState, PoolUnitsList.ViewAction>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store) { _ in
				IfLetStore(store.scope(state: \.lsuComponents, action: identity)) { lsuComponentsViewStore in
					ForEachStore(
						lsuComponentsViewStore.scope(
							state: \.rawValue,
							action: { _ in
								fatalError()
							}
						),
						content: LSUComponent.View.init
					)
				}
			}
		}
	}
}
