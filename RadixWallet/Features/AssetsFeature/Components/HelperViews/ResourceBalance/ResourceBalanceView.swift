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
		case unknown

		struct Fungible: Sendable, Hashable {
			let address: ResourceAddress
			let icon: Thumbnail.FungibleContent
			let title: String?
			let amount: ResourceAmount?
		}

		struct NonFungible: Sendable, Hashable {
			let id: NonFungibleGlobalId?
			let resourceImage: URL?
			let resourceName: String?
			let nonFungibleName: String?
			let amount: ResourceAmount?
		}

		struct LiquidStakeUnit: Sendable, Hashable {
			let address: ResourceAddress
			let icon: URL?
			let title: String?
			let amount: ResourceAmount?
			let worth: ResourceAmount
			var validatorName: String? = nil
		}

		struct PoolUnit: Sendable, Hashable {
			let resourcePoolAddress: PoolAddress
			let poolUnitAddress: ResourceAddress
			let poolIcon: URL?
			let poolName: String?
			let amount: ResourceAmount?
			var dAppName: Loadable<String?>
			var resources: Loadable<[Fungible]>
		}

		typealias StakeClaimNFT = KnownResourceBalance.StakeClaimNFT
	}

	var viewState: ViewState {
		switch self {
		case let .known(known):
			switch known.details {
			case let .fungible(details):
				.fungible(.init(resource: known.resource, details: details))
			case let .nonFungible(details):
				.nonFungible(.init(resource: known.resource, details: details))
			case let .liquidStakeUnit(details):
				.liquidStakeUnit(.init(resource: known.resource, details: details))
			case let .poolUnit(details):
				.poolUnit(.init(resource: known.resource, details: details))
			case let .stakeClaimNFT(details):
				.stakeClaimNFT(details)
			}
		case .unknown:
			.unknown
		}
	}
}

private extension ResourceBalance.ViewState.Fungible {
	init(resource: OnLedgerEntity.Resource, details: KnownResourceBalance.Fungible) {
		self.init(
			address: resource.resourceAddress,
			icon: .token(details.isXRD ? .xrd : .other(resource.metadata.iconURL)),
			title: resource.metadata.title,
			amount: details.amount
		)
	}
}

private extension ResourceBalance.ViewState.NonFungible {
	init(resource: OnLedgerEntity.Resource, details: KnownResourceBalance.NonFungible) {
		switch details {
		case let .token(token):
			self.init(
				id: token.id,
				resourceImage: resource.metadata.iconURL,
				resourceName: resource.metadata.name,
				nonFungibleName: token.data?.name,
				amount: nil
			)
		case let .amount(amount):
			self.init(
				id: nil,
				resourceImage: resource.metadata.iconURL,
				resourceName: resource.metadata.name,
				nonFungibleName: resource.resourceAddress.formatted(),
				amount: .init(amount)
			)
		}
	}
}

private extension ResourceBalance.ViewState.LiquidStakeUnit {
	init(resource: OnLedgerEntity.Resource, details: KnownResourceBalance.LiquidStakeUnit) {
		self.init(
			address: resource.resourceAddress,
			icon: resource.metadata.iconURL,
			title: resource.metadata.title,
			amount: details.amount,
			worth: details.worth,
			validatorName: details.validator.metadata.name
		)
	}
}

private extension ResourceBalance.ViewState.PoolUnit {
	init(resource: OnLedgerEntity.Resource, details: KnownResourceBalance.PoolUnit) {
		self.init(
			resourcePoolAddress: details.details.address,
			poolUnitAddress: resource.resourceAddress,
			poolIcon: resource.metadata.iconURL,
			poolName: resource.fungibleResourceName,
			amount: details.details.poolUnitResource.amount,
			dAppName: .success(details.details.dAppName),
			resources: .success(.init(resources: details.details))
		)
	}
}

// MARK: - ResourceBalanceView
struct ResourceBalanceView: View {
	let viewState: ResourceBalance.ViewState
	let appearance: Appearance
	let hasBorder: Bool
	let isSelected: Bool?
	let action: (() -> Void)?

	enum Appearance: Sendable, Equatable {
		case standard
		case compact
	}

	init(
		_ viewState: ResourceBalance.ViewState,
		appearance: Appearance = .standard,
		hasBorder: Bool = false,
		isSelected: Bool? = nil,
		action: (() -> Void)? = nil
	) {
		self.viewState = viewState
		self.appearance = appearance
		self.hasBorder = hasBorder
		self.isSelected = isSelected
		self.action = action
	}

	var body: some View {
		content
			.embedInButton(when: action)
	}

