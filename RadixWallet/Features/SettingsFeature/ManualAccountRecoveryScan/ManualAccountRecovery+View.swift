import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecovery.View
extension ManualAccountRecovery {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension ManualAccountRecovery.View {
	public var body: some View {
		NavigationStackStore(
			store.scope(state: \.path) { .child(.path($0)) }
		) {
			root()
		} destination: {
			PathView(store: $0)
		}
	}

	private func root() -> some View {
		ScrollView {
			VStack(spacing: .zero) {
				babylonHeader()
				babylonSection()
				olympiaHeader()
				olympiaSection()
			}
		}
		.background(.app.gray5)
		.toolbar {
			ToolbarItem(placement: .automatic) {
				CloseButton {
					store.send(.view(.closeButtonTapped))
				}
			}
		}
	}

	private func babylonHeader() -> some View {
		VStack(spacing: .zero) {
			Text("Account Recovery Scan") // FIXME: Strings
				.textStyle(.sheetTitle)
				.multilineTextAlignment(.center)
				.foregroundColor(.app.gray1)
				.padding(.top, .small1)
				.padding(.horizontal, .medium1)
				.padding(.bottom, .medium3)

			Text(LocalizedStringKey(text))
				.textStyle(.body1Regular)
				.foregroundStyle(.app.gray2)
				.padding(.bottom, .medium1)

			Text("Babylon Accounts") // FIXME: Strings
				.textStyle(.sectionHeader)
				.foregroundStyle(.app.gray1)
				.padding(.bottom, .medium3)

			Text(LocalizedStringKey("Scan for Accounts originally created on the **Babylon** network:")) // FIXME: Strings
				.textStyle(.body1Regular)
				.foregroundStyle(.app.gray2)
				.flushedLeft
				.padding(.bottom, .medium3)
		}
		.padding(.horizontal, .medium2)
	}

	private func babylonSection() -> some View {
		VStack(spacing: 0) {
			Button("Use Seed Phrase") { // FIXME: Strings - repeated
				store.send(.view(.useSeedPhraseTapped(isOlympia: false)))
			}
			.padding(.bottom, .medium2)

			Button("Use Ledger Hardware Wallet") { // FIXME: Strings - repeated
				store.send(.view(.useLedgerTapped(isOlympia: false)))
			}
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.padding(.top, .medium2)
		.padding(.horizontal, .medium1)
		.padding(.bottom, .large3)
		.background(.app.white)
	}

	private func olympiaHeader() -> some View {
		VStack(spacing: .zero) {
			Text("Olympia Accounts") // FIXME: Strings
				.textStyle(.sectionHeader)
				.foregroundStyle(.app.gray1)
				.padding(.top, .medium1)

			Text(LocalizedStringKey("Scan for Accounts originally created on the **Olympia** network:")) // FIXME: Strings
				.textStyle(.body1Regular)
				.foregroundStyle(.app.gray2)
				.flushedLeft
				.padding(.vertical, .medium3)
		}
		.padding(.horizontal, .medium2)
	}

	private func olympiaSection() -> some View {
		VStack(spacing: 0) {
			Button("Use Seed Phrase") { // FIXME: Strings - repeated
				store.send(.view(.useSeedPhraseTapped(isOlympia: true)))
			}
			.padding(.bottom, .medium2)

			Button("Use Ledger Hardware Wallet") { // FIXME: Strings - repeated
				store.send(.view(.useLedgerTapped(isOlympia: true)))
			}
			.padding(.bottom, .small2)

			Text(LocalizedStringKey("Note: You will still use the new **Radix Babylon** app on your Ledger device.")) // FIXME: Strings
				.textStyle(.body1Regular)
				.foregroundStyle(.app.gray2)
				.flushedLeft
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.padding(.top, .medium2)
		.padding(.horizontal, .medium1)
		.padding(.bottom, .small1)
		.background(.app.white)
	}
}

private let text: String =
	"""
	The Radix Wallet can scan for previously used accounts using a bare seed phrase or Ledger hardware wallet device.
	(If you have Olympia Accounts in the Radix Olympia Desktop Wallet, consider using **Import from a Legacy Wallet** instead.)
	""" // FIXME: Strings

// MARK: - ManualAccountRecovery.View.PathView
private extension ManualAccountRecovery.View {
	struct PathView: View {
		let store: StoreOf<ManualAccountRecovery.Path>

		var body: some View {
			SwitchStore(store) { state in
				switch state {
				case .seedPhrase:
					CaseLet(
						/ManualAccountRecovery.Path.State.seedPhrase,
						action: ManualAccountRecovery.Path.Action.seedPhrase,
						then: { ManualAccountRecoverySeedPhrase.View(store: $0) }
					)
				case .ledger:
					CaseLet(
						/ManualAccountRecovery.Path.State.ledger,
						action: ManualAccountRecovery.Path.Action.ledger,
						then: { LedgerHardwareDevices.View(store: $0) }
					)
				case .accountRecoveryScan:
					CaseLet(
						/ManualAccountRecovery.Path.State.accountRecoveryScan,
						action: ManualAccountRecovery.Path.Action.accountRecoveryScan,
						then: { AccountRecoveryScanCoordinator.View(store: $0) }
					)
				case .recoveryComplete:
					CaseLet(
						/ManualAccountRecovery.Path.State.recoveryComplete,
						action: ManualAccountRecovery.Path.Action.recoveryComplete,
						then: { ManualAccountRecoveryCompletion.View(store: $0) }
					)
				}
			}
		}
	}
}
