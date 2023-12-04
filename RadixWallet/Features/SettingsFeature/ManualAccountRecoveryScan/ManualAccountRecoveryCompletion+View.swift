import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryCompletion.View
extension ManualAccountRecoveryCompletion {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension ManualAccountRecoveryCompletion.View {
	public var body: some View {
		ScrollView {
			VStack(spacing: .zero) {
				Text("Recovery Complete") // FIXME: Strings
					.multilineTextAlignment(.center)
					.textStyle(.sheetTitle)
					.foregroundStyle(.app.gray1)
					.padding(.top, .medium3)
					.padding(.horizontal, .large1)
					.padding(.bottom, .large3)

				Text(text)
					.multilineTextAlignment(.center)
					.textStyle(.body1Header)
					.foregroundStyle(.app.gray1)
					.padding(.horizontal, .huge2)
					.padding(.bottom, .huge3)

				Spacer(minLength: 0)
			}
		}
		.footer {
			Button("Continue") { // FIXME: Strings
				store.send(.view(.continueButtonTapped))
			}
			.buttonStyle(.primaryRectangular(shouldExpand: true))
		}
		.navigationBarBackButtonHidden()
	}
}

private let text: String = // FIXME: Strings
	"""
	Accounts discovered in the scan have been added to your wallet.

	You can repeat this process for other seed phrases or Ledger hardware wallet devices.
	"""
