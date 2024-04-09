// MARK: - SignWithFactorSource.View
public extension SignWithFactorSource {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SignWithFactorSource>

		public init(store: StoreOf<SignWithFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			FactorSourceAccess.View(store: store.factorSourceAccess)
		}
	}
}

private extension StoreOf<SignWithFactorSource> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
