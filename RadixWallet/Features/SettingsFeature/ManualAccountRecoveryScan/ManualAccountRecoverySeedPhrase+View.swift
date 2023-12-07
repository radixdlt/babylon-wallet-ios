import ComposableArchitecture
import SwiftUI

extension ManualAccountRecoverySeedPhrase.State {
	var viewState: ManualAccountRecoverySeedPhrase.ViewState {
		.init(
			isOlympia: isOlympia,
			selected: selected,
			deviceFactorSources: deviceFactorSources
		)
	}
}

// MARK: - ManualAccountRecoverySeedPhraseCoordinator.View
extension ManualAccountRecoverySeedPhrase {
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

extension ManualAccountRecoverySeedPhrase.View {
	public var body: some View {
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
		.destinations(with: store)
	}
}

private extension StoreOf<ManualAccountRecoverySeedPhrase> {
	var destination: PresentationStoreOf<ManualAccountRecoverySeedPhrase.Destination> {
		func scopeState(state: State) -> PresentationState<ManualAccountRecoverySeedPhrase.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ManualAccountRecoverySeedPhrase>) -> some View {
		let destinationStore = store.destination
		return sheet(
			store: destinationStore,
			state: /ManualAccountRecoverySeedPhrase.Destination.State.importMnemoninc,
			action: ManualAccountRecoverySeedPhrase.Destination.Action.importMnemoninc,
			content: {
				ImportMnemonic.View(store: $0)
					.withNavigationBar {
						store.send(.view(.closeEnterMnemonicButtonTapped))
					}
			}
		)
	}
}

// MARK: - ManualAccountRecoverySeedPhrase.View.PathView
private extension ManualAccountRecoverySeedPhrase.View {
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

	private func mnemonics(viewStore: ViewStoreOf<ManualAccountRecoverySeedPhrase>) -> some View {
		let binding = viewStore.binding(
			get: \.selected,
			send: ManualAccountRecoverySeedPhrase.ViewAction.selected
		)

		return Selection(binding, from: viewStore.deviceFactorSources) { item in
			Card(.app.gray5) {
				viewStore.send(.selected(item.value))
			} contents: {
				DisplayEntitiesControlledByMnemonic.MnemonicView(
					viewState: .init(
						headingState: .defaultHeading(type: .selectable(item.isSelected)),
						promptUserToBackUpMnemonic: false,
						accounts: item.value.accounts.filter {
							switch $0.securityState {
							case let .unsecured(unsecuredEntityControl):
								let curve = unsecuredEntityControl.transactionSigning.derivationPath.curveForScheme
								return viewStore.isOlympia && curve == .secp256k1 || !viewStore.isOlympia && curve == .curve25519
							}
						},
						hasHiddenAccounts: !item.value.hiddenAccounts.isEmpty
					)
				)
				.padding(.medium3)
			}
			.cardShadow
			.padding(.horizontal, .medium1)
		}
	}
}
