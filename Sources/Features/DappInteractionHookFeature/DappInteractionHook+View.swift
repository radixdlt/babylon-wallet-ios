import DappInteractionFeature
import FeaturePrelude
import TransactionSigningFeature

// MARK: - DappInteractionHook.View
public extension DappInteractionHook {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = StoreOf<DappInteractionHook>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

public extension DappInteractionHook.View {
	var body: some View {
		ZStack {}
//			.fullScreenCover(
//				store: <#T##Store<PresentationState<State>, PresentationAction<State, Action>>#>,
//				state: <#T##(State) -> DestinationState?#>,
//				action: <#T##(DestinationAction) -> Action#>,
//				content: <#T##(Store<DestinationState, DestinationAction>) -> Content#>
//			)
//			.fullScreenCover(
//				store: <#T##Store<PresentationState<State>, PresentationAction<State, Action>>#>,
//				content: <#T##(Store<State, Action>) -> Content#>
//			)
			.task {
				await ViewStore(store.stateless).send(.view(.task)).finish()
			}
	}
}
