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
			FactorSourceAccess.View(store: store.factorSourceAccess)
		}
	}
}

private extension StoreOf<SignWithFactorSourcesOfKindDevice> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
