import FeaturePrelude

// MARK: - EditPersonaName.View
extension EditPersonaName {
	public struct View: SwiftUI.View {
		let store: StoreOf<EditPersonaName>

		public var body: some SwiftUI.View {
			HStack {
				EditPersonaField.View(
					store: store.scope(
						state: \.family,
						action: (/Action.child
							.. EditPersonaName.ChildAction.family
						).embed
					)
				)
				EditPersonaField.View(
					store: store.scope(
						state: \.given,
						action: (/Action.child
							.. EditPersonaName.ChildAction.given
						).embed
					)
				)
			}
		}
	}
}
