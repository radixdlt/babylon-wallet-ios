import FeaturePrelude

extension CreateEntityCoordinator.State {
	fileprivate var viewState: CreateEntityCoordinator.ViewState {
		.init(shouldDisplayNavBar: shouldDisplayNavBar)
	}
}

// MARK: - CreateEntityCoordinator.View
extension CreateEntityCoordinator {
	public struct ViewState: Sendable, Equatable {
		let shouldDisplayNavBar: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreateEntityCoordinator>

		public init(store: StoreOf<CreateEntityCoordinator>) {
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
						destination(for: $0)
						#if os(iOS)
							.toolbar {
								if viewStore.shouldDisplayNavBar {
									ToolbarItem(placement: .navigationBarLeading) {
										CloseButton {
											ViewStore(store.stateless).send(.view(.closeButtonTapped))
										}
									}
								}
							}
						#endif
					}
					// This is required to disable the animation of internal components during transition
					.transaction { $0.animation = nil }
				} destination: {
					destination(for: $0)
				}
				#if os(iOS)
				.navigationTransition(.slide, interactivity: .disabled)
				.navigationBarHidden(!viewStore.shouldDisplayNavBar)
				#endif
			}
		}

		private func destination(
			for store: StoreOf<CreateEntityCoordinator.Destinations>
		) -> some SwiftUI.View {
			ZStack {
				SwitchStore(store) {
					CaseLet(
						state: /CreateEntityCoordinator.Destinations.State.step0_introduction,
						action: CreateEntityCoordinator.Destinations.Action.step0_introduction,
						then: { IntroductionToEntity.View(store: $0) }
					)
					CaseLet(
						state: /CreateEntityCoordinator.Destinations.State.step1_nameNewEntity,
						action: CreateEntityCoordinator.Destinations.Action.step1_nameNewEntity,
						then: { NameNewEntity.View(store: $0) }
					)
					CaseLet(
						state: /CreateEntityCoordinator.Destinations.State.step2_creationOfEntity,
						action: CreateEntityCoordinator.Destinations.Action.step2_creationOfEntity,
						then: { CreationOfEntity.View(store: $0) }
					)
					CaseLet(
						state: /CreateEntityCoordinator.Destinations.State.step3_completion,
						action: CreateEntityCoordinator.Destinations.Action.step3_completion,
						then: { NewEntityCompletion.View(store: $0) }
					)
				}
			}
		}
	}
}
