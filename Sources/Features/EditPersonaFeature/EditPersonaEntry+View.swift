import FeaturePrelude

// MARK: - EditPersonaEntry.View
extension EditPersonaEntry {
	public struct View: SwiftUI.View {
		let store: StoreOf<EditPersonaEntry>

		let contentView: (StoreOf<ContentReducer>) -> AnyView

		public var body: some SwiftUI.View {
			VStack {
				HStack {
					WithViewStore(
						store.scope(
							state: identity,
							action: Action.view
						),
						observe: identity
					) { viewStore in
						VStack {
							Text(viewStore.name)
							if viewStore.isRequestedByDapp {
								Text(L10n.EditPersona.requiredByDapp)
									.textStyle(.body2Regular)
									.foregroundColor(.app.gray2)
									.multilineTextAlignment(.trailing)
							}
						}
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

				contentView(
					store.scope(
						state: \.content,
						action: (/Action.child
							.. EditPersonaEntry<ContentReducer>.ChildAction.content
						).embed
					)
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
