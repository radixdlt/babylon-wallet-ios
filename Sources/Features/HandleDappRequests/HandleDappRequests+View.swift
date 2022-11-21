import ComposableArchitecture
import DesignSystem
import Foundation
import GrantDappWalletAccessFeature
import SwiftUI
import TransactionSigningFeature

// MARK: - HandleDappRequests.View
public extension HandleDappRequests {
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
		Group {
			IfLetStore(
				store.scope(
					state: \.grantDappWalletAccess,
					action: { .child(.grantDappWalletAccess($0)) }
				),
				then: DappConnectionRequest.View.init(store:)
			)

			IfLetStore(
				store.scope(
					state: \.transactionSigning,
					action: { .child(.transactionSigning($0)) }
				),
				then: TransactionSigning.View.init(store:)
			)

			Color.clear
				.task { @MainActor in
					await ViewStore(store.stateless).send(.view(.task)).finish()
				}
		}
	}
}
