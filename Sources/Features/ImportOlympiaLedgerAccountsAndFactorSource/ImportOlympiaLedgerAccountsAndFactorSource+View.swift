import FeaturePrelude

extension ImportOlympiaLedgerAccountsAndFactorSource.State {
	var viewState: ImportOlympiaLedgerAccountsAndFactorSource.ViewState {
		.init()
	}
}

// MARK: - ImportOlympiaLedgerAccountsAndFactorSource.View
extension ImportOlympiaLedgerAccountsAndFactorSource {
	public struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSource>

		public init(store: StoreOf<ImportOlympiaLedgerAccountsAndFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Button("Send Add Ledger Request") {
						viewStore.send(.sendAddLedgerRequestButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.padding(.horizontal, .medium3)
				.onAppear { viewStore.send(.appeared) }
				.alert(store: store.nameLedgerAlert)
//				.task {
//					await ViewStore(store.stateless).send(.view(.task)).finish()
//				}
			}
		}
	}
}

private extension ImportOlympiaLedgerAccountsAndFactorSource.Store {
	var nameLedgerAlert: AlertPresentationStore<ImportOlympiaLedgerAccountsAndFactorSource.ViewAction.ConfirmDisconnectAlert> {
		scope(state: \.$confirmDisconnectAlert) { .view(.confirmDisconnectAlert($0)) }
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
