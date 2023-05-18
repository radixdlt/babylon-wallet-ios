import ChooseAccounts
import FeaturePrelude
import SigningFeature

// MARK: - AccountPermissionChooseAccounts.View
extension AccountPermissionChooseAccounts {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<AccountPermissionChooseAccounts>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: { $0 },
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						DappHeader(
							thumbnail: viewStore.dappMetadata.thumbnail,
							title: viewStore.title,
							subtitle: viewStore.subtitle
						)
						ChooseAccounts.View(store: store.scope(state: \.chooseAccounts, action: { .child(.chooseAccounts($0)) }))
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					WithControlRequirements(
						viewStore.chooseAccounts.selectedAccounts,
						forAction: { viewStore.send(.continueButtonTapped($0)) }
					) { action in
						Button(L10n.Common.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /AccountPermissionChooseAccounts.Destinations.State.signing,
					action: AccountPermissionChooseAccounts.Destinations.Action.signing,
					content: { Signing.View(store: $0) }
				)
			}
		}
	}
}

extension AccountPermissionChooseAccounts.State {
	var title: String {
		switch accessKind {
		case .ongoing:
			return L10n.DAppRequest.ChooseAccountsOngoing.title
		case .oneTime:
			return L10n.DAppRequest.ChooseAccountsOneTime.title
		}
	}

	var subtitle: String {
		let dAppName = dappMetadata.name

		switch accessKind {
		case .ongoing:
			switch (chooseAccounts.selectionRequirement.quantifier, chooseAccounts.selectionRequirement.count) {
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
			switch (chooseAccounts.selectionRequirement.quantifier, chooseAccounts.selectionRequirement.count) {
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
			AccountPermissionChooseAccounts.View(
				store: .init(
					initialState: .previewValue,
					reducer: AccountPermissionChooseAccounts()
				)
			)
			#if os(iOS)
			.toolbar(.visible, for: .navigationBar)
			#endif // iOS
		}
	}
}

extension AccountPermissionChooseAccounts.State {
	static let previewValue: Self = .init(
		challenge: nil,
		accessKind: .ongoing,
		dappMetadata: .previewValue,
		chooseAccounts: .init(
			selectionRequirement: .exactly(1),
			availableAccounts: .init(
				uniqueElements: [
					.previewValue0,
					.previewValue1,
				]
			)
		)
	)
}
#endif
