import FeaturePrelude

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
						destination(for: $0, with: viewStore)
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
					destination(for: $0, with: viewStore)
				}
				#if os(iOS)
				.navigationTransition(.slide, interactivity: .disabled)
				#endif // iOS
			}
		}

		private func destination(
			for store: StoreOf<CreateAccountCoordinator.Destinations>,
			with viewStore: ViewStoreOf<CreateAccountCoordinator>
		) -> some SwiftUI.View {
			ZStack {
				SwitchStore(store) {
					CaseLet(
						state: /CreateAccountCoordinator.Destinations.State.step1_nameAccount,
						action: CreateAccountCoordinator.Destinations.Action.step1_nameAccount,
						then: { NameAccount.View(store: $0) }
					)
					CaseLet(
						state: /CreateAccountCoordinator.Destinations.State.step2_creationOfAccount,
						action: CreateAccountCoordinator.Destinations.Action.step2_creationOfAccount,
						then: { CreationOfAccount.View(store: $0) }
					)
					CaseLet(
						state: /CreateAccountCoordinator.Destinations.State.step3_completion,
						action: CreateAccountCoordinator.Destinations.Action.step3_completion,
						then: { NewAccountCompletion.View(store: $0) }
					)
				}
			}
			#if os(iOS)
			.navigationBarBackButtonHidden(!viewStore.shouldDisplayNavBar)
			.navigationBarHidden(!viewStore.shouldDisplayNavBar)
			#endif // iOS
		}
	}
}
