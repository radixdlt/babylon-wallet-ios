public struct TransferNFTView: View {
	let resourceName: String?
	let id: String
	let idName: String?
	let thumbnail: URL?

	public init(
		resourceName: String?,
		id: String,
		idName: String?,
		thumbnail: URL?
	) {
		self.resourceName = resourceName
		self.id = id
		self.idName = idName
		self.thumbnail = thumbnail
	}

	public var body: some View {
		HStack(spacing: .small1) {
			NFTThumbnail(thumbnail, size: .small)
				.padding(.vertical, .small1)

			VStack(alignment: .leading, spacing: 0) {
				if let resourceName {
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
		guard let idName else { return id }
		return "\(id): \(idName)"
	}
}
