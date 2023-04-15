import FeaturePrelude
import ImportOlympiaLedgerAccountsAndFactorSourceFeature

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
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				IfLetStore(
					store.scope(state: \.root, action: { .child(.root($0)) })
				) {
					destination(for: $0)
					#if os(iOS)
						.toolbar {
							ToolbarItem(placement: .navigationBarLeading) {
								CloseButton {
									ViewStore(store.stateless).send(.view(.closeButtonTapped))
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
			#endif
		}

		private func destination(
			for store: StoreOf<ImportOlympiaWalletCoordinator.Destinations>
		) -> some SwiftUI.View {
			ZStack {
				SwitchStore(store) {
					CaseLet(
						state: /ImportOlympiaWalletCoordinator.Destinations.State.scanMultipleOlympiaQRCodes,
						action: ImportOlympiaWalletCoordinator.Destinations.Action.scanMultipleOlympiaQRCodes,
						then: { ScanMultipleOlympiaQRCodes.View(store: $0) }
					)
					CaseLet(
						state: /ImportOlympiaWalletCoordinator.Destinations.State.selectAccountsToImport,
						action: ImportOlympiaWalletCoordinator.Destinations.Action.selectAccountsToImport,
						then: { SelectAccountsToImport.View(store: $0) }
					)
					CaseLet(
						state: /ImportOlympiaWalletCoordinator.Destinations.State.importOlympiaMnemonic,
						action: ImportOlympiaWalletCoordinator.Destinations.Action.importOlympiaMnemonic,
						then: { ImportOlympiaFactorSource.View(store: $0) }
					)
					CaseLet(
						state: /ImportOlympiaWalletCoordinator.Destinations.State.addLedgerNanoFactorSource,
						action: ImportOlympiaWalletCoordinator.Destinations.Action.addLedgerNanoFactorSource,
						then: { ImportOlympiaLedgerAccountsAndFactorSource.View(store: $0) }
					)
					CaseLet(
						state: /ImportOlympiaWalletCoordinator.Destinations.State.validateOlympiaHardwareAccounts,
						action: ImportOlympiaWalletCoordinator.Destinations.Action.validateOlympiaHardwareAccounts,
						then: { ValidateOlympiaHardwareAccounts.View(store: $0) }
					)
					CaseLet(
						state: /ImportOlympiaWalletCoordinator.Destinations.State.completion,
						action: ImportOlympiaWalletCoordinator.Destinations.Action.completion,
						then: { CompletionMigrateOlympiaAccountsToBabylon.View(store: $0) }
					)
				}
			}
			.navigationTitle(L10n.ImportLegacyWallet.Flow.navigationTitle)
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
