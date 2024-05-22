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
		return dappInteractionCompletion(with: destinationStore)
			.invalidRequestAlert(with: destinationStore)
			.responseFailureAlert(with: destinationStore)
			.npsSurvey(with: destinationStore)
	}

	private func dappInteractionCompletion(with destinationStore: PresentationStoreOf<DappInteractor.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /DappInteractor.Destination.State.dappInteractionCompletion,
			action: DappInteractor.Destination.Action.dappInteractionCompletion,
			content: { Completion.View(store: $0) }
		)
	}

	private func invalidRequestAlert(with destinationStore: PresentationStoreOf<DappInteractor.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /DappInteractor.Destination.State.invalidRequest,
			action: DappInteractor.Destination.Action.invalidRequest
		)
	}

	private func responseFailureAlert(with destinationStore: PresentationStoreOf<DappInteractor.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /DappInteractor.Destination.State.responseFailure,
			action: DappInteractor.Destination.Action.responseFailure
		)
	}

	private func npsSurvey(with destinationStore: PresentationStoreOf<DappInteractor.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /DappInteractor.Destination.State.npsSurvey,
			action: DappInteractor.Destination.Action.npsSurvey,
			content: { NPSSurvey.View(store: $0) }
		)
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
