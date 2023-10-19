import ComposableArchitecture
import SwiftUI
extension EditPersonaEntries {
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaEntries>

		public init(store: StoreOf<EditPersonaEntries>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			VStack(spacing: .medium2) {
				IfLetStore(
					store.scope(
						state: \.name,
						action: (/Action.child
							.. EditPersonaEntries.ChildAction.name
						).embed
					)
				) { store in
					EditPersonaEntry.View(
						store: store,
						contentView: EditPersonaName.View.init
					)

					Separator()
				}

				IfLetStore(
					store.scope(
						state: \.phoneNumber,
						action: (/Action.child
							.. EditPersonaEntries.ChildAction.phoneNumber
						).embed
					)
				) { store in
					EditPersonaEntry.View(
						store: store,
						contentView: EditPersonaDynamicField.View.init
					)
					Separator()
				}

				IfLetStore(
					store.scope(
						state: \.emailAddress,
						action: (/Action.child
							.. EditPersonaEntries.ChildAction.emailAddress
						).embed
					)
				) { store in
					EditPersonaEntry.View(
						store: store,
						contentView: EditPersonaDynamicField.View.init
					)
					Separator()
				}
			}
		}
	}
}
