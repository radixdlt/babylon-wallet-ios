import SwiftUI

// MARK: - ResourceBalance.ViewState
extension ResourceBalance {
	// MARK: - ViewState
	public enum ViewState: Sendable, Hashable {
		case fungible(Fungible)
		case nonFungible(NonFungible)
		case lsu(LSU)
		case poolUnit(PoolUnit)
		case stakeClaimNFT(StakeClaimNFT)

		public struct Fungible: Sendable, Hashable {
			public let address: ResourceAddress
			public let icon: Thumbnail.FungibleContent
			public let title: String?
			public let amount: ResourceBalance.Amount?
		}

		public struct NonFungible: Sendable, Hashable {
			public let id: NonFungibleGlobalId
			public let resourceImage: URL?
			public let resourceName: String?
			public let nonFungibleName: String?
		}

		public struct LSU: Sendable, Hashable {
			public let address: ResourceAddress
			public let icon: URL?
			public let title: String?
			public let amount: ResourceBalance.Amount?
			public let worth: RETDecimal
			public var validatorName: String? = nil
		}

		public struct PoolUnit: Sendable, Hashable, Identifiable {
			public var id: ResourcePoolAddress { resourcePoolAddress }
			public let resourcePoolAddress: ResourcePoolAddress
			public let poolUnitAddress: ResourceAddress
			public let poolIcon: URL?
			public let poolName: String?
			public let amount: ResourceBalance.Amount?
			public var dAppName: Loadable<String?>
			public var resources: Loadable<[Fungible]>
		}
	}
}

// MARK: - ResourceBalanceView
public struct ResourceBalanceView: View {
	public let viewState: ResourceBalance.ViewState
	public let appearance: Appearance
	public let isSelected: Bool?

	public enum Appearance: Equatable {
		case standard
		case compact(border: Bool)

		static let compact: Appearance = .compact(border: false)
	}

	init(_ viewState: ResourceBalance.ViewState, appearance: Appearance = .standard, isSelected: Bool? = nil) {
		self.viewState = viewState
		self.appearance = appearance
		self.isSelected = isSelected
	}

	public var body: some View {
		if border {
			core
				.padding(.small1)
				.roundedCorners(strokeColor: .app.gray3)
		} else {
			core
		}
	}

	private var core: some View {
		HStack(alignment: .center, spacing: .small2) {
			switch viewState {
			case let .fungible(viewState):
				Fungible(viewState: viewState, compact: compact)
			case let .nonFungible(viewState):
				NonFungible(viewState: viewState, compact: compact)
			case let .lsu(viewState):
				LSU(viewState: viewState, isSelected: isSelected)
			case let .poolUnit(viewState):
				PoolUnit(viewState: viewState, isSelected: isSelected)
			case let .stakeClaimNFT(viewState):
				StakeClaimNFT(viewState: viewState, background: .blue.opacity(0.2), onTap: { _ in })
			}

			if !delegateSelection, let isSelected {
				CheckmarkView(appearance: .dark, isChecked: isSelected)
			}
		}
		.overlay(.green.opacity(0.1))
	}

	var compact: Bool {
		appearance != .standard
	}

	var border: Bool {
		appearance == .compact(border: true)
	}

	/// Delegate showing the selection state to the particular resource view
	var delegateSelection: Bool {
		switch viewState {
		case .fungible, .nonFungible:
			false
		case .lsu, .poolUnit, .stakeClaimNFT:
			true
		}
	}
}

extension ResourceBalanceView {
	public struct Fungible: View {
		@Environment(\.missingFungibleAmountFallback) var fallback
		public let viewState: ResourceBalance.ViewState.Fungible
		public let compact: Bool

		public var body: some View {
			HStack(spacing: .zero) {
				Thumbnail(fungible: viewState.icon, size: size)
					.padding(.trailing, .small1)

				if let title = viewState.title {
					Text(title)
						.lineLimit(1)
						.textStyle(titleTextStyle)
						.foregroundColor(.app.gray1)
				}

				if useSpacer {
					Spacer(minLength: .small2)
				}

				AmountView(amount: viewState.amount, fallback: fallback, compact: compact)
			}
		}

