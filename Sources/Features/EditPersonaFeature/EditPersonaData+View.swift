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
			IfLetStore(store) { store in
				EditPersonaField.View(
					store: store.scope(
						state: identity,
						action: (/Action.child .. EditPersonaEntries.ChildAction.emailAddress).embed
					)
				)
			}
		}
	}
}
