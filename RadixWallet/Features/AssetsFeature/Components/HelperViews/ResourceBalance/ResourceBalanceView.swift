import Sargon
import SwiftUI

// MARK: - ResourceBalance.ViewState
extension ResourceBalance {
	// MARK: - ViewState
	enum ViewState: Sendable, Hashable {
		case fungible(Fungible)
		case nonFungible(NonFungible)
		case liquidStakeUnit(LiquidStakeUnit)
		case poolUnit(PoolUnit)
		case stakeClaimNFT(StakeClaimNFT)

		struct Fungible: Sendable, Hashable {
			let address: ResourceAddress
			let icon: Thumbnail.FungibleContent
			let title: String?
			let amount: ResourceBalance.Amount?
		}

		struct NonFungible: Sendable, Hashable {
			let id: NonFungibleGlobalId
			let resourceImage: URL?
			let resourceName: String?
			let nonFungibleName: String?
		}

		struct LiquidStakeUnit: Sendable, Hashable {
			let address: ResourceAddress
			let icon: URL?
			let title: String?
			let amount: ResourceBalance.Amount?
			let worth: ResourceAmount
			var validatorName: String? = nil
		}

		struct PoolUnit: Sendable, Hashable {
			let resourcePoolAddress: PoolAddress
			let poolUnitAddress: ResourceAddress
			let poolIcon: URL?
			let poolName: String?
			let amount: ResourceBalance.Amount?
			var dAppName: Loadable<String?>
			var resources: Loadable<[Fungible]>
		}

		typealias StakeClaimNFT = ResourceBalance.StakeClaimNFT
	}

	var viewState: ViewState {
		switch details {
		case let .fungible(details):
			.fungible(.init(resource: resource, details: details))
		case let .nonFungible(details):
			.nonFungible(.init(resource: resource, details: details))
		case let .liquidStakeUnit(details):
			.liquidStakeUnit(.init(resource: resource, details: details))
		case let .poolUnit(details):
			.poolUnit(.init(resource: resource, details: details))
		case let .stakeClaimNFT(details):
			.stakeClaimNFT(details)
		}
	}
}

private extension ResourceBalance.ViewState.Fungible {
	init(resource: OnLedgerEntity.Resource, details: ResourceBalance.Fungible) {
		self.init(
			address: resource.resourceAddress,
			icon: .token(details.isXRD ? .xrd : .other(resource.metadata.iconURL)),
			title: resource.metadata.title,
			amount: .init(details.amount, guaranteed: details.guarantee?.amount)
		)
	}
}

private extension ResourceBalance.ViewState.NonFungible {
	init(resource: OnLedgerEntity.Resource, details: ResourceBalance.NonFungible) {
		self.init(
			id: details.id,
			resourceImage: resource.metadata.iconURL,
			resourceName: resource.metadata.name,
			nonFungibleName: details.data?.name
		)
	}
}

private extension ResourceBalance.ViewState.LiquidStakeUnit {
	init(resource: OnLedgerEntity.Resource, details: ResourceBalance.LiquidStakeUnit) {
		self.init(
			address: resource.resourceAddress,
			icon: resource.metadata.iconURL,
			title: resource.metadata.title,
			amount: .init(details.amount, guaranteed: details.guarantee?.amount),
			worth: details.worth,
			validatorName: details.validator.metadata.name
		)
	}
}

private extension ResourceBalance.ViewState.PoolUnit {
	init(resource: OnLedgerEntity.Resource, details: ResourceBalance.PoolUnit) {
		self.init(
			resourcePoolAddress: details.details.address,
			poolUnitAddress: resource.resourceAddress,
			poolIcon: resource.metadata.iconURL,
			poolName: resource.fungibleResourceName,
			amount: .init(details.details.poolUnitResource.amount, guaranteed: details.guarantee?.amount),
			dAppName: .success(details.details.dAppName),
			resources: .success(.init(resources: details.details))
		)
	}
}

// MARK: - ResourceBalanceView
struct ResourceBalanceView: View {
	let viewState: ResourceBalance.ViewState
	let appearance: Appearance
	let isSelected: Bool?
	let action: (() -> Void)?

	enum Appearance: Sendable, Equatable {
		case standard
		case compact(border: Bool)

		static let compact: Appearance = .compact(border: false)
	}

	init(
		_ viewState: ResourceBalance.ViewState,
		appearance: Appearance = .standard,
		isSelected: Bool? = nil,
		action: (() -> Void)? = nil
	) {
		self.viewState = viewState
		self.appearance = appearance
		self.isSelected = isSelected
		self.action = action
	}

	var body: some View {
		content
			.embedInButton(when: action)
	}

