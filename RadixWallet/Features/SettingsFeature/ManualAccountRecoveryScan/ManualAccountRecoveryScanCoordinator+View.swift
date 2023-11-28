import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryScanCoordinator.View
extension ManualAccountRecoveryScanCoordinator {
//	public struct ViewState: Equatable {
//		public let canImportOlympiaWallet: Bool
//
//		init(state: AccountSecurity.State) {
//			self.canImportOlympiaWallet = state.canImportOlympiaWallet
//		}
//	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension ManualAccountRecoveryScanCoordinator.View {
	public var body: some View {
		NavigationStackStore(
			store.scope(state: \.path, action: { .child(.path($0)) })
		) {
			root()
				.navigationTitle("Derive Legacy Account") // FIXME: Strings

			//			.toolbar {
			//				ToolbarItem(placement: .cancellationAction) {
			//					CloseButton {
			//						self.store.send(.view(.closeTapped))
			//					}
			//				}
			//			}
		} destination: {
			PathView(store: $0)
		}
	}
}

private extension ManualAccountRecoveryScanCoordinator.View {
	struct PathView: View {
		let store: StoreOf<ManualAccountRecoveryScanCoordinator.Path>

		var body: some View {
			SwitchStore(store) { state in
				switch state {
				case .selectInactiveAccountsToAdd:
					CaseLet(
						/AccountRecoveryScanCoordinator.Path.State.selectInactiveAccountsToAdd,
						action: AccountRecoveryScanCoordinator.Path.Action.selectInactiveAccountsToAdd,
						then: { SelectInactiveAccountsToAdd.View(store: $0) }
					)
				}
			}
		}
	}

	func root() -> some View {
		ScrollView {
			VStack(spacing: .zero) {
				babylonHeader()
					.padding(.bottom, .medium2)
				babylonSection()
					.padding(.bottom, .large3)
				olympiaHeader()
					.padding(.bottom, .medium2)
				olympiaSection()
					.padding(.bottom, .small2)
				footer()
			}
		}
	}

	private func babylonHeader() -> some View {
		VStack(spacing: .zero) {
			Text(LocalizedStringKey(text))
				.textStyle(.body1Regular)
				.foregroundStyle(.app.gray2)
				.padding(.top, .medium3)

			Text("Babylon Accounts")
				.textStyle(.sectionHeader)
				.foregroundStyle(.app.gray1)
				.padding(.top, .medium1)

			Text(LocalizedStringKey("Scan for Accounts originally created on the **Babylon** network:")) // FIXME: Strings
				.textStyle(.body1Regular)
				.foregroundStyle(.app.gray2)
				.flushedLeft
				.padding(.vertical, .medium3)
		}
		.padding(.horizontal, .medium2)
		.background(.app.gray5)
	}

	private func babylonSection() -> some View {
		VStack(spacing: .medium2) {
			Button("Use Seed Phrase") { // FIXME: Strings - repeated
				store.send(.view(.babylonUseSeedPhraseTapped))
			}

			Button("Use Ledger Hardware Wallet") { // FIXME: Strings - repeated
				store.send(.view(.babylonUseLedgerTapped))
			}
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.padding(.horizontal, .medium1)
	}

	private func olympiaHeader() -> some View {
		VStack(spacing: .zero) {
			Text("Olympia Accounts")
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
		.background(.app.gray5)
	}

	private func olympiaSection() -> some View {
		VStack(spacing: .medium2) {
			Button("Use Seed Phrase") { // FIXME: Strings - repeated
				store.send(.view(.olympiaUseSeedPhraseTapped))
			}

			Button("Use Ledger Hardware Wallet") { // FIXME: Strings - repeated
				store.send(.view(.olympiaUseLedgerTapped))
			}
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.padding(.horizontal, .medium1)
	}

	private func footer() -> some View {
		Text(LocalizedStringKey("Note: You will still use the new **Radix Babylon** app on your Ledger device.")) // FIXME: Strings
			.textStyle(.body1Regular)
			.foregroundStyle(.app.gray2)
			.padding(.horizontal, .medium2)
	}
}

private let text: String =
	"""
	The Radix Wallet can scan for previously used accounts using a bare seed phrase or Ledger hardware wallet device.
	(If you have Olympia Accounts in the Radix Olympia Desktop Wallet, consider using **Import from a Legacy Wallet** instead.)
	""" // FIXME: Strings
