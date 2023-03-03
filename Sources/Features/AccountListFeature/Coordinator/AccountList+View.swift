import FeaturePrelude

// MARK: - AccountList.View
extension AccountList {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountList>

		public init(store: StoreOf<AccountList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			LazyVStack(spacing: .medium1) {
				ForEachStore(
					store.scope(
						state: \.accounts,
						action: { .child(.account(id: $0, action: $1)) }
					),
					content: { AccountList.Row.View(store: $0) }
				)
			}
			.onAppear {
				ViewStore(store.stateless).send(.view(.appeared))
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AccountList_Preview: PreviewProvider {
	static var previews: some View {
		AccountList.View(
			store: .init(
				initialState: .previewValue,
				reducer: AccountList()
			)
		)
	}
}

extension AccountList.State {
	static let previewValue: Self = .init(
		accounts: .init(uniqueElements: [.previewValue]))
}

extension Array where Element == AccountList.Row.State {
	public static let previewValue: Self = []
}

extension IdentifiedArray where Element == AccountList.Row.State, ID == AccountList.Row.State.ID {
	public static let previewValue: Self = .init(uniqueElements: Array<AccountList.Row.State>.previewValue)
}
#endif
