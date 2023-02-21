import SwiftUI

// MARK: - LoadingView
public struct LoadingView: View {
	@State private var rotationDegrees: CGFloat
	private let lineWidth: CGFloat
	private let stroke: Color
	public init(
		rotationDegrees: CGFloat = 0.0,
		lineWidth: CGFloat = 2,
		stroke: Color = Color.app.white
	) {
		self.stroke = stroke
		_rotationDegrees = .init(initialValue: rotationDegrees)
		self.lineWidth = lineWidth
	}
}

extension LoadingView {
	public var body: some View {
		ZStack {
			Circle()
				.stroke(
					stroke.opacity(0.3),
					lineWidth: lineWidth
				)
			Circle()
				.trim(from: 0, to: 0.35)
				.stroke(
					stroke,
					lineWidth: lineWidth
				)
				.rotationEffect(.degrees(rotationDegrees))
		}
		.animation(
			.linear(duration: 1).speed(0.7).repeatForever(autoreverses: false),
			value: rotationDegrees
		)
		.onAppear {
			rotationDegrees = 360.0
		}
	}
}

// MARK: - LoaderView_Previews
struct LoaderView_Previews: PreviewProvider {
	static var previews: some View {
		ZStack {
			Color.app.blue2
			LoadingView()
		}
	}
}
