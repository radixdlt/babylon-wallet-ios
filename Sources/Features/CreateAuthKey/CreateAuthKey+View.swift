import DerivePublicKeysFeature
import FeaturePrelude
import TransactionReviewFeature

// MARK: - CreateAuthKey.View
extension CreateAuthKey {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreateAuthKey>

		public init(store: StoreOf<CreateAuthKey>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ZStack {
				SwitchStore(store.scope(state: \.step)) {
					CaseLet(
						state: /CreateAuthKey.State.Step.getAuthKeyDerivationPath,
						action: { CreateAuthKey.Action.child(.getAuthKeyDerivationPath($0)) },
						then: { GetAuthKeyDerivationPath.View(store: $0) }
					)
					CaseLet(
						state: /CreateAuthKey.State.Step.derivePublicKeys,
						action: { CreateAuthKey.Action.child(.derivePublicKeys($0)) },
						then: { DerivePublicKeys.View(store: $0) }
					)
					CaseLet(
						state: /CreateAuthKey.State.Step.transactionReview,
						action: { CreateAuthKey.Action.child(.transactionReview($0)) },
						then: { TransactionReview.View(store: $0) }
					)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - CreateAuthKey_Preview
struct CreateAuthKey_Preview: PreviewProvider {
	static var previews: some View {
		CreateAuthKey.View(
			store: .init(
				initialState: .previewValue,
				reducer: CreateAuthKey()
			)
		)
	}
}

extension CreateAuthKey.State {
	public static let previewValue = Self(entity: .account(.previewValue0))
}
#endif
