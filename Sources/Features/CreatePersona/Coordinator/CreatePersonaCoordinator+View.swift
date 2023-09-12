import FeaturePrelude

extension CreatePersonaCoordinator.State {
	fileprivate var viewState: CreatePersonaCoordinator.ViewState {
		.init(shouldDisplayNavBar: shouldDisplayNavBar)
	}
}

// MARK: - CreatePersonaCoordinator.View
extension CreatePersonaCoordinator {
	public struct ViewState: Sendable, Equatable {
		let shouldDisplayNavBar: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreatePersonaCoordinator>

		public init(store: StoreOf<CreatePersonaCoordinator>) {
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
						#if os(iOS)
							.toolbar {
								if viewStore.shouldDisplayNavBar {
									ToolbarItem(placement: .navigationBarLeading) {
										CloseButton {
											store.send(.view(.closeButtonTapped))
										}
									}
								}
							}
						#endif
					}
					// This is required to disable the animation of internal components during transition
					.transaction { $0.animation = nil }
				} destination: {
					destination(for: $0, shouldDisplayNavBar: viewStore.shouldDisplayNavBar)
				}
				#if os(iOS)
				.navigationTransition(.slide, interactivity: .disabled)
				#endif // iOS
			}
		}

		private func destination(
			for store: StoreOf<CreatePersonaCoordinator.Destinations>,
			shouldDisplayNavBar: Bool
		) -> some SwiftUI.View {
			ZStack {
				SwitchStore(store) { state in
					switch state {
					case .step0_introduction:
						CaseLet(
							state: /CreatePersonaCoordinator.Destinations.State.step0_introduction,
							action: CreatePersonaCoordinator.Destinations.Action.step0_introduction,
							then: { IntroductionToPersonas.View(store: $0) }
						)

					case .step1_newPersonaInfo:
						CaseLet(
							state: /CreatePersonaCoordinator.Destinations.State.step1_newPersonaInfo,
							action: CreatePersonaCoordinator.Destinations.Action.step1_newPersonaInfo,
							then: { NewPersonaInfo.View(store: $0) }
						)

					case .step2_creationOfPersona:
						CaseLet(
							state: /CreatePersonaCoordinator.Destinations.State.step2_creationOfPersona,
							action: CreatePersonaCoordinator.Destinations.Action.step2_creationOfPersona,
							then: { CreationOfPersona.View(store: $0) }
						)

					case .step3_completion:
						CaseLet(
							state: /CreatePersonaCoordinator.Destinations.State.step3_completion,
							action: CreatePersonaCoordinator.Destinations.Action.step3_completion,
							then: { NewPersonaCompletion.View(store: $0) }
						)
					}
				}
			}
			#if os(iOS)
			.navigationBarBackButtonHidden(!shouldDisplayNavBar)
			.navigationBarHidden(!shouldDisplayNavBar)
			#endif // iOS
		}
	}
}
