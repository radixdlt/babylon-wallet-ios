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
						Text(L10n.EditPersona.AddAField.explanation)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding([.top, .horizontal], .medium3)

						ScrollView {
							LazyVStack(spacing: 0) {
								Selection(
									viewStore.binding(
										get: \.selectedFields,
										send: { .selectedFieldsChanged($0) }
									),
									from: viewStore.availableFields,
									requiring: .atLeast(1)
								) { item in
									Button(action: item.action) {
										HStack(spacing: 0) {
											Text(item.value.title)
												.textStyle(.body1HighImportance)
												.foregroundColor(.app.gray1)
											Spacer()
											Image(
												asset: item.isSelected
													? AssetResource.checkmarkDarkSelected
													: AssetResource.checkmarkDarkUnselected
											)
											.padding(.trailing, .small3)
										}
										.padding(.vertical, .medium3)
									}
									.buttonStyle(.inert)
									.separator(.bottom)
								}
							}
							.padding(.horizontal, .medium3)
						}
					}
					.navigationTitle(Text(L10n.EditPersona.AddAField.title))
					#if os(iOS)
						.navigationBarTitleColor(.app.gray1)
						.navigationBarTitleDisplayMode(.inline)
						.navigationBarInlineTitleFont(.app.secondaryHeader)
						.toolbar {
							ToolbarItem(placement: .navigationBarLeading) {
								CloseButton(action: {})
							}
						}
					#endif
						.separator(.top)
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
