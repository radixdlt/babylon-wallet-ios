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
						HStack(spacing: .zero) {
							Image(asset: AssetResource.check)
								.padding(.medium3)
								.opacity(store.isSelected ? 1 : 0)

							VStack(alignment: .leading) {
								Text(store.name)
									.foregroundColor(.app.gray1)
									.textStyle(.body1HighImportance)
									.lineLimit(1)
									.minimumScaleFactor(0.5)

								Text(store.description)
									.foregroundColor(.app.gray2)
									.textStyle(.body2Regular)
							}

							Spacer()

							if store.canBeDeleted {
								Button {
									store.send(.view(.removeButtonTapped))
								} label: {
									Image(asset: AssetResource.trash)
										.padding(.medium3)
								}
							}
						}
						.contentShape(Rectangle())
						.padding(.vertical, .small2)
					}
				)
			}
		}
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
