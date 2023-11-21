// MARK: - AccountRecoveryScanCoordinator.View
public extension AccountRecoveryScanCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountRecoveryScanCoordinator>

		public init(store: StoreOf<AccountRecoveryScanCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				AccountRecoveryScanStart.View(store: store.scope(
					state: \.root,
					action: { .child(.root($0)) }
				))
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						CloseButton {
							self.store.send(.view(.closeTapped))
						}
					}
				}
			} destination: {
				path(for: $0)
			}
		}

		private func path(
			for store: StoreOf<AccountRecoveryScanCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .end:
					CaseLet(
						/AccountRecoveryScanCoordinator.Path.State.end,
						action: AccountRecoveryScanCoordinator.Path.Action.end,
						then: { AccountRecoveryScanEnd.View(store: $0) }
					)
				}
			}
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					CloseButton {
						self.store.send(.view(.closeTapped))
					}
				}
			}
		}
	}
}
