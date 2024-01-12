// MARK: - StakeClaimNFTSView
public struct StakeClaimNFTSView: View {
	public struct ViewState: Sendable, Hashable {
		public let stakeClaimTokens: OnLedgerEntitiesClient.NonFunbileResourceWithTokens
		var selectedStakeClaims: IdentifiedArrayOf<NonFungibleGlobalId>?

		var unstaking: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim> {
			stakeClaimTokens.stakeClaims.filter(not(\.isReadyToBeClaimed))
		}

		var readyToBeClaimed: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim> {
			stakeClaimTokens.stakeClaims.filter(\.isReadyToBeClaimed)
		}

		var resourceMetadata: OnLedgerEntity.Metadata {
			stakeClaimTokens.resource.metadata
		}
	}

	enum SectionKind {
		case unstaking
		case readyToBeClaimed
	}

	public var viewState: ViewState
	public let onTap: (OnLedgerEntitiesClient.StakeClaim) -> Void
	public let onClaimAllTapped: () -> Void

	public var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			HStack {
				TokenThumbnail(.known(viewState.resourceMetadata.iconURL), size: .smaller)
				Text(viewState.resourceMetadata.name ?? "Stake Claim NFTs")
					.textStyle(.body1Header)

				Spacer()
			}

			if !viewState.unstaking.isEmpty {
				sectionView(viewState.unstaking, kind: .unstaking)
			}

			if !viewState.readyToBeClaimed.isEmpty {
				sectionView(viewState.readyToBeClaimed, kind: .readyToBeClaimed)
			}
		}
	}

	@ViewBuilder
	func sectionView(_ claims: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim>, kind: SectionKind) -> some View {
		VStack(alignment: .leading, spacing: .small2) {
			HStack {
				Text(kind.title)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
					.textCase(.uppercase)

				Spacer()

				if case .readyToBeClaimed = kind,
				   viewState.selectedStakeClaims == nil // No selection mode
				{
					Button("Claim") {
						onClaimAllTapped()
					}
					.textStyle(.body2Link)
					.foregroundColor(.app.blue1)
				}
			}
			ForEach(claims) { claim in
				HStack {
					TokenBalanceView.xrd(balance: claim.claimAmount)

					if let isSelected = viewState.selectedStakeClaims?.contains(claim.id) {
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

extension StakeClaimNFTSView.SectionKind {
	var title: String {
		switch self {
		case .unstaking:
			L10n.Account.Staking.unstaking
		case .readyToBeClaimed:
			L10n.Account.Staking.readyToBeClaimed
		}
	}
}
