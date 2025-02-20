import ComposableArchitecture
import SwiftUI

// MARK: - ChooseAccountsRow.View
extension ChooseAccountsRow {
	struct ViewState: Equatable {
		let account: Account
		let mode: ChooseAccountsRow.State.Mode

		init(state: ChooseAccountsRow.State) {
			self.mode = state.mode
			self.account = state.account
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
				AccountCard(kind: .selection(isSelected: isSelected), account: viewState.account, showName: showName) {
					switch viewState.mode {
					case .checkmark:
						CheckmarkView(
							appearance: .light,
							isChecked: isSelected
						)
					case .radioButton:
						RadioButton(
							appearance: .light,
							isSelected: isSelected
						)
					}
				}
			}
			.buttonStyle(.inert)
		}
	}
}
