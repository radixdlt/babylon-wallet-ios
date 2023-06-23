import FeaturePrelude

extension FactorsForRole.State {
	var viewState: FactorsForRole.ViewState {
		.init(role: role)
	}
}

// MARK: - FactorsForRole.View
extension FactorsForRole {
	public struct ViewState: Equatable {
		let role: FactorsForRole.Role
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FactorsForRole>

		public init(store: StoreOf<FactorsForRole>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .medium2) {
					Text(FactorsForRole.Role.role.titleAdvancedFlow)
						.font(.app.sectionHeader)

					Text(FactorsForRole.Role.role.subtitleAdvancedFlow)
						.font(.app.body2Header)
						.foregroundColor(.app.gray3)

					Button(action: { viewStore.send(.setFactorsButtonTapped) }) {
						HStack {
							// FIXME: Strings
							Text("None set")
								.font(.app.body1Header)
								.foregroundColor(viewStore.role.isEmpty ? .app.gray3 : .app.gray1)

							Spacer(minLength: 0)

							Image(asset: AssetResource.chevronRight)
						}
					}
					.cornerRadius(.medium2)
					.frame(maxWidth: .infinity)
					.padding()
					.background(.app.gray5)
				}
				.padding()
				.frame(maxWidth: .infinity)
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - FactorsForRole_Preview
// struct FactorsForRole_Preview: PreviewProvider {
//	static var previews: some View {
//		FactorsForRole.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: FactorsForRole()
//			)
//		)
//	}
// }
//
// extension FactorsForRole.State {
//	public static let previewValue = Self()
// }
// #endif