		private var size: HitTargetSize {
			compact ? .smallest : .small
		}

		private var titleTextStyle: TextStyle {
			compact ? .body1HighImportance : .body2HighImportance
		}

		private var useSpacer: Bool {
			viewState.amount != nil || fallback != nil
		}
	}

	public struct NonFungible: View {
		public let viewState: ResourceBalance.ViewState.NonFungible
		public let compact: Bool

		public var body: some View {
			HStack(spacing: .zero) {
				Thumbnail(.nft, url: viewState.resourceImage, size: size)
					.padding(.trailing, .small1)

				VStack(alignment: .leading, spacing: 0) {
					Text(line1)
						.textStyle(compact ? .body2HighImportance : .body1HighImportance)
						.foregroundColor(.app.gray1)
					Text(line2)
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}
				.lineLimit(1)

				Spacer(minLength: 0)
			}
		}

		private var size: HitTargetSize {
			compact ? .smallest : .smallish
		}

		private var line1: String {
			viewState.resourceName ?? viewState.id.resourceAddress().formatted()
		}

		private var line2: String {
			viewState.nonFungibleName ?? viewState.id.localId().formatted()
		}
	}

	public struct LSU: View {
		let viewState: ResourceBalance.ViewState.LSU
		let isSelected: Bool?

