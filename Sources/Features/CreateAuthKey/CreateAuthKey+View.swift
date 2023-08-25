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
				SwitchStore(store.scope(state: \.step, action: Action.child)) { state in
					switch state {
					case .getAuthKeyDerivationPath:
						CaseLet(
							state: /CreateAuthKey.State.Step.getAuthKeyDerivationPath,
							action: CreateAuthKey.ChildAction.getAuthKeyDerivationPath,
							then: { GetAuthKeyDerivationPath.View(store: $0) }
						)

					case .derivePublicKeys:
						CaseLet(
							state: /CreateAuthKey.State.Step.derivePublicKeys,
							action: CreateAuthKey.ChildAction.derivePublicKeys,
							then: { DerivePublicKeys.View(store: $0) }
						)

					case .transactionReview:
						CaseLet(
							state: /CreateAuthKey.State.Step.transactionReview,
							action: CreateAuthKey.ChildAction.transactionReview,
							then: { store in
								// FIXME: CreateAuthKey should use DappInteractionClient to schedule a transaction!!!
								NavigationView {
									TransactionReview.View(store: store)
								}
							}
						)
					}
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
