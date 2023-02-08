import FeaturePrelude

public extension View {
	func presentsDappInteractions() -> some View {
		self.presentsDappInteractions(
			store: .init(
				initialState: .init(),
				reducer: DappInteractor()
			)
		)
	}

	internal func presentsDappInteractions(store: StoreOf<DappInteractor>) -> some View {
		self.modifier(DappInteractor.ViewModifier(store: store))
	}
}

// MARK: - DappInteractionHook.ViewModifier
extension DappInteractor {
	typealias View = Never

	struct ViewModifier: SwiftUI.ViewModifier {
		let store: StoreOf<DappInteractor>

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
				reducer: DappInteractor()
			)
		)
	}
}
#endif
