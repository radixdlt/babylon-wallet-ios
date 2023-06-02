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
			SwitchStore(store.scope(state: \.step)) {
				CaseLet(
					state: /Signing.State.Step.signWithDeviceFactors,
					action: { Signing.Action.child(.signWithDeviceFactors($0)) },
					then: { SignWithFactorSourcesOfKindDevice.View(store: $0) }
				)
				CaseLet(
					state: /Signing.State.Step.signWithLedgerFactors,
					action: { Signing.Action.child(.signWithLedgerFactors($0)) },
					then: { SignWithFactorSourcesOfKindLedger.View(store: $0) }
				)
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
