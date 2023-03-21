import FeaturePrelude

extension GatewayRow.State {
	var viewState: GatewayRow.ViewState {
		let name = gateway.isDefault ?
			L10n.GatewaySettings.radixBetanetGateway :
			gateway.url.absoluteString

		return .init(
			name: name,
			description: gateway.network.displayDescription,
			isSelected: isSelected,
			canBeDeleted: canBeDeleted
		)
	}
}

// MARK: - GatewayRow.View
extension GatewayRow {
	public struct ViewState: Equatable {
		let name: String
		let description: String
		let isSelected: Bool
		let canBeDeleted: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<GatewayRow>

		public init(store: StoreOf<GatewayRow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Button(
					action: {
						viewStore.send(.didSelect)
					}, label: {
						HStack {
							Image(asset: AssetResource.checkmarkBig)
								.padding(.medium3)
								.opacity(viewStore.isSelected ? 1 : 0)

							VStack(alignment: .leading) {
								Text(viewStore.name)
									.foregroundColor(.app.gray1)
									.textStyle(.body1HighImportance)
									.lineLimit(1)
									.minimumScaleFactor(0.5)

								Text(viewStore.description)
									.foregroundColor(.app.gray2)
									.textStyle(.body2Regular)
							}

							Spacer()

							if viewStore.canBeDeleted {
								Button {
									viewStore.send(.removeButtonTapped)
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
import SwiftUI // NB: necessary for previews to appear

// MARK: - GatewayRow_Preview
struct GatewayRow_Preview: PreviewProvider {
	static var previews: some View {
		GatewayRow.View(
			store: .init(
				initialState: .previewValue2,
				reducer: GatewayRow()
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
