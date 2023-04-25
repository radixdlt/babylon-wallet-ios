import FeaturePrelude

// MARK: - Header
struct Header: View {
	let name: String
	let iconAsset: ImageAsset
	let isExpanded: Bool

	var body: some View {
		HStack(spacing: 18) {
			Image(asset: iconAsset)
				.cornerRadius(.small3)

			VStack(alignment: .leading, spacing: 6) {
				Text(name)
					.foregroundColor(.app.gray1)
					.textStyle(.secondaryHeader)
			}

			Spacer()
		}
		.padding(.horizontal, .medium1)
		.padding(.vertical, .large3)
		.background(
			ExpandableRowBackgroundView(
				paddingEdge: edge,
				paddingValue: value,
				cornerRadius: oppositeValue
			)
			.tokenRowShadow(condition: isExpanded)
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
		[.bottom]
	}

	var value: CGFloat {
		isExpanded ? Constants.radius : .zero
	}

	var oppositeValue: CGFloat {
		isExpanded ? .zero : Constants.radius
	}
}
