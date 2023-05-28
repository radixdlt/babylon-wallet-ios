import FeaturePrelude

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
				.shadow(color: .app.cardShadowBlack, radius: .small2)
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
		HStack(spacing: 0) {
			VStack(alignment: .leading) {
				Text(deviceFactorSource.labelSeedPhraseKind)
					.font(.title3)

				HPair(
					// FIXME: strings
					label: deviceFactorSource.supportsOlympia ? "Imported on" : "Generated on",
					item: deviceFactorSource
						.addedOn
						.ISO8601Format(.iso8601Date(timeZone: .current))
				)

				VStack(alignment: .leading, spacing: .small3) {
					ForEach(accountsForDeviceFactorSource.accounts) { account in
						SmallAccountCard(account: account)
							.cornerRadius(.small1)
					}
				}
			}
			.padding()

			Image(asset: AssetResource.chevronRight)
		}
		.multilineTextAlignment(.leading)
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
