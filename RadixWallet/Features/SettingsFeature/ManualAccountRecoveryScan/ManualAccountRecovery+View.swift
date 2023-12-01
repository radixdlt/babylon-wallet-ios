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
		.navigationTitle("Derive Legacy Account") // FIXME: Strings
		.destinations(with: store)
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
				store.send(.view(.useSeedPhraseTapped(.babylon)))
			}

			Button("Use Ledger Hardware Wallet") { // FIXME: Strings - repeated
				store.send(.view(.useLedgerTapped(.babylon)))
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
				store.send(.view(.useSeedPhraseTapped(.olympia)))
			}

			Button("Use Ledger Hardware Wallet") { // FIXME: Strings - repeated
				store.send(.view(.useLedgerTapped(.olympia)))
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

private extension StoreOf<ManualAccountRecovery> {
	var destination: PresentationStoreOf<ManualAccountRecovery.Destination> {
		func scopeState(state: State) -> PresentationState<ManualAccountRecovery.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ManualAccountRecovery>) -> some View {
		let destinationStore = store.destination
		return seedPhraseCoordinator(with: destinationStore)
			.ledgerCoordinator(with: destinationStore)
	}

	private func seedPhraseCoordinator(with destinationStore: PresentationStoreOf<ManualAccountRecovery.Destination>) -> some View {
		fullScreenCover(
			store: destinationStore,
			state: /ManualAccountRecovery.Destination.State.seedPhrase,
			action: ManualAccountRecovery.Destination.Action.seedPhrase,
			content: { ManualAccountRecoverySeedPhraseCoordinator.View(store: $0) }
		)
	}

	private func ledgerCoordinator(with destinationStore: PresentationStoreOf<ManualAccountRecovery.Destination>) -> some View {
		fullScreenCover(
			store: destinationStore,
			state: /ManualAccountRecovery.Destination.State.ledger,
			action: ManualAccountRecovery.Destination.Action.ledger,
			content: { ManualAccountRecoveryLedgerCoordinator.View(store: $0) }
		)
	}
}
