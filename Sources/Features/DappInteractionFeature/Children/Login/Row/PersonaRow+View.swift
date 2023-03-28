import FeaturePrelude

// MARK: - PersonaRow.View
extension PersonaRow {
	struct ViewState: Equatable {
		let name: String
		let lastLogin: String?

		init(state: PersonaRow.State) {
			name = state.persona.displayName.rawValue

			if let lastLogin = state.lastLogin {
				let formatter = DateFormatter()
				formatter.dateFormat = "d MMM YYY"
				let formatted = formatter.string(from: lastLogin)
				self.lastLogin = L10n.DApp.Login.Row.lastLoginWasOn(formatted)
			} else {
				self.lastLogin = nil
			}
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let viewState: ViewState
		let isSelected: Bool
		let action: () -> Void

		var body: some SwiftUI.View {
			Button(action: action) {
				VStack(alignment: .leading, spacing: .zero) {
					ZStack {
						HStack(alignment: .center) {
							Circle()
								.strokeBorder(Color.app.gray3, lineWidth: 1)
								.background(Circle().fill(Color.app.gray4))
								.frame(.small)
								.padding(.trailing, .small1)

							VStack(alignment: .leading, spacing: 4) {
								Text(viewState.name)
									.foregroundColor(.app.gray1)
									.textStyle(.secondaryHeader)
							}

							Spacer()
						}

						HStack {
							Spacer()
							RadioButton(
								appearance: .dark,
								state: isSelected ? .selected : .unselected
							)
						}
					}
					.padding(.medium2)

					if let lastLogin = viewState.lastLogin {
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
			}
			.buttonStyle(.inert)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - PersonaRow_Preview
struct PersonaRow_Preview: PreviewProvider {
	static var previews: some View {
		WithState(initialValue: false) { $isSelected in
			PersonaRow.View(
				viewState: .init(state: .previewValue),
				isSelected: isSelected,
				action: { isSelected = true }
			)
		}
	}
}

extension PersonaRow.State {
	static let previewValue: Self = .init(
		persona: .previewValue0,
		lastLogin: Date()
	)
}
#endif
