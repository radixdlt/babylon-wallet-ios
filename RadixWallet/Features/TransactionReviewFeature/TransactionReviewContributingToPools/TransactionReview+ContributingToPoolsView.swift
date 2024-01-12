import ComposableArchitecture
import SwiftUI

extension TransactionReview {
	public struct ContributingToPoolsState: Sendable, Hashable {
		public var pools: IdentifiedArrayOf<Pool>
	}

	public struct Pool: Sendable, Identifiable, Hashable {
		public var id: String { name }
		public let name: String
		public let image: URL? = nil
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
					HStack(spacing: .medium3) {
						AssetIcon(.asset(AssetResource.xrd), verySmall: false)

						Text(pool.name)
							.textStyle(.body1Header)
							.foregroundColor(.app.gray1)
					}
				}
//				.cardShadow
			}
		}
	}
}
