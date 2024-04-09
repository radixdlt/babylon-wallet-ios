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
			SwitchStore(store.scope(state: \.step, action: Action.child)) { state in
				switch state {
				case .signWithFactorSource:
					CaseLet(
						/Signing.State.Step.signWithFactorSource,
						action: Signing.ChildAction.signWithFactorSource,
						then: { SignWithFactorSource.View(store: $0) }
					)
				}
			}
		}
	}
}
