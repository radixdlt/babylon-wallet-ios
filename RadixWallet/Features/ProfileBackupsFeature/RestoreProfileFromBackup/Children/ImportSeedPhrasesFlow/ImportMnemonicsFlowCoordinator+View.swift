import ComposableArchitecture
import SwiftUI

// MARK: - ImportMnemonicsFlowCoordinator.View
extension ImportMnemonicsFlowCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportMnemonicsFlowCoordinator>

		public init(store: StoreOf<ImportMnemonicsFlowCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			Group {
				NavigationStackStore(
					store.scope(state: \.path, action: { .child(.path($0)) })
				) {
					path(for: store.scope(state: \.root, action: { .child(.root($0)) }))
				} destination: {
					path(for: $0)
						.toolbar {
							ToolbarItem(placement: .cancellationAction) {
								CloseButton {
									store.send(.view(.closeButtonTapped))
								}
							}
						}
				}
				.onFirstTask { @MainActor in
					await store.send(.view(.onFirstTask)).finish()
				}
			}
			.withNavigationBar {
				store.send(.view(.closeButtonTapped))
			}
		}

		private func path(
			for store: StoreOf<ImportMnemonicsFlowCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .loading:
					ProgressView()
				case .importMnemonicControllingAccounts:
					CaseLet(
						/ImportMnemonicsFlowCoordinator.Path.State.importMnemonicControllingAccounts,
						action: ImportMnemonicsFlowCoordinator.Path.Action.importMnemonicControllingAccounts,
						then: { ImportMnemonicControllingAccounts.View(store: $0).navigationBarBackButtonHidden() }
					)
				}
			}
		}
	}
}
