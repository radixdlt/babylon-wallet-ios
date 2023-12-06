import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryCoordinator.View
extension ManualAccountRecoveryCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension ManualAccountRecoveryCoordinator.View {
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
			VStack(spacing: .large3) {
				header()
				separator()
				babylonSection()
				separator()
				olympiaSection()
			}
			.foregroundStyle(.app.gray1)
			.padding(.bottom, .small1)
		}
		.background(.app.white)
		.toolbar {
			ToolbarItem(placement: .automatic) {
				CloseButton {
					store.send(.view(.closeButtonTapped))
				}
			}
		}
	}

	private func header() -> some View {
		VStack(spacing: .zero) {
			Text("Account Recovery Scan") // FIXME: Strings
				.textStyle(.sheetTitle)
				.multilineTextAlignment(.center)
				.padding(.top, .small1)
				.padding(.horizontal, .large1)
				.padding(.bottom, .medium1)

			Text("The Radix Wallet can scan for previously used accounts using a bare seed phrase or Ledger hardware wallet device.") // FIXME: Strings
				.textStyle(.body1Regular)
				.padding(.horizontal, .large2)
		}
	}

	private func separator() -> some View {
		Divider()
			.padding(.horizontal, .medium1)
	}

	private func babylonSection() -> some View {
		VStack(spacing: .zero) {
			Text("Babylon Accounts") // FIXME: Strings
				.textStyle(.sectionHeader)
				.padding(.horizontal, .medium1)
				.padding(.bottom, .medium2)

			Text(LocalizedStringKey("Scan for Accounts originally created on the **Babylon** network.")) // FIXME: Strings
				.multilineTextAlignment(.center)
				.textStyle(.body1Regular)
				.padding(.horizontal, .large2)
				.padding(.bottom, .large3)

			Button("Use Seed Phrase") { // FIXME: Strings - repeated
				store.send(.view(.useSeedPhraseTapped(isOlympia: false)))
			}
			.padding(.horizontal, .medium3)
			.padding(.bottom, .small1)

			Button("Use Ledger Hardware Wallet") { // FIXME: Strings - repeated
				store.send(.view(.useLedgerTapped(isOlympia: false)))
			}
			.padding(.horizontal, .medium3)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
	}

	private func olympiaSection() -> some View {
		VStack(spacing: .zero) {
			Text("Olympia Accounts") // FIXME: Strings
				.textStyle(.sectionHeader)
				.padding(.bottom, .medium2)

			Text(LocalizedStringKey("Scan for Accounts originally created on the **Olympia** network.\n\n(If you have Olympia Accounts in the Radix Olympia Desktop Wallet, consider using **Import from a Legacy Wallet** instead.)")) // FIXME: Strings
				.multilineTextAlignment(.center)
				.textStyle(.body1Regular)
				.padding(.horizontal, .large2)
				.padding(.bottom, .large3)

			Button("Use Seed Phrase") { // FIXME: Strings - repeated
				store.send(.view(.useSeedPhraseTapped(isOlympia: true)))
			}
			.padding(.horizontal, .medium3)
			.padding(.bottom, .small1)

			Button("Use Ledger Hardware Wallet") { // FIXME: Strings - repeated
				store.send(.view(.useLedgerTapped(isOlympia: true)))
			}
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium1)

			Text(LocalizedStringKey("Note: You will still use the new **Radix Babylon** app on your Ledger device, not the old Radix Ledger app.")) // FIXME: Strings
				.textStyle(.body1Regular)
				.flushedLeft
				.padding(.horizontal, .large2)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
	}
}

// MARK: - ManualAccountRecoveryCoordinator.View.PathView
private extension ManualAccountRecoveryCoordinator.View {
	struct PathView: View {
		let store: StoreOf<ManualAccountRecoveryCoordinator.Path>

		var body: some View {
			SwitchStore(store) { state in
				switch state {
				case .seedPhrase:
					CaseLet(
						/ManualAccountRecoveryCoordinator.Path.State.seedPhrase,
						action: ManualAccountRecoveryCoordinator.Path.Action.seedPhrase,
						then: { ManualAccountRecoverySeedPhrase.View(store: $0) }
					)
				case .ledger:
					CaseLet(
						/ManualAccountRecoveryCoordinator.Path.State.ledger,
						action: ManualAccountRecoveryCoordinator.Path.Action.ledger,
						then: { LedgerHardwareDevices.View(store: $0) }
					)
				case .accountRecoveryScan:
					CaseLet(
						/ManualAccountRecoveryCoordinator.Path.State.accountRecoveryScan,
						action: ManualAccountRecoveryCoordinator.Path.Action.accountRecoveryScan,
						then: { AccountRecoveryScanCoordinator.View(store: $0) }
					)
				case .recoveryComplete:
					CaseLet(
						/ManualAccountRecoveryCoordinator.Path.State.recoveryComplete,
						action: ManualAccountRecoveryCoordinator.Path.Action.recoveryComplete,
						then: { RecoverWalletControlWithBDFSComplete.View(store: $0) }
					)
				}
			}
		}
	}
}
