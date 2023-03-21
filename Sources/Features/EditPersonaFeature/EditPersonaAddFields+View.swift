import FeaturePrelude

extension EditPersonaAddFields.State {
	var viewState: EditPersonaAddFields.ViewState {
		.init(
			availableFields: availableFields,
			chosenFields: chosenFields
		)
	}
}

extension EditPersonaAddFields {
	public struct ViewState: Equatable {
		let availableFields: [EditPersona.State.DynamicField]
		let chosenFields: [EditPersona.State.DynamicField]?
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
						Choices(
							viewStore.binding(
								get: \.chosenFields,
								send: { .chosenFieldsChanged($0) }
							),
							in: viewStore.availableFields,
							requiring: .atLeast(1)
						) { item in
							HStack {
								Text(item.value.title)
								Spacer()
								Button(action: item.action) {
									Image(systemName: item.isChosen ? "square.fill" : "square")
								}
							}
							.disabled(item.isDisabled)
						}
					}
					.safeAreaInset(edge: .bottom, spacing: 0) {
						WithControlRequirements(
							viewStore.chosenFields.flatMap(NonEmptyArray.init(rawValue:)),
							forAction: { viewStore.send(.addButtonTapped($0)) }
						) { action in
							Button(L10n.EditPersona.AddAField.Button.add, action: action)
								.buttonStyle(.primaryRectangular)
						}
						.padding(.medium2)
						.background(Color.white)
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
					excludedFields: [
						.emailAddress,
					]
				),
				reducer: EditPersonaAddFields()
			)
		)
	}
}
#endif
