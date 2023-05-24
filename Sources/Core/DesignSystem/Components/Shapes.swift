import SwiftUI

// MARK: - VLine
public struct VLine: Shape {
	public init() {}

	public func path(in rect: CGRect) -> SwiftUI.Path {
		SwiftUI.Path { path in
			path.move(to: .init(x: rect.midX, y: rect.minY))
			path.addLine(to: .init(x: rect.midX, y: rect.maxY))
		}
	}
}

// MARK: - RoundedCorners
/// A more advanced rounded corners shape, allowing to round specific corners.
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

extension View {
	public func roundedCorners(radius: CGFloat, corners: UIRectCorner = .allCorners) -> some View {
		self.clipShape(RoundedCorners(radius: radius, corners: corners))
	}

	public func topRoundedCorners(radius: CGFloat) -> some View {
		roundedCorners(radius: radius, corners: .top)
	}

	public func bottomRoundedCorners(radius: CGFloat) -> some View {
		roundedCorners(radius: radius, corners: .bottom)
	}
}

extension UIRectCorner {
	public static var top: UIRectCorner {
		[.topLeft, .topRight]
	}

	public static var bottom: UIRectCorner {
		[.bottomLeft, .bottomRight]
	}
}
