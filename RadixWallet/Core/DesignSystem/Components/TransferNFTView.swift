// MARK: - TransferNFTView
public struct TransferNFTView: View {
	let viewState: ViewState
	let background: Color
	let onTap: () -> Void
	let disabled: Bool

	public init(viewState: ViewState, background: Color, onTap: (() -> Void)? = nil) {
		self.viewState = viewState
		self.background = background
		self.onTap = onTap ?? {}
		self.disabled = onTap == nil
	}

	public var body: some View {
		Button(action: onTap) {
			HStack(spacing: .zero) {
				NFTThumbnail(viewState.thumbnail, size: .small)
					.padding([.vertical, .trailing], .small1)

				Spacer(minLength: 0)

				VStack(alignment: .leading, spacing: 0) {
					Text(viewState.tokenID)
						.multilineTextAlignment(.leading)
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
						.lineLimit(1)

					if let tokenName = viewState.tokenName {
						Text(tokenName)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray1)
					}
				}
			}
			.padding(.horizontal, .medium3)
			.background(background)
		}
		.disabled(disabled)
		.buttonStyle(.borderless)
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

// MARK: TransferNFTView.ViewState
extension TransferNFTView {
	public struct ViewState: Equatable {
		public let tokenID: String
		public let tokenName: String?
		public let thumbnail: URL?

		public init(tokenID: String, tokenName: String?, thumbnail: URL?) {
			self.tokenID = tokenID
			self.tokenName = tokenName
			self.thumbnail = thumbnail
		}
	}
}
