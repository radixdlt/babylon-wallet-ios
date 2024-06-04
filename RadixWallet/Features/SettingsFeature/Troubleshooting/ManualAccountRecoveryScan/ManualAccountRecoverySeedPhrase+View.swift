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
					Text(L10n.AccountRecoveryScan.ChooseSeedPhrase.title)
						.multilineTextAlignment(.center)
						.textStyle(.sheetTitle)
						.padding(.top, .medium3)
						.padding(.horizontal, .large2)
						.padding(.bottom, .large3)

					Text(subtitle(isOlympia: viewStore.isOlympia))
						.multilineTextAlignment(.center)
						.textStyle(.body1Header)
						.padding(.horizontal, .huge2)
						.padding(.bottom, .huge3)

					mnemonics(viewStore: viewStore)
						.padding(.bottom, .large3)

					Button(buttonText(isOlympia: viewStore.isOlympia)) {
						store.send(.view(.addButtonTapped))
					}
					.buttonStyle(.secondaryRectangular)
				}
			}
			.foregroundStyle(.app.gray1)
			.padding(.bottom, .medium3)
		}
		.footer {
			WithViewStore(store, observe: \.selected) { viewStore in
				WithControlRequirements(viewStore.state) { selection in
					store.send(.view(.continueButtonTapped(selection)))
				} control: { action in
					Button(L10n.AccountRecoveryScan.ChooseSeedPhrase.continueButton, action: action)
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
		return navigationDestination(
			store: destinationStore,
			state: /ManualAccountRecoverySeedPhrase.Destination.State.importMnemonic,
			action: ManualAccountRecoverySeedPhrase.Destination.Action.importMnemonic,
			destination: { ImportMnemonic.View(store: $0) }
		)
	}
}

// MARK: - ManualAccountRecoverySeedPhrase.View.PathView
private extension ManualAccountRecoverySeedPhrase.View {
	private func subtitle(isOlympia: Bool) -> String {
		if isOlympia {
			L10n.AccountRecoveryScan.ChooseSeedPhrase.subtitleOlympia
		} else {
			L10n.AccountRecoveryScan.ChooseSeedPhrase.subtitleBabylon
		}
	}

	private func buttonText(isOlympia: Bool) -> String {
		if isOlympia {
			L10n.AccountRecoveryScan.ChooseSeedPhrase.addButtonOlympia
		} else {
			L10n.AccountRecoveryScan.ChooseSeedPhrase.addButtonBabylon
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
						headingState: .init(
							title: L10n.SeedPhrases.SeedPhrase.headingScan,
							type: .scanning(selected: item.isSelected),
							isError: false
						),
						promptUserToBackUpMnemonic: false,
						promptUserToImportMnemonic: false,
						accounts: item.value.accounts.filter {
							switch $0.securityState {
							case let .unsecured(unsecuredEntityControl):
								let curve = unsecuredEntityControl.transactionSigning.derivationPath.curve
								return viewStore.isOlympia && curve == .secp256k1 || !viewStore.isOlympia && curve == .curve25519
							}
						},
						hiddenAccountsCount: item.value.hiddenAccounts.count
					)
				)
				.padding(.medium3)
			}
			.cardShadow
			.padding(.horizontal, .medium1)
		}
	}
}
