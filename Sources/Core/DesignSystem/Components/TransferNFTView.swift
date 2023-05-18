public struct TransferNFTView: View {
	let name: String?
	let thumbnail: URL?

	public init(name: String?, thumbnail: URL?) {
		self.name = name
		self.thumbnail = thumbnail
	}

	public var body: some View {
		HStack(spacing: .small1) {
			NFTThumbnail(thumbnail, size: .small)
				.padding(.vertical, .small1)

			if let name {
				Text(name)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray1)
			}

			Spacer(minLength: 0)
		}
		.padding(.horizontal, .medium3)
	}
}
