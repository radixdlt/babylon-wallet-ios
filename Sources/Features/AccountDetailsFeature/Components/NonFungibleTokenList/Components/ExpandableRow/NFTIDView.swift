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
	let thumbnail: URL?
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

				ForEach(metadata, id: \.self) { element in
					HStack(alignment: .top) {
						Text(element.keys.first ?? "")
							.foregroundColor(.app.buttonTextBlack)
							.textStyle(.body1Regular)

						Spacer()

						Text(element.values.first ?? "")
							.foregroundColor(.app.buttonTextBlack)
							.textStyle(.body1Header)
					}
				}

				if metadata.isEmpty {
					HStack {
						Spacer()
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

// MARK: - Private Computed Properties

extension NFTIDView {
	private var metadata: [[String: String]] {
		// TODO: refactor when API returns NFT metadata
		//		token.metadata ?? []
		[]
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
