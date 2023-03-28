import FeaturePrelude

extension ImportOlympiaWalletCoordinator.State {
	var viewState: ImportOlympiaWalletCoordinator.ViewState {
		.init()
	}
}

// MARK: - ImportOlympiaWalletCoordinator.View
extension ImportOlympiaWalletCoordinator {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaWalletCoordinator>

		public init(store: StoreOf<ImportOlympiaWalletCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				SwitchStore(store.scope(state: \.step)) {
					CaseLet(
						state: /ImportOlympiaWalletCoordinator.State.Step.scanMultipleOlympiaQRCodes,
						action: { ImportOlympiaWalletCoordinator.Action.child(.scanMultipleOlympiaQRCodes($0)) },
						then: { ScanMultipleOlympiaQRCodes.View(store: $0) }
					)
					CaseLet(
						state: /ImportOlympiaWalletCoordinator.State.Step.selectAccountsToImport,
						action: { ImportOlympiaWalletCoordinator.Action.child(.selectAccountsToImport($0)) },
						then: { SelectAccountsToImport.View(store: $0) }
					)
					CaseLet(
						state: /ImportOlympiaWalletCoordinator.State.Step.importOlympiaMnemonic,
						action: { ImportOlympiaWalletCoordinator.Action.child(.importOlympiaMnemonic($0)) },
						then: { ImportOlympiaFactorSource.View(store: $0) }
					)
					CaseLet(
						state: /ImportOlympiaWalletCoordinator.State.Step.completion,
						action: { ImportOlympiaWalletCoordinator.Action.child(.completion($0)) },
						then: { CompletionMigrateOlympiaAccountsToBabylon.View(store: $0) }
					)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ImportOlympiaWalletCoordinator_Preview
struct ImportOlympiaWalletCoordinator_Preview: PreviewProvider {
	static var previews: some View {
		ImportOlympiaWalletCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: ImportOlympiaWalletCoordinator()
			)
		)
	}
}

extension ImportOlympiaWalletCoordinator.State {
	public static let previewValue = Self()
}
#endif
