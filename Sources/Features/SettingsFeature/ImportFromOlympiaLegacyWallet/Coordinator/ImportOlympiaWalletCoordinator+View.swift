import FeaturePrelude
import ImportOlympiaLedgerAccountsAndFactorSourcesFeature

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
					Destinations.View(store: $0)
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
				Destinations.View(store: $0)
			}
			#if os(iOS)
			.navigationTransition(.slide, interactivity: .disabled)
			#endif
		}
	}
}

// MARK: - ImportOlympiaWalletCoordinator.Destinations.View
extension ImportOlympiaWalletCoordinator.Destinations {
	struct View: SwiftUI.View {
		let store: StoreOf<ImportOlympiaWalletCoordinator.Destinations>

		var body: some SwiftUI.View {
			ZStack {
				SwitchStore(store) {
					CaseLet(
						state: /State.scanMultipleOlympiaQRCodes,
						action: Action.scanMultipleOlympiaQRCodes,
						then: { ScanMultipleOlympiaQRCodes.View(store: $0) }
					)
					CaseLet(
						state: /State.selectAccountsToImport,
						action: Action.selectAccountsToImport,
						then: { SelectAccountsToImport.View(store: $0) }
					)
					CaseLet(
						state: /State.importOlympiaMnemonic,
						action: Action.importOlympiaMnemonic,
						then: { ImportOlympiaFactorSource.View(store: $0) }
					)
					CaseLet(
						state: /State.importOlympiaLedgerAccountsAndFactorSources,
						action: Action.importOlympiaLedgerAccountsAndFactorSources,
						then: { ImportOlympiaLedgerAccountsAndFactorSources.View(store: $0) }
					)
					CaseLet(
						state: /State.completion,
						action: Action.completion,
						then: { CompletionMigrateOlympiaAccountsToBabylon.View(store: $0) }
					)
				}
			}
			.navigationTitle(L10n.ImportLegacyWallet.title)
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
