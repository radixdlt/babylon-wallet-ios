// MARK: - FlowLayout
public struct FlowLayout: Layout {
	public let alignment: VerticalAlignment
	public let spacing: CGSize
	public let multilineAlignment: HorizontalAlignment

	public init(
		alignment: VerticalAlignment = .center,
		multilineAlignment: HorizontalAlignment = .leading,
		spacing: CGFloat = 10
	) {
		self.init(alignment: alignment, multilineAlignment: multilineAlignment, spacing: .init(width: spacing, height: spacing))
	}

	public init(
		alignment: VerticalAlignment = .center,
		multilineAlignment: HorizontalAlignment = .leading,
		spacing: CGSize
	) {
		self.alignment = alignment
		self.multilineAlignment = multilineAlignment
		self.spacing = spacing
	}

	public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		let containerWidth = proposal.replacingUnspecifiedDimensions().width
		let dimensions = subviews.map { $0.dimensions(in: .unspecified) }

		let laidOutSize = layout(
			dimensions: dimensions,
			spacing: spacing,
			containerWidth: containerWidth,
			alignment: alignment
		).size

		return .init(width: min(laidOutSize.width, containerWidth), height: laidOutSize.height)
	}

	public func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) {
		let dimensions = subviews.map { $0.dimensions(in: .unspecified) }
		let offsets = layout(
			dimensions: dimensions,
			spacing: spacing,
			containerWidth: bounds.width,
			alignment: alignment
		).offsets

		for (offset, subview) in zip(offsets, subviews) {
			subview.place(at: CGPoint(x: offset.x + bounds.minX, y: offset.y + bounds.minY), proposal: .init(width: proposal.width, height: nil))
		}
	}

	private func layout(
		dimensions: [ViewDimensions],
		spacing: CGSize,
		containerWidth: CGFloat,
		alignment: VerticalAlignment
	) -> (offsets: [CGPoint], size: CGSize) {
		var result: [CGRect] = []
		var currentPosition: CGPoint = .zero
		var currentLine: [CGRect] = []

		func flushLine() {
			currentPosition.x = 0
			let union = currentLine.union
			let remainingWidth = abs(containerWidth - union.width)
			result.append(contentsOf: currentLine.map { rect in
				var copy = rect
				copy.origin.y += currentPosition.y - union.minY

				switch multilineAlignment {
				case .center:
					copy.origin.x += remainingWidth / 2
				case .trailing:
					copy.origin.x += remainingWidth
				case .leading:
					// default alignment, no adjustment needed.
					break
				default:
					break
				}

				return copy
			})

			currentPosition.y += union.height + spacing.height
			currentLine.removeAll()
		}

		for dim in dimensions {
			if currentPosition.x + dim.width > containerWidth {
				flushLine()
			}

			currentLine.append(.init(x: currentPosition.x, y: -dim[alignment], width: dim.width, height: dim.height))
			currentPosition.x += dim.width
			currentPosition.x += spacing.width
		}
		flushLine()

		return (result.map(\.origin), result.union.size)
	}
}

extension Sequence<CGRect> {
	public var union: CGRect {
		reduce(.null) { $0.union($1) }
	}
}
