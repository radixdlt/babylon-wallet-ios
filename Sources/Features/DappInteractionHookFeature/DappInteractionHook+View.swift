import DappInteractionFeature
import FeaturePrelude

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
		#if os(iOS)
			.fullScreenCover(
				store: store.scope(state: \.$dappInteraction, action: { .child(.dappInteraction($0)) }),
				content: { DappInteraction.View(store: $0) }
			)
		#elseif os(macOS)
			.sheet(
				store: store.scope(state: \.$dappInteraction, action: { .child(.dappInteraction($0)) }),
				content: { DappInteraction.View(store: $0) }
			)
		#endif
			.task {
				await ViewStore(store.stateless).send(.view(.task)).finish()
			}
	}
}
