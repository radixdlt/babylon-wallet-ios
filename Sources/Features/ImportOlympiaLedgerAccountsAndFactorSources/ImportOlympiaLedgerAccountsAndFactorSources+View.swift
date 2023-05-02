import FeaturePrelude

extension ImportOlympiaLedgerAccountsAndFactorSources.State {
	var viewState: ImportOlympiaLedgerAccountsAndFactorSources.ViewState {
		.init(
			failedToFindAnyLinks: failedToFindAnyLinks,
			ledgerName: ledgerName,
			modelOfLedgerToName: unnamedDeviceToAdd?.model,
			numberOfUnverifiedAccounts: unverified.count,
			ledgersWithAccounts: ledgersWithAccounts,
			viewControlState: isWaitingForResponseFromLedger ? .loading(.global(text: "Waiting for ledger response")) : .enabled
		)
	}
}

// MARK: - ImportOlympiaLedgerAccountsAndFactorSources.View
extension ImportOlympiaLedgerAccountsAndFactorSources {
	public struct ViewState: Equatable {
		public let failedToFindAnyLinks: Bool
		public let ledgerName: String
		public let modelOfLedgerToName: P2P.LedgerHardwareWallet.Model?
		public let numberOfUnverifiedAccounts: Int
		public let ledgersWithAccounts: OrderedSet<LedgerWithAccounts>
		public let viewControlState: ControlState
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

					if viewStore.failedToFindAnyLinks {
						Text("⚠️ Found no open RadixConnect connections. Either open your previously linked browser or Go to settings and link to a new browser.")
					}

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

					if let model = viewStore.modelOfLedgerToName {
						VStack {
							nameLedgerField(with: viewStore, model: model)

							Button("Confirm name") {
								viewStore.send(.confirmNameButtonTapped)
							}
							.buttonStyle(.primaryRectangular)

							Button("Skip name") {
								viewStore.send(.skipNamingLedgerButtonTapped)
							}
							.buttonStyle(.secondaryRectangular(shouldExpand: true))
						}
					} else {
						Button("Send Add Ledger Request") {
							viewStore.send(.sendAddLedgerRequestButtonTapped)
						}
						.controlState(viewStore.viewControlState)
						.buttonStyle(.primaryRectangular)

						Button("Skip remaining accounts") {
							viewStore.send(.skipRestOfTheAccounts)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
					}
				}
				.padding(.horizontal, .medium3)
				.task { @MainActor in await ViewStore(store.stateless).send(.view(.task)).finish()
				}
			}
		}

		@ViewBuilder
		private func nameLedgerField(
			with viewStore: ViewStoreOf<ImportOlympiaLedgerAccountsAndFactorSources>,
			model: P2P.LedgerHardwareWallet.Model
		) -> some SwiftUI.View {
			VStack {
				Text("Found ledger model: '\(model.rawValue)'")
				AppTextField(
					primaryHeading: "Name your Ledger",
					secondaryHeading: "e.g. 'scratch'",
					placeholder: "scratched",
					text: .init(
						get: { viewStore.ledgerName },
						set: { viewStore.send(.ledgerNameChanged($0)) }
					),
					hint: .info("Displayed when you are prompted to sign with this.")
				)
				.padding()
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
