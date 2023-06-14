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
					destination(
						for: store.scope(state: \.root, action: { .child(.root($0)) }),
						shouldDisplayNavBar: viewStore.shouldDisplayNavBar
					)
					#if os(iOS)
					.toolbar {
						if viewStore.shouldDisplayNavBar {
							ToolbarItem(placement: .primaryAction) {
								CloseButton {
									ViewStore(store.stateless).send(.view(.closeButtonTapped))
								}
							}
						}
					}
					#endif
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
			for store: StoreOf<CreateAccountCoordinator.Path>,
			shouldDisplayNavBar: Bool
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .step1_nameAccount:
					CaseLet(
						state: /CreateAccountCoordinator.Path.State.step1_nameAccount,
						action: CreateAccountCoordinator.Path.Action.step1_nameAccount,
						then: { NameAccount.View(store: $0) }
					)
				case .step2_creationOfAccount:
					CaseLet(
						state: /CreateAccountCoordinator.Path.State.step2_creationOfAccount,
						action: CreateAccountCoordinator.Path.Action.step2_creationOfAccount,
						then: { CreationOfAccount.View(store: $0) }
					)
				case .step3_completion:
					CaseLet(
						state: /CreateAccountCoordinator.Path.State.step3_completion,
						action: CreateAccountCoordinator.Path.Action.step3_completion,
						then: { NewAccountCompletion.View(store: $0) }
					)
				}
			}
			#if os(iOS)
			.navigationBarBackButtonHidden(!shouldDisplayNavBar)
			.navigationBarHidden(!shouldDisplayNavBar)
			#endif // iOS
		}
	}
}
