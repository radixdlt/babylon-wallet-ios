import FeaturePrelude

extension EditPersonaAddFields.State {
	var viewState: EditPersonaAddFields.ViewState {
		.init(
			availableFields: availableFields,
			selectedFields: selectedFields
		)
	}
}

extension EditPersonaAddFields {
	public struct ViewState: Equatable {
		let availableFields: [EditPersona.State.DynamicFieldID]
		let selectedFields: [EditPersona.State.DynamicFieldID]?
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaAddFields>

		public init(store: StoreOf<EditPersonaAddFields>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStack {
					List {
						Selection(
							viewStore.binding(
								get: \.selectedFields,
								send: { .selectedFieldsChanged($0) }
							),
							from: viewStore.availableFields,
							requiring: .atLeast(1)
						) { item in
							HStack {
								Text(item.value.title)
								Spacer()
								Button(action: item.action) {
									Image(systemName: item.isSelected ? "square.fill" : "square")
								}
							}
						}
					}
					.footer {
						WithControlRequirements(
							viewStore.selectedFields,
							forAction: { viewStore.send(.addButtonTapped($0)) }
						) { action in
							Button(L10n.EditPersona.AddAField.Button.add, action: action)
								.buttonStyle(.primaryRectangular)
						}
					}
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct EditPersonaAddFields_PreviewProvider: PreviewProvider {
	static var previews: some View {
		EditPersonaAddFields_Preview()
	}
}

struct EditPersonaAddFields_Preview: View {
	var body: some View {
		EditPersonaAddFields.View(
			store: Store(
				initialState: EditPersonaAddFields.State(
					excludedFieldIDs: [
						.emailAddress,
					]
				),
				reducer: EditPersonaAddFields()
			)
		)
	}
}
#endif
