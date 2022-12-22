import ComposableArchitecture
import DesignSystem
import Foundation
import GrantDappWalletAccessFeature
import SwiftUI
import TransactionSigningFeature

// MARK: - HandleDappRequests.View
public extension HandleDappRequests {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = StoreOf<HandleDappRequests>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

public extension HandleDappRequests.View {
	var body: some View {
		ZStack {
			IfLetStore(
				store.scope(
					state: \.chooseAccounts,
					action: { .child(.chooseAccounts($0)) }
				),
				then: ChooseAccounts.View.init(store:)
			)

			IfLetStore(
				store.scope(
					state: \.transactionSigning,
					action: { .child(.transactionSigning($0)) }
				),
				then: TransactionSigning.View.init(store:)
			)
		}
		.task { @MainActor in
			await ViewStore(store.stateless).send(.view(.task)).finish()
		}
	}
}
