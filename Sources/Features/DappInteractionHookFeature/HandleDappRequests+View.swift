import DappInteractionFeature
import FeaturePrelude
import TransactionSigningFeature

// MARK: - HandleDappRequests.View
public extension HandleDappRequests {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = StoreOf<HandleDappRequests>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

public extension HandleDappRequests.View {
	var body: some View {
		ZStack {}
//			.sheet(
//				store: <#T##Store<PresentationState<State>, PresentationAction<State, Action>>#>,
//				state: <#T##(State) -> DestinationState?#>,
//				action: <#T##(DestinationAction) -> Action#>,
//				content: <#T##(Store<DestinationState, DestinationAction>) -> View#>
//			)
			.task {
				await ViewStore(store.stateless).send(.view(.task)).finish()
			}
	}
}
