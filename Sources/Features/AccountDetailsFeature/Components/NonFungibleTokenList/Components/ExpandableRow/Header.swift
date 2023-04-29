import FeaturePrelude

// MARK: - Header
struct Header: View {
	let name: String
	let thumbnail: URL?
	let isExpanded: Bool

	var body: some View {
		HStack(spacing: .zero) {
			NFTThumbnail(thumbnail, size: .small)
				.padding(.trailing, .medium3)

			VStack(alignment: .leading, spacing: .small2) {
				Text(name)
					.foregroundColor(.app.gray1)
					.textStyle(.secondaryHeader)
			}

			Spacer(minLength: 0)
		}
		.padding(.horizontal, .medium1)
		.padding(.vertical, .large3)
		.background(
			RoundedCornerBackground(
				exclude: isExpanded ? .bottom : [],
				cornerRadius: Constants.radius
			)
			.tokenRowShadow(!isExpanded)
		)
	}
}

// MARK: Header.Constants
extension Header {
	fileprivate enum Constants {
		static let radius: CGFloat = .small1
	}
}
