import SwiftUI

extension InteractionReview {
	struct ExpandableHeadingView: View {
		typealias Common = InteractionReview

		let heading: Common.HeadingView
		let isExpanded: Bool
		let action: () -> Void

		var body: some SwiftUI.View {
			Button(action: action) {
				HStack(spacing: .small3) {
					heading

					Image(asset: isExpanded ? AssetResource.chevronUp : AssetResource.chevronDown)
						.renderingMode(.original)

					Spacer(minLength: 0)
				}
			}
			.padding(.trailing, Common.transferLineTrailingPadding + .small3) // padding from the vertical dotted line
		}
	}
}
