import FeaturePrelude

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		// FIXME: Rewire
		.init(
			displayName: "temp",
			thumbnail: .xrd,
			amount: "2312.213223",
			symbol: "SYM"
		)
	}
}

// MARK: - PoolUnitDetails.View
extension PoolUnitDetails {
	public struct ViewState: Equatable {
		let displayName: String
		let thumbnail: TokenThumbnail.Content
		let amount: String
		let symbol: String?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitDetails>

		public init(store: StoreOf<PoolUnitDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: PoolUnitDetails.Action.view
			) { viewStore in
				NavigationStack {
					ScrollView {
						header(with: viewStore)
					}
					#if os(iOS)
					.navigationBarTitle(viewStore.displayName)
					.navigationBarTitleColor(.app.gray1)
					.navigationBarTitleDisplayMode(.inline)
					.navigationBarInlineTitleFont(.app.secondaryHeader)
					.toolbar {
						ToolbarItem(placement: .primaryAction) {
							CloseButton {
								viewStore.send(.closeButtonTapped)
							}
						}
					}
					#endif
				}
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
			}
		}

		@ViewBuilder
		private func header(with viewStore: ViewStoreOf<PoolUnitDetails>) -> some SwiftUI.View {
			VStack(spacing: .medium3) {
				TokenThumbnail(viewStore.thumbnail, size: .veryLarge)
				if let symbol = viewStore.symbol {
					Text(viewStore.amount)
						.font(.app.sheetTitle)
						.kerning(-0.5)
						+ Text(" " + symbol)
						.font(.app.sectionHeader)
				}
			}
			.padding(.top, .small2)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - PoolUnitDetails_Preview
struct PoolUnitDetails_Preview: PreviewProvider {
	static var previews: some View {
		PoolUnitDetails.View(
			store: .init(
				initialState: .previewValue,
				reducer: PoolUnitDetails()
			)
		)
	}
}

extension PoolUnitDetails.State {
	public static let previewValue = Self()
}
#endif
