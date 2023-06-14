import FeaturePrelude

extension ManageSecurityStructureStart.State {
	var viewState: ManageSecurityStructureStart.ViewState {
		.init()
	}
}

// MARK: - ManageSecurityStructureStart.View
extension ManageSecurityStructureStart {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageSecurityStructureStart>

		public init(store: StoreOf<ManageSecurityStructureStart>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					VStack {
						Image(asset: AssetResource.placeholderSecurityStructure)

						Spacer(minLength: 0)

						Text("Security Setup for Accounts") // FIXME: strings
							.fixedSize(horizontal: false, vertical: true)
							.lineLimit(2)
							.font(.app.sheetTitle)

						Spacer(minLength: 0)

						Text("Let's make sure you can always access your accounts - even if you lose your phone or buy a new one.") // FIXME: strings
							.font(.app.body1Regular)

						Button("Set up account Security") { // FIXME: strings
							viewStore.send(.simpleFlow)
						}
						.buttonStyle(.primaryRectangular)
					}
					.padding(.medium1)

					footerView(viewStore)
				}
			}
		}

		private func footerView(_ viewStore: ViewStoreOf<ManageSecurityStructureStart>) -> some SwiftUI.View {
			VStack(spacing: .medium1) {
				Text("Used Metamask or other crypto wallets? You may prefer:")
					.font(.app.body1Header)
					.padding()
				Button("Advanced Security Setup") {
					viewStore.send(.advancedFlow)
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
			}
			.padding(.medium1)
			.background(Color.app.gray3)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ManageSecurityStructureStart_Preview
struct ManageSecurityStructureStart_Preview: PreviewProvider {
	static var previews: some View {
		ManageSecurityStructureStart.View(
			store: .init(
				initialState: .previewValue,
				reducer: ManageSecurityStructureStart()
			)
		)
	}
}

extension ManageSecurityStructureStart.State {
	public static let previewValue = Self()
}
#endif
