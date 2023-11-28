import ComposableArchitecture
import SwiftUI

extension ManualAccountRecoverySeedPhraseCoordinator.State {
	var viewState: ManualAccountRecoverySeedPhraseCoordinator.ViewState {
		.init(isOlympia: isOlympia, selected: selected, deviceFactorSources: deviceFactorSources)
	}
}

// MARK: - ManualAccountRecoverySeedPhraseCoordinator.View
extension ManualAccountRecoverySeedPhraseCoordinator {
	public struct ViewState: Equatable {
		public let isOlympia: Bool
		public let selected: EntitiesControlledByFactorSource?
		public let deviceFactorSources: IdentifiedArrayOf<EntitiesControlledByFactorSource>
	}

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
			rootView()
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
	func rootView() -> some View {
		ScrollView {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					Text("Choose Seed Phrase") // FIXME: Strings
						.multilineTextAlignment(.center)
						.textStyle(.sheetTitle)
						.foregroundStyle(.app.gray1)
						.padding(.top, .medium3)
						.padding(.horizontal, .large2)
						.padding(.bottom, .large3)

					Text(subtitle(isOlympia: viewStore.isOlympia))
						.multilineTextAlignment(.center)
						.textStyle(.body1Header)
						.foregroundStyle(.app.gray1)
						.padding(.horizontal, .huge2)
						.padding(.bottom, .huge3)

					mnemonics(viewStore: viewStore)
						.padding(.bottom, .large3)

					Button(buttonText(isOlympia: viewStore.isOlympia)) {
						store.send(.view(.addButtonTapped))
					}
					.buttonStyle(.secondaryRectangular)

					Spacer(minLength: 0)
				}
			}
		}
		.footer {
			WithViewStore(store, observe: \.selected) { viewStore in
				WithControlRequirements(viewStore.state) { selection in
					store.send(.view(.continueButtonTapped(selection)))
				} control: { action in
					Button("Continue", action: action) // FIXME: Strings
						.buttonStyle(.primaryRectangular(shouldExpand: true))
				}
			}
		}
		.onFirstAppear {
			store.send(.view(.appeared))
		}
	}

	private func subtitle(isOlympia: Bool) -> String {
		if isOlympia {
			"Choose the Olympia seed phrase to use for derivation" // FIXME: Strings
		} else {
			"Choose the Babylon seed phrase to use for derivation" // FIXME: Strings
		}
	}

	private func buttonText(isOlympia: Bool) -> String {
		if isOlympia {
			"Add Olympia seed phrase" // FIXME: Strings
		} else {
			"Add Babylon seed phrase" // FIXME: Strings
		}
	}

	private func mnemonics(viewStore: ViewStoreOf<ManualAccountRecoverySeedPhraseCoordinator>) -> some View {
		let binding = viewStore.binding(get: \.selected, send: ManualAccountRecoverySeedPhraseCoordinator.ViewAction.selected)
		return Selection(binding, from: viewStore.deviceFactorSources) { item in
			Card(.app.gray5) {
				viewStore.send(.selected(item.value))
			} contents: {
				DisplayEntitiesControlledByMnemonic.MnemonicView(
					viewState: .init(
						headingState: .defaultHeading(type: .selectable(item.isSelected)),
						promptUserToBackUpMnemonic: false,
						accounts: item.value.accounts,
						hasHiddenAccounts: !item.value.hiddenAccounts.isEmpty
					)
				)
				.padding(.medium3)
			}
			.cardShadow
			.padding(.horizontal, .medium1)
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
				case .accountRecoveryScan:
					CaseLet(
						/ManualAccountRecoverySeedPhraseCoordinator.Path.State.accountRecoveryScan,
						action: ManualAccountRecoverySeedPhraseCoordinator.Path.Action.accountRecoveryScan,
						then: { AccountRecoveryScanCoordinator.View(store: $0) }
					)
				case .recoveryComplete:
					CaseLet(
						/ManualAccountRecoverySeedPhraseCoordinator.Path.State.recoveryComplete,
						action: ManualAccountRecoverySeedPhraseCoordinator.Path.Action.recoveryComplete,
						then: { ManualAccountRecoveryCompletion.View(store: $0) }
					)
				}
			}
		}
	}
}
