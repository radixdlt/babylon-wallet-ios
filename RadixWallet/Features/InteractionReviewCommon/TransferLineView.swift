import SwiftUI

extension InteractionReviewCommon {
	typealias Common = InteractionReviewCommon

	struct TransferLineView: View {
		var body: some View {
			VLine()
				.stroke(.app.gray3, style: .interactionReview)
				.frame(width: 1)
				.padding(.trailing, Common.transferLineTrailingPadding)
				.padding(.top, -.medium1)
		}
	}
}

private extension StrokeStyle {
	static let interactionReview = StrokeStyle(lineWidth: 2, dash: [5, 5])
}
