import Prelude

public struct TokenBalanceView: View {
	public struct ViewState {
		public let thumbnail: TokenThumbnail.Content
		public let name: String
		public let balance: BigDecimal

		public init(thumbnail: TokenThumbnail.Content, name: String, balance: BigDecimal) {
			self.thumbnail = thumbnail
			self.name = name
			self.balance = balance
		}
	}

	let viewState: ViewState

	public init(viewState: ViewState) {
		self.viewState = viewState
	}

	public var body: some View {
		HStack(alignment: .center) {
			TokenThumbnail(viewState.thumbnail, size: .small)
				.padding(.trailing, .small1)
			Text(viewState.name)
				.foregroundColor(.app.gray1)
				.textStyle(.body2HighImportance)

			Spacer()

			Text(viewState.balance.format())
				.foregroundColor(.app.gray1)
				.textStyle(.secondaryHeader)
		}
	}
}
