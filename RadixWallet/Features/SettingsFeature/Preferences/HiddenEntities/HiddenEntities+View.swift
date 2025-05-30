import SwiftUI

// MARK: - HiddenEntities.View
extension HiddenEntities {
	struct View: SwiftUI.View {
		let store: StoreOf<HiddenEntities>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					LazyVStack(alignment: .leading, spacing: .large3) {
						Text(L10n.HiddenEntities.text)
							.textStyle(.body1HighImportance)
							.foregroundColor(Color.secondaryText)

						header(L10n.HiddenEntities.personas)
						personas

						header(L10n.HiddenEntities.accounts)
						accounts
					}
					.padding(.medium3)
				}
				.background(Color.secondaryBackground)
				.radixToolbar(title: L10n.HiddenEntities.title)
				.task {
					store.send(.view(.task))
				}
				.alert(store: store.scope(state: \.$destination.unhideAlert, action: \.destination.unhideAlert))
			}
		}

		private func header(_ value: String) -> some SwiftUI.View {
			Text(value)
				.textStyle(.secondaryHeader)
				.foregroundColor(.secondaryText)
		}

		@ViewBuilder
		private var personas: some SwiftUI.View {
			if store.personas.isEmpty {
				emptyState
			} else {
				VStack(spacing: .medium3) {
					ForEachStatic(store.personas) { persona in
						Card {
							PlainListRow(viewState: .init(
								rowCoreViewState: .init(context: .hiddenPersona, title: persona.displayName.value),
								accessory: { unhideButton(action: .unhidePersonaTapped(persona.id)) },
								icon: { Thumbnail(.persona, url: nil) }
							))
						}
					}
				}
			}
		}

		@ViewBuilder
		private var accounts: some SwiftUI.View {
			if store.accounts.isEmpty {
				emptyState
			} else {
				VStack(spacing: .medium3) {
					ForEachStatic(store.accounts) { account in
						Card {
							AccountCard(kind: .details, account: account) {
								unhideButton(action: .unhideAccountTapped(account.id))
							}
						}
					}
				}
			}
		}

		private func unhideButton(action: ViewAction) -> some SwiftUI.View {
			Button(L10n.HiddenEntities.unhide) {
				store.send(.view(action))
			}
			.buttonStyle(.secondaryRectangular(shouldExpand: false))
			.padding(.leading, .small3)
		}

		private var emptyState: some SwiftUI.View {
			ZStack {
				PlainListRow(viewState: .init(
					rowCoreViewState: .init(context: .hiddenPersona, title: "dummy"),
					accessory: { unhideButton(action: .task) },
					icon: { Thumbnail(.persona, url: nil) }
				))
				.hidden()

				Text(L10n.Common.none)
					.textStyle(.secondaryHeader)
					.foregroundColor(.secondaryText)
			}
			.background(.tertiaryBackground)
			.clipShape(RoundedRectangle(cornerRadius: .medium3))
		}
	}
}
