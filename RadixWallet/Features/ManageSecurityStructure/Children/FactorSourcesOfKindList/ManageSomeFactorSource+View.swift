import ComposableArchitecture
import SwiftUI

// MARK: - ManageSomeFactorSource.View
extension ManageSomeFactorSource {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageSomeFactorSource>

		public init(store: StoreOf<ManageSomeFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .manageSecurityQuestions:
					CaseLet(
						/ManageSomeFactorSource.State.manageSecurityQuestions,
						action: { ManageSomeFactorSource.Action.child(.manageSecurityQuestions($0)) },
						then: { AnswerSecurityQuestionsCoordinator.View(store: $0) }
					)
				case .manageTrustedContact:
					CaseLet(
						/ManageSomeFactorSource.State.manageTrustedContact,
						action: { ManageSomeFactorSource.Action.child(.manageTrustedContact($0)) },
						then: { ManageTrustedContactFactorSource.View(store: $0) }
					)
				case .manageOffDeviceMnemonics:
					CaseLet(
						/ManageSomeFactorSource.State.manageOffDeviceMnemonics,
						action: { ManageSomeFactorSource.Action.child(.manageOffDeviceMnemonics($0)) },
						then: { ImportMnemonic.View(store: $0) }
					)
				}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI
import ComposableArchitecture //

//// MARK: - ManageSomeFactorSource_Preview
// struct ManageSomeFactorSource_Preview: PreviewProvider {
//	static var previews: some View {
//		ManageSomeFactorSource.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: ManageSomeFactorSource.init
//			)
//		)
//	}
// }
//
// extension ManageSomeFactorSource.State {
//	public static let previewValue = Self()
// }
// #endif
