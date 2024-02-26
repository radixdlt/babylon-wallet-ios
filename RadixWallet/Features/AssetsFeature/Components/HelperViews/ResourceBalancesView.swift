import SwiftUI

// MARK: - ResourceBalancesView
public struct ResourceBalancesView: View {
	public let resources: [ResourceBalance]

	public init(resources: [ResourceBalance]) {
		self.resources = resources
	}

	public init(fungibles: [ResourceBalance.Fungible]) {
		self.init(resources: fungibles.map(ResourceBalance.fungible))
	}

	public init(nonFungibles: [ResourceBalance.NonFungible]) {
		self.init(resources: nonFungibles.map(ResourceBalance.nonFungible))
	}

	public var body: some View {
		VStack(spacing: 0) {
			ForEach(resources) { resource in
				let isNotLast = resource.id != resources.last?.id
				ResourceBalanceView(resource: resource, appearance: .compact)
					.padding(.small1)
					.padding(.bottom, isNotLast ? dividerHeight : 0)
					.overlay(alignment: .bottom) {
						if isNotLast {
							Rectangle()
//								.fill(.app.gray3)
								.fill(.yellow)
								.frame(height: dividerHeight)
						}
					}
			}
		}
//		.roundedCorners(strokeColor: .app.gray3)
		.roundedCorners(strokeColor: .yellow)
	}

	private let dividerHeight: CGFloat = 1
}

// MARK: - ResourceBalance
public enum ResourceBalance: Sendable, Hashable {
	case fungible(Fungible)
	case nonFungible(NonFungible)
	case lsu(LSU)

	public struct Fungible: Sendable, Hashable {
		public let address: ResourceAddress
		public let icon: Thumbnail.FungibleContent
		public let title: String?
		public let amount: Amount?
		public let fallback: String?

		init(address: ResourceAddress, tokenIcon: Thumbnail.TokenContent, title: String?, amount: Amount? = nil, fallback: String? = nil) {
			self.init(
				address: address,
				icon: .token(tokenIcon),
				title: title,
				amount: amount,
				fallback: fallback
			)
		}

		init(address: ResourceAddress, icon: Thumbnail.FungibleContent, title: String?, amount: Amount? = nil, fallback: String? = nil) {
			self.address = address
			self.icon = icon
			self.title = title
			self.amount = amount
			self.fallback = fallback
		}
	}

	public struct NonFungible: Sendable, Hashable {
		public let id: NonFungibleGlobalId
		public let resourceImage: URL?
		public let resourceName: String?
		public let nonFungibleName: String?
	}

	public struct LSU: Sendable, Hashable {
		public let resource: OnLedgerEntity.Resource
		public let amount: Amount?
		public let worth: RETDecimal
		public var validatorName: String? = nil
	}

	// Helper types

	public struct Amount: Sendable, Hashable {
		public let amount: RETDecimal
		public let guaranteed: RETDecimal?

		init(_ amount: RETDecimal, guaranteed: RETDecimal? = nil) {
			self.amount = amount
			self.guaranteed = guaranteed
		}
	}
}

// MARK: - ResourceBalanceButton
public struct ResourceBalanceButton: View {
	public let resource: ResourceBalance
	public let appearance: Appearance
	public let isSelected: Bool?
	public let onTap: () -> Void

	public enum Appearance {
		case assetList
		case transactionReview
	}

	init(resource: ResourceBalance, appearance: Appearance, isSelected: Bool? = nil, onTap: @escaping () -> Void) {
		self.resource = resource
		self.appearance = appearance
		self.isSelected = isSelected
		self.onTap = onTap
	}

