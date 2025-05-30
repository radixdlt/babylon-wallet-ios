import ComposableArchitecture
import SwiftUI

// MARK: - ValidatorNameView
struct ValidatorHeaderView: View {
	struct ViewState: Hashable {
		let imageURL: URL?
		let name: String?
		let stakedAmount: Decimal192?
	}

	let viewState: ViewState

	var body: some View {
		HStack(spacing: .zero) {
			Thumbnail(.validator, url: viewState.imageURL, size: .small)
				.padding(.trailing, .medium3)

			VStack(alignment: .leading) {
				if let name = viewState.name {
					Text(name)
						.textStyle(.secondaryHeader)
						.foregroundColor(.primaryText)
						.multilineTextAlignment(.leading)
				}

				if let stakedAmount = viewState.stakedAmount {
					Text(L10n.Account.Staking.currentStake("\(stakedAmount.formatted()) XRD"))
						.textStyle(.body2HighImportance)
						.foregroundColor(.secondaryText)
				}
			}

			Spacer(minLength: 0)
		}
	}
}
