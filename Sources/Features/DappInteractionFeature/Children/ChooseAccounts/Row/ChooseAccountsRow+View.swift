import FeaturePrelude

// MARK: - ChooseAccountsRow.View
extension ChooseAccountsRow {
	struct ViewState: Equatable {
		let appearanceID: Profile.Network.Account.AppearanceID
		let accountName: String
		let accountAddress: AddressView.ViewState
		let mode: ChooseAccountsRow.State.Mode

		init(state: ChooseAccountsRow.State) {
			appearanceID = state.account.appearanceID
			accountName = state.account.displayName.rawValue
			accountAddress = AddressView.ViewState(address: state.account.address.address, format: .default)
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
						Text(viewState.accountName)
							.foregroundColor(.app.white)
							.textStyle(.body1Header)

						AddressView(viewState.accountAddress, copyAddressAction: .none)
							.foregroundColor(.app.white.opacity(0.8))
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
