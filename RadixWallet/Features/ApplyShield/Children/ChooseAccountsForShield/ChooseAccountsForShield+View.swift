import ComposableArchitecture
import SwiftUI

// MARK: - ChooseAccountsForShield.View
extension ChooseAccountsForShield {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<ChooseAccountsForShield>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						Text(L10n.ShieldWizardApplyShield.ChooseAccounts.title)
							.lineSpacing(0)
							.textStyle(.sheetTitle)

						Text(L10n.ShieldWizardApplyShield.ChooseAccounts.subtitle)
							.textStyle(.body1HighImportance)

						ChooseAccounts.View(store: store.chooseAccounts)
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
					.multilineTextAlignment(.center)
					.foregroundStyle(.primaryText)
				}
				.background(.primaryBackground)
				.footer {
					VStack(spacing: .medium3) {
						WithControlRequirements(
							viewStore.chooseAccounts.selectedAccounts,
							forAction: { viewStore.send(.view(.continueButtonTapped($0))) }
						) { action in
							Button(L10n.DAppRequest.ChooseAccounts.continue, action: action)
								.buttonStyle(.primaryRectangular)
						}

						Button("Choose Persona") {
							viewStore.send(.view(.skipButtonTapped))
						}
						.buttonStyle(.primaryText())
					}
				}
			}
		}
	}
}

private extension StoreOf<ChooseAccountsForShield> {
	var chooseAccounts: StoreOf<ChooseAccounts> {
		scope(state: \.chooseAccounts, action: \.child.chooseAccounts)
	}
}
