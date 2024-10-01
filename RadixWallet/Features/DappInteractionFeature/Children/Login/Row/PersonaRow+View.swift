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
		let mode: Mode

		init(viewState: ViewState, mode: Mode) {
			self.viewState = viewState
			self.mode = mode
		}

		init(viewState: ViewState, isSelected: Bool, action: @escaping () -> Void) {
			self.viewState = viewState
			self.mode = .selection(isSelected: isSelected, action: action)
		}

		var body: some SwiftUI.View {
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

					if let isSelected {
						RadioButton(
							appearance: .dark,
							state: isSelected ? .selected : .unselected
						)
						.padding(.leading, .small3)
					}
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
			.cardShadow
			.embedInButton(when: action)
			.buttonStyle(.inert)
		}
	}
}

extension PersonaRow.View {
	var isSelected: Bool? {
		switch mode {
		case let .selection(isSelected, _):
			isSelected
		case .display:
			nil
		}
	}

	var action: (() -> Void)? {
		switch mode {
		case let .selection(_, action):
			action
		case .display:
			nil
		}
	}

	enum Mode {
		case selection(isSelected: Bool, action: () -> Void)
		case display
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
