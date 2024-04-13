import ComposableArchitecture
import SwiftUI

// MARK: - ChooseAccountsRow.View
extension ChooseAccountsRow {
	struct ViewState: Equatable {
		let account: Sargon.Account
		let mode: ChooseAccountsRow.State.Mode

		init(state: ChooseAccountsRow.State) {
			self.mode = state.mode
			self.account = state.account
		}

		var name: String {
			account.displayName.rawValue
		}

		var appearanceID: AppearanceID {
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
		let showName: Bool
		let action: () -> Void

		init(viewState: ViewState, isSelected: Bool, showName: Bool = true, action: @escaping () -> Void) {
			self.viewState = viewState
			self.isSelected = isSelected
			self.showName = showName
			self.action = action
		}

		var body: some SwiftUI.View {
			Button(action: action) {
				HStack(spacing: 0) {
					VStack(alignment: .leading, spacing: .medium3) {
						if showName {
							Text(viewState.name)
								.foregroundColor(.app.white)
								.textStyle(.body1Header)
						}

						AddressView(.address(of: viewState.account))
							.foregroundColor(.app.whiteTransparent)
							.textStyle(.body2HighImportance)
					}

					Spacer(minLength: .small2)

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
				.padding(.vertical, .medium3)
				.padding(.horizontal, .medium1)
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
