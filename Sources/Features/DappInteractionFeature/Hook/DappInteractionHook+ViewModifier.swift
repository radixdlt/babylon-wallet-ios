import FeaturePrelude

// MARK: - DappInteractionHook.View
extension DappInteractionHook {
	struct ViewModifier: SwiftUI.ViewModifier {
		let store: StoreOf<DappInteractionHook>

		func body(content: Content) -> some View {
			content
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
}
