import ComposableArchitecture
import SwiftUI

// MARK: - Signing.View

extension Signing {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Signing>

		init(store: StoreOf<Signing>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			SignWithFactorSource.View(store: store.scope(state: \.signWithFactorSource, action: \.child.signWithFactorSource))
		}
	}
}
