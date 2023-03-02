import SwiftUI

// MARK: - Card
public struct Card<Contents: View>: View {
	let contents: Contents
	let insetContents: Bool

	public init(insetContents: Bool = false, @ViewBuilder contents: () -> Contents) {
		self.insetContents = insetContents
		self.contents = contents()
	}

	public var body: some View {
		HStack(spacing: 0) {
			if insetContents {
				contents
					.clipShape(RoundedRectangle(cornerRadius: .small1))
					.padding(.small1)
			} else {
				contents
			}
		}
		.cardStyle
	}
}

extension View {
	public var cardStyle: some View {
		background {
			RoundedRectangle(cornerRadius: .medium3)
				.fill(.white)
				.cardShadow
		}
	}

	public var cardShadow: some View {
		shadow(color: .app.gray2.opacity(0.26), radius: .medium3, x: .zero, y: .small2)
	}
}
