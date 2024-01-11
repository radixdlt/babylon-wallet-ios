import ComposableArchitecture
import SwiftUI

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
			Color.app.background
				.onFirstTask { @MainActor in
					await store.send(.view(.onFirstTask)).finish()
				}
				.navigationTitle(L10n.Signing.SignatureRequest.title)
		}
	}
}
