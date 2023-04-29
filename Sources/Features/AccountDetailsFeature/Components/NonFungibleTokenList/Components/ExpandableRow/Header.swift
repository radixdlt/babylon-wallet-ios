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
			ExpandableRowBackgroundView(
				paddingEdge: edge,
				paddingValue: value,
				cornerRadius: oppositeValue
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

// MARK: ExpandableRow
extension Header: ExpandableRow {
	var edge: Edge.Set {
		.bottom
	}

	var value: CGFloat {
		isExpanded ? Constants.radius : .zero
	}

	var oppositeValue: CGFloat {
		isExpanded ? .zero : Constants.radius
	}
}
