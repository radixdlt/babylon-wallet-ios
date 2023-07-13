import ComposableArchitecture
import SwiftUI

extension EditPersonaEntry {
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaEntry>

		public init(store: StoreOf<EditPersonaEntry>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			EditPersonaField.View(
				store: store.scope(
					state: { $0 },
					action: (/Action.child .. EditPersonaEntry<ID>.ChildAction.field).embed
				)
			)
		}
	}
}
