import DesignSystem
import FeaturePrelude
import Profile

extension CreateSecurityStructureCoordinator.State {
	var viewState: CreateSecurityStructureCoordinator.ViewState {
		.init()
	}
}

// MARK: - CreateSecurityStructureCoordinator.View
extension CreateSecurityStructureCoordinator {
	public struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreateSecurityStructureCoordinator>

		public init(store: StoreOf<CreateSecurityStructureCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					VStack {
						Image(asset: AssetResource.placeholderSecurityStructure)

						Spacer(minLength: 0)

						Text("Security Setup for Accounts") // FIXME: strings
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

		private func footerView(_ viewStore: ViewStoreOf<CreateSecurityStructureCoordinator>) -> some SwiftUI.View {
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

// MARK: - CreateSecurityStructure_Preview
struct CreateSecurityStructure_Preview: PreviewProvider {
	static var previews: some View {
		CreateSecurityStructureCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: CreateSecurityStructureCoordinator()
			)
		)
	}
}

extension CreateSecurityStructureCoordinator.State {
	public static let previewValue = Self()
}
#endif
