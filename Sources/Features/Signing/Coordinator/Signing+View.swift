import FeaturePrelude

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
				case .signWithDeviceFactors:
					CaseLet(
						/Signing.State.Step.signWithDeviceFactors,
						action: Signing.ChildAction.signWithDeviceFactors,
						then: { SignWithFactorSourcesOfKindDevice.View(store: $0) }
					)

				case .signWithLedgerFactors:
					CaseLet(
						/Signing.State.Step.signWithLedgerFactors,
						action: Signing.ChildAction.signWithLedgerFactors,
						then: { SignWithFactorSourcesOfKindLedger.View(store: $0) }
					)
				}
			}
		}
	}

	/// A wrapper for Signing.View to be used in a sheet context
	@MainActor
	public struct SheetView: SwiftUI.View {
		private let store: StoreOf<Signing>

		public init(store: StoreOf<Signing>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithNavigationBar {
				ViewStore(store).send(.view(.closeButtonTapped))
			} content: {
				View(store: store)
			}
		}
	}
}
