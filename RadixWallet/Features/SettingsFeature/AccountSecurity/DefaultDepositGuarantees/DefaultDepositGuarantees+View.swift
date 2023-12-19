import ComposableArchitecture
import SwiftUI

// MARK: - DefaultDepositGuarantees.View
extension DefaultDepositGuarantees {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		@FocusState
		private var focused: Bool

		public init(store: Store) {
			self.store = store
		}
	}
}

extension DefaultDepositGuarantees.View {
	public var body: some View {
		VStack(spacing: .medium1) {
			Text(L10n.AccountSecuritySettings.DepositGuarantees.text)
				.textStyle(.body1HighImportance)
				.foregroundColor(.app.gray2)
				.allowsHitTesting(false)

			Card {
				let stepperStore = store.scope(state: \.percentageStepper) { .child(.percentageStepper($0)) }
				MinimumPercentageStepper.View(store: stepperStore, vertical: true)
					.focused($focused)
					.padding(.medium3)
			}

			Spacer(minLength: 0)
		}
		.padding(.medium3)
		.background {
			Color.app.gray5
				.onTapGesture {
					focused = false
				}
		}
		.navigationTitle(L10n.AccountSecuritySettings.DepositGuarantees.title)
	}
}
