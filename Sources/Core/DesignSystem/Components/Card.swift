import SwiftUI

// MARK: - Card
public struct Card<Contents: View>: View {
	let contents: Contents
	let action: () -> Void
	let disabled: Bool

	public init(
		@ViewBuilder contents: () -> Contents
	) {
		self.action = {}
		self.contents = contents()
		self.disabled = true
	}

	public init(
		action: @escaping () -> Void,
		@ViewBuilder contents: () -> Contents
	) {
		self.action = action
		self.contents = contents()
		self.disabled = false
	}

	public var body: some View {
		Button(action: action) {
			contents
		}
		.buttonStyle(.cardButtonStyle)
		.disabled(disabled)
	}
}

public extension ButtonStyle where Self == CardButtonStyle {
	static var cardButtonStyle: CardButtonStyle { CardButtonStyle() }
}

// MARK: - CardButtonStyle
public struct CardButtonStyle: ButtonStyle {
	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.inCard(isPressed: configuration.isPressed)
	}
}

// MARK: - Speechbubble
public struct Speechbubble<Contents: View>: View {
	let insetContents: Bool
	let contents: Contents

	public init(insetContents: Bool = false, @ViewBuilder contents: () -> Contents) {
		self.insetContents = insetContents
		self.contents = contents()
	}

	public var body: some View {
		contents
			.padding(insetContents ? .small1 : 0)
			.inSpeechbubble
	}
}

// MARK: - InnerCard
public struct InnerCard<Contents: View>: View {
	let verticalSpacing: CGFloat
	let contents: Contents

	public init(verticalSpacing: CGFloat = 0, @ViewBuilder contents: () -> Contents) {
		self.verticalSpacing = verticalSpacing
		self.contents = contents()
	}

	public var body: some View {
		VStack(spacing: verticalSpacing) {
			contents
		}
		.inFlatCard
	}
}

extension View {
	/// Gives the view a white background, rounded corners (16 px), and a shadow, useful for root level cards
	public var inCard: some View {
		inCard(isPressed: false)
	}

	fileprivate func inCard(isPressed: Bool) -> some View {
		background(isPressed ? .app.gray4 : .app.white)
			.clipShape(RoundedRectangle(cornerRadius: .medium3))
			.cardShadow
	}

	public var inSpeechbubble: some View {
		padding(.bottom, SpeechbubbleShape.triangleSize.height)
			.background(.app.white)
			.clipShape(SpeechbubbleShape(cornerRadius: .medium3))
			.cardShadow
	}

	/// Gives the view rounded corners  (12 px) and no shadow, useful for inner views
	public var inFlatCard: some View {
		clipShape(RoundedRectangle(cornerRadius: .small1))
	}

	public var cardShadow: some View {
		shadow(color: .app.gray2.opacity(0.26), radius: .medium3, x: .zero, y: .small2)
	}
}

// MARK: - SpeechbubbleShape
public struct SpeechbubbleShape: Shape {
	let cornerRadius: CGFloat
	public static let triangleSize: CGSize = .init(width: 20, height: 10)
	public static let triangleInset: CGFloat = 50

	public init(cornerRadius: CGFloat) {
		self.cornerRadius = cornerRadius
	}

	public func path(in rect: CGRect) -> Path {
		let inner = rect.inset(by: .init(top: 0, left: 0, bottom: Self.triangleSize.height, right: 0))
		let arcCenters = inner.insetBy(dx: cornerRadius, dy: cornerRadius)
		return Path { path in
			path.addRelativeArc(center: .init(x: arcCenters.minX, y: arcCenters.minY),
			                    radius: cornerRadius,
			                    startAngle: .radians(.pi),
			                    delta: .radians(.pi / 2))

			path.addRelativeArc(center: .init(x: arcCenters.maxX, y: arcCenters.minY),
			                    radius: cornerRadius,
			                    startAngle: -.radians(.pi / 2),
			                    delta: .radians(.pi / 2))

			path.addRelativeArc(center: .init(x: arcCenters.maxX, y: arcCenters.maxY),
			                    radius: cornerRadius,
			                    startAngle: .zero,
			                    delta: .radians(.pi / 2))

			path.addLine(to: .init(x: inner.maxX - Self.triangleInset - Self.triangleSize.width / 2, y: inner.maxY))
			path.addLine(to: .init(x: inner.maxX - Self.triangleInset, y: rect.maxY))
			path.addLine(to: .init(x: inner.maxX - Self.triangleInset + Self.triangleSize.width / 2, y: inner.maxY))

			path.addRelativeArc(center: .init(x: arcCenters.minX, y: arcCenters.maxY),
			                    radius: cornerRadius,
			                    startAngle: .radians(.pi / 2),
			                    delta: .radians(.pi / 2))

			path.closeSubpath()
		}
	}
}
