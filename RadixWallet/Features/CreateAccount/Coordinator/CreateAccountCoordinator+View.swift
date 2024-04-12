import ComposableArchitecture
import NavigationTransitions
import SwiftUI

extension CreateAccountCoordinator.State {
	fileprivate var viewState: CreateAccountCoordinator.ViewState {
		.init(shouldDisplayNavBar: shouldDisplayNavBar)
	}
}

extension CreateAccountCoordinator {
	public struct ViewState: Sendable, Equatable {
		let shouldDisplayNavBar: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreateAccountCoordinator>

		public init(store: StoreOf<CreateAccountCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStackStore(
					store.scope(state: \.path, action: { .child(.path($0)) })
				) {
					IfLetStore(
						store.scope(state: \.root, action: { .child(.root($0)) })
					) {
						destinations(for: $0, shouldDisplayNavBar: viewStore.shouldDisplayNavBar)
							.toolbar {
								if viewStore.shouldDisplayNavBar {
									ToolbarItem(placement: .cancellationAction) {
										CloseButton {
											store.send(.view(.closeButtonTapped))
										}
									}
								}
							}
					}
					// This is required to disable the animation of internal components during transition
					.transaction { $0.animation = nil }
				} destination: {
					destinations(for: $0, shouldDisplayNavBar: viewStore.shouldDisplayNavBar)
				}
				.navigationTransition(.slide, interactivity: .disabled)
				.destinations(with: store)
			}
		}

		private func destinations(
			for store: StoreOf<CreateAccountCoordinator.Path>,
			shouldDisplayNavBar: Bool
		) -> some SwiftUI.View {
			ZStack {
				SwitchStore(store) { state in
					switch state {
					case .nameAccount:
						CaseLet(
							/CreateAccountCoordinator.Path.State.nameAccount,
							action: CreateAccountCoordinator.Path.Action.nameAccount,
							then: { NameAccount.View(store: $0) }
						)
					case .selectLedger:
						CaseLet(
							/CreateAccountCoordinator.Path.State.selectLedger,
							action: CreateAccountCoordinator.Path.Action.selectLedger,
							then: { LedgerHardwareDevices.View(store: $0) }
						)
					case .completion:
						CaseLet(
							/CreateAccountCoordinator.Path.State.completion,
							action: CreateAccountCoordinator.Path.Action.completion,
							then: { NewAccountCompletion.View(store: $0) }
						)
					}
				}
			}
			.navigationBarBackButtonHidden(!shouldDisplayNavBar)
			.navigationBarHidden(!shouldDisplayNavBar)
		}
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<CreateAccountCoordinator>) -> some View {
		let destinationStore = store.destination
		return sheet(
			store: destinationStore,
			state: /CreateAccountCoordinator.Destination.State.derivePublicKeys,
			action: CreateAccountCoordinator.Destination.Action.derivePublicKeys,
			content: { DerivePublicKeys.View(store: $0) }
		)
	}
}

extension StoreOf<CreateAccountCoordinator> {
	var destination: PresentationStoreOf<CreateAccountCoordinator.Destination> {
		func scopeState(state: State) -> PresentationState<CreateAccountCoordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}
