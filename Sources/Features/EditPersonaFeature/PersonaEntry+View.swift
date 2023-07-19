import ComposableArchitecture
import Prelude
import SwiftUI

extension EditPersonaEntry {
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaEntry>

		public init(store: StoreOf<EditPersonaEntry>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			IfLetStore(
				store.scope(state: { $0.emailAddresses.dynamicField })
			) { store in
				EditPersonaField.View(
					store: store.scope(
						state: identity,
						action: (/Action.child .. EditPersonaEntry.ChildAction.emailAddress).embed
					)
				)
			}
		}
	}
}
