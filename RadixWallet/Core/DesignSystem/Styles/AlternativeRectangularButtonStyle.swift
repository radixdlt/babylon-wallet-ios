import Foundation

// MARK: - AlternativeRectangularButtonStyle
public struct AlternativeRectangularButtonStyle: ButtonStyle {
	let height: CGFloat

	public func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.foregroundColor(.app.blue2)
			.font(.app.body1Header)
			.frame(height: height)
			.frame(maxWidth: .infinity)
			.background(.app.white)
			.brightness(configuration.isPressed ? -0.1 : 0)
			.cornerRadius(.small2)
	}
}

extension ButtonStyle where Self == AlternativeRectangularButtonStyle {
	public static var alternativeRectangular: Self { .alternativeRectangular() }

	public static func alternativeRectangular(
		height: CGFloat = .standardButtonHeight
	) -> Self {
		Self(height: height)
	}
}
