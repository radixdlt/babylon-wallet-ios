import ComposableArchitecture
import Prelude
import SwiftUI

extension EditPersonaData {
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaData>

		public init(store: StoreOf<EditPersonaData>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			IfLetStore(store) { store in
				EditPersonaField.View(
					store: store.scope(
						state: identity,
						action: (/Action.child .. EditPersonaData.ChildAction.emailAddress).embed
					)
				)
			}
		}
	}
}
