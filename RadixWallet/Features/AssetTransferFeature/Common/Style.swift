import ComposableArchitecture
import SwiftUI

extension View {
	@ViewBuilder
	func roundedCorners(_ corners: UIRectCorner = .allCorners, strokeColor: Color, active: Bool = true) -> some View {
		if active {
			clipShape(RoundedCorners(corners: corners, radius: .small2))
				.background(
					RoundedCorners(corners: corners, radius: .small2)
						.stroke(strokeColor, lineWidth: 1)
				)
		} else {
			self
		}
	}
}

extension Color {
	static let borderColor: Color = .app.gray4
	static let focusedBorderColor: Color = .app.gray1

	static let containerContentBackground: Color = .app.gray5
}

extension CGFloat {
	static let dottedLineHeight: CGFloat = 64.0
	public static let transferMessageDefaultHeight: Self = 64
}
