import Prelude
import SharedModels
import SwiftUI

// MARK: - SmallAccountCard
public struct SmallAccountCard: View {
	let name: String
	let identifiable: LedgerIdentifiable
	let gradient: Gradient
	let height: CGFloat

	public init(
		_ name: String,
		identifiable: LedgerIdentifiable,
		gradient: Gradient,
		height: CGFloat = .standardButtonHeight
	) {
		self.name = name
		self.identifiable = identifiable
		self.gradient = gradient
		self.height = height
	}
}

extension SmallAccountCard {
	public var body: some View {
		HStack(spacing: 0) {
			Text(name)
				.foregroundColor(.app.white)
				.textStyle(.body1Header)

			Spacer(minLength: 0)

			AddressView(identifiable)
				.foregroundColor(.app.whiteTransparent)
				.textStyle(.body2HighImportance)
		}
		.padding(.horizontal, .medium3)
		.frame(height: height)
		.background {
			LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
		}
	}
}
