import FeaturePrelude

// MARK: - ChooseAccountsRow.View
extension ChooseAccountsRow {
	struct ViewState: Equatable {
		let appearanceID: Profile.Network.Account.AppearanceID
		let name: String
		let address: AccountAddress
		let mode: ChooseAccountsRow.State.Mode

		init(state: ChooseAccountsRow.State) {
			appearanceID = state.account.appearanceID
			name = state.account.displayName.rawValue
			address = state.account.address
			mode = state.mode
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let viewState: ViewState
		let isSelected: Bool
		let action: () -> Void

		var body: some SwiftUI.View {
			Button(action: action) {
				HStack {
					VStack(alignment: .leading, spacing: .medium3) {
						Text(viewState.name)
							.foregroundColor(.app.white)
							.textStyle(.body1Header)

						AddressView(.address(.account(viewState.address)))
							.foregroundColor(.app.whiteTransparent)
							.textStyle(.body2HighImportance)
					}

					Spacer()

					switch viewState.mode {
					case .checkmark:
						CheckmarkView(
							appearance: .light,
							isChecked: isSelected
						)
					case .radioButton:
						RadioButton(
							appearance: .light,
							state: isSelected ? .selected : .unselected
						)
					}
				}
				.padding(.medium1)
				.background(
					viewState.appearanceID.gradient
						.brightness(isSelected ? -0.1 : 0)
				)
				.cornerRadius(.small1)
			}
			.buttonStyle(.inert)
		}
	}
}
