import ComposableArchitecture
import SwiftUI

// MARK: - ChooseAccountsRow.View
extension ChooseAccountsRow {
	struct ViewState: Equatable {
		let account: Profile.Network.Account
		let mode: ChooseAccountsRow.State.Mode

		init(state: ChooseAccountsRow.State) {
			self.mode = state.mode
			self.account = state.account
		}

		var name: String {
			account.displayName.rawValue
		}

		var appearanceID: Profile.Network.Account.AppearanceID {
			account.appearanceID
		}

		var address: AccountAddress {
			account.address
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

						AddressView(.address(of: viewState.account))
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
