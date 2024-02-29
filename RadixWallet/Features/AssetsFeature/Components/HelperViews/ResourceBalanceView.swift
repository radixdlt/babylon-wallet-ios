import SwiftUI

// MARK: - ResourceBalancesView
public struct ResourceBalancesView: View {
	public let viewState: [ResourceBalance.ViewState]

	public init(_ viewState: [ResourceBalance.ViewState]) {
		self.viewState = viewState
	}

	public init(fungibles: [ResourceBalance.ViewState.Fungible]) {
		self.init(fungibles.map(ResourceBalance.ViewState.fungible))
	}

	public init(nonFungibles: [ResourceBalance.ViewState.NonFungible]) {
		self.init(nonFungibles.map(ResourceBalance.ViewState.nonFungible))
	}

	public var body: some View {
		VStack(spacing: 0) {
			ForEach(viewState) { resource in
				let isNotLast = resource.id != viewState.last?.id
				ResourceBalanceView(resource, appearance: .compact)
					.padding(.small1)
					.padding(.bottom, isNotLast ? dividerHeight : 0)
					.overlay(alignment: .bottom) {
						if isNotLast {
							Rectangle()
								.fill(.app.gray3)
								.frame(height: dividerHeight)
						}
					}
			}
		}
		.roundedCorners(strokeColor: .app.gray3)
	}

	private let dividerHeight: CGFloat = 1
}

// MARK: - ResourceBalanceButton
public struct ResourceBalanceButton: View {
	public let viewState: ResourceBalance.ViewState
	public let appearance: Appearance
	public let isSelected: Bool?
	public let onTap: () -> Void

	public enum Appearance {
		case assetList
		case transactionReview
	}

	init(_ viewState: ResourceBalance.ViewState, appearance: Appearance, isSelected: Bool? = nil, onTap: @escaping () -> Void) {
		self.viewState = viewState
		self.appearance = appearance
		self.isSelected = isSelected
		self.onTap = onTap
	}

	public var body: some View {
		HStack(alignment: .center, spacing: .small2) {
			Button(action: onTap) {
				ResourceBalanceView(viewState, appearance: viewAppearance, isSelected: isSelected)
					.padding(.vertical, verticalSpacing)
					.padding(.horizontal, horizontalSpacing)
					.contentShape(Rectangle())
					.background(background)
			}
		}
	}

	private var viewAppearance: ResourceBalanceView.Appearance {
		switch appearance {
		case .assetList, .transactionReview:
			.standard
		}
	}

	private var verticalSpacing: CGFloat {
		switch appearance {
		case .assetList:
			switch viewState {
			case .fungible, .nonFungible:
				.medium2
			case .lsu, .poolUnit, .stakeClaimNFT:
				.medium3
			}
		case .transactionReview:
			.medium2
		}
	}

	private var horizontalSpacing: CGFloat {
		switch appearance {
		case .assetList:
			switch viewState {
			case .fungible, .nonFungible:
				.large3
			case .lsu, .poolUnit, .stakeClaimNFT:
				.medium3
			}
		case .transactionReview:
			.medium2
		}
	}

	private var background: Color {
		switch appearance {
		case .assetList:
			.white
		case .transactionReview:
			.app.gray5
		}
	}
}

extension EnvironmentValues {
	/// The fallback string when the amount value is missing
	var missingFungibleAmountFallback: String? {
		get { self[MissingFungibleAmountKey.self] }
		set { self[MissingFungibleAmountKey.self] = newValue }
	}
}

// MARK: - MissingFungibleAmountKey
private struct MissingFungibleAmountKey: EnvironmentKey {
	static let defaultValue: String? = nil
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
				fatalError() // FIXME: GK
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
	func withAuxiliary(spacing: CGFloat = 0, _ content: () -> some View) -> some View {
		HStack(spacing: 0) {
			self
				.layoutPriority(1)

			Spacer(minLength: spacing)

			content()
				.layoutPriority(-1)
		}
	}
}

extension ResourceBalance.ViewState.Fungible {
	public static func xrd(balance: RETDecimal) -> Self {
		.init(
			address: try! .init(validatingAddress: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"), // FIXME: REMOVE
			icon: .token(.xrd),
			title: Constants.xrdTokenName,
			amount: .init(balance)
		)
	}
}

// MARK: - ResourceBalance.ViewState + Identifiable
extension ResourceBalance.ViewState: Identifiable {
	public var id: AnyHashable {
		self
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

extension ResourceBalance.ViewState.PoolUnit {
	public init(poolUnit: OnLedgerEntity.Account.PoolUnit, details: Loadable<OnLedgerEntitiesClient.OwnedResourcePoolDetails> = .idle) {
		self.init(
			resourcePoolAddress: poolUnit.resourcePoolAddress,
			poolUnitAddress: poolUnit.resource.resourceAddress,
			poolIcon: poolUnit.resource.metadata.iconURL,
			poolName: poolUnit.resource.metadata.fungibleResourceName,
			amount: nil,
			dAppName: details.dAppName,
			resources: details.map { .init(resources: $0) }
		)
	}
}
