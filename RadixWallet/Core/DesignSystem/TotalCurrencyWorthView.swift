struct TotalCurrencyWorthView: View {
	struct State: Hashable, Sendable {
		let totalCurrencyWorth: Loadable<FiatWorth>
	}

	let state: State
	let backgroundColor: Color
	let onTap: () -> Void

	var body: some View {
		loadable(state.totalCurrencyWorth, backgroundColor: backgroundColor) { totalCurrencyWorth in
			Button {
				onTap()
			} label: {
				HStack {
					Text(totalCurrencyWorth.currencyFormatted(applyCustomFont: true)!)
						.textStyle(.sheetTitle)

					Image(asset: totalCurrencyWorth.isVisible ? AssetResource.homeAggregatedValueShown : AssetResource.homeAggregatedValueHidden)
				}
			}
		}
	}
}
