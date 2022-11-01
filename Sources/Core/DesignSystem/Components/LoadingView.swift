import SwiftUI

// An ugly temporary LoadingView
public struct LoadingView: View {
	@State public var isLoading = false

	public init() {}

	public var body: some View {
		ZStack {
			Circle()
				.stroke(Color(.systemGray), lineWidth: 14)
				.frame(width: 100, height: 100)

			Circle()
				.trim(from: 0, to: 0.2)
				.stroke(Color.green, lineWidth: 7)
				.frame(width: 100, height: 100)
				.rotationEffect(Angle(degrees: isLoading ? 360 : 0))
				.animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: self.isLoading)
				.onAppear {
					self.isLoading = true
				}
		}
	}
}
