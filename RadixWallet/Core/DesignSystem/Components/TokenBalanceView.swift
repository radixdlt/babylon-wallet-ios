// MARK: - TokenBalanceView
public struct TokenBalanceView: View {
	public struct ViewState: Equatable {
		public let thumbnail: TokenThumbnail.Content
		public let name: String
		public let balance: RETDecimal
		public let iconSize: HitTargetSize

		public init(
			thumbnail: TokenThumbnail.Content,
			name: String,
			balance: RETDecimal,
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
			TokenThumbnail(viewState.thumbnail, size: viewState.iconSize)
				.padding(.trailing, .small1)

			Text(viewState.name)
				.foregroundColor(.app.gray1)
				.textStyle(.body2HighImportance)

			Spacer()

			Text(viewState.balance.formatted())
				.foregroundColor(.app.gray1)
				.textStyle(.secondaryHeader)
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
	public static func xrd(balance: RETDecimal) -> Self {
		.init(
			thumbnail: .xrd,
			name: Constants.xrdTokenName,
			balance: balance
		)
	}
}
