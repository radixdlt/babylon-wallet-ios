// MARK: - SignWithFactorSource.View
public extension SignWithFactorSource {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SignWithFactorSource>

		public init(store: StoreOf<SignWithFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			/// We set the `.id` to the `kind` so that, when multiple factor sources are required, each of them has its own view created.
			/// Otherwise, only the first of them would have the `.onFirstTask()` triggered, and the logic for the remaining ones
			/// wouldn't be performed.
			FactorSourceAccess.View(store: store.factorSourceAccess)
				.id(store.kind)
		}
	}
}

private extension StoreOf<SignWithFactorSource> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
