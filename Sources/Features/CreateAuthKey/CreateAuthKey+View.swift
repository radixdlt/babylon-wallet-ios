import DerivePublicKeyFeature
import FeaturePrelude
import TransactionReviewFeature

extension CreateAuthKey.State {
	var viewState: CreateAuthKey.ViewState {
		.init()
	}
}

// MARK: - CreateAuthKey.View
extension CreateAuthKey {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreateAuthKey>

		public init(store: StoreOf<CreateAuthKey>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				ZStack {
					SwitchStore(store.scope(state: \.step)) {
						CaseLet(
							state: /CreateAuthKey.State.Step.getAuthKeyDerivationPath,
							action: { CreateAuthKey.Action.child(.getAuthKeyDerivationPath($0)) },
							then: { GetAuthKeyDerivationPath.View(store: $0) }
						)
						CaseLet(
							state: /CreateAuthKey.State.Step.derivePublicKey,
							action: { CreateAuthKey.Action.child(.derivePublicKey($0)) },
							then: { DerivePublicKey.View(store: $0) }
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
