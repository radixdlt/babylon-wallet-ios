import FeaturePrelude

// MARK: - Component
struct Component: View {
	let token: NonFungibleToken
	let isLast: Bool
	let isExpanded: Bool

	@State private var imageHeight: CGFloat?
	private let collapsedImageHeight: CGFloat = 0

	@State private var height: CGFloat?
	private let collapsedHeight: CGFloat = 0
}

extension Component {
	var body: some View {
		VStack(spacing: .medium2) {
			// TODO: refactor when API returns individual NFT image
			AsyncImage(url: URL(string: ""))
				.frame(height: isExpanded ? imageHeight : collapsedImageHeight)
				.cornerRadius(.small3)
				.onSizeChanged { size in
					if imageHeight == nil, size.height != collapsedImageHeight {
						imageHeight = size.height
					}
				}
				// TODO: remove when API returns individual NFT image
				.hidden()

			VStack(alignment: .leading, spacing: .small2) {
				Text(token.id.stringRepresentation)
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
			.frame(height: isExpanded ? height : collapsedHeight)
			.onSizeChanged { size in
				if height == nil, size.height != collapsedHeight {
					height = size.height
				}
			}
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

extension Component {
	private var metadata: [[String: String]] {
		// TODO: refactor when API returns NFT metadata
		//		token.metadata ?? []
		[]
	}
}

extension NonFungibleToken.ID {
	var stringRepresentation: String {
		switch self {
		case let .integer(value):
			return "\(value)"
		case let .uuid(value):
			return "\(value)"
		case let .string(value):
			return value
		case let .bytes(value):
			return "\(value.description)"
		}
	}
}

// MARK: - Component + ExpandableRow
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

	var oppositeValue: CGFloat {
		isExpanded ? 0 : Constants.radius
	}
}

// MARK: - Component.Constants
extension Component {
	fileprivate enum Constants {
		static let radius: CGFloat = .small1
	}
}
