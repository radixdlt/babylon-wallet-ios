import AddLedgerFactorSourceFeature
import DerivePublicKeysFeature
import FeaturePrelude
import LedgerHardwareDevicesFeature

extension ImportOlympiaLedgerAccountsAndFactorSources.State {
	var viewState: ImportOlympiaLedgerAccountsAndFactorSources.ViewState {
		.init(
			numberOfUnverifiedAccounts: unmigrated.unvalidated.count,
			ledgersWithAccounts: ledgersWithAccounts
		)
	}
}

// MARK: - ImportOlympiaLedgerAccountsAndFactorSources.View
extension ImportOlympiaLedgerAccountsAndFactorSources {
	public struct ViewState: Equatable {
		public let numberOfUnverifiedAccounts: Int
		public let ledgersWithAccounts: OrderedSet<LedgerWithAccounts>
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSources>

		public init(store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSources>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Text(L10n.ImportOlympiaLedgerAccounts.unverifiedAccountsLeft(viewStore.numberOfUnverifiedAccounts))
						.textStyle(.body1Header)

					Spacer()

					if !viewStore.ledgersWithAccounts.isEmpty {
						Text(L10n.ImportOlympiaLedgerAccounts.importLedgersAndAccounts)

						ScrollView {
							ForEach(viewStore.ledgersWithAccounts, id: \.self) { _ in
								LazyVStack {
//									Text(L10n.ImportOlympiaLedgerAccounts.accountCount(ledgerWithAccounts.displayName, ledgerWithAccounts.migratedAccounts.count))
								}
							}
						}
					}

					Spacer()

					LedgerHardwareDevices.View(
						store: store.scope(
							state: \.chooseLedger,
							action: { .child(.chooseLedger($0)) }
						)
					)
				}
				.sheet(
					store: store.destination,
					state: /ImportOlympiaLedgerAccountsAndFactorSources.Destinations.State.derivePublicKeys,
					action: ImportOlympiaLedgerAccountsAndFactorSources.Destinations.Action.derivePublicKeys,
					content: { DerivePublicKeys.View(store: $0) }
				)
				.padding(.horizontal, .medium3)
			}
		}
	}
}

private extension StoreOf<ImportOlympiaLedgerAccountsAndFactorSources> {
	var destination: PresentationStoreOf<ImportOlympiaLedgerAccountsAndFactorSources.Destinations> {
		scope(state: \.$destinations, action: { .child(.destinations($0)) })
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - ImportOlympiaLedgerAccountsAndFactorSource_Preview
// struct ImportOlympiaLedgerAccountsAndFactorSource_Preview: PreviewProvider {
//	static var previews: some View {
//		ImportOlympiaLedgerAccountsAndFactorSources.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: ImportOlympiaLedgerAccountsAndFactorSources()
//			)
//		)
//	}
// }
//
// extension ImportOlympiaLedgerAccountsAndFactorSources.State {
//    public static let previewValue = Self(hardwareAccounts: <#NonEmpty<OrderedSet<OlympiaAccountToMigrate>>#>)
// }
// #endif
