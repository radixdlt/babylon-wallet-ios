import DerivePublicKeyFeature
import FeaturePrelude

extension CreationOfPersona {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreationOfPersona>

		public init(store: StoreOf<CreationOfPersona>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			DerivePublicKey.View(
				store: store.scope(
					state: \.derivePublicKey,
					action: { CreationOfPersona.Action.child(.derivePublicKey($0)) }
				)
			)
			.navigationTitle(L10n.CreateEntity.Ledger.createPersona)
		}
	}
}
