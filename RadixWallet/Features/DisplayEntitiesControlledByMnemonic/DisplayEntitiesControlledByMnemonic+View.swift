import ComposableArchitecture
import SwiftUI

extension DisplayEntitiesControlledByMnemonic.State {
	var viewState: DisplayEntitiesControlledByMnemonic.ViewState {
		let accountsCount = accountsForDeviceFactorSource.accounts.count
		let connectedAccounts: String = if accountsCount == 1 {
			L10n.SeedPhrases.SeedPhrase.oneConnectedAccount
		} else {
			L10n.SeedPhrases.SeedPhrase.multipleConnectedAccounts(accountsCount)
		}
		return .init(
			connectedAccounts: connectedAccounts,
			buttonState: {
				switch mode {
				case .mnemonicCanBeDisplayed:
					.init(title: L10n.SeedPhrases.SeedPhrase.reveal, imageAsset: AssetResource.signingKey, isError: false)
				case .mnemonicNeedsImport:
					.init(title: "Seed Phrase Entry Required", imageAsset: AssetResource.error, isError: true)
				case .displayAccountListOnly: nil
				}
			}(),
			promptUserToBackUpMnemonic: mode == .mnemonicCanBeDisplayed && !accountsForDeviceFactorSource.isMnemonicMarkedAsBackedUp,
			accounts: accountsForDeviceFactorSource.accounts,
			hasHiddenAccounts: !accountsForDeviceFactorSource.hiddenAccounts.isEmpty
		)
	}
}

// MARK: - DisplayEntitiesControlledByMnemonic.ViewState
extension DisplayEntitiesControlledByMnemonic {
	public struct ViewState: Equatable {
		public let connectedAccounts: String
		public struct ButtonState: Equatable {
			public let title: String
			public let imageAsset: ImageAsset
			public let isError: Bool
			var foregroundColor: Color {
				isError ? .app.red1 : .black
			}
		}

		public let buttonState: ButtonState?
		public let promptUserToBackUpMnemonic: Bool
		public let accounts: [Profile.Network.Account]
		public let hasHiddenAccounts: Bool
	}
}

// MARK: - DisplayEntitiesControlledByMnemonic.View
extension DisplayEntitiesControlledByMnemonic {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DisplayEntitiesControlledByMnemonic>

		public init(store: StoreOf<DisplayEntitiesControlledByMnemonic>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading) {
					if let buttonState = viewStore.buttonState {
						Button {
							viewStore.send(.navigateButtonTapped)
						} label: {
							HStack {
								Image(asset: buttonState.imageAsset)
									.resizable()
									.renderingMode(.template)
									.frame(.smallest)
									.foregroundColor(buttonState.foregroundColor)

								VStack(alignment: .leading) {
									Text(buttonState.title)
										.textStyle(.body1Header)
										.foregroundColor(buttonState.foregroundColor)

									Text(viewStore.connectedAccounts)
										.textStyle(.body2Regular)
										.foregroundColor(.app.gray2)
								}

								Spacer(minLength: 0)
								Image(asset: AssetResource.chevronRight)
							}
						}
					}

					if viewStore.promptUserToBackUpMnemonic {
						WarningErrorView(
							text: "Please write down your Seed Phrase",
							type: .error,
							useNarrowSpacing: true
						)
					}

					if !viewStore.accounts.isEmpty {
						VStack(alignment: .leading, spacing: .small3) {
							ForEach(viewStore.accounts) { account in
								SmallAccountCard(account: account)
									.cornerRadius(.small1)
							}
						}
					} else if viewStore.hasHiddenAccounts {
						NoContentView("Hidden Accounts only.") // FIXME: Strings
							.frame(maxWidth: .infinity)
							.frame(height: .huge2)
							.padding(.vertical, .medium1)
					}
				}
			}
		}
	}
}
