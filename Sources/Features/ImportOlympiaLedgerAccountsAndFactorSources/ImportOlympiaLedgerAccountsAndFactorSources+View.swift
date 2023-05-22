import AddLedgerFactorSourceFeature
import FeaturePrelude

extension ImportOlympiaLedgerAccountsAndFactorSources.State {
	var viewState: ImportOlympiaLedgerAccountsAndFactorSources.ViewState {
		.init(
			numberOfUnverifiedAccounts: unverified.count,
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
					Text("#\(viewStore.numberOfUnverifiedAccounts) accounts left to import")
						.textStyle(.body1Header)

					Spacer()

					if !viewStore.ledgersWithAccounts.isEmpty {
						Text("Imported ledgers and accounts")
						ScrollView {
							ForEach(viewStore.ledgersWithAccounts, id: \.self) { ledgerWithAccounts in
								LazyVStack {
									Text("\(ledgerWithAccounts.displayName) (new? \(ledgerWithAccounts.isLedgerNew ? "yes" : "no")) - #\(ledgerWithAccounts.migratedAccounts.count) accounts")
								}
							}
						}
					}

					Spacer()
				}
				.sheet(
					store: store.scope(
						state: \.$addLedgerFactorSource,
						action: { .child(.addLedgerFactorSource($0)) }
					),
					content: {
						AddLedgerFactorSource.View(store: $0)
					}
				)

				.padding(.horizontal, .medium3)
			}
		}
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
