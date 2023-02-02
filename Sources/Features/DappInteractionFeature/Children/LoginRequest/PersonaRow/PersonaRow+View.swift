import FeaturePrelude

// MARK: - PersonaRow.View
public extension PersonaRow {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<PersonaRow>

		public init(store: StoreOf<PersonaRow>) {
			self.store = store
		}
	}
}

public extension PersonaRow.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack(alignment: .leading, spacing: .zero) {
				ZStack {
					HStack(alignment: .top) {
						Circle()
							.strokeBorder(Color.app.gray3, lineWidth: 1)
							.background(Circle().fill(Color.app.gray4))
							.frame(.small)
							.padding(.trailing, .small1)

						VStack(alignment: .leading, spacing: 4) {
							Text(viewStore.name)
								.foregroundColor(.app.gray1)
								.textStyle(.secondaryHeader)

							Text("Sharing")
								.foregroundColor(.app.gray2)
								.textStyle(.body2Header)

							Group {
								Text("3 pieces of personal data")
								Text("4 accounts")
							}
							.foregroundColor(.app.gray2)
							.textStyle(.body2Regular)
						}

						Spacer()
					}

					HStack {
						Spacer()
						RadioButton(state: viewStore.selectionState)
					}
				}
				.padding(.medium2)

				if viewStore.hasAlreadyLoggedIn {
					Group {
						Color.app.gray4
							.frame(height: 1)

						// TODO: replace with dapp.lastUsedOn
						Text("Your last login was on 23 Jan 2023")
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

// MARK: - PersonaRow.View.ViewState
extension PersonaRow.View {
	struct ViewState: Equatable {
		let name: String
		let hasAlreadyLoggedIn: Bool
		let selectionState: RadioButton.State

		init(state: PersonaRow.State) {
			name = state.persona.displayName ?? L10n.DApp.unknownName
			hasAlreadyLoggedIn = state.hasAlreadyLoggedIn

			switch state.selectionState {
			case .unselected:
				selectionState = .unselected
			case .selected:
				selectionState = .selected
			case .disabled:
				selectionState = .disabled
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
