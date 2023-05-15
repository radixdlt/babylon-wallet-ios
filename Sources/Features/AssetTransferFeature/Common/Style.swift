import FeaturePrelude
import SwiftUI

extension View {
	func roundedCorners(strokeColor: Color, corners: UIRectCorner) -> some View {
		self.modifier { view in
			view
				.clipShape(RoundedCorners(radius: .small2, corners: corners))
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