		public var body: some View {
			VStack(alignment: .leading, spacing: .medium3) {
				HStack(spacing: .zero) {
					Thumbnail(.lsu, url: viewState.icon, size: .slightlySmaller)
						.padding(.trailing, .small2)

					VStack(alignment: .leading, spacing: .zero) {
						if let title = viewState.title {
							Text(title)
								.textStyle(.body1Header)
						}

						if let validatorName = viewState.validatorName {
							Text(validatorName)
								.foregroundStyle(.app.gray2)
								.textStyle(.body2Regular)
						}
					}
					.padding(.trailing, .small2)

					Spacer(minLength: 0)

					AmountView(amount: viewState.amount, compact: false)
						.padding(.leading, isSelected != nil ? .small2 : 0)

					if let isSelected {
						CheckmarkView(appearance: .dark, isChecked: isSelected)
					}
				}

				VStack(alignment: .leading, spacing: .small3) {
					Text(L10n.Account.Staking.worth.uppercased())
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray2)

					ResourceBalanceView(.fungible(.xrd(balance: viewState.worth)), appearance: .compact(border: true))
				}
			}
		}
	}

	public struct PoolUnit: View {
		public let viewState: ResourceBalance.ViewState.PoolUnit
		public let isSelected: Bool?

		public var body: some View {
			VStack(alignment: .leading, spacing: .zero) {
				HStack(spacing: .zero) {
					Thumbnail(.poolUnit, url: viewState.poolIcon, size: .slightlySmaller)
						.padding(.trailing, .small1)

					VStack(alignment: .leading, spacing: 0) {
						Text(viewState.poolName ?? L10n.TransactionReview.poolUnits)
							.textStyle(.body1Header)
							.foregroundColor(.app.gray1)

						loadable(viewState.dAppName, loadingViewHeight: .small1) { dAppName in
							if let dAppName {
								Text(dAppName)
									.textStyle(.body2Regular)
									.foregroundColor(.app.gray2)
							}
						}
					}

					Spacer(minLength: 0)

					ResourceBalanceView.AmountView(amount: viewState.amount, compact: false)
						.padding(.leading, isSelected != nil ? .small2 : 0)

					if let isSelected {
						CheckmarkView(appearance: .dark, isChecked: isSelected)
					}

					//					AssetIcon(.asset(AssetResource.info), size: .smallest)
					//						.tint(.app.gray3)
				}
				.padding(.bottom, .small2)

				Text(L10n.TransactionReview.worth.uppercased())
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
					.padding(.bottom, .small3)

				loadable(viewState.resources) { fungibles in
					ResourceBalancesView(fungibles: fungibles)
						.environment(\.missingFungibleAmountFallback, L10n.Account.PoolUnits.noTotalSupply)
				}
			}
		}
	}

	public struct StakeClaimNFT: View {
		public let viewState: ResourceBalance.StakeClaimNFT
		public let background: Color
		public let onTap: (OnLedgerEntitiesClient.StakeClaim) -> Void
		public let onClaimAllTapped: (() -> Void)?

		public init(
			viewState: ResourceBalance.StakeClaimNFT,
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
					Thumbnail(token: .other(viewState.resourceMetadata.iconURL), size: .slightlySmaller)
						.padding(.trailing, .small1)

					VStack(alignment: .leading, spacing: .zero) {
						if let title = viewState.resourceMetadata.title {
							Text(title)
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

				Tokens(
					viewState: viewState.stakeClaimTokens,
					background: background,
					onTap: onTap,
					onClaimAllTapped: onClaimAllTapped
				)
			}
			.padding(.medium3)
			.background(background)
		}

		public struct Tokens: View {
			enum SectionKind {
				case unstaking
				case readyToBeClaimed
				case toBeClaimed
			}

			public var viewState: ResourceBalance.StakeClaimNFT.Tokens
			public let background: Color
			public let onTap: ((OnLedgerEntitiesClient.StakeClaim) -> Void)?
			public let onClaimAllTapped: (() -> Void)?

			init(
				viewState: ResourceBalance.StakeClaimNFT.Tokens,
				background: Color,
				onTap: ((OnLedgerEntitiesClient.StakeClaim) -> Void)? = nil,
				onClaimAllTapped: (() -> Void)? = nil
			) {
				self.viewState = viewState
				self.background = background
				self.onTap = onTap
				self.onClaimAllTapped = onClaimAllTapped
			}

			public var body: some View {
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

			@ViewBuilder
			func sectionView(
				_ claims: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim>,
				kind: SectionKind
			) -> some View {
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
								onTap?(claim)
							} label: {
								let isSelected = viewState.selectedStakeClaims?.contains(claim.id)
								ResourceBalanceView(.fungible(.xrd(balance: claim.claimAmount)), appearance: .compact, isSelected: isSelected)
									.padding(.small1)
									.background(background)
							}
							.disabled(onTap == nil)
							.buttonStyle(.borderless)
							.roundedCorners(strokeColor: .red) // .app.gray3
						}
					}
				}
			}
		}
	}

	// Helper Views

	struct AmountView: View {
		let amount: ResourceBalance.Amount?
		let fallback: String?
		let compact: Bool

		init(amount: ResourceBalance.Amount?, fallback: String? = nil, compact: Bool) {
			self.amount = amount
			self.fallback = fallback
			self.compact = compact
		}

		var body: some View {
			if let amount {
				core(amount: amount, compact: compact)
					.overlay(.green.opacity(0.1))
			} else if let fallback {
				Text(fallback)
					.textStyle(amountTextStyle)
					.foregroundColor(.app.gray2)
					.overlay(.green.opacity(0.1))
			}
		}

		@ViewBuilder
		private func core(amount: ResourceBalance.Amount, compact: Bool) -> some View {
			if compact {
				Text(amount.amount.formatted())
					.textStyle(amountTextStyle)
					.foregroundColor(.app.gray1)
			} else {
				VStack(alignment: .trailing, spacing: 0) {
					if amount.guaranteed != nil {
						Text(L10n.TransactionReview.estimated)
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.gray1)
					}
					Text(amount.amount.formatted())
						.lineLimit(1)
						.minimumScaleFactor(0.8)
						.truncationMode(.tail)
						.textStyle(.secondaryHeader)
						.foregroundColor(.app.gray1)

					if let guaranteedAmount = amount.guaranteed {
						Text(L10n.TransactionReview.guaranteed)
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.gray2)
							.padding(.top, .small3)

						Text(guaranteedAmount.formatted())
							.textStyle(.body1Header)
							.foregroundColor(.app.gray2)
					}
				}
			}
		}

		private var amountTextStyle: TextStyle {
			compact ? .body1HighImportance : .secondaryHeader
		}
	}
}

extension ResourceBalanceView.StakeClaimNFT.Tokens.SectionKind {
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
