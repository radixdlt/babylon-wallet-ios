import ComposableArchitecture
import SwiftUI

// MARK: - Signing.View

extension Signing {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Signing>

		public init(store: StoreOf<Signing>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SignWithFactorSource.View(store: store.scope(state: \.signWithFactorSource, action: \.child.signWithFactorSource))
		}
	}
}
