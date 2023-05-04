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
					VStack(spacing: .medium3) {
						Text(L10n.EditPersona.AddAField.subtitle)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding([.top, .horizontal], .medium3)

						SelectionList(
							viewStore.availableFields,
							title: \.title,
							selection: viewStore.binding(
								get: \.selectedFields,
								send: { .selectedFieldsChanged($0) }
							),
							requiring: .atLeast(1)
						)
					}
					.navigationTitle(Text(L10n.EditPersona.AddAField.title))
					#if os(iOS)
						.navigationBarTitleColor(.app.gray1)
						.navigationBarTitleDisplayMode(.inline)
						.navigationBarInlineTitleFont(.app.secondaryHeader)
						.toolbar {
							ToolbarItem(placement: .navigationBarLeading) {
								CloseButton(action: { viewStore.send(.closeButtonTapped) })
							}
						}
					#endif
						.separator(.top)
						.footer {
							WithControlRequirements(
								viewStore.selectedFields,
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
