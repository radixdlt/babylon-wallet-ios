// MARK: - TokenBalanceView
public struct TokenBalanceView: View {
	public struct ViewState: Equatable {
		public let thumbnail: Thumbnail.TokenContent
		public let name: String
		public let balance: ResourceAmount
		public let iconSize: HitTargetSize

		public init(
			thumbnail: Thumbnail.TokenContent,
			name: String,
			balance: ResourceAmount,
			iconSize: HitTargetSize = .smallest
		) {
			self.thumbnail = thumbnail
			self.name = name
			self.balance = balance
			self.iconSize = iconSize
		}
	}

	let viewState: ViewState

	public init(viewState: ViewState) {
		self.viewState = viewState
	}

	public var body: some View {
		HStack(alignment: .center, spacing: .zero) {
			Thumbnail(token: viewState.thumbnail, size: viewState.iconSize)
				.padding(.trailing, .small1)

			Text(viewState.name)
				.foregroundColor(.app.gray1)
				.textStyle(.body2HighImportance)

			Spacer()
			VStack(alignment: .trailing) {
				Text(viewState.balance.nominalAmount.formatted())
					.foregroundColor(.app.gray1)
					.textStyle(.secondaryHeader)

				if let worth = viewState.balance.fiatWorth {
					Text(worth.currencyFormatted(applyCustomFont: false)!)
						.textStyle(.body2HighImportance)
						.foregroundStyle(.app.gray2)
				}
			}
		}
	}

	public struct Bordered: View {
		let viewState: ViewState

		public var body: some View {
			TokenBalanceView(viewState: viewState)
				.padding(.small1)
				.roundedCorners(strokeColor: .app.gray3)
		}
	}
}

extension TokenBalanceView.ViewState {
	public static func xrd(balance: ResourceAmount) -> Self {
		.init(
			thumbnail: .xrd,
			name: Constants.xrdTokenName,
			balance: balance
		)
	}
}
