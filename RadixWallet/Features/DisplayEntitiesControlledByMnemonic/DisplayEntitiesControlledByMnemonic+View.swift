import ComposableArchitecture
import SwiftUI

extension DisplayEntitiesControlledByMnemonic.State {
	var viewState: DisplayEntitiesControlledByMnemonic.ViewState {
		.init(
			headingState: {
				switch mode {
				case .mnemonicCanBeDisplayed:
					.init(
						title: L10n.SeedPhrases.SeedPhrase.headingReveal,
						imageAsset: AssetResource.signingKey,
						type: .standard,
						isError: false
					)
				case .mnemonicNeedsImport:
					.init(
						title: L10n.SeedPhrases.SeedPhrase.headingNeedsImport,
						imageAsset: AssetResource.error,
						type: .standard,
						isError: true
					)
				case .displayAccountListOnly:
					nil
				}
			}(),
			promptUserToBackUpMnemonic: mode == .mnemonicCanBeDisplayed && !isMnemonicMarkedAsBackedUp,
			accounts: accounts.elements,
			hasHiddenAccounts: hasHiddenAccounts
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
						L10n.SeedPhrases.SeedPhrase.noConnectedAccountsReveal
					} else if accounts == 1 {
						L10n.SeedPhrases.SeedPhrase.oneConnectedAccountReveal
					} else {
						L10n.SeedPhrases.SeedPhrase.multipleConnectedAccountsReveal(accounts)
					}
				case .scanning:
					if accounts == 0 {
						L10n.SeedPhrases.SeedPhrase.noConnectedAccountsScan
					} else if accounts == 1 {
						L10n.SeedPhrases.SeedPhrase.oneConnectedAccountScan
					} else {
						L10n.SeedPhrases.SeedPhrase.multipleConnectedAccountsScan(accounts)
					}
				}
			}
		}

		public let headingState: HeadingState?
		public let promptUserToBackUpMnemonic: Bool
		public let accounts: [Account]
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
					case .scanning:
						heading(headingState)
					}
				}

				if viewState.promptUserToBackUpMnemonic {
					WarningErrorView(
						text: L10n.SeedPhrases.backupWarning,
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
					NoContentView(L10n.SeedPhrases.hiddenAccountsOnly)
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
