import ComposableArchitecture
import SwiftUI

extension EditPersonaAddEntryKinds.State {
	var viewState: EditPersonaAddEntryKinds.ViewState {
		.init(
			availableEntryKinds: availableEntryKinds,
			selectedEntryKinds: selectedEntryKinds
		)
	}
}

extension EditPersonaAddEntryKinds {
	struct ViewState: Equatable {
		let availableEntryKinds: [EntryKind]
		let selectedEntryKinds: [EntryKind]?
	}

	struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaAddEntryKinds>

		init(store: StoreOf<EditPersonaAddEntryKinds>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStack {
					VStack(spacing: .medium3) {
						Text(L10n.EditPersona.AddAField.subtitle)
							.textStyle(.body1HighImportance)
							.foregroundColor(.secondaryText)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding([.top, .horizontal], .medium3)

						SelectionList(
							viewStore.availableEntryKinds,
							title: \.title,
							selection: viewStore.binding(
								get: \.selectedEntryKinds,
								send: { .selectedEntryKindsChanged($0) }
							),
							requiring: .atLeast(1)
						)
					}
					.radixToolbar(title: L10n.EditPersona.AddAField.title)
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							CloseButton(action: { viewStore.send(.closeButtonTapped) })
						}
					}
					.separator(.top)
					.footer {
						WithControlRequirements(
							viewStore.selectedEntryKinds,
							forAction: { viewStore.send(.addButtonTapped($0)) }
						) { action in
							Button(L10n.EditPersona.AddAField.add, action: action)
								.buttonStyle(.primaryRectangular)
						}
					}
					.background(.primaryBackground)
				}
			}
		}
	}
}

/// No `PreviewProvider` here ☹️
/// Use the `PersonaDetailsPreview` scheme instead 🤠
