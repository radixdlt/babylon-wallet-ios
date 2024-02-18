import ComposableArchitecture
import SwiftUI

extension CreationOfPersona {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreationOfPersona>

		public init(store: StoreOf<CreationOfPersona>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			DerivePublicKeys.View(
				store: store.scope(
					state: \.derivePublicKeys,
					action: { CreationOfPersona.Action.child(.derivePublicKeys($0)) }
				)
			)
			.navigationTitle(L10n.CreateEntity.Ledger.createPersona)
		}
	}
}
