import FeaturePrelude

// MARK: - ChooseAccount.View
extension ChooseAccount {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ChooseAccount>

		public init(store: StoreOf<ChooseAccount>) {
			self.store = store
		}
	}
}

extension ChooseAccount.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { _ in
			Text("CHOOSE ACCOUNT: TODO IMPLEMENT").textStyle(.sheetTitle)
		}
	}
}
