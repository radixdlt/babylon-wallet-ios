import ComposableArchitecture
import SwiftUI

extension DisplayEntitiesControlledByMnemonic.State {
	var viewState: DisplayEntitiesControlledByMnemonic.ViewState {
		.init(
			headingState: {
				switch mode {
				case .mnemonicCanBeDisplayed:
					.defaultHeading(type: .button)
				case .mnemonicNeedsImport:
					.init(
						title: "Seed Phrase Entry Required", // FIXME: String
						imageAsset: AssetResource.error,
						type: .button,
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

			static func defaultHeading(type: HeadingType) -> HeadingState {
				.init(
					title: L10n.SeedPhrases.SeedPhrase.reveal,
					imageAsset: AssetResource.signingKey,
					type: type,
					isError: false
				)
			}

			public enum HeadingType: Equatable {
				case button
				case selectable(Bool)
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
					if headingState.type == .button {
						Button(action: action) {
							heading(headingState)
						}
					} else {
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

					Text(connectedAccountsLabel(count: viewState.accounts.count))
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}

				Spacer(minLength: 0)

				switch headingState.type {
				case .button:
					Image(asset: AssetResource.chevronRight)
				case let .selectable(isSelected):
					RadioButton(appearance: .dark, state: isSelected ? .selected : .unselected)
				}
			}
		}

		private func connectedAccountsLabel(count: Int) -> String {
			if count == 1 {
				L10n.SeedPhrases.SeedPhrase.oneConnectedAccount
			} else {
				L10n.SeedPhrases.SeedPhrase.multipleConnectedAccounts(count)
			}
		}
	}
}
