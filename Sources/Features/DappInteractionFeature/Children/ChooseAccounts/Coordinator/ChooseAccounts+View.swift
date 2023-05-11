import CreateEntityFeature
import FeaturePrelude

// MARK: - ChooseAccounts.View
extension ChooseAccounts {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString
		let availableAccounts: [ChooseAccountsRow.State]
		let selectionRequirement: SelectionRequirement
		let selectedAccounts: [ChooseAccountsRow.State]?

		init(state: ChooseAccounts.State) {
			switch state.accessKind {
			case .ongoing:
				self.title = L10n.DappRequest.ChooseAccountsOngoing.title
			case .oneTime:
				self.title = L10n.DappRequest.ChooseAccountsOneTime.title
			}

			self.subtitle = {
				let message: String = {
					switch state.accessKind {
					case .ongoing:
						switch (state.numberOfAccounts.quantifier, state.numberOfAccounts.quantity) {
						case (.atLeast, 0):
							return L10n.DappRequest.ChooseAccountsOngoing.subtitleAtLeastZero
						case (.atLeast, 1):
							return L10n.DappRequest.ChooseAccountsOngoing.subtitleAtLeastOne
						case let (.atLeast, number):
							return L10n.DappRequest.ChooseAccountsOngoing.subtitleAtLeast(number)
						case (.exactly, 1):
							return L10n.DappRequest.ChooseAccountsOngoing.subtitleExactlyOne
						case let (.exactly, number):
							return L10n.DappRequest.ChooseAccountsOngoing.subtitleExactly(number)
						}
					case .oneTime:
						switch (state.numberOfAccounts.quantifier, state.numberOfAccounts.quantity) {
						case (.atLeast, 0):
							return L10n.DappRequest.ChooseAccountsOneTime.subtitleAtLeastZero
						case (.atLeast, 1):
							return L10n.DappRequest.ChooseAccountsOneTime.subtitleAtLeastOne
						case let (.atLeast, number):
							return L10n.DappRequest.ChooseAccountsOneTime.subtitleAtLeast(number)
						case (.exactly, 1):
							return L10n.DappRequest.ChooseAccountsOneTime.subtitleExactlyOne
						case let (.exactly, number):
							return L10n.DappRequest.ChooseAccountsOneTime.subtitleExactly(number)
						}
					}
				}()

				let attributedMessage = AttributedString(message, foregroundColor: .app.gray2)
				let dappName = AttributedString(state.dappMetadata.name.rawValue, foregroundColor: .app.gray1)
				let dot = AttributedString(".", foregroundColor: .app.gray2)

				switch state.accessKind {
				case .ongoing:
					return attributedMessage + dappName + dot
				case .oneTime:
					return dappName + attributedMessage
				}
			}()

			let selectionRequirement = SelectionRequirement(state.numberOfAccounts)

			self.availableAccounts = state.availableAccounts.map { account in
				ChooseAccountsRow.State(
					account: account,
					mode: selectionRequirement == .exactly(1) ? .radioButton : .checkmark
				)
			}
			self.selectionRequirement = selectionRequirement
			self.selectedAccounts = state.selectedAccounts
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
				ScrollView {
					VStack(spacing: .medium2) {
						DappHeader(
							icon: nil,
							title: viewStore.title,
							subtitle: viewStore.subtitle
						)

						VStack(spacing: .small1) {
							Selection(
								viewStore.binding(
									get: \.selectedAccounts,
									send: { .selectedAccountsChanged($0) }
								),
								from: viewStore.availableAccounts,
								requiring: viewStore.selectionRequirement
							) { item in
								ChooseAccountsRow.View(
									viewState: .init(state: item.value),
									isSelected: item.isSelected,
									action: item.action
								)
							}
						}

						Button(L10n.DappRequest.ChooseAccounts.createNewAccount) {
							viewStore.send(.createAccountButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: false))
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					WithControlRequirements(
						viewStore.selectedAccounts,
						forAction: { viewStore.send(.continueButtonTapped($0)) }
					) { action in
						Button(L10n.Common.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.onAppear {
					viewStore.send(.appeared)
				}
				.sheet(
					store: store.scope(
						state: \.$createAccountCoordinator,
						action: { .child(.createAccountCoordinator($0)) }
					),
					content: { CreateAccountCoordinator.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ChooseAccounts_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		NavigationStack {
			ChooseAccounts.View(
				store: .init(
					initialState: .previewValue,
					reducer: ChooseAccounts()
				)
			)
			#if os(iOS)
			.toolbar(.visible, for: .navigationBar)
			#endif // iOS
		}
	}
}

extension ChooseAccounts.State {
	static let previewValue: Self = .init(
		accessKind: .ongoing,
		dappDefinitionAddress: try! .init(address: "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6"),
		dappMetadata: .previewValue,
		availableAccounts: .init(
			uniqueElements: [
				.previewValue0,
				.previewValue1,
			]
		),
		numberOfAccounts: .exactly(1),
		createAccountCoordinator: nil
	)
}
#endif
