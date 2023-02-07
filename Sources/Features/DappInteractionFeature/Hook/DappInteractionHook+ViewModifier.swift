import FeaturePrelude

public extension View {
	func presentsDappInteractions() -> some View {
		self.presentsDappInteractions(
			store: .init(
				initialState: .init(),
				reducer: DappInteractionHook()
			)
		)
	}

	internal func presentsDappInteractions(store: StoreOf<DappInteractionHook>) -> some View {
		self.modifier(DappInteractionHook.ViewModifier(store: store))
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
				store: store.scope(state: \.$currentDappInteraction, action: { .child(.dappInteraction($0)) }),
				content: { DappInteractionCoordinator.View(store: $0.relay()) }
			)
			#elseif os(macOS)
			.sheet(
				store: store.scope(state: \.$currentDappInteraction, action: { .child(.dappInteraction($0)) }),
				content: { DappInteractionCoordinator.View(store: $0.relay()) }
			)
			#endif
			.task {
				await ViewStore(store.stateless).send(.view(.task)).finish()
			}
		}
	}
}

#if DEBUG
struct DappInteractionHook_Previews: PreviewProvider {
	static var previews: some View {
		Color.red.presentsDappInteractions(
			store: .init(
				initialState: .init(),
				reducer: DappInteractionHook()
			)
		)
	}
}
#endif
