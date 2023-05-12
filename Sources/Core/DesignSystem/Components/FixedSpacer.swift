import SwiftUI

public struct FixedSpacer: View {
	let width: CGFloat
	let height: CGFloat

	public init(width: CGFloat = 1, height: CGFloat = 1) {
		self.width = width
		self.height = height
	}

	public var body: some View {
		Rectangle()
			.fill(.clear)
			.frame(width: width, height: height)
	}
}
