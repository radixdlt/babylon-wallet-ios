import FeaturePrelude

public extension View {
	func presentsDappInteractions(onDismiss: (@Sendable () -> Void)?) -> some View {
		self.presentsDappInteractions(
			store: .init(
				initialState: .init(),
				reducer: DappInteractor(onDismiss: onDismiss)
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
				store: store.scope(state: \.$currentModal, action: { .child(.modal($0)) }),
				state: /DappInteractor.Destinations.State.dappInteraction,
				action: DappInteractor.Destinations.Action.dappInteraction,
				content: { DappInteractionCoordinator.View(store: $0.relay()) }
			)
			#elseif os(macOS) // .fullScreenCover is not available on macOS
			.sheet(
				store: store.scope(state: \.$currentModal, action: { .child(.modal($0)) }),
				state: /DappInteractor.Destinations.State.dappInteraction,
				action: DappInteractor.Destinations.Action.dappInteraction,
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
				reducer: DappInteractor(onDismiss: nil)
			)
		)
	}
}
#endif
