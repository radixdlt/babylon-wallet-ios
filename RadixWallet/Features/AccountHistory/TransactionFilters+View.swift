import ComposableArchitecture
import SwiftUI

// extension TransactionFilters.State {
//	var viewState: TransactionFilters.ViewState {
//		typealias FilterViewState = TransactionFilters.ViewState.Filter
//		var transferTypeFilters: [FilterViewState] = []
//		var fungibleAssetFilters: [FilterViewState] = []
//		var nonFungibleAssetFilters: [FilterViewState] = []
//		var transactionTypeFilters: [FilterViewState] = []
//
//		for filter in filters {
//			switch filter {
//			case .transferType(let transferType):
//				transferTypeFilters.append(filter)
//			case .asset(let resource):
//				<#code#>
//			case .transactionType(let transactionType):
//				<#code#>
//			}
//		}
//	}
// }

// MARK: - TransactionHistoryFilters.View
extension TransactionFilters {
	public struct ViewState: Equatable, Sendable {
		let sections: [FilterSection]

		public struct FilterSection: Equatable, Sendable {
			let title: String
			let filters: [Filter]
		}

		public struct Filter: Equatable, Sendable, Identifiable {
			public var id: TransactionFilters.State.Filter { filter }
			let filter: TransactionFilters.State.Filter
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
