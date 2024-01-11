import ComposableArchitecture
import SwiftUI

extension NameSecurityStructure.State {
	var viewState: NameSecurityStructure.ViewState {
		.init(name: metadata.label)
	}
}

// MARK: - NameSecurityStructure.View
extension NameSecurityStructure {
	public struct ViewState: Equatable {
		public let name: String
		public var nonEmptyName: NonEmptyString? {
			.init(rawValue: name)
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NameSecurityStructure>

		public init(store: StoreOf<NameSecurityStructure>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					// FIXME: future strings
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
						// FIXME: future strings
						Button("Save security config", action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI
import ComposableArchitecture //

//// MARK: - NameNewSecurityStructure_Preview
// struct NameNewSecurityStructure_Preview: PreviewProvider {
//	static var previews: some View {
//		NameSecurityStructure.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: NameSecurityStructure.init
//			)
//		)
//	}
// }
//
// extension NameSecurityStructure.State {
//	public static let previewValue = Self()
// }
// #endif
