import AddLedgerFactorSourceFeature
import DerivePublicKeysFeature
import FeaturePrelude
import LedgerHardwareDevicesFeature

extension ImportOlympiaLedgerAccountsAndFactorSources.State {
	var viewState: ImportOlympiaLedgerAccountsAndFactorSources.ViewState {
		.init(
			ledgerControlledAccounts: olympiaACcounts.unvalidated.count + olympiaACcounts.validated.count,
			knownLedgers: knownLedgers,
			moreAccounts: olympiaACcounts.unvalidated.count
		)
	}
}

// MARK: - ImportOlympiaLedgerAccountsAndFactorSources.View
extension ImportOlympiaLedgerAccountsAndFactorSources {
	public struct ViewState: Equatable {
		public let ledgerControlledAccounts: Int
		public let knownLedgers: IdentifiedArrayOf<LedgerHardwareWalletFactorSource>
		public let moreAccounts: Int
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSources>

		public init(store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSources>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .center) {
					Text("Confirm Ledgers") // FIXME: Strings
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
						.multilineTextAlignment(.center)
						.padding(.top, .small1)
						.padding(.bottom, .medium2)

					Text("\(viewStore.ledgerControlledAccounts) of your accounts are controlled by Ledger Hardware Wallets") // FIXME: Strings
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)
						.multilineTextAlignment(.center)
						.padding(.horizontal, .large3)
						.padding(.bottom, .medium3)

					Text("Currently Known Ledgers") // FIXME: Strings
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)
						.padding(.bottom, .medium3)

					if viewStore.knownLedgers.isEmpty {
						Card(.app.gray5) {
							Text("None") // FIXME: Strings
						}
						.padding(.horizontal, .medium1)

					} else {
						ForEach(viewStore.knownLedgers) { ledger in
							VStack(spacing: .small1) {
								LedgerRowView(viewState: .init(factorSource: ledger))
									.padding(.horizontal, .medium1)
							}
						}
						.padding(.bottom, .medium3)
					}

					Text("\(viewStore.moreAccounts) more accounts are controlled by other devices. Connect a Ledger hardware wallet device and tap Continue.") // FIXME: Strings
						.padding(.horizontal, .large3)

					Button("Continue") { // FIXME: Strings
						viewStore.send(.continueTapped)
					}
					.buttonStyle(.primaryRectangular)

//					Text(L10n.ImportOlympiaLedgerAccounts.unverifiedAccountsLeft(viewStore.numberOfUnverifiedAccounts))
//						.textStyle(.body1Header)
//
//					Spacer()
//
//					if !viewStore.ledgersWithAccounts.isEmpty {
//						Text(L10n.ImportOlympiaLedgerAccounts.importLedgersAndAccounts)
//
//						ScrollView {
//							ForEach(viewStore.ledgersWithAccounts, id: \.self) { ledgerWithAccounts in
//								LazyVStack {
//									Text(L10n.ImportOlympiaLedgerAccounts.accountCount(ledgerWithAccounts.displayName, ledgerWithAccounts.migratedAccounts.count))
//								}
//							}
//						}
//					}
//
//					Spacer()
//
//					LedgerHardwareDevices.View(
//						store: store.scope(
//							state: \.chooseLedger,
//							action: { .child(.chooseLedger($0)) }
//						)
//					)
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
