import ComposableArchitecture
import SwiftUI

extension NewAccountCompletion.State {
	var viewState: NewAccountCompletion.ViewState {
		.init(state: self)
	}
}

extension NewAccountCompletion {
	struct ViewState: Equatable {
		let entityName: String
		let destinationDisplayText: String
		let isFirstOnNetwork: Bool
		let explanation: String
		let subtitle: String

		let accountAddress: AccountAddress
		let appearanceID: AppearanceID

		init(state: NewAccountCompletion.State) {
			self.entityName = state.account.displayName.rawValue

			self.destinationDisplayText = switch state.navigationButtonCTA {
			case .goHome:
				L10n.CreateEntity.Completion.destinationHome
			case .goBackToChooseAccounts:
				L10n.CreateEntity.Completion.destinationChooseAccounts
			case .goBackToGateways:
				L10n.CreateEntity.Completion.destinationGateways
			}

			self.isFirstOnNetwork = state.isFirstOnNetwork
			self.accountAddress = state.account.address
			self.appearanceID = state.account.appearanceID
			self.explanation = L10n.CreateAccount.Completion.explanation

			self.subtitle = state.isFirstOnNetwork ? L10n.CreateAccount.Completion.subtitleFirst : L10n.CreateAccount.Completion.subtitleNotFirst
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NewAccountCompletion>

		init(store: StoreOf<NewAccountCompletion>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium2) {
					Spacer()
					accountsStackView(with: viewStore)
					Spacer()

					VStack(spacing: .medium1) {
						Text(L10n.CreateEntity.Completion.title)
							.foregroundColor(.primaryText)
							.textStyle(.sheetTitle)

						Text(viewStore.subtitle)
							.foregroundColor(.primaryText)
							.textStyle(.body1Regular)

						Text(viewStore.explanation)
							.foregroundColor(.primaryText)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, .small1)

					Spacer()
				}
				.background(.primaryBackground)
				.padding(.medium1)
				.footer {
					Button(L10n.CreateEntity.Completion.goToDestination(viewStore.destinationDisplayText)) {
						viewStore.send(.goToDestination)
					}
					.buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}

private extension NewAccountCompletion.View {
	@ViewBuilder
	func accountsStackView(
		with viewStore: ViewStoreOf<NewAccountCompletion>
	) -> some View {
		ZStack {
			ForEach(0 ..< transparentCardsCount, id: \.self) { index in
				AppearanceID.fromNumberOfAccounts(Int(viewStore.appearanceID.value) + index).gradient.opacity(0.2)
					.frame(width: cardFrame.width, height: cardFrame.height)
					.cornerRadius(.small1)
					.scaleEffect(scale(index: index))
					.zIndex(reversedZIndex(count: transparentCardsCount, index: index))
					.offset(y: transparentCardOffset * CGFloat(index + 1))
			}

			VStack(spacing: .small2) {
				Text(viewStore.entityName)
					.foregroundColor(.app.white)
					.textStyle(.body1Header)
					.multilineTextAlignment(.center)

				AddressView(.address(.account(viewStore.accountAddress)))
					.foregroundColor(.app.whiteTransparent)
					.textStyle(.body2HighImportance)
			}
			.frame(width: cardFrame.width, height: cardFrame.height)
			.background(viewStore.appearanceID.gradient)
			.cornerRadius(.small1)
			.padding(.horizontal, .medium1)
			.zIndex(Double(transparentCardsCount + 1))
		}
	}

	func scale(index: Int) -> CGFloat {
		1 - (CGFloat(index + 1) * 0.05)
	}

	func reversedZIndex(count: Int, index: Int) -> Double {
		Double(count - index)
	}
}

private let cardFrame: CGSize = .init(width: 277, height: 85)
private let transparentCardsCount: Int = 3
private let transparentCardOffset: CGFloat = .small1
