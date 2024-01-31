// MARK: - StakeClaimNFTSView
public struct StakeClaimNFTSView: View {
	public struct ViewState: Sendable, Hashable {
		public let canClaimTokens: Bool
		public let validatorName: String?
		public let stakeClaimTokens: OnLedgerEntitiesClient.NonFunbileResourceWithTokens

		var selectedStakeClaims: IdentifiedArrayOf<NonFungibleGlobalId>?

		var unstaking: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim> {
			stakeClaimTokens.stakeClaims.filter(\.isUnstaking)
		}

		var readyToBeClaimed: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim> {
			stakeClaimTokens.stakeClaims.filter(\.isReadyToBeClaimed)
		}

		var toBeClaimed: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim> {
			stakeClaimTokens.stakeClaims.filter(\.isToBeClaimed)
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
		case toBeClaimed
	}

	public let viewState: ViewState
	public let background: Color
	public let onTap: (OnLedgerEntitiesClient.StakeClaim) -> Void
	public let onClaimAllTapped: (() -> Void)?

	public init(
		viewState: ViewState,
		background: Color,
		onTap: @escaping (OnLedgerEntitiesClient.StakeClaim) -> Void,
		onClaimAllTapped: (() -> Void)? = nil
	) {
		self.viewState = viewState
		self.background = background
		self.onTap = onTap
		self.onClaimAllTapped = onClaimAllTapped
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: .medium3) {
			HStack(spacing: .zero) {
				TokenThumbnail(.known(viewState.resourceMetadata.iconURL), size: .smaller)
					.padding(.trailing, .small1)

				VStack(alignment: .leading, spacing: .zero) {
					if let name = viewState.resourceMetadata.name {
						Text(name)
							.textStyle(.body1Header)
							.foregroundStyle(.app.gray1)
					}

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

			if !viewState.toBeClaimed.isEmpty {
				sectionView(viewState.toBeClaimed, kind: .toBeClaimed)
			}
		}
		.padding(.medium3)
		.background(background)
	}

	@ViewBuilder
	func sectionView(_ claims: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim>, kind: SectionKind) -> some View {
		VStack(alignment: .leading, spacing: .zero) {
			HStack {
				Text(kind.title)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
					.textCase(.uppercase)

				Spacer()

				if case .readyToBeClaimed = kind, viewState.canClaimTokens {
					let label = Text(L10n.Account.Staking.claim)
						.textStyle(.body2Link)
						.foregroundColor(.app.blue1)
					if let onClaimAllTapped {
						Button(action: onClaimAllTapped) { label }
					} else {
						label
					}
				}
			}
			.padding(.bottom, .small3)

			VStack(alignment: .leading, spacing: .small2) {
				ForEach(claims) { claim in
					Button {
						onTap(claim)
					} label: {
						HStack {
							TokenBalanceView(viewState: .xrd(balance: claim.claimAmount))

							if let isSelected = viewState.selectedStakeClaims?.contains(claim.id) {
								CheckmarkView(appearance: .dark, isChecked: isSelected)
							}
						}
						.padding(.small1)
						.background(background)
					}
					.buttonStyle(.borderless)
					.roundedCorners(strokeColor: .app.gray3)
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
		case .toBeClaimed:
			L10n.TransactionReview.toBeClaimed
		}
	}
}
