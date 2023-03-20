import FeaturePrelude

// MARK: - ChooseAccountsRow.View
extension ChooseAccountsRow {
	struct ViewState: Equatable {
		let appearanceID: Profile.Network.Account.AppearanceID
		let isSelected: Bool
		let accountName: String
		let accountAddress: AddressView.ViewState
		let mode: ChooseAccountsRow.State.Mode

		init(state: ChooseAccountsRow.State) {
			appearanceID = state.account.appearanceID
			isSelected = state.isSelected
			accountName = state.account.displayName.rawValue
			accountAddress = .init(address: state.account.address.address, format: .default)
			mode = state.mode
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<ChooseAccountsRow>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ChooseAccountsRow.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				HStack {
					VStack(alignment: .leading, spacing: .medium3) {
						Text(viewStore.accountName)
							.foregroundColor(.app.white)
							.textStyle(.body1Header)

						AddressView(viewStore.accountAddress, copyAddressAction: .none)
							.foregroundColor(.app.white.opacity(0.8))
							.textStyle(.body2HighImportance)
					}

					Spacer()

					switch viewStore.mode {
					case .checkmark:
						CheckmarkView(
							appearance: .light,
							isChecked: viewStore.isSelected
						)
					case .radioButton:
						RadioButton(
							appearance: .light,
							state: viewStore.isSelected ? .selected : .unselected
						)
					}
				}
				.padding(.medium1)
				.background(
					viewStore.appearanceID.gradient
						.brightness(viewStore.isSelected ? -0.1 : 0)
				)
				.cornerRadius(.small1)
				.onTapGesture {
					viewStore.send(.didSelect)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Row_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		ChooseAccountsRow.View(
			store: .init(
				initialState: .previewValueOne,
				reducer: ChooseAccountsRow()
			)
		)
	}
}

extension ChooseAccountsRow.State {
	static let previewValueOne = Self(account: .previewValue0, mode: .radioButton)
	static let previewValueTwo = Self(account: .previewValue1, mode: .checkmark)
}
#endif
