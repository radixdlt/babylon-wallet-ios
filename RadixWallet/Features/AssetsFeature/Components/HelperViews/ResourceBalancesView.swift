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
				ResourceBalanceView(resource: resource, compact: true)
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
//		.roundedCorners(strokeColor: .green)
	}

	private let dividerHeight: CGFloat = 1
}

// MARK: - ResourceBalance
public enum ResourceBalance: Sendable, Hashable {
	case fungible(Fungible)
	case nonFungible(NonFungible)

	public struct Fungible: Sendable, Hashable {
		public let address: ResourceAddress
		public let title: String?
		public let icon: Thumbnail.TokenContent
		public let amount: Amount?
		public let fallback: String?
	}

	public struct NonFungible: Sendable, Hashable {
		public let id: NonFungibleGlobalId
		public let resourceName: String?
		public let nonFungibleName: String?
		public let icon: URL?
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

// MARK: - ResourceBalanceView
public struct ResourceBalanceView: View {
	public let resource: ResourceBalance
	public let compact: Bool

	init(resource: ResourceBalance, compact: Bool) {
		self.resource = resource
		self.compact = compact
	}

	public var body: some View {
		switch resource {
		case let .fungible(viewState):
			Fungible(viewState: viewState, compact: compact)
		case let .nonFungible(viewState):
			NonFungible(viewState: viewState, compact: compact)
		}
	}
}

extension ResourceBalanceView {
	var bordered: some View {
		padding(.small1)
			.roundedCorners(strokeColor: .app.gray3)
//			.roundedCorners(strokeColor: .yellow)
	}
}

extension ResourceBalance.Fungible {
	public static func xrd(balance: RETDecimal) -> Self {
		.init(
			address: try! .init(validatingAddress: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"), // FIXME: REMOVE
			title: Constants.xrdTokenName,
			icon: .xrd,
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
				Thumbnail(token: viewState.icon, size: size)
					.padding(.trailing, .small1)

				if let title = viewState.title {
					Text(title)
						.textStyle(titleTextStyle)
						.foregroundColor(.app.gray1)
				}

				Spacer(minLength: .small2)

				AmountView(amount: viewState.amount, fallback: viewState.fallback, compact: compact)
			}
		}

		private var size: HitTargetSize {
			compact ? .smallest : .small
		}

		private var titleTextStyle: TextStyle {
			compact ? .body1HighImportance : .body2HighImportance
		}
	}

	public struct NonFungible: View {
		public let viewState: ResourceBalance.NonFungible
		public let compact: Bool

		public var body: some View {
			HStack(spacing: .zero) {
				Thumbnail(.nft, url: viewState.icon, size: size)
					.padding(.trailing, .small1)

				if compact {
					Text(compactTitle)
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray1)
				} else {
					VStack(alignment: .leading, spacing: .small3) {
						if let nonFungibleName = viewState.nonFungibleName {
							Text(nonFungibleName)
								.textStyle(.body2Regular)
								.foregroundColor(.app.gray1)
						}
						if let resourceName = viewState.resourceName {
							Text(resourceName)
								.textStyle(.body1HighImportance)
								.foregroundColor(.app.gray1)
						}
					}
				}

				Spacer(minLength: 0)
			}
		}

		private var size: HitTargetSize {
			compact ? .smallest : .smallish
		}

		private var compactTitle: String {
			viewState.nonFungibleName ?? viewState.id.localId().toUserFacingString().formatted(.default)
		}
	}

	// Helper Views

	struct AmountView: View {
		let amount: ResourceBalance.Amount?
		let fallback: String?
		let compact: Bool

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
						.textStyle(.body1Header)
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