	@ViewBuilder
	private var content: some View {
		if hasBorder {
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
			case .unknown:
				Unknown()
			}

			if !delegateSelection, let isSelected {
				CheckmarkView(appearance: .dark, isChecked: isSelected)
			}
		}
	}

	var compact: Bool {
		appearance != .standard
	}

	/// Delegate showing the selection state to the particular resource view
	var delegateSelection: Bool {
		switch viewState {
		case .fungible, .nonFungible, .unknown:
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
				caption1: viewState.resourceName ?? viewState.id?.resourceAddress.formatted(),
				caption2: viewState.nonFungibleName ?? viewState.id?.localID.formatted(),
				compact: compact,
				amount: viewState.amount
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

						ResourceBalanceView(
							.fungible(fungible),
							appearance: .compact,
							hasBorder: true
						)
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
					Text(L10n.InteractionReview.worth.uppercased())
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray2)
						.padding(.top, .small2)
						.padding(.bottom, .small3)

					loadable(viewState.resources) { fungibles in
						ResourceBalancesView(fungibles: fungibles, appearance: .compact)
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
					compact: compact,
					amount: nil
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

			var viewState: KnownResourceBalance.StakeClaimNFT.Tokens
			let background: Color
			let onTap: ((OnLedgerEntitiesClient.StakeClaim) -> Void)?
			let onClaimAllTapped: (() -> Void)?

			init(
				viewState: KnownResourceBalance.StakeClaimNFT.Tokens,
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
									.fungible(.xrd(balance: .exact(claim.claimAmount), network: claim.validatorAddress.networkID)),
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

	struct Unknown: View {
		var body: some View {
			HStack(spacing: .small1) {
				Image(.unknownDeposits)

				Text("----")
					.textStyle(.body2HighImportance)
					.foregroundStyle(.app.gray4)

				StatusMessageView(
					text: L10n.InteractionReview.Unknown.deposits,
					type: .warning,
					useNarrowSpacing: true,
					useSmallerFontSize: true
				)
			}
			.frame(maxWidth: .infinity)
		}
	}

	// Helper Views

	private struct FungibleView: View {
		let thumbnail: Thumbnail.FungibleContent
		let caption1: String?
		let caption2: String?
		let fallback: String?
		let amount: ResourceAmount?
		let compact: Bool
		let isSelected: Bool?

		var body: some View {
			VStack(alignment: .leading) {
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

					AmountView(amount: amount, fallback: fallback, appearance: compact ? .compact : .standard)
						.padding(.leading, isSelected != nil ? .small2 : 0)

					if let isSelected {
						Spacer(minLength: .small2)
						CheckmarkView(appearance: .dark, isChecked: isSelected)
					}
				}

				if case .unknown = amount {
					StatusMessageView(
						text: L10n.InteractionReview.Unknown.amount,
						type: .warning,
						useNarrowSpacing: true,
						useSmallerFontSize: true
					)
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
		let amount: ResourceAmount?

		var body: some View {
			VStack(alignment: .leading) {
				HStack(spacing: .zero) {
					CaptionedThumbnailView(
						type: thumbnail.type,
						url: thumbnail.url,
						caption1: caption1 ?? "-",
						caption2: caption2 ?? "-",
						compact: compact
					)

					Spacer(minLength: amount != nil ? .small2 : 0)

					if let amount {
						AmountView(amount: amount, appearance: compact ? .compact : .standard)
					}
				}

				if case .unknown = amount {
					StatusMessageView(
						text: L10n.InteractionReview.Unknown.amount,
						type: .warning,
						useNarrowSpacing: true,
						useSmallerFontSize: true
					)
				}
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
			compact ? .smallest : .small
		}

		private var titleTextStyle: TextStyle {
			compact ? .body2HighImportance : .body1HighImportance
		}
	}

	struct AmountView: View {
		let amount: ResourceAmount?
		let fallback: String?
		let appearance: Appearance
		let symbol: Loadable<String?>?

		enum Appearance: Sendable, Equatable {
			case standard
			case compact
			case large
		}

		init(
			amount: ResourceAmount?,
			fallback: String? = nil,
			appearance: Appearance,
			symbol: Loadable<String?>? = nil
		) {
			self.amount = amount
			self.fallback = fallback
			self.appearance = appearance
			self.symbol = symbol
		}

		var body: some View {
			if let amount {
				switch amount {
				case let .exact(exactAmount):
					SubAmountView(
						amount: exactAmount,
						appearance: appearance,
						symbol: symbol
					)
				case let .atLeast(exactAmount):
					SubAmountView(
						title: L10n.InteractionReview.atLeast,
						amount: exactAmount,
						appearance: appearance,
						symbol: symbol
					)
				case let .between(minAmount, maxAmount):
					VStack(alignment: alignment, spacing: .small3) {
						SubAmountView(
							title: L10n.InteractionReview.atLeast,
							amount: minAmount,
							appearance: appearance,
							symbol: symbol
						)
						SubAmountView(
							title: L10n.InteractionReview.noMoreThan,
							amount: maxAmount,
							appearance: appearance,
							symbol: symbol
						)
					}
				case let .predicted(predicted, guaranteed):
					SubAmountView(
						amount: predicted,
						guaranteed: guaranteed,
						appearance: appearance,
						symbol: symbol
					)
				case .unknown:
					EmptyView()
				}
			} else if let fallback {
				Text(fallback)
					.textStyle(amountTextStyle)
					.foregroundColor(.app.gray2)
			}
		}

		private var amountTextStyle: TextStyle {
			switch appearance {
			case .standard, .large:
				.secondaryHeader
			case .compact:
				.body1HighImportance
			}
		}

		private var alignment: HorizontalAlignment {
			switch appearance {
			case .standard, .compact:
				.trailing
			case .large:
				.center
			}
		}
	}

	struct SubAmountView: View {
		@Environment(\.resourceBalanceHideFiatValue) var resourceBalanceHideFiatValue
		let title: String?
		let amount: ExactResourceAmount
		let guaranteed: ExactResourceAmount?
		let appearance: AmountView.Appearance
		let symbol: Loadable<String?>?

		init(
			title: String? = nil,
			amount: ExactResourceAmount,
			guaranteed: ExactResourceAmount? = nil,
			appearance: AmountView.Appearance,
			symbol: Loadable<String?>?
		) {
			self.title = title
			self.amount = amount
			self.guaranteed = guaranteed
			self.appearance = appearance
			self.symbol = symbol
		}

		var body: some View {
			if appearance == .compact {
				VStack(alignment: .trailing, spacing: 0) {
					if let title {
						Text(title)
							.textStyle(titleTextStyle)
							.foregroundColor(.app.gray1)
					}
					amountView(amount: amount.nominalAmount, isGuaranteed: false)
						.textStyle(amountTextStyle)
						.foregroundColor(.app.gray1)
					if !resourceBalanceHideFiatValue, let fiatWorth = amount.fiatWorth?.currencyFormatted(applyCustomFont: false) {
						Text(fiatWorth)
							.textStyle(.body2HighImportance)
							.foregroundStyle(.app.gray2)
							.padding(.top, .small3)
					}
				}
			} else {
				VStack(alignment: alignment, spacing: 0) {
					if guaranteed != nil {
						Text(L10n.InteractionReview.estimated)
							.textStyle(titleTextStyle)
							.foregroundColor(.app.gray1)
					} else if let title {
						Text(title)
							.textStyle(titleTextStyle)
							.foregroundColor(.app.gray1)
					}

					amountView(amount: amount.nominalAmount, isGuaranteed: false)
						.textStyle(amountTextStyle)
						.foregroundColor(.app.gray1)

					if !resourceBalanceHideFiatValue, let fiatWorth = amount.fiatWorth?.currencyFormatted(applyCustomFont: false) {
						Text(fiatWorth)
							.textStyle(.body2HighImportance)
							.foregroundStyle(.app.gray2)
							.padding(.top, .small3)
					}

					if let guaranteedAmount = guaranteed?.nominalAmount {
						Text(L10n.InteractionReview.guaranteed)
							.textStyle(.body3Regular)
							.foregroundColor(.app.gray2)
							.padding(.top, .small3)

						amountView(amount: guaranteedAmount, isGuaranteed: true)
							.textStyle(guaranteedAmountTextStyle)
							.foregroundColor(.app.gray2)
					}
				}
			}
		}

		@ViewBuilder
		private func amountView(amount: Decimal192, isGuaranteed: Bool) -> some View {
			let amountView = Text(amount.formatted())

			if let wrappedValue = symbol?.wrappedValue, let symbol = wrappedValue {
				(amountView + Text(" " + symbol).font(isGuaranteed ? .app.body2Header : .app.secondaryHeader))
					.lineLimit(1)
					.minimumScaleFactor(0.8)
					.truncationMode(.tail)
			} else {
				amountView
					.lineLimit(1)
					.minimumScaleFactor(0.8)
					.truncationMode(.tail)
			}
		}

		private var titleTextStyle: TextStyle {
			switch appearance {
			case .standard, .compact:
				.body3Regular
			case .large:
				.body1HighImportance
			}
		}

		private var amountTextStyle: TextStyle {
			switch appearance {
			case .standard:
				.secondaryHeader
			case .compact:
				.body1HighImportance
			case .large:
				.sheetTitle
			}
		}

		private var guaranteedAmountTextStyle: TextStyle {
			switch appearance {
			case .standard, .compact:
				.body1Header
			case .large:
				.sectionHeader
			}
		}

		private var alignment: HorizontalAlignment {
			switch appearance {
			case .standard, .compact:
				.trailing
			case .large:
				.center
			}
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
			L10n.InteractionReview.toBeClaimed
		}
	}
}
