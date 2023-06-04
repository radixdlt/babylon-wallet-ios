import FeaturePrelude
import Logging

extension SimpleCreateSecurityStructureFlow.State {
	var viewState: SimpleCreateSecurityStructureFlow.ViewState {
		.init(newPhoneConfirmer: newPhoneConfirmer, lostPhoneHelper: lostPhoneHelper)
	}
}

/// PLACEHOLDER
public typealias SecurityQuestionsFactorSource = OffDeviceMnemonicFactorSource

/// PLACEHOLDER
public typealias TrustedContactFactorSource = LedgerHardwareWalletFactorSource

// MARK: - SimpleCreateSecurityStructureFlow.View
extension SimpleCreateSecurityStructureFlow {
	public struct ViewState: Equatable {
		let newPhoneConfirmer: SecurityQuestionsFactorSource?
		let lostPhoneHelper: TrustedContactFactorSource?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SimpleCreateSecurityStructureFlow>

		public init(store: StoreOf<SimpleCreateSecurityStructureFlow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					SecurityStructureTutorialHeader()

					FactorForRoleView<ConfirmationRoleTag, SecurityQuestionsFactorSource>(
						factorSet: viewStore.newPhoneConfirmer
					) {
						viewStore.send(.selectNewPhoneConfirmer)
					}

					FactorForRoleView<RecoveryRoleTag, TrustedContactFactorSource>(
						factorSet: viewStore.lostPhoneHelper
					) {
						viewStore.send(.selectLostPhoneHelper)
					}

					Spacer(minLength: 0)
				}
				/*
				 WithControlRequirements(
				 viewStore.chooseAccounts.selectedAccounts?.first?.account,
				 or: viewStore.validateAccountAddress,
				 forAction: { result in
				 viewStore.send(.chooseButtonTapped(result))
				 },
				 control: { action in
				 Button(L10n.Common.choose, action: action)
				 .buttonStyle(.primaryRectangular)
				 }
				 )
				 */
				.footer {
//					WithControlRequirements(
//						viewStore.
//					) { action in
//						// FIXME: Strings
//						Button("Confirm Multifactor Settings", action: action)
//							.buttonStyle(.primaryRectangular)
//					}
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SimpleCreateSecurityStructureFlow_Preview
struct SimpleCreateSecurityStructureFlow_Preview: PreviewProvider {
	static var previews: some View {
		SimpleCreateSecurityStructureFlow.View(
			store: .init(
				initialState: .previewValue,
				reducer: SimpleCreateSecurityStructureFlow()
			)
		)
	}
}

extension SimpleCreateSecurityStructureFlow.State {
	public static let previewValue = Self(
		newPhoneConfirmer: nil,
		lostPhoneHelper: nil
	)
}
#endif
