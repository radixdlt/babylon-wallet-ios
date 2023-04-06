import FeaturePrelude

extension ValidateOlympiaHardwareAccounts.State {
	var viewState: ValidateOlympiaHardwareAccounts.ViewState {
		.init(numberOfAccounts: self.hardwareAccounts.count)
	}
}

// MARK: - ValidateOlympiaHardwareAccounts.View
extension ValidateOlympiaHardwareAccounts {
	public struct ViewState: Equatable {
		public let numberOfAccounts: Int
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ValidateOlympiaHardwareAccounts>

		public init(store: StoreOf<ValidateOlympiaHardwareAccounts>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				VStack {
					Button("MOCK validate #\(viewStore.numberOfAccounts) accounts") {
						viewStore.send(.finishedButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.padding(.horizontal, .medium3)
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

//// MARK: - ValidateOlympiaHardwareAccounts_Preview
// struct ValidateOlympiaHardwareAccounts_Preview: PreviewProvider {
//	static var previews: some View {
//		ValidateOlympiaHardwareAccounts.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: ValidateOlympiaHardwareAccounts()
//			)
//		)
//	}
// }

// extension ValidateOlympiaHardwareAccounts.State {
//    public static let previewValue = Self(
//        hardwareAccounts: .previewValue,
//        ledgerNanoFactorSourceID: .previewValue
//    )
// }
#endif
