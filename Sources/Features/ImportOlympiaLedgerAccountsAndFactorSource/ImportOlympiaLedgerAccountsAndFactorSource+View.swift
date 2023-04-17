import FeaturePrelude

extension ImportOlympiaLedgerAccountsAndFactorSource.State {
	var viewState: ImportOlympiaLedgerAccountsAndFactorSource.ViewState {
		.init(
			failedToFindAnyLinks: failedToFindAnyLinks,
			ledgerName: ledgerName,
			isLedgerNameInputVisible: isLedgerNameInputVisible,
			numberOfUnverifiedAccounts: unverified.count,
			addedLedgersWithAccounts: addedLedgersWithAccounts,
			viewControlState: isWaitingForResponseFromLedger ? .loading(.global(text: "Waiting for ledger response")) : .enabled
		)
	}
}

// MARK: - ImportOlympiaLedgerAccountsAndFactorSource.View
extension ImportOlympiaLedgerAccountsAndFactorSource {
	public struct ViewState: Equatable {
		public let failedToFindAnyLinks: Bool
		public let ledgerName: String
		public let isLedgerNameInputVisible: Bool
		//        public let isWaitingForResponseFromLedger: Bool
		public let numberOfUnverifiedAccounts: Int
		public let addedLedgersWithAccounts: OrderedSet<AddedLedgerWithAccounts>
		public let viewControlState: ControlState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSource>

		public init(store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Text("#\(viewStore.numberOfUnverifiedAccounts) accounts left to import")
						.textStyle(.body1Header)

					if viewStore.failedToFindAnyLinks {
						Text("⚠️ Found no RadixConnect linked browsers, go to settings and link first")
					}

					Spacer()

					if !viewStore.addedLedgersWithAccounts.isEmpty {
						Text("Imported ledgers and accounts")
						ScrollView {
							ForEach(viewStore.addedLedgersWithAccounts, id: \.self) { addedLedgerWithAccounts in
								LazyVStack {
									Text("\(addedLedgerWithAccounts.displayName) - #\(addedLedgerWithAccounts.migratedAccounts.count) accounts")
								}
							}
						}
					}

					Spacer()

					if viewStore.isLedgerNameInputVisible {
						VStack {
							nameLedgerField(with: viewStore)

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
						.buttonStyle(.primaryRectangular)

						Button("Skip remaining accounts") {
							viewStore.send(.skipRestOfTheAccounts)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
					}
				}
				//                .controlState(viewStore.viewControlState)
				.padding(.horizontal, .medium3)
//				.onAppear { viewStore.send(.appeared) }
				.task { @MainActor in await ViewStore(store.stateless).send(.view(.task)).finish()
				}
			}
		}

		@ViewBuilder
		private func nameLedgerField(with viewStore: ViewStoreOf<ImportOlympiaLedgerAccountsAndFactorSource>) -> some SwiftUI.View {
			AppTextField(
				primaryHeading: "Name this Ledger",
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

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - ImportOlympiaLedgerAccountsAndFactorSource_Preview
// struct ImportOlympiaLedgerAccountsAndFactorSource_Preview: PreviewProvider {
//	static var previews: some View {
//		ImportOlympiaLedgerAccountsAndFactorSource.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: ImportOlympiaLedgerAccountsAndFactorSource()
//			)
//		)
//	}
// }
//
// extension ImportOlympiaLedgerAccountsAndFactorSource.State {
//    public static let previewValue = Self(hardwareAccounts: <#NonEmpty<OrderedSet<OlympiaAccountToMigrate>>#>)
// }
// #endif
