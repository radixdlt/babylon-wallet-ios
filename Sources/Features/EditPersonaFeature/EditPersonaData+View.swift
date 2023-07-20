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
					state: \.emailAddress,
					action: (/Action.child
						.. EditPersonaEntries.ChildAction.emailAddress
					).embed
				),
				then: EditPersonaField.View.init
			)
			IfLetStore(
				store.scope(
					state: \.name,
					action: (/Action.child
						.. EditPersonaEntries.ChildAction.name
					).embed
				)
			) { store in
				EntryWrapperView(
					viewState: .init(
						name: "Name!",
						isRequestedByDapp: true,
						isDeletable: true
					)
				) {
					EditPersonaName.View(store: store)
				}
			}
		}
	}
}
