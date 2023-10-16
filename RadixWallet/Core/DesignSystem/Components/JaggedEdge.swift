// MARK: - JaggedEdge
public struct JaggedEdge: View {
	private let toothWidth: CGFloat = 10
	private let toothHeight: CGFloat = 5

	let color: Color
	let shadowColor: Color
	let isTopEdge: Bool
	let padding: CGFloat

	public init(color: Color = .white, shadowColor: Color, isTopEdge: Bool, padding: CGFloat = 0) {
		self.color = color
		self.shadowColor = shadowColor
		self.isTopEdge = isTopEdge
		self.padding = padding
	}

	public var body: some View {
		JaggedEdgeShape(
			isTopEdge: isTopEdge,
			toothWidth: toothWidth,
			toothHeight: toothHeight,
			padding: padding
		)
		.fill(.white)
		.shadow(color: shadowColor, radius: 5)
		.frame(height: padding + toothHeight)
	}
}

// MARK: - JaggedEdgeShape
struct JaggedEdgeShape: Shape {
	let isTopEdge: Bool
	let toothWidth: CGFloat
	let toothHeight: CGFloat
	let padding: CGFloat

	func path(in rect: CGRect) -> SwiftUI.Path {
		Path { path in
			let teeth = round(rect.width / toothWidth)
			let w = rect.width / teeth
			let bottom = rect.maxY - (isTopEdge ? 0 : padding)
			path.move(to: .init(x: 0, y: bottom))
			for i in 0 ..< Int(teeth) {
				let baseX = rect.origin.x + CGFloat(i) * w
				path.addLine(to: .init(x: baseX + 0.5 * w, y: isTopEdge ? padding : 0))
				path.addLine(to: .init(x: baseX + w, y: bottom))
			}

			if isTopEdge {
				path.addLine(to: .init(x: rect.maxX, y: 0))
				path.addLine(to: rect.origin)
			} else {
				path.addLine(to: .init(x: rect.maxX, y: rect.maxY))
				path.addLine(to: .init(x: rect.minX, y: rect.maxY))
			}
			path.closeSubpath()
		}
	}
}
