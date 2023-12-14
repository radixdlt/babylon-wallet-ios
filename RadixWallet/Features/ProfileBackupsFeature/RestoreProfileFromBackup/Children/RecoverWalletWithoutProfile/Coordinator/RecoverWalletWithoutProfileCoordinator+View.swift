// MARK: - RecoverWalletWithoutProfileCoordinator.View
public extension RecoverWalletWithoutProfileCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletWithoutProfileCoordinator>

		public init(store: StoreOf<RecoverWalletWithoutProfileCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				IfLetStore(
					store.scope(state: \.root, action: { .child(.root($0)) })
				) {
					path(for: $0)
				}
			} destination: {
				path(for: $0)
			}
			.destinations(with: store)
		}

		private func path(
			for store: StoreOf<RecoverWalletWithoutProfileCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .start:
					CaseLet(
						/RecoverWalletWithoutProfileCoordinator.Path.State.start,
						action: RecoverWalletWithoutProfileCoordinator.Path.Action.start,
						then: { RecoverWalletWithoutProfileStart.View(store: $0) }
					)
				case .recoverWalletControlWithBDFSOnly:
					CaseLet(
						/RecoverWalletWithoutProfileCoordinator.Path.State.recoverWalletControlWithBDFSOnly,
						action: RecoverWalletWithoutProfileCoordinator.Path.Action.recoverWalletControlWithBDFSOnly,
						then: { RecoverWalletControlWithBDFSOnly.View(store: $0) }
					)
				case .importMnemonic:
					CaseLet(
						/RecoverWalletWithoutProfileCoordinator.Path.State.importMnemonic,
						action: RecoverWalletWithoutProfileCoordinator.Path.Action.importMnemonic,
						then: { ImportMnemonic.View(store: $0) }
					)

				case .recoveryComplete:
					CaseLet(
						/RecoverWalletWithoutProfileCoordinator.Path.State.recoveryComplete,
						action: RecoverWalletWithoutProfileCoordinator.Path.Action.recoveryComplete,
						then: { RecoverWalletControlWithBDFSComplete.View(store: $0) }
					)
				}
			}
		}
	}
}

private extension StoreOf<RecoverWalletWithoutProfileCoordinator> {
	var destination: PresentationStoreOf<RecoverWalletWithoutProfileCoordinator.Destination> {
		func scopeState(state: State) -> PresentationState<RecoverWalletWithoutProfileCoordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

private extension View {
	@MainActor
	func destinations(with store: StoreOf<RecoverWalletWithoutProfileCoordinator>) -> some View {
		let destinationStore = store.destination
		return fullScreenCover(
			store: destinationStore,
			state: /RecoverWalletWithoutProfileCoordinator.Destination.State.accountRecoveryScanCoordinator,
			action: RecoverWalletWithoutProfileCoordinator.Destination.Action.accountRecoveryScanCoordinator,
			content: {
				AccountRecoveryScanCoordinator.View(store: $0)
					.inNavigationStack
			}
		)
	}
}
