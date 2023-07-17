import FeaturePrelude

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
							title: \.entry.kind.rawValue,
							selection: viewStore.binding(
								get: \.selectedEntryKinds,
								send: { .selectedEntryKindsChanged($0) }
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
							ToolbarItem(placement: .primaryAction) {
								CloseButton(action: { viewStore.send(.closeButtonTapped) })
							}
						}
					#endif
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

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct EditPersonaAddEntryKinds_PreviewProvider: PreviewProvider {
	static var previews: some View {
		EditPersonaAddEntryKinds_Preview()
	}
}

struct EditPersonaAddEntryKinds_Preview: View {
	var body: some View {
		EditPersonaAddEntryKinds.View(
			store: Store(
				initialState: EditPersonaAddEntryKinds.State(
					excludedEntryKinds: [
						.emailAddress,
					]
				),
				reducer: EditPersonaAddEntryKinds()
			)
		)
	}
}
#endif
