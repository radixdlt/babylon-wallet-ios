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
	let corners: UIRectCorner
	let radius: CGFloat

	public init(corners: UIRectCorner = .allCorners, radius: CGFloat) {
		self.corners = corners
		self.radius = radius
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
	public func roundedCorners(_ corners: UIRectCorner = .allCorners, radius: CGFloat) -> some View {
		self.clipShape(RoundedCorners(corners: corners, radius: radius))
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
