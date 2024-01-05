public struct StakeSummaryView: View {
	struct ViewState: Equatable {
		let staked: RETDecimal
		let unstaking: RETDecimal
		let readyToClaim: RETDecimal
	}

	let viewState: ViewState
	let onReadyToClaimTapped: () -> Void

	public var body: some View {
		VStack {
			HStack {
				Image(asset: AssetResource.stakes)
				Text("Radix Network")
					.textStyle(.body1Header)
				Text("XRD Stake Summary")
					.textStyle(.body1Header)

				Spacer()
			}
			HStack {
				Text("Staked")
				Text(viewState.staked.formatted())
			}
			HStack {
				Text("Unstaking")
				Text(viewState.unstaking.formatted())
			}
			HStack {
				Text("Ready to Claim")
				Text(viewState.readyToClaim.formatted())
			}
		}
	}
}
