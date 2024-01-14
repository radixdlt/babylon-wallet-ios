import ComposableArchitecture
import SwiftUI

extension TransactionReview {
	public struct InteractWithPoolsState: Sendable, Hashable {
		public var pools: IdentifiedArrayOf<ResourcePoolItem>
	}

	public enum ResourcePoolItem: Identifiable, Sendable, Hashable {
		case known(ResourcePool)
		case unknown([ResourcePoolAddress])

		public var id: ResourcePoolAddress? {
			switch self {
			case let .known(resourcePool):
				resourcePool.address
			case .unknown:
				nil
			}
		}
	}

	public struct ResourcePool: Sendable, Hashable {
		public let address: ResourcePoolAddress
		public let icon: URL?
		public let name: String?
	}
}

// MARK: - TransactionReview.View.InteractWithPoolsView
extension TransactionReview.View {
	public struct InteractWithPoolsView: View {
		public var viewState: TransactionReview.InteractWithPoolsState

		public var body: some View {
			Card {
				VStack(spacing: .small1) {
					ForEach(viewState.pools) { pool in
						switch pool {
						case let .known(knownPool):
							PoolView(pool: knownPool)
						case let .unknown(pools):
							UnkownPoolsView(count: pools.count)
						}
					}
				}
				.padding(.small1)
			}
		}

		struct PoolView: View {
			let pool: TransactionReview.ResourcePool

			var body: some View {
				Card {
					HStack(spacing: .medium3) {
						DappThumbnail(.known(pool.icon), size: .small)

						let addressView = AddressView(.address(.resourcePool(pool.address)))

						if let name = pool.name {
							VStack(alignment: .leading, spacing: .small3) {
								Text(name)
									.textStyle(.body1Header)
									.foregroundColor(.app.gray1)

								addressView
							}
						} else {
							addressView
						}

						Spacer(minLength: 0)
					}
				}
			}
		}

		struct UnkownPoolsView: View {
			let count: Int

			var body: some View {
				Card {
					HStack(spacing: .medium3) {
						DappThumbnail(.unknown, size: .small)

						Text("\(count) unknown pools")
							.textStyle(.body1Header)
							.foregroundColor(.app.gray1)

						Spacer(minLength: 0)
					}
				}
			}
		}
	}
}