	@ViewBuilder
	private var content: some View {
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
			case let .liquidStakeUnit(viewState):
				LiquidStakeUnit(viewState: viewState, compact: compact, isSelected: isSelected)
			case let .poolUnit(viewState):
				PoolUnit(viewState: viewState, compact: compact, isSelected: isSelected)
			case let .stakeClaimNFT(viewState):
				StakeClaimNFT(viewState: viewState, appearance: .standalone, compact: compact, onTap: { _ in })
			}

			if !delegateSelection, let isSelected {
				CheckmarkView(appearance: .dark, isChecked: isSelected)
			}
		}
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
		case .liquidStakeUnit, .poolUnit, .stakeClaimNFT:
			true
		}
	}
}

extension ResourceBalanceView {
	struct Fungible: View {
		@Environment(\.missingFungibleAmountFallback) var fallback
		let viewState: ResourceBalance.ViewState.Fungible
		let compact: Bool

		var body: some View {
			FungibleView(
				thumbnail: viewState.icon,
				caption1: viewState.title ?? "-",
				caption2: nil,
				fallback: fallback,
				amount: viewState.amount,
				compact: compact,
				isSelected: nil
			)
		}
	}

	struct NonFungible: View {
		let viewState: ResourceBalance.ViewState.NonFungible
		let compact: Bool

		var body: some View {
			NonFungibleView(
				thumbnail: .nft(viewState.resourceImage),
				caption1: viewState.resourceName ?? viewState.id.resourceAddress.formatted(),
				caption2: viewState.nonFungibleName ?? viewState.id.localID.formatted(),
				compact: compact
			)
		}
	}

	struct LiquidStakeUnit: View {
		@Environment(\.resourceBalanceHideDetails) var hideDetails
		let viewState: ResourceBalance.ViewState.LiquidStakeUnit
		let compact: Bool
		let isSelected: Bool?

		private var fungible: ResourceBalance.ViewState.Fungible {
			.xrd(balance: viewState.worth, network: viewState.address.networkID)
		}

