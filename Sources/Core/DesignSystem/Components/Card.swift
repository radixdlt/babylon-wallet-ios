import SwiftUI

// MARK: - Card
public struct Card<Contents: View>: View {
	let contents: Contents

	public init(@ViewBuilder contents: () -> Contents) {
		self.contents = contents()
	}

	public var body: some View {
		HStack(spacing: 0) {
			contents
		}
		.cardStyle
	}
}

extension View {
	public var cardStyle: some View {
		background {
			RoundedRectangle(cornerRadius: .small1)
				.fill(.white)
				.cardShadow
		}
	}

	public var cardShadow: some View {
		shadow(color: .app.gray2.opacity(0.26), radius: .medium3, x: .zero, y: .small2)
	}
}
