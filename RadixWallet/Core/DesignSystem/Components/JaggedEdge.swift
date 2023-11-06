// MARK: - JaggedEdge
public struct JaggedEdge: View {
	private let toothWidth: CGFloat = 10
	private let toothHeight: CGFloat = 5

	let color: Color
	let shadowColor: Color
	let isTopEdge: Bool
	let edgeShape: JaggedEdgeShape

	public init(color: Color = .white, shadowColor: Color, isTopEdge: Bool) {
		self.color = color
		self.shadowColor = shadowColor
		self.isTopEdge = isTopEdge
		self.edgeShape = JaggedEdgeShape(isTopEdge: isTopEdge, toothWidth: toothWidth, toothHeight: toothHeight)
	}

	public var body: some View {
		ZStack {
			edgeShape
				.frame(height: toothHeight)
				.frame(maxHeight: .infinity, alignment: isTopEdge ? .bottom : .top)
				.shadow(color: shadowColor, radius: 5)
			edgeShape
				.fill(.white)
		}
	}
}

// MARK: - JaggedEdgeShape
struct JaggedEdgeShape: Shape {
	let isTopEdge: Bool
	let toothWidth: CGFloat
	let toothHeight: CGFloat

	func path(in rect: CGRect) -> SwiftUI.Path {
		Path { path in
			let width = rect[.trailing].x - rect[.leading].x
			let teeth = round(width / toothWidth)
			let w = width / teeth
			path.move(to: rect[.topLeading])

			func addEdge(fromX: CGFloat, dx: CGFloat, y: CGFloat) {
				for i in 0 ..< Int(teeth) {
					let baseX = fromX + CGFloat(i) * dx
					path.addLine(to: .init(x: baseX + 0.5 * dx, y: y))
					path.addLine(to: .init(x: baseX + dx, y: y - toothHeight))
				}
			}

			if isTopEdge {
				path.addLine(to: rect[.topTrailing])
				path.addLine(to: .init(x: rect[.trailing].x, y: rect.maxY - toothHeight))
				addEdge(fromX: rect[.trailing].x, dx: -w, y: rect.maxY)
			} else {
				addEdge(fromX: rect[.leading].x, dx: w, y: rect.minY + toothHeight)
				path.addLine(to: rect[.bottomTrailing])
				path.addLine(to: rect[.bottomLeading])
			}

			path.closeSubpath()
		}
	}
}

extension CGRect {
	subscript(unitPoint: UnitPoint) -> CGPoint {
		.init(x: minX + unitPoint.x * width, y: minY + unitPoint.y * height)
	}
}
