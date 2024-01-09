// MARK: - StakeClaimNFTSView
struct StakeClaimNFTSView: View {
	struct ViewState: Sendable, Hashable {
		public let resource: OnLedgerEntity.Resource
		public let sections: IdentifiedArrayOf<Section>
	}

	public let viewState: ViewState
	public let onTap: (NonFungibleGlobalId) -> Void

	public var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			HStack {
				TokenThumbnail(.known(viewState.resource.metadata.iconURL), size: .smaller)
				Text(viewState.resource.metadata.name ?? "Stake Claim NFTs")
					.textStyle(.body1Header)

				Spacer()
			}

			ForEach(viewState.sections) { section in
				sectionView(section)
			}
		}
	}

	@ViewBuilder
	func sectionView(_ section: Section) -> some View {
		VStack(alignment: .leading, spacing: .small2) {
			Text(section.title)
				.textStyle(.body2HighImportance)
				.foregroundColor(.app.gray2)
				.textCase(.uppercase)

			ForEach(section.stakeClaims) { claim in
				TokenBalanceView.xrd(balance: claim.worth)
					.padding(.small1)
					.roundedCorners(strokeColor: .app.gray3)
					.contentShape(Rectangle())
					.onTapGesture {
						onTap(claim.id)
					}
			}
		}
	}
}

extension StakeClaimNFTSView {
	public struct StakeClaim: Sendable, Hashable, Identifiable {
		let id: NonFungibleGlobalId
		let worth: RETDecimal
	}

	public typealias StakeClaims = IdentifiedArrayOf<StakeClaim>

	public enum Section: Sendable, Hashable, Identifiable {
		var id: Int {
			switch self {
			case .unstaking:
				0
			case .readyToBeClaimed:
				1
			}
		}

		case unstaking(StakeClaims)
		case readyToBeClaimed(StakeClaims)
	}
}

extension StakeClaimNFTSView.Section {
	var title: String {
		switch self {
		case .unstaking:
			L10n.Account.Staking.unstaking
		case .readyToBeClaimed:
			L10n.Account.Staking.readyToBeClaimed
		}
	}

	var stakeClaims: StakeClaimNFTSView.StakeClaims {
		switch self {
		case let .unstaking(claims), let .readyToBeClaimed(claims):
			claims
		}
	}
}
