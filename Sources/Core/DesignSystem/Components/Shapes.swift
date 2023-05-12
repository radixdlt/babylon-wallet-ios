import SwiftUI

// MARK: - VLine
public struct VLine: Shape {
	public func path(in rect: CGRect) -> SwiftUI.Path {
		SwiftUI.Path { path in
			path.move(to: .init(x: rect.midX, y: rect.minY))
			path.addLine(to: .init(x: rect.midX, y: rect.maxY))
		}
	}
}

// MARK: - RoundedCorners
public struct RoundedCorners: Shape {
	let radius: CGFloat
	let corners: UIRectCorner

	public init(radius: CGFloat, corners: UIRectCorner = .allCorners) {
		self.radius = radius
		self.corners = corners
	}

	public func path(in rect: CGRect) -> SwiftUI.Path {
		.init(
			UIBezierPath(
				roundedRect: rect,
				byRoundingCorners: corners,
				cornerRadii: .init(width: radius, height: radius)
			).cgPath
		)
	}
}
