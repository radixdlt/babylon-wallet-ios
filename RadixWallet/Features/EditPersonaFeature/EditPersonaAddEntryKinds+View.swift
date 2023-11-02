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
	public struct ViewState: Equatable {
		let availableEntryKinds: [EntryKind]
		let selectedEntryKinds: [EntryKind]?
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaAddEntryKinds>

		public init(store: StoreOf<EditPersonaAddEntryKinds>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStack {
					VStack(spacing: .medium3) {
						Text(L10n.EditPersona.AddAField.subtitle)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
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
					.navigationTitle(Text(L10n.EditPersona.AddAField.title))
					.navigationBarTitleColor(.app.gray1)
					.navigationBarTitleDisplayMode(.inline)
					.navigationBarInlineTitleFont(.app.secondaryHeader)
					.toolbar {
						ToolbarItem(placement: .primaryAction) {
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
				}
			}
		}
	}
}

/// No `PreviewProvider` here ☹️
/// Use the `PersonaDetailsPreview` scheme instead 🤠
