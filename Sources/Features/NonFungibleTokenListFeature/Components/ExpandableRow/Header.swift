import Common
import SwiftUI

// MARK: - Header
struct Header: View {
	let name: String
	let supply: String
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
				Text(supply)
					.foregroundColor(.app.gray2)
					.textStyle(.body2HighImportance)
			}

			Spacer()
		}
		.padding(.horizontal, .medium1)
		.padding(.vertical, .large2)
		.background(
			ExpandableRowBackgroundView(
				paddingEdge: edge,
				paddingValue: value,
				cornerRadius: opositeValue
			)
			.tokenRowShadow(condition: isExpanded)
		)
	}
}

// MARK: Header.Constants
private extension Header {
	enum Constants {
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

	var opositeValue: CGFloat {
		isExpanded ? .zero : Constants.radius
	}
}
