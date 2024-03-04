import ComposableArchitecture
import SwiftUI

// MARK: - TransactionHistoryFilters.View
extension TransactionFilters {
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
