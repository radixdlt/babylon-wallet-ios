struct TotalCurrencyWorthView: View {
	struct State: Hashable, Sendable {
		let isShowingCurrencyWorth: Bool
		let totalCurrencyWorth: Loadable<AttributedString>
	}

	let state: State
	let onTap: () -> Void

	var body: some View {
		loadable(state.totalCurrencyWorth) { totalCurrencyWorth in
			Button {
				onTap()
			} label: {
				HStack {
					Text("\(state.isShowingCurrencyWorth ? totalCurrencyWorth : "• • • •")")
						.textStyle(.sheetTitle)

					Image(asset: state.isShowingCurrencyWorth ? AssetResource.homeAggregatedValueShown : AssetResource.homeAggregatedValueHidden)
				}
			}
		}
	}
}
