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
						destination(for: $0, shouldDisplayNavBar: viewStore.shouldDisplayNavBar)
							.safeToolbar {
								if viewStore.shouldDisplayNavBar {
									ToolbarItem(placement: .primaryAction) {
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
					destination(for: $0, shouldDisplayNavBar: viewStore.shouldDisplayNavBar)
				}
				.navigationTransition(.slide, interactivity: .disabled)
			}
		}

		private func destination(
			for store: StoreOf<CreateAccountCoordinator.Destinations>,
			shouldDisplayNavBar: Bool
		) -> some SwiftUI.View {
			ZStack {
				SwitchStore(store) { state in
					switch state {
					case .step1_nameAccount:
						CaseLet(
							/CreateAccountCoordinator.Destinations.State.step1_nameAccount,
							action: CreateAccountCoordinator.Destinations.Action.step1_nameAccount,
							then: { NameAccount.View(store: $0) }
						)
					case .step2_creationOfAccount:
						CaseLet(
							/CreateAccountCoordinator.Destinations.State.step2_creationOfAccount,
							action: CreateAccountCoordinator.Destinations.Action.step2_creationOfAccount,
							then: { CreationOfAccount.View(store: $0) }
						)
					case .step3_completion:
						CaseLet(
							/CreateAccountCoordinator.Destinations.State.step3_completion,
							action: CreateAccountCoordinator.Destinations.Action.step3_completion,
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
