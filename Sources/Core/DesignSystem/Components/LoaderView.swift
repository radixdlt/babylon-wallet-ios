import SwiftUI

// MARK: - LoaderView
struct LoaderView: View {
	@State private var isRotating = 0.0
	private let lineWidth: CGFloat = 2

	var body: some View {
		ZStack {
			Circle()
				.stroke(
					Color.app.white.opacity(0.3),
					lineWidth: lineWidth
				)
			Circle()
				.trim(from: 0, to: 0.35)
				.stroke(
					Color.app.white,
					lineWidth: lineWidth
				)
				.rotationEffect(.degrees(isRotating))
		}
		.onAppear {
			withAnimation(.linear(duration: 1)
				.speed(0.7)
				.repeatForever(autoreverses: false)) {
					isRotating = 360.0
				}
		}
		.frame(width: 14, height: 14)
	}
}

// MARK: - LoaderView_Previews
struct LoaderView_Previews: PreviewProvider {
	static var previews: some View {
		ZStack {
			Color.app.blue2
			LoaderView()
		}
	}
}
