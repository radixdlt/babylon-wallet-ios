import Foundation

// MARK: - AlternativeRectangularButtonStyle
struct AlternativeRectangularButtonStyle: ButtonStyle {
	@Environment(\.controlState) var controlState
	let height: CGFloat

	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.foregroundColor(forgroundColor)
			.font(.app.body1Header)
			.frame(height: height)
			.frame(maxWidth: .infinity)
			.background(.app.white)
			.brightness(configuration.isPressed ? -0.1 : 0)
			.cornerRadius(.small2)
	}

	var forgroundColor: Color {
		controlState.isEnabled
			? .app.blue2
			: .app.gray4
	}
}

extension ButtonStyle where Self == AlternativeRectangularButtonStyle {
	static var alternativeRectangular: Self { .alternativeRectangular() }

	static func alternativeRectangular(
		height: CGFloat = .standardButtonHeight
	) -> Self {
		Self(height: height)
	}
}
