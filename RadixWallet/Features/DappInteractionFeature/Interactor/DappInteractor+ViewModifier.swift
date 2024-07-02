import ComposableArchitecture
import SwiftUI

extension View {
	public func presentsDappInteractions() -> some View {
		self.presentsDappInteractions(
			store: .init(
				initialState: .init(),
				reducer: DappInteractor.init
			)
		)
	}

	func presentsDappInteractions(store: StoreOf<DappInteractor>) -> some View {
		self.modifier(DappInteractor.ViewModifier(store: store))
	}
}

// MARK: - DappInteractionHook.ViewModifier
extension DappInteractor {
	typealias View = Never

	struct ViewModifier: SwiftUI.ViewModifier {
		let store: StoreOf<DappInteractor>

		func body(content: Content) -> some SwiftUI.View {
			ZStack {
				content
				WithViewStore(store, observe: { $0.currentModal }) { viewStore in
					IfLetStore(
						store.scope(state: \.$currentModal, action: { .child(.modal($0)) }),
						state: /DappInteractor.Modal.State.dappInteraction,
						action: DappInteractor.Modal.Action.dappInteraction,
						then: { DappInteractionCoordinator.View(store: $0) }
					)
					.transition(.move(edge: .bottom))
					.animation(.linear, value: viewStore.state)
				}
			}
			.sheet(
				store: store.scope(state: \.$currentModal, action: { .child(.modal($0)) }),
				state: /DappInteractor.Modal.State.dappInteractionCompletion,
				action: DappInteractor.Modal.Action.dappInteractionCompletion,
				onDismiss: { store.send(.view(.completionDismissed)) },
				content: { Completion.View(store: $0) }
			)
			.alert(
				store: store.scope(
					state: \.$invalidRequestAlert,
					action: { .view(.invalidRequestAlert($0)) }
				)
			)
			.alert(
				store: store.scope(
					state: \.$responseFailureAlert,
					action: { .view(.responseFailureAlert($0)) }
				)
			)
			.task {
				await store.send(.view(.task)).finish()
			}
			.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
				store.send(.view(.moveToForeground))
			}
			.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
				store.send(.view(.moveToBackground))
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
				reducer: DappInteractor.init
			)
		)
	}
}
#endif
