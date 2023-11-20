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
					destinations(for: $0, shouldDisplayNavBar: viewStore.shouldDisplayNavBar)
				}
				.navigationTransition(.slide, interactivity: .disabled)
			}
		}

		private func destinations(
			for store: StoreOf<CreateAccountCoordinator.Path>,
			shouldDisplayNavBar: Bool
		) -> some SwiftUI.View {
			ZStack {
				SwitchStore(store) { state in
					switch state {
					case .step1_nameAccount:
						CaseLet(
							/CreateAccountCoordinator.Path.State.step1_nameAccount,
							action: CreateAccountCoordinator.Path.Action.step1_nameAccount,
							then: { NameAccount.View(store: $0) }
						)
					case .step2_creationOfAccount:
						CaseLet(
							/CreateAccountCoordinator.Path.State.step2_creationOfAccount,
							action: CreateAccountCoordinator.Path.Action.step2_creationOfAccount,
							then: { CreationOfAccount.View(store: $0) }
						)
					case .step3_completion:
						CaseLet(
							/CreateAccountCoordinator.Path.State.step3_completion,
							action: CreateAccountCoordinator.Path.Action.step3_completion,
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
