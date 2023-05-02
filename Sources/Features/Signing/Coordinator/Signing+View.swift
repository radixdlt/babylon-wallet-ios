import FeaturePrelude

extension Signing.State {
	var viewState: Signing.ViewState {
		.init()
	}
}

// MARK: - Signing.View
extension Signing {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Signing>

		public init(store: StoreOf<Signing>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store.scope(state: \.step)) {
				CaseLet(
					state: /Signing.State.Step.prepare,
					action: { Signing.Action.child(.prepare($0)) },
					then: { PrepareForSigning.View(store: $0) }
				)
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
}
