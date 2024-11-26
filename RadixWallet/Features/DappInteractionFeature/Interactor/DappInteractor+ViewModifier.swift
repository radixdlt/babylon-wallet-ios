import ComposableArchitecture
import SwiftUI

extension View {
	func presentsDappInteractions() -> some View {
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
				dappInteraction
			}
			.destinations(with: store)
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

		@MainActor
		private var dappInteraction: some SwiftUI.View {
			WithViewStore(store, observe: { $0.destination }) { viewStore in
				IfLetStore(
					store.destination,
					state: /DappInteractor.Destination.State.dappInteraction,
					action: DappInteractor.Destination.Action.dappInteraction,
					then: { DappInteractionCoordinator.View(store: $0) }
				)
				.transition(.move(edge: .bottom))
				.animation(.linear, value: viewStore.state)
			}
		}
	}
}

private extension StoreOf<DappInteractor> {
	var destination: PresentationStoreOf<DappInteractor.Destination> {
		func scopeState(state: State) -> PresentationState<DappInteractor.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<DappInteractor>) -> some View {
		let destinationStore = store.destination
		return dappInteractionCompletion(with: destinationStore, store: store)
			.invalidRequestAlert(with: destinationStore)
			.responseFailureAlert(with: destinationStore)
			.preAuthorizationPolling(with: destinationStore)
	}

	private func dappInteractionCompletion(with destinationStore: PresentationStoreOf<DappInteractor.Destination>, store: StoreOf<DappInteractor>) -> some View {
		sheet(
			store: destinationStore.scope(state: \.dappInteractionCompletion, action: \.dappInteractionCompletion),
			onDismiss: { store.send(.view(.completionDismissed)) }
		) {
			DappInteractionCompletion.View(store: $0)
		}
	}

	private func invalidRequestAlert(with destinationStore: PresentationStoreOf<DappInteractor.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.invalidRequest, action: \.invalidRequest))
	}

	private func responseFailureAlert(with destinationStore: PresentationStoreOf<DappInteractor.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.responseFailure, action: \.responseFailure))
	}

	private func preAuthorizationPolling(with destinationStore: PresentationStoreOf<DappInteractor.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.pollPreAuthorizationStatus, action: \.pollPreAuthorizationStatus)) {
			PreAuthorizationReview.PollingStatus.View(store: $0)
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
