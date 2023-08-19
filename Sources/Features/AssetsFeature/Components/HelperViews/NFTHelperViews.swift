import EngineKit
import FeaturePrelude
import SharedModels

// MARK: - NFTFullView
struct NFTFullView: View {
	let url: URL
	let minAspect: CGFloat
	let maxAspect: CGFloat

	init(url: URL, minAspect: CGFloat = .zero, maxAspect: CGFloat = .infinity) {
		self.url = url
		self.minAspect = minAspect
		self.maxAspect = maxAspect
	}

	var body: some View {
		LoadableImage(
			url: url,
			size: .flexible(minAspect: minAspect, maxAspect: maxAspect),
			placeholders: .init(loading: .shimmer)
		)
		.cornerRadius(.small1)
	}
}

// MARK: - NFTIDView
struct NFTIDView: View {
	let id: String
	let name: String?
	let description: String?
	let thumbnail: URL?

	var body: some View {
		VStack(spacing: .small1) {
			if let thumbnail {
				NFTFullView(
					url: thumbnail,
					minAspect: minImageAspect,
					maxAspect: maxImageAspect
				)
				.padding(.bottom, .small1)
			}
			NFTNameAndIDView(name: name, id: id)
		}
	}

	private let minImageAspect: CGFloat = 1
	private let maxImageAspect: CGFloat = 16 / 9
}

// MARK: - NFTNameAndIDView
private struct NFTNameAndIDView: View {
	let name: String?
	let id: String

	var body: some View {
		VStack(alignment: .leading, spacing: .small3) {
			if let name {
				Text(name)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray1)
			}

			Text(id)
				.textStyle(.body2HighImportance)
				.foregroundColor(.app.gray2)
		}
		.flushedLeft
	}
}
