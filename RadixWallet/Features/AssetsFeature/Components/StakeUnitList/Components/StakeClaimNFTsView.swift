// MARK: - StakeClaimNFTSView
public struct StakeClaimNFTSView: View {
	public struct ViewState: Sendable, Hashable {
		public let resource: OnLedgerEntity.Resource
		public var sections: IdentifiedArrayOf<Section>
	}

	public var viewState: ViewState
	public let onTap: (StakeClaim) -> Void

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
				HStack {
					TokenBalanceView.xrd(balance: claim.worth)

					if let isSelected = claim.isSelected {
						CheckmarkView(appearance: .dark, isChecked: isSelected)
					}
				}
				.padding(.small1)
				.roundedCorners(strokeColor: .app.gray3)
				.contentShape(Rectangle())
				.onTapGesture {
					onTap(claim)
				}
			}
		}
	}
}

extension StakeClaimNFTSView {
	public struct StakeClaim: Sendable, Hashable, Identifiable {
		public let id: NonFungibleGlobalId
		public let worth: RETDecimal
		public var isSelected: Bool?
	}

	public typealias StakeClaims = IdentifiedArrayOf<StakeClaim>

	public struct Section: Sendable, Hashable, Identifiable {
		public enum Kind: Sendable {
			case unstaking
			case readyToBeClaimed
		}

		public let id: Kind
		public var stakeClaims: StakeClaims
	}
}

extension StakeClaimNFTSView.Section {
	var title: String {
		switch self.id {
		case .unstaking:
			L10n.Account.Staking.unstaking
		case .readyToBeClaimed:
			L10n.Account.Staking.readyToBeClaimed
		}
	}
}
