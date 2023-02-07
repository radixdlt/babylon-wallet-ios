import CreateEntityFeature
import FeaturePrelude

// MARK: - ChooseAccounts.View
extension ChooseAccounts {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString
		let canProceed: Bool

		init(state: ChooseAccounts.State) {
			switch state.accessKind {
			case .ongoing:
				title = L10n.DApp.ChooseAccounts.Title.ongoing
			case .oneTime:
				title = L10n.DApp.ChooseAccounts.Title.oneTime
			}

			subtitle = {
				let message: String = {
					switch state.accessKind {
					case .ongoing:
						switch (state.numberOfAccounts.quantifier, state.numberOfAccounts.quantity) {
						case (.atLeast, 0):
							return L10n.DApp.ChooseAccounts.Subtitle.Message.Ongoing.atLeastZero
						case (.atLeast, 1):
							return L10n.DApp.ChooseAccounts.Subtitle.Message.Ongoing.atLeastOne
						case let (.atLeast, number):
							return L10n.DApp.ChooseAccounts.Subtitle.Message.Ongoing.atLeast(number)
						case (.exactly, 1):
							return L10n.DApp.ChooseAccounts.Subtitle.Message.Ongoing.exactlyOne
						case let (.exactly, number):
							return L10n.DApp.ChooseAccounts.Subtitle.Message.Ongoing.exactly(number)
						}
					case .oneTime:
						switch (state.numberOfAccounts.quantifier, state.numberOfAccounts.quantity) {
						case (.atLeast, 0):
							return L10n.DApp.ChooseAccounts.Subtitle.Message.OneTime.atLeastZero
						case (.atLeast, 1):
							return L10n.DApp.ChooseAccounts.Subtitle.Message.OneTime.atLeastOne
						case let (.atLeast, number):
							return L10n.DApp.ChooseAccounts.Subtitle.Message.OneTime.atLeast(number)
						case (.exactly, 1):
							return L10n.DApp.ChooseAccounts.Subtitle.Message.OneTime.exactlyOne
						case let (.exactly, number):
							return L10n.DApp.ChooseAccounts.Subtitle.Message.OneTime.exactly(number)
						}
					}
				}()

				let attributedMessage = AttributedString(message, foregroundColor: .app.gray2)
				let dappName = AttributedString(state.dappMetadata.name, foregroundColor: .app.gray1)
				let dot = AttributedString(".", foregroundColor: .app.gray2)

				switch state.accessKind {
				case .ongoing:
					return attributedMessage + dappName + dot
				case .oneTime:
					return dappName + attributedMessage
				}
			}()

			let quantifier = state.numberOfAccounts.quantifier
			let quantity = state.numberOfAccounts.quantity
			canProceed = {
				switch quantifier {
				case .atLeast:
					return state.selectedAccounts.count >= quantity
				case .exactly:
					return state.selectedAccounts.count == quantity
				}
			}()
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<ChooseAccounts>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ChooseAccounts.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				ForceFullScreen {
					ScrollView {
						VStack(spacing: .small1) {
							VStack(spacing: .medium2) {
								dappImage

								Text(viewStore.title)
									.foregroundColor(.app.gray1)
									.textStyle(.sheetTitle)

								Text(viewStore.subtitle)
									.textStyle(.secondaryHeader)
									.multilineTextAlignment(.center)
							}
							.padding(.bottom, .medium2)

							ForEachStore(
								store.scope(
									state: \.availableAccounts,
									action: { .child(.account(id: $0, action: $1)) }
								),
								content: { ChooseAccountsRow.View(store: $0) }
							)

							Spacer()
								.frame(height: .small3)

							Button(L10n.DApp.ChooseAccounts.createNewAccount) {
								viewStore.send(.createAccountButtonTapped)
							}
							.buttonStyle(.secondaryRectangular(
								shouldExpand: false
							))

							Spacer()
								.frame(height: .large1 * 1.5)
						}
						.padding(.horizontal, .medium1)
					}
					.safeAreaInset(edge: .bottom) {
						ConfirmationFooter(
							title: L10n.DApp.LoginRequest.continueButtonTitle,
							isEnabled: viewStore.canProceed,
							action: { viewStore.send(.continueButtonTapped) }
						)
					}
				}
				.onAppear {
					viewStore.send(.didAppear)
				}
			}
		}
	}
}

// MARK: - Private Computed Properties
private extension ChooseAccounts.View {
	var dappImage: some SwiftUI.View {
		// NOTE: using placeholder until API is available
		Color.app.gray4
			.frame(.medium)
			.cornerRadius(.medium3)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ChooseAccounts_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		ChooseAccounts.View(
			store: .init(
				initialState: .previewValue,
				reducer: ChooseAccounts()
			)
		)
	}
}

extension ChooseAccounts.State {
	static let previewValue: Self = .init(
		accessKind: .oneTime,
		dappDefinitionAddress: try! .init(address: "account_deadbeef"),
		dappMetadata: .previewValue,
		numberOfAccounts: .atLeast(2),
		availableAccounts: .init(
			uniqueElements: [
				.previewValueOne,
			]
		),
		createAccountCoordinator: nil
	)
}
#endif
