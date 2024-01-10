import ComposableArchitecture
import SwiftUI

// MARK: - ValidatorNameView
struct ValidatorHeaderView: View {
	struct ViewState: Equatable {
		let imageURL: URL?
		let name: String
		let stakedAmount: RETDecimal?
	}

	let viewState: ViewState

	var body: some View {
		HStack(spacing: .zero) {
			NFTThumbnail(viewState.imageURL, size: .small)
				.padding(.trailing, .small1)

			VStack(alignment: .leading) {
				Text(viewState.name)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)
				if let stakedAmount = viewState.stakedAmount {
					Text("Staked \(stakedAmount.formatted()) XRD")
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray2)
				}
			}

			Spacer(minLength: 0)
		}
	}
}
