import FeaturePrelude

extension View {
	public func presentsDappInteractions() -> some View {
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
			WithViewStore(store) { viewStore in
				ZStack {
					content
					IfLetStore(
						store.scope(state: \.$currentModal, action: { .child(.modal($0)) }),
						state: /DappInteractor.Destinations.State.dappInteraction,
						action: DappInteractor.Destinations.Action.dappInteraction,
						then: { DappInteractionCoordinator.View(store: $0.relay()) }
					)
					.transition(.identity.combined(with: .move(edge: .bottom)))
					.animation(.linear, value: UUID())
					.zIndex(1)
				}
				.sheet(
					store: store.scope(state: \.$currentModal, action: { .child(.modal($0)) }),
					state: /DappInteractor.Destinations.State.dappInteractionCompletion,
					action: DappInteractor.Destinations.Action.dappInteractionCompletion,
					content: { Completion.View(store: $0) }
				)
				.alert(
					store: store.scope(
						state: \.$responseFailureAlert,
						action: { .view(.responseFailureAlert($0)) }
					)
				)
				.task {
					await ViewStore(store.stateless).send(.view(.task)).finish()
				}
				#if os(iOS)
				.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
					viewStore.send(.view(.moveToForeground))
				}
				.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
					viewStore.send(.view(.moveToBackground))
				}
				#endif
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
