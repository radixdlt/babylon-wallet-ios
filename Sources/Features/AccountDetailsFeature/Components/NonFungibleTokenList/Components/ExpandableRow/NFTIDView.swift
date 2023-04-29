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

				ForEach(metadata) { pair in
					KeyValueView(key: pair.key, value: pair.value, isID: false)
				}
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
			ExpandableRowBackgroundView(
				paddingEdge: edge,
				paddingValue: value,
				cornerRadius: oppositeValue
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

// MARK: - NFTIDView + ExpandableRow
extension NFTIDView: ExpandableRow {
	var edge: Edge.Set {
		isLast ? .top : .all
	}

	var value: CGFloat {
		isExpanded ? Constants.radius : 0
	}

	var oppositeValue: CGFloat {
		isExpanded ? 0 : Constants.radius
	}
}

// MARK: - NFTIDView.Constants
extension NFTIDView {
	fileprivate enum Constants {
		static let radius: CGFloat = .small1
	}
}
