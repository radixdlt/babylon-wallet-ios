import DesignSystem
import SwiftUI

// MARK: - LSUMaker
enum LSUMaker {
	static func makeValidatorNameView(
		viewState: ValidatorNameViewState
	) -> some View {
		HStack(spacing: .small1) {
			NFTThumbnail(viewState.imageURL, size: .smallest)
			Text(viewState.name)
				.font(.app.body1Header)
			Spacer()
		}
	}
}

// MARK: - ValidatorNameViewState
struct ValidatorNameViewState: Equatable {
	let imageURL: URL?
	let name: String
}