		var body: some View {
			VStack(alignment: .leading, spacing: .medium3) {
				FungibleView(
					thumbnail: .lsu(viewState.icon),
					caption1: viewState.title ?? "-",
					caption2: viewState.validatorName ?? "-",
					fallback: nil,
					amount: viewState.amount,
					compact: compact,
					isSelected: isSelected
				)

				if !hideDetails {
					VStack(alignment: .leading, spacing: .small3) {
						Text(L10n.Account.Staking.worth.uppercased())
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.gray2)

						ResourceBalanceView(.fungible(fungible), appearance: .compact(border: true))
					}
					.padding(.top, .small2)
				}
			}
		}
	}

	struct PoolUnit: View {
		@Environment(\.resourceBalanceHideDetails) var hideDetails
		let viewState: ResourceBalance.ViewState.PoolUnit
		let compact: Bool
		let isSelected: Bool?

		var body: some View {
			VStack(alignment: .leading, spacing: .zero) {
				FungibleView(
					thumbnail: .poolUnit(viewState.poolIcon),
					caption1: viewState.poolName ?? "-",
					caption2: viewState.dAppName.wrappedValue?.flatMap { $0 } ?? "-",
					fallback: nil,
					amount: viewState.amount,
					compact: compact,
					isSelected: isSelected
				)
				.padding(.horizontal, hideDetails ? .zero : .small3)

				if !hideDetails {
					Text(L10n.TransactionReview.worth.uppercased())
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray2)
						.padding(.top, .small2)
						.padding(.bottom, .small3)

					loadable(viewState.resources) { fungibles in
						ResourceBalancesView(fungibles: fungibles)
							.environment(\.missingFungibleAmountFallback, L10n.Account.PoolUnits.noTotalSupply)
					}
				}
			}
		}
	}

	struct StakeClaimNFT: View {
		@Environment(\.resourceBalanceHideDetails) var hideDetails
		let viewState: ResourceBalance.ViewState.StakeClaimNFT
		let appearance: Appearance
		let compact: Bool
		let onTap: (OnLedgerEntitiesClient.StakeClaim) -> Void
		var onClaimAllTapped: (() -> Void)? = nil

		enum Appearance {
			case standalone
			case transactionReview
		}

		var body: some View {
			VStack(alignment: .leading, spacing: .zero) {
				NonFungibleView(
					thumbnail: .stakeClaimNFT(viewState.resourceMetadata.iconURL),
					caption1: viewState.resourceMetadata.title,
					caption2: viewState.validatorName,
					compact: compact
				)

				if !hideDetails {
					Tokens(
						viewState: viewState.stakeClaimTokens,
						background: background,
						onTap: onTap,
						onClaimAllTapped: onClaimAllTapped
					)
					.padding(.top, .small2)
				}
			}
			.padding(padding)
			.background(background)
		}

		private var padding: CGFloat {
			switch appearance {
			case .standalone: .zero
			case .transactionReview: .medium3
			}
		}

		private var background: Color {
			switch appearance {
			case .standalone: .white
			case .transactionReview: .app.gray5
			}
		}

		struct Tokens: View {
			enum SectionKind {
				case unstaking
				case readyToBeClaimed
				case toBeClaimed
			}

			var viewState: ResourceBalance.StakeClaimNFT.Tokens
			let background: Color
			let onTap: ((OnLedgerEntitiesClient.StakeClaim) -> Void)?
			let onClaimAllTapped: (() -> Void)?

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

			var body: some View {
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
								ResourceBalanceView(
									.fungible(.xrd(balance: claim.claimAmount, network: claim.validatorAddress.networkID)),
									appearance: .compact,
									isSelected: isSelected
								)
								.padding(.small1)
								.background(background)
							}
							.disabled(onTap == nil)
							.buttonStyle(.borderless)
							.roundedCorners(strokeColor: .app.gray3)
						}
					}
				}
			}
		}
	}

	// Helper Views

	private struct FungibleView: View {
		let thumbnail: Thumbnail.FungibleContent
		let caption1: String?
		let caption2: String?
		let fallback: String?
		let amount: ResourceBalance.Amount?
		let compact: Bool
		let isSelected: Bool?

		var body: some View {
			HStack(spacing: .zero) {
				CaptionedThumbnailView(
					type: thumbnail.type,
					url: thumbnail.url,
					caption1: caption1,
					caption2: caption2,
					compact: compact
				)

				if useSpacer, isSelected == nil {
					Spacer(minLength: .small2)
				}

				AmountView(amount: amount, fallback: fallback, compact: compact)
					.padding(.leading, isSelected != nil ? .small2 : 0)

				if let isSelected {
					Spacer(minLength: .small2)
					CheckmarkView(appearance: .dark, isChecked: isSelected)
				}
			}
		}

		private var size: HitTargetSize {
			compact ? .smallest : .small
		}

		private var titleTextStyle: TextStyle {
			compact ? .body2HighImportance : .body1HighImportance
		}

		private var useSpacer: Bool {
			amount != nil || fallback != nil
		}
	}

	private struct NonFungibleView: View {
		let thumbnail: Thumbnail.NonFungibleContent
		let caption1: String?
		let caption2: String?
		let compact: Bool

		var body: some View {
			HStack(spacing: .zero) {
				CaptionedThumbnailView(
					type: thumbnail.type,
					url: thumbnail.url,
					caption1: caption1 ?? "-",
					caption2: caption2 ?? "-",
					compact: compact
				)

				Spacer(minLength: 0)
			}
		}
	}

	private struct CaptionedThumbnailView: View {
		let type: Thumbnail.ContentType
		let url: URL?
		let caption1: String?
		let caption2: String?
		let compact: Bool

		var body: some View {
			Thumbnail(type, url: url, size: size)
				.padding(.trailing, .small1)

			VStack(alignment: .leading, spacing: 0) {
				if let caption1 {
					Text(caption1)
						.textStyle(titleTextStyle)
						.foregroundColor(.app.gray1)
				}
				if let caption2 {
					Text(caption2)
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}
			}
			.lineLimit(1)
			.truncationMode(.tail)
		}

		private var size: HitTargetSize {
			compact ? .smallest : .smallish
		}

		private var titleTextStyle: TextStyle {
			compact ? .body2HighImportance : .body1HighImportance
		}
	}

	struct AmountView: View {
		@Environment(\.resourceBalanceHideFiatValue) var resourceBalanceHideFiatValue
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
			} else if let fallback {
				Text(fallback)
					.textStyle(amountTextStyle)
					.foregroundColor(.app.gray2)
			}
		}

		@ViewBuilder
		private func core(amount: ResourceBalance.Amount, compact: Bool) -> some View {
			if compact {
				VStack(alignment: .trailing, spacing: 0) {
					Text(amount.amount.nominalAmount.formatted())
						.textStyle(amountTextStyle)
						.foregroundColor(.app.gray1)
					if !resourceBalanceHideFiatValue, let fiatWorth = amount.amount.fiatWorth?.currencyFormatted(applyCustomFont: false) {
						Text(fiatWorth)
							.textStyle(.body2HighImportance)
							.foregroundStyle(.app.gray2)
							.padding(.top, .small3)
					}
				}
			} else {
				VStack(alignment: .trailing, spacing: 0) {
					if amount.guaranteed != nil {
						Text(L10n.TransactionReview.estimated)
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.gray1)
					}
					Text(amount.amount.nominalAmount.formatted())
						.lineLimit(1)
						.minimumScaleFactor(0.8)
						.truncationMode(.tail)
						.textStyle(.secondaryHeader)
						.foregroundColor(.app.gray1)

					if !resourceBalanceHideFiatValue, let fiatWorth = amount.amount.fiatWorth?.currencyFormatted(applyCustomFont: false) {
						Text(fiatWorth)
							.textStyle(.body2HighImportance)
							.foregroundStyle(.app.gray2)
							.padding(.top, .small3)
					}

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
