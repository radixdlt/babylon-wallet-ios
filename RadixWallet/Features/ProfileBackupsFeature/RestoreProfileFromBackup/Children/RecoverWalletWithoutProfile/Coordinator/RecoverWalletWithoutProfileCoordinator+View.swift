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
				RecoverWalletWithoutProfileStart.View(store: store.scope(
					state: \.root,
					action: { .child(.root($0)) }
				))
			} destination: {
				path(for: $0)
			}
		}

		private func path(
			for store: StoreOf<RecoverWalletWithoutProfileCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
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

				case .accountRecoveryScanCoordinator:
					CaseLet(
						/RecoverWalletWithoutProfileCoordinator.Path.State.accountRecoveryScanCoordinator,
						action: RecoverWalletWithoutProfileCoordinator.Path.Action.accountRecoveryScanCoordinator,
						then: { AccountRecoveryScanCoordinator.View(store: $0) }
					)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - RecoverWalletWithoutProfileCoordinator_Preview

struct RecoverWalletWithoutProfileCoordinator_Preview: PreviewProvider {
	static var previews: some View {
		RecoverWalletWithoutProfileCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: RecoverWalletWithoutProfileCoordinator.init
			)
		)
	}
}

public extension RecoverWalletWithoutProfileCoordinator.State {
	static let previewValue = Self()
}
#endif
