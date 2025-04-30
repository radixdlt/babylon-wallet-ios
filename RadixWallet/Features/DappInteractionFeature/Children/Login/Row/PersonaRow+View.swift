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

		init(
			viewState: ViewState,
			selectionType: SelectionType,
			isSelected: Bool,
			action: @escaping () -> Void
		) {
			self.viewState = viewState
			self.mode = .selection(type: selectionType, isSelected: isSelected, action: action)
		}

		var body: some SwiftUI.View {
			VStack(alignment: .leading, spacing: .zero) {
				HStack(alignment: .center, spacing: .zero) {
					Image(.persona)
						.resizable()
						.frame(.small)

					Text(viewState.name)
						.foregroundColor(.primaryText)
						.textStyle(.secondaryHeader)
						.padding(.leading, .medium3)

					Spacer()

					if case let .selection(selectionType, isSelected, _) = mode {
						switch selectionType {
						case .radioButton:
							RadioButton(
								appearance: .dark,
								isSelected: isSelected
							)
							.padding(.leading, .small3)
						case .checkmark:
							CheckmarkView(
								appearance: .dark,
								isChecked: isSelected
							)
						}
					}
				}
				.padding(.medium2)

				if let lastLogin = viewState.lastLogin {
					VStack(alignment: .leading, spacing: .zero) {
						Separator()

						Text(lastLogin)
							.foregroundColor(.secondaryText)
							.textStyle(.body2Regular)
							.padding(.horizontal, .medium2)
							.padding(.vertical, .small2)
					}
				}
			}
			.background(.secondaryBackground)
			.cornerRadius(.small1)
			.embedInButton(when: action)
			.buttonStyle(.inert)
		}
	}
}

extension PersonaRow.View {
	var action: (() -> Void)? {
		switch mode {
		case let .selection(_, _, action):
			action
		case .display:
			nil
		}
	}

	enum Mode {
		case selection(type: SelectionType, isSelected: Bool, action: () -> Void)
		case display
	}

	enum SelectionType {
		case radioButton
		case checkmark
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
				selectionType: .radioButton,
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
