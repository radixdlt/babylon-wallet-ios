import DesignSystem
import SwiftUI

// MARK: - ValidatorNameView
struct ValidatorNameView: View {
	struct ViewState: Equatable {
		let imageURL: URL?
		let name: String
	}

	let viewState: ViewState

	var body: some View {
		HStack(spacing: .zero) {
			NFTThumbnail(viewState.imageURL, size: .smallest)
				.padding(.trailing, .small1)

			Text(viewState.name)
				.font(.app.body1Header)

			Spacer(minLength: 0)
		}
	}
}
