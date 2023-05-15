import FeaturePrelude
import SharedModels

// MARK: - NFTView
struct NFTView: View {
	let url: URL?

	var body: some View {
		LoadableImage(url: url, size: .flexibleHeight, loading: .shimmer) {
			Rectangle()
				.fill(.app.gray4)
				.frame(height: .large2)
		}
		.cornerRadius(.small1)
	}
}

// MARK: - NFTIDView
struct NFTIDView: View {
	let id: String
	let name: String?
	let description: String?
	let thumbnail: URL?
	let metadata: [AccountPortfolio.Metadata]
	let isLast: Bool
	let isExpanded: Bool

	var body: some View {
		VStack(spacing: .small1) {
			if isExpanded {
				NFTView(url: thumbnail)
					.padding(.bottom, .small1)

				KeyValueView(key: L10n.AssetDetails.NFTDetails.id, value: id)
			} else {
				// This is apparently needed, else the card disappears when not expanded
				Rectangle()
					.fill(.clear)
					.frame(height: 20)
			}
		}
		.padding(.medium1)
		.frame(maxWidth: .infinity)
		.background(
			RoundedCornerBackground(
				exclude: isExpanded ? (isLast ? .top : .vertical) : [],
				cornerRadius: .small1
			)
			.tokenRowShadow(isLast || !isExpanded)
		)
	}
}

// MARK: - KeyValueView
struct KeyValueView<Content: View>: View {
	let key: String
	let content: Content

	init(key: String, value: String) where Content == Text {
		self.key = key
		self.content = Text(value)
	}

	init(key: String, @ViewBuilder content: () -> Content) {
		self.key = key
		self.content = content()
	}

	var body: some View {
		HStack(alignment: .top, spacing: 0) {
			Text(key)
				.textStyle(.body1Regular)
				.foregroundColor(.app.gray2)
			Spacer(minLength: 0)
			content
				.multilineTextAlignment(.trailing)
				.textStyle(.body1HighImportance)
				.foregroundColor(.app.gray1)
		}
	}
}
