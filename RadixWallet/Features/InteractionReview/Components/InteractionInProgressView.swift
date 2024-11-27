import SwiftUI

extension InteractionReview {
	struct InteractionInProgressView: View {
		@State private var opacity: Double = 1.0

		var body: some View {
			Image(asset: AssetResource.transactionInProgress)
				.opacity(opacity)
				.animation(
					.easeInOut(duration: 0.3)
						.delay(0.2)
						.repeatForever(autoreverses: true),
					value: opacity
				)
				.onAppear {
					withAnimation {
						opacity = 0.5
					}
				}
		}
	}
}
