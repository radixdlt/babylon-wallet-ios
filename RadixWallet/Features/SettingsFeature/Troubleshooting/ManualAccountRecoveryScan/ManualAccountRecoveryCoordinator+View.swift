import ComposableArchitecture
import SwiftUI

extension ManualAccountRecoveryCoordinator.State {
	var viewState: ManualAccountRecoveryCoordinator.ViewState {
		.init(olympiaControlState: isMainnet ? .enabled : .disabled)
	}
}

// MARK: - ManualAccountRecoveryCoordinator.View
extension ManualAccountRecoveryCoordinator {
	struct ViewState: Equatable {
		let olympiaControlState: ControlState
	}

	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable var store: Store

		init(store: Store) {
			self.store = store
		}
	}
}

extension ManualAccountRecoveryCoordinator.View {
	var body: some View {
		WithPerceptionTracking {
			NavigationStack(
				path: $store.scope(state: \.path, action: \.child.path)
			) {
				root()
			} destination: {
				PathView(store: $0)
			}
		}
	}

	private func root() -> some View {
		ScrollView {
			VStack(spacing: .large3) {
				header()
				separator()
				babylonSection()
				separator()
				WithViewStore(store, observe: \.viewState) { viewStore in
					olympiaSection()
						.controlState(viewStore.olympiaControlState)
				}
			}
			.foregroundStyle(.primaryText)
			.padding(.bottom, .small1)
		}
		.background(.primaryBackground)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				CloseButton {
					store.send(.view(.closeButtonTapped))
				}
			}
		}
		.onAppear {
			store.send(.view(.appeared))
		}
	}

	private func header() -> some View {
		VStack(spacing: .zero) {
			Text(L10n.AccountRecoveryScan.title)
				.textStyle(.sheetTitle)
				.multilineTextAlignment(.center)
				.padding(.top, .small1)
				.padding(.horizontal, .large1)
				.padding(.bottom, .medium1)

			Text(L10n.AccountRecoveryScan.subtitle)
				.textStyle(.body1Regular)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .large2)
		}
	}

	private func separator() -> some View {
		Divider()
			.padding(.horizontal, .medium1)
	}

	private func babylonSection() -> some View {
		VStack(spacing: .zero) {
			Text(L10n.AccountRecoveryScan.BabylonSection.title)
				.textStyle(.sectionHeader)
				.padding(.horizontal, .medium1)
				.padding(.bottom, .medium2)

			Text(LocalizedStringKey(L10n.AccountRecoveryScan.BabylonSection.subtitle))
				.multilineTextAlignment(.center)
				.textStyle(.body1Regular)
				.padding(.horizontal, .large2)
				.padding(.bottom, .large3)

			Button("Recover Babylon Accounts") {
				store.send(.view(.recoverBabylonAccountsTapped))
			}
			.padding(.horizontal, .medium3)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
	}

	private func olympiaSection() -> some View {
		VStack(spacing: .zero) {
			Text(L10n.AccountRecoveryScan.OlympiaSection.title)
				.textStyle(.sectionHeader)
				.padding(.bottom, .medium2)

			Text(LocalizedStringKey(L10n.AccountRecoveryScan.OlympiaSection.subtitle))
				.multilineTextAlignment(.center)
				.textStyle(.body1Regular)
				.padding(.horizontal, .large2)
				.padding(.bottom, .large3)

			Button("Recover Olympia Accounts") {
				store.send(.view(.recoverOlympiaAccountsTapped))
			}
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium1)

			Text(LocalizedStringKey(L10n.AccountRecoveryScan.OlympiaSection.footnote))
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
				case .selectFactorSource:
					if let store = store.scope(state: \.selectFactorSource, action: \.selectFactorSource) {
						SelectFactorSource.View(store: store)
					}

				case .seedPhrase:
					if let store = store.scope(state: \.seedPhrase, action: \.seedPhrase) {
						ManualAccountRecoverySeedPhrase.View(store: store)
					}

				case .ledger:
					if let store = store.scope(state: \.ledger, action: \.ledger) {
						LedgerHardwareDevices.View(store: store)
					}

				case .accountRecoveryScan:
					if let store = store.scope(state: \.accountRecoveryScan, action: \.accountRecoveryScan) {
						AccountRecoveryScanCoordinator.View(store: store)
					}

				case .recoveryComplete:
					if let store = store.scope(state: \.recoveryComplete, action: \.recoveryComplete) {
						RecoverWalletControlWithBDFSComplete.View(store: store)
					}
				}
			}
		}
	}
}
