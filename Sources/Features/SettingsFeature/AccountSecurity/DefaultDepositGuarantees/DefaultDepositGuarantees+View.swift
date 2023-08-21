import AuthorizedDAppsFeature
import FeaturePrelude
import LedgerHardwareDevicesFeature
import TransactionReviewFeature

// MARK: - DefaultDepositGuarantees.View
extension DefaultDepositGuarantees {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension DefaultDepositGuarantees.View {
	public var body: some View {
		VStack(spacing: .medium1) {
			Text("Set the guaranteed minimum deposit to be applied whenever a deposit in a transaction can only be estimated.\n\nYou can always change the guarantee from this default in each transaction.") // FIXME: Strings
				.textStyle(.body1HighImportance)
				.foregroundColor(.app.gray2)

			Card {
				let stepperStore = store.scope(state: \.percentageStepper) { .child(.percentageStepper($0)) }
				MinimumPercentageStepper.View(store: stepperStore, vertical: true)
					.padding(.medium3)
			}

			Spacer(minLength: 0)
		}
		.padding(.medium3)
		.background(.app.gray5)
		.navigationTitle("Deposit Guarantees") // FIXME: Strings - title
	}
}
