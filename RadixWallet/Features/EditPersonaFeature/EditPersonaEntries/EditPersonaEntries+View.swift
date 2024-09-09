import ComposableArchitecture
import SwiftUI

extension EditPersonaEntries {
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaEntries>

		public init(store: StoreOf<EditPersonaEntries>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			VStack(spacing: .large1) {
				IfLetStore(
					store.scope(state: \.name, action: \.child.name)
				) { store in
					EditPersonaEntry.View(
						store: store,
						contentView: EditPersonaName.View.init
					)

					Separator()
				}

				IfLetStore(
					store.scope(state: \.phoneNumber, action: \.child.phoneNumber)
				) { store in
					EditPersonaEntry.View(
						store: store,
						contentView: EditPersonaDynamicField.View.init
					)
					Separator()
				}

				IfLetStore(
					store.scope(state: \.emailAddress, action: \.child.emailAddress)
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
