import ComposableArchitecture
import SwiftUI

extension TransactionFilters.State {
	var viewState: TransactionFilters.ViewState {
		.init(
			transferTypes: transferTypes,
			fungibles: fungibles,
			nonFungibles: nonFungibles,
			transactionTypes: transactionTypes
		)
	}

	private var transferTypes: [TransactionFilters.ViewState.Filter] {
		filters.transferTypes.map {
			let type: FilterType = .transferType($0)
			return .init(id: type, caption: "", isActive: isActive(type))
		}
	}

	private var fungibles: [TransactionFilters.ViewState.Filter] {
		filters.fungibles.map {
			let type: FilterType = .asset($0.resourceAddress)
			return .init(id: type, caption: "", isActive: isActive(type))
		}
	}

	private var nonFungibles: [TransactionFilters.ViewState.Filter] {
		filters.nonFungibles.map {
			let type: FilterType = .asset($0.resourceAddress)
			return .init(id: type, caption: "", isActive: isActive(type))
		}
	}

	private var transactionTypes: [TransactionFilters.ViewState.Filter] {
		filters.transactionTypes.map {
			let type: FilterType = .transactionType($0)
			return .init(id: type, caption: "", isActive: isActive(type))
		}
	}
}

// MARK: - TransactionHistoryFilters.View
extension TransactionFilters {
	public struct ViewState: Equatable, Sendable {
		let transferTypes: [Filter]
		let fungibles: [Filter]
		let nonFungibles: [Filter]
		let transactionTypes: [Filter]

		public struct Filter: Equatable, Sendable, Identifiable {
			public let id: State.FilterType
//			let icon: ImageAsset?
			let caption: String
			let isActive: Bool
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionFilters>

		public init(store: StoreOf<TransactionFilters>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			VStack {
				FilterCapsule(category: "XRD", active: true) {
					print("Tap XRD")
				}

				FilterCapsule(category: "WIP", active: false) {
					print("Tap WIP")
				}
			}
		}

		struct FilterCapsule: SwiftUI.View {
			let category: String
			let active: Bool
			let action: () -> Void

			var body: some SwiftUI.View {
				if active {
					core
				} else {
					Button(action: action) {
						core
					}
					.contentShape(Capsule())
				}
			}

			private var core: some SwiftUI.View {
				HStack(spacing: .small2) {
					Text(category)
						.textStyle(.body1HighImportance)
						.foregroundStyle(active ? .app.white : .app.gray1)

					if active {
						Button(asset: AssetResource.close, action: action)
							.tint(.app.gray3)
					}
				}
				.padding(.horizontal, .medium3)
				.padding(.trailing, active ? -.small3 : 0) // Adjust for spacing inside "X"
				.padding(.vertical, .small2)
				.background(background)
			}

			@ViewBuilder
			private var background: some SwiftUI.View {
				if active {
					Capsule().fill(.app.gray1)
				} else {
					Capsule().stroke(.app.gray3)
				}
			}
		}
	}
}
