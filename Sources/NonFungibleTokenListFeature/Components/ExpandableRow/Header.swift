import Common
import SwiftUI

// MARK: - Header
struct Header: View {
	let name: String
	let supply: String
	let imageURL: String?
	let isExpanded: Bool

	var body: some View {
		HStack(spacing: 18) {
			Image(imageURL ?? "")
				.cornerRadius(4)

			VStack(alignment: .leading) {
				Text(name)
					.foregroundColor(.app.buttonTextBlack)
					.font(.app.body1Header)
				Text(supply)
					.foregroundColor(.app.secondary)
					.font(.app.body2Regular)
			}

			Spacer()

			Text(toggleDisplayText)
				.foregroundColor(.app.secondary)
				.font(.app.body2Regular)
		}
		.padding(25)
		.background(
			ExpandableRowBackgroundView(
				paddingEdge: edge,
				paddingValue: value,
				cornerRadius: opositeValue
			)
			.shadow(color: isExpanded ? .clear : .app.shadowBlack, radius: 8, x: 0, y: 9)
		)
	}
}

// MARK: - Private Computed Propeties
private extension Header {
	var toggleDisplayText: String {
		isExpanded ? L10n.NftList.Header.hide : L10n.NftList.Header.show
	}
}

// MARK: Header.Constants
private extension Header {
	enum Constants {
		static let radius: CGFloat = 6
	}
}

// MARK: ExpandableRow
extension Header: ExpandableRow {
	var edge: Edge.Set {
		[.bottom]
	}

	var value: CGFloat {
		isExpanded ? Constants.radius : 0
	}

	var opositeValue: CGFloat {
		isExpanded ? 0 : Constants.radius
	}
}
