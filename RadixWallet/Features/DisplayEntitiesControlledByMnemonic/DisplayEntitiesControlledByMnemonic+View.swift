import ComposableArchitecture
import SwiftUI

extension DisplayEntitiesControlledByMnemonic.State {
	var viewState: DisplayEntitiesControlledByMnemonic.ViewState {
		.init(
			headingState: {
				switch mode {
				case .mnemonicCanBeDisplayed, .mnemonicNeedsImport:
					.init(
						title: L10n.SeedPhrases.SeedPhrase.headingReveal,
						type: .standard,
						isError: mode == .mnemonicNeedsImport
					)
				case .displayAccountListOnly:
					nil
				}
			}(),
			promptUserToBackUpMnemonic: mode == .mnemonicCanBeDisplayed && !isMnemonicMarkedAsBackedUp,
			promptUserToImportMnemonic: mode == .mnemonicNeedsImport,
			accounts: accounts.elements,
			hiddenAccountsCount: hiddenAccountsCount,
			personasCount: personasCount
		)
	}
}

// MARK: - DisplayEntitiesControlledByMnemonic.ViewState
extension DisplayEntitiesControlledByMnemonic {
	struct ViewState: Equatable {
		struct HeadingState: Equatable {
			let title: String
			let type: HeadingType
			let isError: Bool
			var foregroundColor: Color {
				isError ? .secondaryText : .primaryText
			}

			enum HeadingType: Equatable {
				case standard
				case scanning(selected: Bool)
			}

			func connectedAccountsLabel(accounts: Int, personas: Int) -> String {
				switch type {
				case .standard:
					switch (personas, accounts) {
					case (0, 0): L10n.SeedPhrases.SeedPhrase.noConnectedAccounts
					case (0, 1): L10n.SeedPhrases.SeedPhrase.oneConnectedAccount
					case (0, _): L10n.SeedPhrases.SeedPhrase.multipleConnectedAccounts(accounts)
					case (_, 1): L10n.DisplayMnemonics.ConnectedAccountsPersonasLabel.one(accounts)
					case (_, _): L10n.DisplayMnemonics.ConnectedAccountsPersonasLabel.many(accounts)
					}
				case .scanning:
					if accounts == 0 {
						L10n.SeedPhrases.SeedPhrase.noConnectedAccounts
					} else if accounts == 1 {
						L10n.SeedPhrases.SeedPhrase.oneConnectedAccount
					} else {
						L10n.SeedPhrases.SeedPhrase.multipleConnectedAccounts(accounts)
					}
				}
			}
		}

		let headingState: HeadingState?
		let promptUserToBackUpMnemonic: Bool
		let promptUserToImportMnemonic: Bool
		let accounts: [Account]
		let hiddenAccountsCount: Int
		let personasCount: Int

		var totalAccountsCount: Int {
			accounts.count + hiddenAccountsCount
		}
	}
}

// MARK: - DisplayEntitiesControlledByMnemonic.View
extension DisplayEntitiesControlledByMnemonic {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<DisplayEntitiesControlledByMnemonic>

		init(store: StoreOf<DisplayEntitiesControlledByMnemonic>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				MnemonicView(viewState: viewStore.state) {
					viewStore.send(.navigateButtonTapped)
				}
			}
		}
	}

	struct MnemonicView: SwiftUI.View {
		@Environment(\.colorScheme) private var colorScheme
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
					StatusMessageView(
						text: L10n.SecurityProblems.No3.seedPhrases,
						type: .warning,
						useNarrowSpacing: true
					)
				} else if viewState.promptUserToImportMnemonic {
					StatusMessageView(
						text: L10n.SecurityProblems.No9.seedPhrases,
						type: .warning,
						useNarrowSpacing: true
					)
				}

				if !viewState.accounts.isEmpty {
					VStack(alignment: .leading, spacing: .small3) {
						ForEach(viewState.accounts) { account in
							AccountCard(kind: .compact, account: account)
						}
					}
				} else if viewState.hiddenAccountsCount > 0 {
					NoContentView(L10n.SeedPhrases.hiddenAccountsOnly)
						.frame(maxWidth: .infinity)
						.frame(height: .huge2)
						.padding(.vertical, .medium1)
				}
			}
		}

		private func heading(_ headingState: ViewState.HeadingState) -> some SwiftUI.View {
			HStack {
				Image(.signingKey)
					.resizable()
					.renderingMode(.template)
					.frame(.smallest)
					.foregroundColor(headingState.foregroundColor)

				VStack(alignment: .leading) {
					Text(headingState.title)
						.textStyle(.body1Header)
						.foregroundColor(headingState.foregroundColor)

					Text(headingState.connectedAccountsLabel(accounts: viewState.totalAccountsCount, personas: viewState.personasCount))
						.textStyle(.body2Regular)
						.foregroundColor(.secondaryText)
				}

				Spacer(minLength: 0)

				switch headingState.type {
				case .standard:
					Image(.chevronRight)
						.foregroundColor(headingState.foregroundColor)
				case let .scanning(isSelected):
					RadioButton(
						appearance: colorScheme == .light ? .dark : .light,
						isSelected: isSelected
					)
				}
			}
		}
	}
}
