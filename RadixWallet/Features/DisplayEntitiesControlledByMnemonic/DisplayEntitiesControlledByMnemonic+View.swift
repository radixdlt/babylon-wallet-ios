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
			headingState: {
				switch mode {
				case .mnemonicCanBeDisplayed:
					.defaultHeading(mode: .button)
				case .mnemonicNeedsImport:
					.init(
						title: "Seed Phrase Entry Required", // FIXME: String
						imageAsset: AssetResource.error,
						isButton: true,
						isError: true
					)
				case .selectableHeadingAndAccountList:
					.defaultHeading(isButton: false)
				case .displayAccountListOnly:
					nil
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
		public struct HeadingState: Equatable {
			public let title: String
			public let imageAsset: ImageAsset
			public let mode: Mode
			public let isError: Bool
			var foregroundColor: Color {
				isError ? .app.red1 : .black
			}

			static func defaultHeading(mode: Mode) -> HeadingState {
				.init(
					title: L10n.SeedPhrases.SeedPhrase.reveal,
					imageAsset: AssetResource.signingKey,
					mode: mode,
					isError: false
				)
			}

			public enum Mode: Equatable {
				case button
				case selected(Bool)
			}
		}

		public let headingState: HeadingState?
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
					MnemonicView(
						headingState: viewStore.headingState,
						connectedAccounts: viewStore.connectedAccounts
					) {
						viewStore.send(.navigateButtonTapped)
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

	struct MnemonicView: SwiftUI.View {
		let headingState: ViewState.HeadingState?
		let connectedAccounts: String
		let action: () -> Void

		var body: some SwiftUI.View {
			if let headingState {
				if headingState.isButton {
					Button(action: action) {
						heading(headingState)
					}
				} else {
					heading(headingState)
				}
			}
		}

		private func heading(_ headingState: ViewState.HeadingState) -> some SwiftUI.View {
			HStack {
				Image(asset: headingState.imageAsset)
					.resizable()
					.renderingMode(.template)
					.frame(.smallest)
					.foregroundColor(headingState.foregroundColor)

				VStack(alignment: .leading) {
					Text(headingState.title)
						.textStyle(.body1Header)
						.foregroundColor(headingState.foregroundColor)

					Text(connectedAccounts)
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}

				Spacer(minLength: 0)

				if headingState.isButton {
					Image(asset: AssetResource.chevronRight)
				}
			}
		}
	}
}
