import Prelude

// MARK: - FlowLayout
public struct FlowLayout: Layout {
	public let alignment: VerticalAlignment
	public let spacing: CGSize

	public init(alignment: VerticalAlignment = .center, spacing: CGFloat = 10) {
		self.alignment = alignment
		self.spacing = .init(width: spacing, height: spacing)
	}

	public init(alignment: VerticalAlignment = .center, spacing: CGSize) {
		self.alignment = alignment
		self.spacing = spacing
	}

	public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		let containerWidth = proposal.replacingUnspecifiedDimensions().width
		let dimensions = subviews.map { $0.dimensions(in: .unspecified) }

		return layout(
			dimensions: dimensions,
			spacing: spacing,
			containerWidth: containerWidth,
			alignment: alignment
		).size
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
			subview.place(at: CGPoint(x: offset.x + bounds.minX, y: offset.y + bounds.minY), proposal: .unspecified)
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
			result.append(contentsOf: currentLine.map { rect in
				var copy = rect
				copy.origin.y += currentPosition.y - union.minY
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

extension Sequence where Element == CGRect {
	public var union: CGRect {
		reduce(.null) { $0.union($1) }
	}
}