	public var body: some View {
		HStack(alignment: .center, spacing: .small2) {
			Button(action: onTap) {
				ResourceBalanceView(resource: resource, appearance: viewAppearance, isSelected: isSelected)
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
			switch resource {
			case .fungible, .nonFungible:
				.medium2
			case .lsu:
				.medium3
			}
		case .transactionReview:
			.medium2
		}
	}

	private var horizontalSpacing: CGFloat {
		switch appearance {
		case .assetList:
			switch resource {
			case .fungible, .nonFungible:
				.large3
			case .lsu:
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

// MARK: - ResourceBalanceView
public struct ResourceBalanceView: View {
	public let resource: ResourceBalance
	public let appearance: Appearance
	public let isSelected: Bool?

	public enum Appearance: Equatable {
		case standard
		case compact(border: Bool)

		static let compact: Appearance = .compact(border: false)
	}

	init(resource: ResourceBalance, appearance: Appearance = .standard, isSelected: Bool? = nil) {
		self.resource = resource
		self.appearance = appearance
		self.isSelected = isSelected
	}

	public var body: some View {
		if border {
			core
				.padding(.small1)
				.roundedCorners(strokeColor: .blue)
			//		.roundedCorners(strokeColor: .app.gray3)
		} else {
			core
		}
	}

	private var core: some View {
		HStack(alignment: .center, spacing: .small2) {
			switch resource {
			case let .fungible(viewState):
				Fungible(viewState: viewState, compact: compact)
			case let .nonFungible(viewState):
				NonFungible(viewState: viewState, compact: compact)
			case let .lsu(viewState):
				LSU(viewState: viewState, isSelected: isSelected)
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
		switch resource {
		case .fungible, .nonFungible:
			false
		case .lsu:
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

extension ResourceBalance.Fungible {
	public static func xrd(balance: RETDecimal) -> Self {
		.init(
			address: try! .init(validatingAddress: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"), // FIXME: REMOVE
			tokenIcon: .xrd,
			title: Constants.xrdTokenName,
			amount: .init(balance),
			fallback: nil
		)
	}
}

// MARK: - ResourceBalance + Identifiable
extension ResourceBalance: Identifiable {
	public var id: AnyHashable {
		self
	}
}

extension ResourceBalanceView {
	public struct Fungible: View {
		public let viewState: ResourceBalance.Fungible
		public let compact: Bool

		public var body: some View {
			HStack(spacing: .zero) {
				Thumbnail(fungible: viewState.icon, size: size)
					.padding(.trailing, .small1)

				if let title = viewState.title {
					Text(title)
						.lineLimit(1)
						.textStyle(titleTextStyle)
						.foregroundColor(.app.green1)
//						.foregroundColor(.app.gray1)
				}

				if useSpacer {
					Spacer(minLength: .small2)
				}

				AmountView(amount: viewState.amount, fallback: viewState.fallback, compact: compact)
			}
		}

		private var size: HitTargetSize {
			compact ? .smallest : .small
		}

		private var titleTextStyle: TextStyle {
			compact ? .body1HighImportance : .body2HighImportance
		}

		private var useSpacer: Bool {
			viewState.amount != nil || viewState.fallback != nil
		}
	}

	public struct NonFungible: View {
		public let viewState: ResourceBalance.NonFungible
		public let compact: Bool

		public var body: some View {
			HStack(spacing: .zero) {
				Thumbnail(.nft, url: viewState.resourceImage, size: size)
					.padding(.trailing, .small1)

				VStack(alignment: .leading, spacing: 0) {
					Text(line1)
						.textStyle(compact ? .body2HighImportance : .body1HighImportance)
						.foregroundColor(.app.green1)
//						.foregroundColor(.app.gray1)
					Text(line2)
						.textStyle(.body2Regular)
						.foregroundColor(.app.green1)
//						.foregroundColor(.app.gray2)
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
		let viewState: ResourceBalance.LSU
		let isSelected: Bool?

		public var body: some View {
			VStack(alignment: .leading, spacing: .medium3) {
				HStack(spacing: .zero) {
					Thumbnail(.lsu, url: viewState.resource.metadata.iconURL, size: .slightlySmaller)
						.padding(.trailing, .small2)

					VStack(alignment: .leading, spacing: .zero) {
						if let title = viewState.resource.metadata.title {
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

					ResourceBalanceView(resource: .fungible(.xrd(balance: viewState.worth)), appearance: .compact(border: true))
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
