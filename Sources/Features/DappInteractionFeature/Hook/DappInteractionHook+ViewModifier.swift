import FeaturePrelude

public extension View {
	func presentsDappInteractions() -> some View {
		self.modifier(
			DappInteractionHook.ViewModifier(
				store: .init(
					initialState: .init(),
					reducer: DappInteractionHook()
				)
			)
		)
	}
}

// MARK: - DappInteractionHook.ViewModifier
extension DappInteractionHook {
	typealias View = Never

	struct ViewModifier: SwiftUI.ViewModifier {
		let store: StoreOf<DappInteractionHook>

		func body(content: Content) -> some SwiftUI.View {
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
