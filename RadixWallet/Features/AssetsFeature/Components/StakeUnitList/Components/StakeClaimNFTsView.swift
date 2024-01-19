// MARK: - StakeClaimNFTSView
public struct StakeClaimNFTSView: View {
	public struct ViewState: Sendable, Hashable {
		public let canClaimTokens: Bool
		public let validatorName: String?
		public let stakeClaimTokens: OnLedgerEntitiesClient.NonFunbileResourceWithTokens
		var selectedStakeClaims: IdentifiedArrayOf<NonFungibleGlobalId>?

		var unstaking: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim> {
			stakeClaimTokens.stakeClaims.filter(not(\.isReadyToBeClaimed))
		}

		var readyToBeClaimed: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim> {
			stakeClaimTokens.stakeClaims.filter(\.isReadyToBeClaimed)
		}

		var toBeClaimed: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim> {
			stakeClaimTokens.stakeClaims.filter(\.isReadyToBeClaimed)
		}

		var resourceMetadata: OnLedgerEntity.Metadata {
			stakeClaimTokens.resource.metadata
		}

		init(
			canClaimTokens: Bool,
			stakeClaimTokens: OnLedgerEntitiesClient.NonFunbileResourceWithTokens,
			validatorName: String? = nil,
			selectedStakeClaims: IdentifiedArrayOf<NonFungibleGlobalId>? = nil
		) {
			self.canClaimTokens = canClaimTokens
			self.validatorName = validatorName
			self.stakeClaimTokens = stakeClaimTokens
			self.selectedStakeClaims = selectedStakeClaims
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
		VStack(alignment: .leading, spacing: .small1) {
			HStack {
				TokenThumbnail(.known(viewState.resourceMetadata.iconURL), size: .smaller)
				VStack(alignment: .leading, spacing: .zero) {
					Text(viewState.resourceMetadata.name ?? "")
						.textStyle(.body1Header)
						.foregroundStyle(.app.gray1)

					if let validatorName = viewState.validatorName {
						Text(validatorName)
							.textStyle(.body2Regular)
							.foregroundStyle(.app.gray2)
					}
				}

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

				if case .readyToBeClaimed = kind, viewState.canClaimTokens {
					Text(L10n.Account.Staking.claim).onTapGesture {
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
