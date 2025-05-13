import SwiftUI

extension InteractionReview {
	typealias Common = InteractionReview

	struct TransferLineView: View {
		var body: some View {
			VLine()
				.stroke(.iconTertiary, style: .interactionReview)
				.frame(width: 1)
				.padding(.trailing, Common.transferLineTrailingPadding)
				.padding(.top, -.medium1)
		}
	}
}

private extension StrokeStyle {
	static let interactionReview = StrokeStyle(lineWidth: 2, dash: [5, 5])
}
