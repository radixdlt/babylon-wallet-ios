import ComposableArchitecture
import SwiftUI

// MARK: - ValidatorNameView
struct ValidatorHeaderView: View {
	struct ViewState: Hashable {
		let imageURL: URL?
		let name: String
		let stakedAmount: RETDecimal?
	}

	let viewState: ViewState

	var body: some View {
		HStack(spacing: .zero) {
			ValidatorThumbnail(viewState.imageURL, size: .small)
				.padding(.trailing, .small1)

			VStack(alignment: .leading) {
				Text(viewState.name)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.leading)

				if let stakedAmount = viewState.stakedAmount {
					// This localization does not look right, should be only one string.
					Text(L10n.Account.Staking.staked + " \(stakedAmount.formatted()) XRD")
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray2)
				}
			}

			Spacer(minLength: 0)
		}
	}
}
