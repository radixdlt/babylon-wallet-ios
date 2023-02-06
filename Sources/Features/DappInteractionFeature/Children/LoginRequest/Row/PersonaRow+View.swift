import FeaturePrelude

// MARK: - PersonaRow.View
extension PersonaRow {
	struct ViewState: Equatable {
		let name: String
		let lastLogin: String?
		let numberOfSharedAccounts: String?
		let selectionState: RadioButton.State

		init(state: PersonaRow.State) {
			name = state.persona.displayName.rawValue

			if let lastLogin = state.lastLogin {
				let formatter = DateFormatter()
				formatter.dateFormat = "d MMM YYY"
				let formatted = formatter.string(from: lastLogin)
				self.lastLogin = L10n.DApp.LoginRequest.Row.lastLoginWasOn(formatted)
			} else {
				self.lastLogin = nil
			}

			switch state.numberOfSharedAccounts {
			case 0:
				numberOfSharedAccounts = nil
			case 1:
				numberOfSharedAccounts = L10n.DApp.LoginRequest.Row.oneSharedAccount
			default:
				numberOfSharedAccounts = L10n.DApp.LoginRequest.Row.moreSharedAccounts(state.numberOfSharedAccounts)
			}

			selectionState = state.isSelected ? .selected : .unselected
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PersonaRow>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				VStack(alignment: .leading, spacing: .zero) {
					ZStack {
						HStack(alignment: .center) {
							Circle()
								.strokeBorder(Color.app.gray3, lineWidth: 1)
								.background(Circle().fill(Color.app.gray4))
								.frame(.small)
								.padding(.trailing, .small1)

							VStack(alignment: .leading, spacing: 4) {
								Text(viewStore.name)
									.foregroundColor(.app.gray1)
									.textStyle(.secondaryHeader)

								if let numberOfSharedAccounts = viewStore.numberOfSharedAccounts {
									Text(L10n.DApp.LoginRequest.Row.sharing)
										.foregroundColor(.app.gray2)
										.textStyle(.body2Header)

									Text(numberOfSharedAccounts)
										.foregroundColor(.app.gray2)
										.textStyle(.body2Regular)
								}
							}

							Spacer()
						}

						HStack {
							Spacer()
							RadioButton(state: viewStore.selectionState)
						}
					}
					.padding(.medium2)

					if let lastLogin = viewStore.lastLogin {
						Group {
							Color.app.gray4
								.frame(height: 1)

							Text(lastLogin)
								.foregroundColor(.app.gray2)
								.textStyle(.body2Regular)
								.padding(.horizontal, .medium2)
								.padding(.vertical, .small1)
						}
					}
				}
				.background(Color.app.gray5)
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

// MARK: - PersonaRow_Preview
struct PersonaRow_Preview: PreviewProvider {
	static var previews: some View {
		PersonaRow.View(
			store: .init(
				initialState: .previewValue,
				reducer: PersonaRow()
			)
		)
	}
}
#endif
