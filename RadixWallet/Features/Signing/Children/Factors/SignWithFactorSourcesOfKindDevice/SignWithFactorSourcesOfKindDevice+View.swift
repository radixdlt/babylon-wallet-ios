import ComposableArchitecture
import SwiftUI

// MARK: - SignWithFactorSourcesOfKindDevice.View
extension SignWithFactorSourcesOfKindDevice {
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
