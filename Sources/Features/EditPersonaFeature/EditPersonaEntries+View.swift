import ComposableArchitecture
import Prelude
import SwiftUI

extension EditPersonaEntries {
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaEntries>

		public init(store: StoreOf<EditPersonaEntries>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			IfLetStore(
				store.scope(
					state: \.name,
					action: (/Action.child
						.. EditPersonaEntries.ChildAction.name
					).embed
				)
			) { store in
				EditPersonaEntry.View(store: store) { s in
					AnyView(EditPersonaName.View(
						store: s
					))
				}
			}

			IfLetStore(
				store.scope(
					state: \.emailAddress,
					action: (/Action.child
						.. EditPersonaEntries.ChildAction.emailAddress
					).embed
				),
				then: EditPersonaField.View.init
			)
		}
	}
}
