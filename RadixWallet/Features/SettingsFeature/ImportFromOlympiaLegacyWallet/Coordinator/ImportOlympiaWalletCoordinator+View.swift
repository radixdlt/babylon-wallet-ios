import ComposableArchitecture
import SwiftUI

// MARK: - ImportOlympiaWalletCoordinator.View
extension ImportOlympiaWalletCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaWalletCoordinator>

		public init(store: StoreOf<ImportOlympiaWalletCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStackStore(store.scope(state: \.path, action: { .child(.path($0)) })) {
				let scanQRStore = store.scope(state: \.scanQR, action: { .child(.scanQR($0)) })
				ScanMultipleOlympiaQRCodes.View(store: scanQRStore)
					.toolbar {
						ToolbarItem(placement: .primaryAction) {
							CloseButton {
								store.send(.view(.closeButtonTapped))
							}
						}
					}
					// This is required to disable the animation of internal components during transition
					.transaction { $0.animation = nil }
			} destination: {
				Path.View(store: $0)
			}
			.navigationTransition(.slide, interactivity: .disabled)
		}
	}
}

// MARK: - ImportOlympiaWalletCoordinator.Path.View
extension ImportOlympiaWalletCoordinator.Path {
	struct View: SwiftUI.View {
		let store: StoreOf<ImportOlympiaWalletCoordinator.Path>

		var body: some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .accountsToImport:
					CaseLet(
						/State.accountsToImport,
						action: Action.accountsToImport,
						then: { AccountsToImport.View(store: $0) }
					)
				case .importMnemonic:
					CaseLet(
						/State.importMnemonic,
						action: Action.importMnemonic,
						then: { ImportMnemonic.View(store: $0) }
					)
				case .importOlympiaLedgerAccountsAndFactorSources:
					CaseLet(
						/State.importOlympiaLedgerAccountsAndFactorSources,
						action: Action.importOlympiaLedgerAccountsAndFactorSources,
						then: { ImportOlympiaLedgerAccountsAndFactorSources.View(store: $0) }
					)
				case .completion:
					CaseLet(
						/State.completion,
						action: Action.completion,
						then: { CompletionMigrateOlympiaAccountsToBabylon.View(store: $0) }
					)
				}
			}
		}
	}
}

#if DEBUG

// MARK: - ImportOlympiaWalletCoordinator_Preview
struct ImportOlympiaWalletCoordinator_Preview: PreviewProvider {
	static var previews: some View {
		ImportOlympiaWalletCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: ImportOlympiaWalletCoordinator.init
			)
		)
	}
}

extension ImportOlympiaWalletCoordinator.State {
	public static let previewValue = Self()
}
#endif
