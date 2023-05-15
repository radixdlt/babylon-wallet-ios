import CreateEntityFeature
import FeaturePrelude

// MARK: - ChooseAccounts.View
extension ChooseAccounts {
	struct ViewState: Equatable {
		let thumbnail: URL?
		let title: String
		let subtitle: String
		let availableAccounts: [ChooseAccountsRow.State]
		let selectionRequirement: SelectionRequirement
		let selectedAccounts: [ChooseAccountsRow.State]?

		init(state: ChooseAccounts.State) {
			self.thumbnail = state.dappMetadata.thumbnail
			self.title = state.title
			self.subtitle = state.subtitle

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
							thumbnail: viewStore.thumbnail,
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

						Button(L10n.DAppRequest.ChooseAccounts.createNewAccount) {
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

extension ChooseAccounts.State {
	var title: String {
		switch accessKind {
		case .ongoing:
			return L10n.DAppRequest.ChooseAccountsOngoing.title
		case .oneTime:
			return L10n.DAppRequest.ChooseAccountsOneTime.title
		}
	}

	var subtitle: String {
		let dAppName = dappMetadata.name.rawValue

		switch accessKind {
		case .ongoing:
			switch (numberOfAccounts.quantifier, numberOfAccounts.quantity) {
			case (.atLeast, 0):
				return L10n.DAppRequest.ChooseAccountsOngoing.subtitleAtLeastZero(dAppName)
			case (.atLeast, 1):
				return L10n.DAppRequest.ChooseAccountsOngoing.subtitleAtLeastOne(dAppName)
			case let (.atLeast, number):
				return L10n.DAppRequest.ChooseAccountsOngoing.subtitleAtLeast(number, dAppName)
			case (.exactly, 1):
				return L10n.DAppRequest.ChooseAccountsOngoing.subtitleExactlyOne(dAppName)
			case let (.exactly, number):
				return L10n.DAppRequest.ChooseAccountsOngoing.subtitleExactly(number, dAppName)
			}
		case .oneTime:
			switch (numberOfAccounts.quantifier, numberOfAccounts.quantity) {
			case (.atLeast, 0):
				return L10n.DAppRequest.ChooseAccountsOneTime.subtitleAtLeastZero(dAppName)
			case (.atLeast, 1):
				return L10n.DAppRequest.ChooseAccountsOneTime.subtitleAtLeastOne(dAppName)
			case let (.atLeast, number):
				return L10n.DAppRequest.ChooseAccountsOneTime.subtitleAtLeast(dAppName, number)
			case (.exactly, 1):
				return L10n.DAppRequest.ChooseAccountsOneTime.subtitleExactlyOne(dAppName)
			case let (.exactly, number):
				return L10n.DAppRequest.ChooseAccountsOneTime.subtitleExactly(dAppName, number)
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
