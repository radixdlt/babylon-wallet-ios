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
					// FIXME: Temporary UI shows only the navigation title
					//                                                Text(L10n.Signing.WithDeviceFactorSource.signTransaction)
					//
					//                                                if let currentSigningFactor = viewStore.currentSigningFactor {
					//                                                        Text(L10n.Signing.WithDeviceFactorSource.idLabel(currentSigningFactor.factorSource.id.hex()))
					//                                                }
				}
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
			}
			.navigationTitle(L10n.Signing.SignatureRequest.title)
		}
	}
}
