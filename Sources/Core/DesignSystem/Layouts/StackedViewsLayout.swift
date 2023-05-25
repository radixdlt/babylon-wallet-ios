import Prelude

public struct StackedViewsLayout: Layout {
	var isExpanded: Bool

	/// Spacing between views in Expanded state
	var spacing: CGFloat

	/// Spacing between views in Collapsed state
	var collapsedSpacing: CGFloat

	/// Number of visible views in Collapsed state
	var collapsedViewsCount: Int

	public init(isExpanded: Bool, spacing: CGFloat = 10, collapsedSpacing: CGFloat = 10, collapsedViewsCount: Int = 3) {
		self.isExpanded = isExpanded
		self.spacing = spacing
		self.collapsedSpacing = collapsedSpacing
		self.collapsedViewsCount = collapsedViewsCount
	}

	public static var layoutProperties: LayoutProperties {
		var properties = LayoutProperties()
		properties.stackOrientation = .vertical
		return properties
	}

	public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		let container = proposal.replacingUnspecifiedDimensions()
		guard !subviews.isEmpty else {
			return container
		}

		let heights = subviews.map { $0.sizeThatFits(.init(width: container.width, height: nil)).height }
		let height: CGFloat = {
			if !isExpanded {
				return heights[0] + CGFloat(collapsedViewsCount - 1) * collapsedSpacing
			} else {
				return heights.reduce(0.0, +) + spacing * CGFloat(subviews.count - 1)
			}
		}()
		return .init(width: container.width, height: height)
	}

	public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		let container = proposal.replacingUnspecifiedDimensions()
		var offset: CGFloat = 0
		for (index, subview) in subviews.enumerated() {
			let place = CGPoint(x: bounds.minX, y: bounds.minY + offset)
			subview.place(at: place, proposal: .init(width: container.width, height: nil))

			if isExpanded {
				let subviewSize = subview.sizeThatFits(.init(width: container.width, height: nil))
				offset += subviewSize.height + spacing
			} else {
				// The rest of the cards that go over `collapsedViewsCount` will go behind the last card.
				if index < collapsedViewsCount - 1 {
					offset += collapsedSpacing
				}
			}
		}
	}
}
