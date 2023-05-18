import FeaturePrelude
import SwiftUI

extension View {
	func roundedCorners(strokeColor: Color, corners: UIRectCorner = .allCorners) -> some View {
		self.modifier { view in
			view
				.clipShape(RoundedCorners(radius: .small2, corners: corners))
				.background(
					RoundedCorners(radius: .small2, corners: corners)
						.stroke(strokeColor, lineWidth: 1)
				)
		}
	}

	func roundedCorners(corners: UIRectCorner = .allCorners) -> some View {
		self.modifier { view in
			view
				.clipShape(RoundedCorners(radius: .small2, corners: corners))
		}
	}

	func bordered(strokeColor: Color, corners: UIRectCorner = .allCorners) -> some View {
		self.modifier { view in
			view
				.background(
					RoundedCorners(radius: .small2, corners: corners)
						.stroke(strokeColor, lineWidth: 1)
				)
		}
	}

	func topRoundedCorners(strokeColor: Color) -> some View {
		roundedCorners(strokeColor: strokeColor, corners: [.topLeft, .topRight])
	}

	func bottomRoundedCorners(strokeColor: Color) -> some View {
		roundedCorners(strokeColor: strokeColor, corners: [.bottomLeft, .bottomRight])
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
