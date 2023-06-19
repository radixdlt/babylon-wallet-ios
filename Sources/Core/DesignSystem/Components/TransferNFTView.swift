// MARK: - TransferNFTView
public struct TransferNFTView: View {
	public let viewState: ViewState

	public init(viewState: ViewState) {
		self.viewState = viewState
	}

	public var body: some View {
		HStack(spacing: .small1) {
			NFTThumbnail(viewState.thumbnail, size: .small)
				.padding(.vertical, .small1)

			VStack(alignment: .leading, spacing: 0) {
				if let resourceName = viewState.resourceName {
					Text(resourceName)
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}

				Text(subtitle)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray1)
			}

			Spacer(minLength: 0)
		}
		.padding(.horizontal, .medium3)
	}

	private var subtitle: String {
		guard let tokenName = viewState.tokenName else { return viewState.tokenID }
		return "\(viewState.tokenID): \(tokenName)"
	}
}

// MARK: TransferNFTView.ViewState
extension TransferNFTView {
	public struct ViewState: Equatable {
		public let resourceName: String?
		public let tokenID: String
		public let tokenName: String?
		public let thumbnail: URL?

		public init(resourceName: String?, tokenID: String, tokenName: String?, thumbnail: URL?) {
			self.resourceName = resourceName
			self.tokenID = tokenID
			self.tokenName = tokenName
			self.thumbnail = thumbnail
		}
	}
}
