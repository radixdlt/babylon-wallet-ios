import FeaturePrelude
import SharedModels

// MARK: - NFTView
struct NFTView: View {
	let url: URL?

	var body: some View {
		LoadableImage(url: url, mode: .aspectFill) {
			Rectangle()
				.fill(.yellow)
				.frame(height: 150)
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
		VStack(spacing: .medium2) {
			if isExpanded {
				NFTView(url: thumbnail)
			}

			VStack(alignment: .leading, spacing: .small2) {
				Text(id)
					.foregroundColor(.app.gray2)
					.textStyle(.body2Regular)
					.offset(y: -.small2)

				ForEach(metadata) { pair in
					HStack(alignment: .top) {
						Text(pair.key)
							.foregroundColor(.app.buttonTextBlack)
							.textStyle(.body1Regular)

						Spacer(minLength: 0)

						Text(pair.value)
							.foregroundColor(.app.buttonTextBlack)
							.textStyle(.body1Header)
					}
				}
			}
			.opacity(isExpanded ? 1 : 0)
		}
		.padding(.medium1)
		.background(
			ExpandableRowBackgroundView(
				paddingEdge: edge,
				paddingValue: value,
				cornerRadius: oppositeValue
			)
			.tokenRowShadow(condition: isExpanded && !isLast)
		)
	}
}

// MARK: ExpandableRow
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

// MARK: NFTIDView.Constants
extension NFTIDView {
	fileprivate enum Constants {
		static let radius: CGFloat = .small1
	}
}
