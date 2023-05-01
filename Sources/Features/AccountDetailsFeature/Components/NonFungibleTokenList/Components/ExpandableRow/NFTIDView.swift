import FeaturePrelude
import SharedModels

// MARK: - NFTView
struct NFTView: View {
	let url: URL?

	var body: some View {
		LoadableImage(url: url, size: .flexibleHeight, loading: .shimmer) {
			Rectangle()
				.fill(.gray)
				.frame(height: .large1)
		}
		.cornerRadius(.small3)
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

				KeyValueView(key: L10n.AccountDetails.id, value: id, isID: true)
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
struct KeyValueView: View {
	let key: String
	let value: String
	let isID: Bool

	var body: some View {
		HStack(alignment: .top, spacing: 0) {
			Text(key)
				.textStyle(.body1Regular)
			Spacer(minLength: 0)
			Text(value)
				.foregroundColor(isID ? .app.gray2 : .app.gray1)
				.textStyle(.body1HighImportance)
		}
		.foregroundColor(.app.gray2)
	}
}
