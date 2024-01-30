// MARK: - TokenBalanceView
public struct TokenBalanceView: View {
	public struct ViewState {
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
}

extension TokenBalanceView {
	public static func xrd(balance: RETDecimal) -> Self {
		TokenBalanceView(
			viewState: .init(
				thumbnail: .xrd,
				name: "XRD",
				balance: balance
			)
		)
	}
}
