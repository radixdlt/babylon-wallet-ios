import SwiftUI

// MARK: - Card
public struct Card<Contents: View>: View {
	let insetContents: Bool
	let verticalSpacing: CGFloat
	let contents: Contents

	public init(insetContents: Bool = false, verticalSpacing: CGFloat = 0, @ViewBuilder contents: () -> Contents) {
		self.insetContents = insetContents
		self.verticalSpacing = verticalSpacing
		self.contents = contents()
	}

	public var body: some View {
		VStack(spacing: verticalSpacing) {
			contents
		}
		.padding(insetContents ? .small1 : 0)
		.inCard
	}
}

// MARK: - FlatCard
public struct FlatCard<Contents: View>: View {
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
		background(.app.white)
			.clipShape(RoundedRectangle(cornerRadius: .medium3))
			.cardShadow
	}

	public var inSpeechbubble: some View {
		padding(.bottom, 20)
			.background(.app.account1pink)
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

	public init(cornerRadius: CGFloat) {
		self.cornerRadius = cornerRadius
	}

	public func path(in rect: CGRect) -> Path {
		Path { path in
			path.addRelativeArc(center: .init(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
			                    radius: cornerRadius,
			                    startAngle: .radians(.pi),
			                    delta: .radians(.pi / 2))

			path.addRelativeArc(center: .init(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
			                    radius: cornerRadius,
			                    startAngle: -.radians(.pi / 2),
			                    delta: .radians(.pi / 2))

			path.addRelativeArc(center: .init(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
			                    radius: cornerRadius,
			                    startAngle: .zero,
			                    delta: .radians(.pi / 2))

			path.addLine(to: .init(x: 0, y: rect.maxY))
			path.closeSubpath()
		}
	}
}
