import Asset
import Common
import SwiftUI

// MARK: - Component
struct Component: View {
	let container: NonFungibleTokenContainer
	let isLast: Bool
	let isExpanded: Bool

	@State private var imageHeight: CGFloat?
	private let collapsedImageHeight: CGFloat = 0

	@State private var height: CGFloat?
	private let collapsedHeight: CGFloat = 0
}

extension Component {
	var body: some View {
		VStack(spacing: 20) {
			Image(container.asset.iconURL ?? "")
				.frame(height: isExpanded ? imageHeight : collapsedImageHeight)
				.cornerRadius(4)
				.onSizeChanged(ReferenceView.self) { size in
					if imageHeight == nil, size.height != collapsedImageHeight {
						imageHeight = size.height
					}
				}

			VStack(alignment: .leading, spacing: 8) {
				Text(container.asset.address)
					.foregroundColor(.app.secondary)
					.font(.app.body2Regular)

				ForEach(metadata, id: \.self) { element in
					HStack(alignment: .top) {
						Text(element.keys.first ?? "")
							.foregroundColor(.app.buttonTextBlack)
							.font(.app.body1Regular)

						Spacer()

						Text(element.values.first ?? "")
							.foregroundColor(.app.buttonTextBlack)
							.font(.app.body1Header)
					}
				}

				if metadata.isEmpty {
					HStack {
						Spacer()
					}
				}
			}
			.opacity(isExpanded ? 1 : 0)
			.frame(height: isExpanded ? height : collapsedHeight)
			.onSizeChanged(ReferenceView.self) { size in
				if height == nil, size.height != collapsedHeight {
					height = size.height
				}
			}
		}
		.padding(25)
		.background(
			ExpandableRowBackgroundView(
				paddingEdge: edge,
				paddingValue: value,
				cornerRadius: opositeValue
			)
			.shadow(color: isExpanded && !isLast ? .clear : .app.shadowBlack, radius: 8, x: 0, y: 9)
		)
	}
}

// MARK: - Private Computed Properties
private extension Component {
	var metadata: [[String: String]] {
		container.metadata ?? []
	}
}

// MARK: ExpandableRow
extension Component: ExpandableRow {
	var edge: Edge.Set {
		if isLast {
			return [.top]
		} else {
			return [.all]
		}
	}

	var value: CGFloat {
		isExpanded ? Constants.radius : 0
	}

	var opositeValue: CGFloat {
		isExpanded ? 0 : Constants.radius
	}
}

// MARK: Component.Constants
private extension Component {
	enum Constants {
		static let radius: CGFloat = 6
	}
}
