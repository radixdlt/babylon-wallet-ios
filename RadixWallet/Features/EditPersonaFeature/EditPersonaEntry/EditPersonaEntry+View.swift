import ComposableArchitecture
import Sargon
import SwiftUI

extension PersonaData.Entry.Kind {
	var title: String {
		switch self {
		case .fullName:
			L10n.AuthorizedDapps.PersonaDetails.fullName
		case .emailAddress:
			L10n.AuthorizedDapps.PersonaDetails.emailAddress
		case .phoneNumber:
			L10n.AuthorizedDapps.PersonaDetails.phoneNumber
		}
	}
}

// MARK: - EditPersonaEntry.View
extension EditPersonaEntry {
	struct View: SwiftUI.View {
		let store: StoreOf<EditPersonaEntry>

		let contentView: (StoreOf<ContentReducer>) -> ContentReducer.View

		var body: some SwiftUI.View {
			VStack(spacing: .small2) {
				WithViewStore(
					store.scope(
						state: identity,
						action: Action.view
					),
					observe: identity
				) { viewStore in
					HStack {
						Text(viewStore.kind.title)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray1)

						Spacer()

						if viewStore.isRequestedByDapp {
							Text(L10n.EditPersona.requiredByDapp)
								.textStyle(.body2Regular)
								.foregroundColor(.app.gray2)
								.multilineTextAlignment(.trailing)
						} else {
							// TODO: Clarify below
							// Zepplin design specifies that single filed Entry should have the delete button next to the field.
							// This however sets it next to the Entry title to be consistent across Entries.
							Button(action: { viewStore.send(.deleteButtonTapped) }) {
								Image(asset: AssetResource.trash)
									.offset(x: .small3)
									.frame(.verySmall, alignment: .trailing)
							}
							.modifier {
								if viewStore.canBeDeleted { $0 } else { $0.hidden() }
							}
						}
					}
				}

				contentView(
					store.scope(state: \.content) { .child(.content($0)) }
				)
			}
		}
	}
}

extension EditPersonaEntry.State {
	fileprivate var canBeDeleted: Bool {
		!isRequestedByDapp
	}
}
