// MARK: - SignWithFactorSource.View
public extension SignWithFactorSource {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SignWithFactorSource>

		public init(store: StoreOf<SignWithFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			// We need to create two different views so that each of them triggers the corresponding `.onFirstTask()` that
			// starts the factor source access. Otherwise, when having multiple signatures chained, it would only trigger the first one.
			switch store.kind {
			case .device:
				FactorSourceAccess.View(store: store.factorSourceAccess)
			case .ledger:
				FactorSourceAccess.View(store: store.factorSourceAccess)
			}
		}
	}
}

private extension StoreOf<SignWithFactorSource> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
