import FeaturePrelude

extension CustomizeFees {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<CustomizeFees>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack {
					Text("Customize Fees")
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
					Text("Choose what account to pay the transaction fee from, or add a “tip” to speed up your transaction if necessary.")
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)
					Divider()

					feePayerView(viewStore)
					feesBreakdownView(viewStore)

					Button("View Advanced Mode") {
						viewStore.send(.viewAdvancedModeTapped)
					}
				}
			}
		}

		func feePayerView(_ viewStore: ViewStoreOf<CustomizeFees>) -> some SwiftUI.View {
			let feePayer = viewStore.feePayerAccount

			return VStack {
				HStack {
					Text("Pay Fee From")
					Button("Change") {
						viewStore.send(.changeFeePayerTapped)
					}
				}
				SmallAccountCard(feePayer.displayName.rawValue,
				                 identifiable: .address(.account(feePayer.address)),
				                 gradient: .init(feePayer.appearanceID))
			}
		}

		func feesBreakdownView(_ viewStore: ViewStoreOf<CustomizeFees>) -> some SwiftUI.View {
			VStack {
				HStack {
					Text("Network Fee")
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
					Spacer()
					Text(viewStore.feeSummary.networkFee.asStr())
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.gray1)
				}

				HStack {
					Text("Royalty Fees")
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
					Spacer()
					Text(viewStore.feeSummary.royaltyFee.asStr())
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.gray1)
				}

				HStack {
					Text("Tip")
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
					Spacer()
					Text("0.00 XRD")
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.gray1)
				}

				Divider()
				HStack {
					Text("Total")
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
					Spacer()
					Text("0.00 XRD")
				}
			}
		}
	}
}
