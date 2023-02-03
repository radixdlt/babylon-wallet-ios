import SwiftUI

// MARK: - RadixCard
public struct RadixCard<Contents: View>: View {
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

public extension View {
	var cardStyle: some View {
		background {
			RoundedRectangle(cornerRadius: .small1)
				.fill(.white)
				.radixShadow
		}
	}

	var radixShadow: some View {
		shadow(color: .app.gray2.opacity(0.26), radius: .medium3, x: .zero, y: .small2)
	}
}
