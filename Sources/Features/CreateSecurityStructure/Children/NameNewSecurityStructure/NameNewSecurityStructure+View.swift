import FeaturePrelude

extension NameNewSecurityStructure.State {
	var viewState: NameNewSecurityStructure.ViewState {
		.init(name: name)
	}
}

// MARK: - NameNewSecurityStructure.View
extension NameNewSecurityStructure {
	public struct ViewState: Equatable {
		public let name: String
		public var nonEmptyName: NonEmptyString? {
			.init(rawValue: name)
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NameNewSecurityStructure>

		public init(store: StoreOf<NameNewSecurityStructure>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					// FIXME: Strings
					AppTextField(
						primaryHeading: "Label this security config",
						placeholder: "Main",
						text: viewStore.binding(get: \.name, send: { .nameChanged($0) }),
						hint: .info("This label will be displayed in App Settings when you apply Multi-Factor to your acocunts.")
					)
				}
				.padding()
				.navigationTitle("Label config")
				.footer {
					WithControlRequirements(
						viewStore.nonEmptyName,
						forAction: { viewStore.send(.confirmedName($0)) }
					) { action in
						// FIXME: Strings
						Button("Save security config", action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - NameNewSecurityStructure_Preview
// struct NameNewSecurityStructure_Preview: PreviewProvider {
//	static var previews: some View {
//		NameNewSecurityStructure.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: NameNewSecurityStructure()
//			)
//		)
//	}
// }
//
// extension NameNewSecurityStructure.State {
//	public static let previewValue = Self()
// }
// #endif
