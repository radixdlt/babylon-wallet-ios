import FeaturePrelude

// extension DisplayMnemonicRow.State {
//	var viewState: DisplayMnemonicRow.ViewState {
//		.init(
//			factorSourceID: deviceFactorSource.factorSource.id,
//			accounts: accountsForDeviceFactorSource.accounts,
//			labelSeedPhraseKind: deviceFactorSource.labelSeedPhraseKind,
//			addedOn:

//		)
//	}
// }

extension HDOnDeviceFactorSource {
	var labelSeedPhraseKind: String {
		// FIXME: string
		supportsOlympia ? "Legacy seed phrase" : "Main seed phrase"
	}
}

// MARK: - DisplayMnemonicRow.View
extension DisplayMnemonicRow {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DisplayMnemonicRow>

		public init(store: StoreOf<DisplayMnemonicRow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				Card(.app.gray5) {
					viewStore.send(.tapped)
				} contents: {
					AccountsForDeviceFactorSourceView(
						accountsForDeviceFactorSource: viewStore.accountsForDeviceFactorSource
					)
				}
			}
		}
	}
}

// MARK: - AccountsForDeviceFactorSourceView
struct AccountsForDeviceFactorSourceView: SwiftUI.View {
	let accountsForDeviceFactorSource: AccountsForDeviceFactorSource
	var deviceFactorSource: HDOnDeviceFactorSource {
		accountsForDeviceFactorSource.deviceFactorSource
	}

	var body: some View {
		VStack {
			Text(deviceFactorSource.labelSeedPhraseKind)
				.font(.title3)

			HPair(label: "Added", item: deviceFactorSource
				.addedOn
				.ISO8601Format(.iso8601Date(timeZone: .current)))

			ForEach(accountsForDeviceFactorSource.accounts) { account in
				SmallAccountCard(account: account)
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - DisplayMnemonicRow_Preview
// struct DisplayMnemonicRow_Preview: PreviewProvider {
//	static var previews: some View {
//		DisplayMnemonicRow.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: DisplayMnemonicRow()
//			)
//		)
//	}
// }
//
// extension DisplayMnemonicRow.State {
//    public static let previewValue = Self(deviceFactorSource: )
// }
// #endif
