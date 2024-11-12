import Foundation

// MARK: - TruncationTextMask
struct TruncationTextMask: ViewModifier {
	let size: CGSize
	let enabled: Bool

	@Environment(\.layoutDirection) private var layoutDirection

	func body(content: Content) -> some View {
		if enabled {
			content
				.mask(
					VStack(spacing: 0) {
						Rectangle()
						HStack(spacing: 0) {
							Rectangle()

							HStack(spacing: 0) {
								LinearGradient(
									gradient: Gradient(stops: [
										Gradient.Stop(color: .black, location: 0),
										Gradient.Stop(color: .clear, location: 1),
									]),
									startPoint: layoutDirection == .rightToLeft ? .trailing : .leading,
									endPoint: layoutDirection == .rightToLeft ? .leading : .trailing
								)
								.frame(width: .medium1, height: size.height)

								Rectangle()
									.foregroundColor(.clear)
									.frame(width: size.width, height: size.height)
							}
						}
						.frame(height: size.height)
					}
				)
		} else {
			content
				.fixedSize(horizontal: false, vertical: true)
		}
	}
}

extension View {
	func applyingTruncationMask(size: CGSize, enabled: Bool) -> some View {
		modifier(TruncationTextMask(size: size, enabled: enabled))
	}
}
