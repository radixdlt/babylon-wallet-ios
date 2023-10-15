// MARK: - TransferNFTView
public struct TransferNFTView: View {
	let viewState: ViewState
	let onTap: () -> Void
	let disabled: Bool

	public init(viewState: ViewState, onTap: (() -> Void)? = nil) {
		self.viewState = viewState
		self.onTap = onTap ?? {}
		self.disabled = onTap == nil
	}

	public var body: some View {
		Button(action: onTap) {
			HStack(spacing: .small1) {
				NFTThumbnail(viewState.thumbnail, size: .small)
					.padding(.vertical, .small1)

				VStack(alignment: .leading, spacing: 0) {
					Text(viewState.tokenID)
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)

					if let tokenName = viewState.tokenName {
						Text(tokenName)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray1)
					}
				}
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal, .medium3)
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
