import AddLedgerFactorSourceFeature
import DerivePublicKeysFeature
import FeaturePrelude
import LedgerHardwareDevicesFeature

extension ImportOlympiaLedgerAccountsAndFactorSources.State {
	var viewState: ImportOlympiaLedgerAccountsAndFactorSources.ViewState {
		.init(
			ledgerControlledAccounts: olympiaAccounts.unvalidated.count + olympiaAccounts.validated.count,
			knownLedgers: knownLedgers,
			moreAccounts: olympiaAccounts.unvalidated.count
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
				ScrollView(showsIndicators: false) {
					VStack(alignment: .center, spacing: .medium2) {
						Text("Confirm Ledgers") // FIXME: Strings
							.textStyle(.sheetTitle)
							.padding(.top, .small1)

						Text("\(viewStore.ledgerControlledAccounts) of your accounts are controlled by Ledger Hardware Wallets") // FIXME: Strings
							.textStyle(.body1Header)
							.padding(.horizontal, .large3)

						Text("Currently Known Ledgers:") // FIXME: Strings
							.textStyle(.body1Header)

						if viewStore.knownLedgers.isEmpty {
							Card(.app.gray5) {
								Text("None") // FIXME: Strings
									.textStyle(.secondaryHeader)
									.frame(height: .largeButtonHeight)
									.frame(maxWidth: .infinity)
							}
							.padding(.horizontal, .medium3)
						} else {
							ForEach(viewStore.knownLedgers) { ledger in
								VStack(spacing: .small1) {
									LedgerRowView(viewState: .init(factorSource: ledger))
										.padding(.horizontal, .medium3)
								}
							}
						}

						if viewStore.moreAccounts > 0 {
							Text("\(viewStore.moreAccounts) more accounts are controlled by other devices. Connect a Ledger hardware wallet device and tap Continue.") // FIXME: Strings
								.textStyle(.body1Regular)
								.padding(.horizontal, .large3)
						}

						Spacer(minLength: 0)
					}
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
				}
				.footer(visible: viewStore.moreAccounts > 0) {
					Button("Continue") { // FIXME: Strings
						viewStore.send(.continueTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.sheet(
					store: store.destination,
					state: /ImportOlympiaLedgerAccountsAndFactorSources.Destinations.State.derivePublicKeys,
					action: ImportOlympiaLedgerAccountsAndFactorSources.Destinations.Action.derivePublicKeys,
					content: { DerivePublicKeys.View(store: $0) }
				)
				.sheet(
					store: store.destination,
					state: /ImportOlympiaLedgerAccountsAndFactorSources.Destinations.State.nameLedger,
					action: ImportOlympiaLedgerAccountsAndFactorSources.Destinations.Action.nameLedger,
					content: { NameLedgerFactorSource.View(store: $0) }
				)
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
