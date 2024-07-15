import ComposableArchitecture
import SwiftUI

// MARK: - PersonaRow.View
extension PersonaRow {
	struct ViewState: Equatable {
		let name: String
		let lastLogin: String?

		init(state: PersonaRow.State) {
			self.name = state.persona.displayName.rawValue

			if let lastLogin = state.lastLogin {
				let lastLoginString = lastLogin.formatted(date: .abbreviated, time: .omitted)
				self.lastLogin = L10n.DAppRequest.Login.lastLoginWasOn(lastLoginString)
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
					HStack(alignment: .center, spacing: .zero) {
						Image(.persona)
							.resizable()
							.frame(.small)

						Text(viewState.name)
							.foregroundColor(.app.gray1)
							.textStyle(.secondaryHeader)
							.padding(.leading, .medium3)

						Spacer()

						RadioButton(
							appearance: .dark,
							state: isSelected ? .selected : .unselected
						)
						.padding(.leading, .small3)
					}
					.padding(.medium2)

					Separator()
					if let lastLogin = viewState.lastLogin {
						VStack(alignment: .leading, spacing: .zero) {
							Separator()

							Text(lastLogin)
								.foregroundColor(.app.gray2)
								.textStyle(.body2Regular)
								.padding(.horizontal, .medium2)
								.padding(.vertical, .small2)
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
import struct SwiftUINavigation.WithState

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
