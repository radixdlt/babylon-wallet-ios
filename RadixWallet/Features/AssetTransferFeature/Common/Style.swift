import ComposableArchitecture
import SwiftUI

extension View {
	@ViewBuilder
	func roundedCorners(
		_ corners: UIRectCorner = .allCorners,
		strokeColor: Color,
		radius: CGFloat = .small2
	) -> some View {
		clipShape(RoundedCorners(corners: corners, radius: radius))
			.background(
				RoundedCorners(corners: corners, radius: radius)
					.stroke(strokeColor, lineWidth: 1)
			)
	}
}

extension Color {
	static let borderColor: Color = .app.gray4
	static let focusedBorderColor: Color = .primaryText

	static let containerContentBackground: Color = .app.gray5
}

extension CGFloat {
	static let dottedLineHeight: CGFloat = 64.0
	static let transferMessageDefaultHeight: Self = 64
}
