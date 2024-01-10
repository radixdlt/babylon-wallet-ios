import ComposableArchitecture
import SwiftUI

extension TransactionReview {
	public struct ContributingToPoolsState: Sendable, Hashable {
		public var pools: IdentifiedArrayOf<Pool>
	}

	public struct Pool: Sendable, Identifiable, Hashable {
//			public var id: AccountAddress.ID { account.address.id }
//			public let account: Profile.Network.Account
		public var id: String { name }
		public let name: String
	}
}

// MARK: - TransactionReview.View.ContributingToPoolsView
extension TransactionReview.View {
	public struct ContributingToPoolsView: View {
		public var viewState: TransactionReview.ContributingToPoolsState

		public var body: some View {
			Card {
				VStack(spacing: .small1) {
					ForEach(viewState.pools) { pool in
						PoolView(pool: pool)
					}
				}
				.padding(.small1)
			}
		}

		struct PoolView: View {
			let pool: TransactionReview.Pool

			var body: some View {
				Card {
					PlainListRow(.asset(AssetResource.xrd), title: pool.name)
				}
				.cardShadow
			}
		}
	}
}
