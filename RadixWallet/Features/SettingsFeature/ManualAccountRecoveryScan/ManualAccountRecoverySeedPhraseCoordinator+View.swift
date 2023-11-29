import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoverySeedPhraseCoordinator.View
extension ManualAccountRecoverySeedPhraseCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension ManualAccountRecoverySeedPhraseCoordinator.View {
	public var body: some View {
		NavigationStackStore(
			store.scope(state: \.path, action: { .child(.path($0)) })
		) {
			rootView
				.toolbar {
					ToolbarItem(placement: .automatic) {
						CloseButton {
							store.send(.view(.closeButtonTapped))
						}
					}
				}
		} destination: {
			PathView(store: $0)
		}
	}
}

// MARK: - ManualAccountRecoverySeedPhraseCoordinator.View.PathView
private extension ManualAccountRecoverySeedPhraseCoordinator.View {
	var rootView: some View {
		ScrollView {
			VStack(spacing: .zero) {
				Text("Choose Seed Phrase") // FIXME: Strings
					.multilineTextAlignment(.center)
					.textStyle(.sheetTitle)
					.foregroundStyle(.app.gray1)
					.padding(.top, .medium3)
					.padding(.horizontal, .large1)
					.padding(.bottom, .large3)

				Text("Choose the Olympia seed phrase to use for derivation") // FIXME: Strings
					.multilineTextAlignment(.center)
					.textStyle(.body1Header)
					.foregroundStyle(.app.gray1)
					.padding(.horizontal, .huge2)
					.padding(.bottom, .huge3)

				Card {
					Text("Seed Phrase")
				}
				.padding(.horizontal, .medium1)
				.padding(.bottom, .large3)

				Button("Add Olympia Seed Phrase") { // FIXME: Strings
					store.send(.view(.addButtonTapped))
				}
				.buttonStyle(.secondaryRectangular)

				Spacer(minLength: 0)
			}
		}
		.footer {
			Button("Continue") { // FIXME: Strings
				store.send(.view(.continueButtonTapped))
			}
			.buttonStyle(.primaryRectangular(shouldExpand: true))
		}
	}

	struct PathView: View {
		let store: StoreOf<ManualAccountRecoverySeedPhraseCoordinator.Path>

		var body: some View {
			SwitchStore(store) { state in
				switch state {
				case .enterSeedPhrase:
					CaseLet(
						/ManualAccountRecoverySeedPhraseCoordinator.Path.State.enterSeedPhrase,
						action: ManualAccountRecoverySeedPhraseCoordinator.Path.Action.enterSeedPhrase,
						then: { ImportMnemonic.View(store: $0) }
					)
				case .recoveryComplete:
					CaseLet(
						/ManualAccountRecoverySeedPhraseCoordinator.Path.State.recoveryComplete,
						action: ManualAccountRecoverySeedPhraseCoordinator.Path.Action.recoveryComplete,
						then: { ManualAccountRecoveryComplete.View(store: $0) }
					)
				}
			}
		}
	}
}

// MARK: - ManualAccountRecoveryComplete.View
extension ManualAccountRecoveryComplete {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension ManualAccountRecoveryComplete.View {
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
	}
}

private let text: String = // FIXME: Strings
	"""
	Accounts discovered in the scan have been added to your wallet.

	You can repeat this process for other seed phrases or Ledger hardware wallet devices.
	"""
