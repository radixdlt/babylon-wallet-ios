import ComposableArchitecture
import SwiftUI

extension CreatePersonaCoordinator.State {
	fileprivate var viewState: CreatePersonaCoordinator.ViewState {
		.init(shouldDisplayNavBar: shouldDisplayNavBar)
	}
}

// MARK: - CreatePersonaCoordinator.View
extension CreatePersonaCoordinator {
	struct ViewState: Sendable, Equatable {
		let shouldDisplayNavBar: Bool
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<CreatePersonaCoordinator>

		init(store: StoreOf<CreatePersonaCoordinator>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStackStore(
					store.scope(state: \.path, action: { .child(.path($0)) })
				) {
					IfLetStore(
						store.scope(state: \.root, action: { .child(.root($0)) })
					) {
						destination(for: $0, shouldDisplayNavBar: viewStore.shouldDisplayNavBar)
							.toolbar {
								if viewStore.shouldDisplayNavBar {
									ToolbarItem(placement: .navigationBarLeading) {
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
			}
		}

		private func destination(
			for store: StoreOf<CreatePersonaCoordinator.Path>,
			shouldDisplayNavBar: Bool
		) -> some SwiftUI.View {
			ZStack {
				SwitchStore(store) { state in
					switch state {
					case .step0_introduction:
						IntroductionToPersonasView {
							self.store.send(.view(.introductionContinueButtonTapped))
						}

					case .step1_createPersona:
						CaseLet(
							/CreatePersonaCoordinator.Path.State.step1_createPersona,
							action: CreatePersonaCoordinator.Path.Action.step1_createPersona,
							then: { EditPersona.View(store: $0) }
						)

					case .step2_completion:
						CaseLet(
							/CreatePersonaCoordinator.Path.State.step2_completion,
							action: CreatePersonaCoordinator.Path.Action.step2_completion,
							then: { NewPersonaCompletion.View(store: $0) }
						)
					}
				}
			}
			.navigationBarBackButtonHidden(!shouldDisplayNavBar)
			.navigationBarHidden(!shouldDisplayNavBar)
		}
	}
}
