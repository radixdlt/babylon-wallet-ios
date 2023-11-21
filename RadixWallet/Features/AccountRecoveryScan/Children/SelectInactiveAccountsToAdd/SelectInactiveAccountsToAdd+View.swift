
// MARK: - SelectInactiveAccountsToAdd.View

public extension SelectInactiveAccountsToAdd {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SelectInactiveAccountsToAdd>

		public init(store: StoreOf<SelectInactiveAccountsToAdd>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
//			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
//				ScrollView {
//					VStack(spacing: .medium3) {
//
//						Text("Found these accounts")
//						.foregroundColor(.app.gray1)
//						.multilineTextAlignment(.center)
//
//					}
//					.padding(.bottom, .medium3)
//				}
//				.footer {
//					Button(viewStore.buttonTitle) {
//						viewStore.send(.continueButtonTapped)
//					}
//					.buttonStyle(.primaryRectangular)
//				}
//				.onAppear {
//					viewStore.send(.appeared)
//				}
//			}
			Text("Select inactive accounts")
		}
	}
}
