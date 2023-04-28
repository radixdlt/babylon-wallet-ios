import struct FactorSourcesClient.SigningFactor
import FeaturePrelude

extension SignWithFactorSourcesOfKindDevice.State {
	var viewState: SignWithFactorSourcesOfKindDevice.ViewState {
		.init(currentSigningFactor: currentSigningFactor)
	}
}

// MARK: - SignWithFactorSourcesOfKindDevice.View
extension SignWithFactorSourcesOfKindDevice {
	public struct ViewState: Equatable {
		// TODO: declare some properties
		let currentSigningFactor: SigningFactor?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SignWithFactorSourcesOfKindDevice>

		public init(store: StoreOf<SignWithFactorSourcesOfKindDevice>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Text("Sign transaction with phone")
					if let currentSigningFactor = viewStore.currentSigningFactor {
						Text("Factor Source ID: \(currentSigningFactor.factorSource.id.hex())")
					}
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}
