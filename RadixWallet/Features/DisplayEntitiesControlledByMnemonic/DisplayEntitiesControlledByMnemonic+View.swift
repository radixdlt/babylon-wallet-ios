import ComposableArchitecture
import SwiftUI

extension DisplayEntitiesControlledByMnemonic.State {
	var viewState: DisplayEntitiesControlledByMnemonic.ViewState {
		.init(
			headingState: {
				switch mode {
				case .mnemonicCanBeDisplayed:
					.init(
						title: L10n.SeedPhrases.SeedPhrase.reveal,
						imageAsset: AssetResource.signingKey,
						type: .standard,
						isError: false
					)
				case .mnemonicNeedsImport:
					.init(
						title: "Seed Phrase Entry Required", // FIXME: String
						imageAsset: AssetResource.error,
						type: .standard,
						isError: true
					)
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
		public struct HeadingState: Equatable {
			public let title: String
			public let imageAsset: ImageAsset
			public let type: HeadingType
			public let isError: Bool
			var foregroundColor: Color {
				isError ? .app.red1 : .black
			}

			public enum HeadingType: Equatable {
				case standard
				case scanning(selected: Bool)
			}

			public func connectedAccountsLabel(accounts: Int) -> String {
				switch type {
				case .standard:
					if accounts == 0 {
						"Not connected to any Accounts" // FIXME: Strings
					} else if accounts == 1 {
						L10n.SeedPhrases.SeedPhrase.oneConnectedAccount
					} else {
						L10n.SeedPhrases.SeedPhrase.multipleConnectedAccounts(accounts)
					}
				case .scanning:
					if accounts == 0 {
						"Not yet connected to any Accounts" // FIXME: Strings
					} else if accounts == 1 {
						"Currently connected to 1 account" // FIXME: Strings
					} else {
						"Currently connected to \(accounts) accounts" // FIXME: Strings
					}
				}
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
				MnemonicView(viewState: viewStore.state) {
					viewStore.send(.navigateButtonTapped)
				}
			}
		}
	}

	struct MnemonicView: SwiftUI.View {
		let viewState: ViewState
		let action: () -> Void

		init(viewState: ViewState, action: @escaping () -> Void = {}) {
			self.viewState = viewState
			self.action = action
		}

		var body: some SwiftUI.View {
			VStack(alignment: .leading) {
				if let headingState = viewState.headingState {
					switch headingState.type {
					case .standard:
						Button(action: action) {
							heading(headingState)
						}
					case let .scanning(selected):
						heading(headingState)
					}
				}

				if viewState.promptUserToBackUpMnemonic {
					WarningErrorView(
						text: "Please write down your Seed Phrase", // FIXME: Strings
						type: .error,
						useNarrowSpacing: true
					)
				}

				if !viewState.accounts.isEmpty {
					VStack(alignment: .leading, spacing: .small3) {
						ForEach(viewState.accounts) { account in
							SmallAccountCard(account: account)
								.cornerRadius(.small1)
						}
					}
				} else if viewState.hasHiddenAccounts {
					NoContentView("Hidden Accounts only.") // FIXME: Strings
						.frame(maxWidth: .infinity)
						.frame(height: .huge2)
						.padding(.vertical, .medium1)
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

					Text(headingState.connectedAccountsLabel(accounts: viewState.accounts.count))
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}

				Spacer(minLength: 0)

				switch headingState.type {
				case .standard:
					Image(asset: AssetResource.chevronRight)
				case let .scanning(isSelected):
					RadioButton(appearance: .dark, state: isSelected ? .selected : .unselected)
				}
			}
		}
	}
}
