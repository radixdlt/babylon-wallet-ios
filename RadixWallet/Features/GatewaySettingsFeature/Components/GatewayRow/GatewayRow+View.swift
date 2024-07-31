import ComposableArchitecture
import SwiftUI

extension Gateway {
	var displayName: String {
		if isWellknown {
			switch network.id {
			case .mainnet:
				"Radix Mainnet Gateway"
			case .stokenet:
				"Stokenet (testnet) Gateway"
			default:
				network.displayDescription
			}
		} else {
			url.absoluteString
		}
	}
}

extension GatewayRow.State {
	var rowCoreViewState: PlainListRowCore.ViewState {
		.init(
			title: name,
			detail: description
		)
	}
}

// MARK: - GatewayRow.View
extension GatewayRow {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<GatewayRow>

		public init(store: StoreOf<GatewayRow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				Button(
					action: {
						store.send(.view(.didSelect))
					}, label: {
						PlainListRow(viewState: .init(
							rowCoreViewState: store.rowCoreViewState,
							accessory: { accesoryView },
							icon: { iconView }
						))
					}
				)
			}
		}
	}
}

extension GatewayRow.View {
	@ViewBuilder
	private var accesoryView: some SwiftUI.View {
		if store.canBeDeleted {
			Button(asset: AssetResource.trash) {
				store.send(.view(.removeButtonTapped))
			}
		}
	}

	private var iconView: some SwiftUI.View {
		Image(.check)
			.opacity(store.isSelected ? 1 : 0)
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - GatewayRow_Preview
struct GatewayRow_Preview: PreviewProvider {
	static var previews: some View {
		GatewayRow.View(
			store: .init(
				initialState: .previewValue2,
				reducer: GatewayRow.init
			)
		)
	}
}

extension GatewayRow.State {
	static let previewValue1 = Self(
		gateway: .nebunet,
		isSelected: true,
		canBeDeleted: false
	)

	static let previewValue2 = Self(
		gateway: .hammunet,
		isSelected: false,
		canBeDeleted: true
	)

	static let previewValue3 = Self(
		gateway: .enkinet,
		isSelected: false,
		canBeDeleted: true
	)
}
#endif
