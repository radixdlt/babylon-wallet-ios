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
		private let store: Store

		init(store: Store) {
			self.store = store
		}
	}
}

extension ManualAccountRecoveryCoordinator.View {
	var body: some View {
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
				WithViewStore(store, observe: \.viewState) { viewStore in
					olympiaSection()
						.controlState(viewStore.olympiaControlState)
				}
			}
			.foregroundStyle(.app.gray1)
			.padding(.bottom, .small1)
		}
		.background(.app.white)
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

			Button(L10n.AccountRecoveryScan.seedPhraseButtonTitle) {
				store.send(.view(.useSeedPhraseTapped(isOlympia: false)))
			}
			.padding(.horizontal, .medium3)
			.padding(.bottom, .small1)

			Button(L10n.AccountRecoveryScan.ledgerButtonTitle) {
				store.send(.view(.useLedgerTapped(isOlympia: false)))
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

			Button(L10n.AccountRecoveryScan.seedPhraseButtonTitle) {
				store.send(.view(.useSeedPhraseTapped(isOlympia: true)))
			}
			.padding(.horizontal, .medium3)
			.padding(.bottom, .small1)

			Button(L10n.AccountRecoveryScan.ledgerButtonTitle) {
				store.send(.view(.useLedgerTapped(isOlympia: true)))
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
					CaseLet(
						/ManualAccountRecoveryCoordinator.Path.State.selectFactorSource,
						action: ManualAccountRecoveryCoordinator.Path.Action.selectFactorSource,
						then: { FactorSourcesList.View(store: $0) }
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
