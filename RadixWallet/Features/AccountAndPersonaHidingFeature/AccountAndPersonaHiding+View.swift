extension AccountAndPersonaHiding.State {
	var viewState: AccountAndPersonaHiding.ViewState {
		.init(
			hiddenAccountsCount: hiddenEntityCounts?.hiddenAccountsCount ?? 0,
			hiddenPersonasCount: hiddenEntityCounts?.hiddenPersonasCount ?? 0
		)
	}
}

extension AccountAndPersonaHiding {
	public struct ViewState: Equatable {
		public let hiddenAccountsCount: Int
		public let hiddenPersonasCount: Int

		public var hiddenAccountsText: String {
			if hiddenAccountsCount == 1 {
				L10n.AppSettings.EntityHiding.hiddenAccount(1)
			} else {
				L10n.AppSettings.EntityHiding.hiddenAccounts(hiddenAccountsCount)
			}
		}

		public var hiddenPersonasText: String {
			if hiddenPersonasCount == 1 {
				L10n.AppSettings.EntityHiding.hiddenPersona(1)
			} else {
				L10n.AppSettings.EntityHiding.hiddenPersonas(hiddenPersonasCount)
			}
		}

		public var unhideAllButtonControlState: ControlState {
			if hiddenAccountsCount > 0 || hiddenPersonasCount > 0 {
				.enabled
			} else {
				.disabled
			}
		}
	}

	public struct View: SwiftUI.View {
		public let store: StoreOf<AccountAndPersonaHiding>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				VStack(spacing: .medium3) {
					Text(L10n.AppSettings.EntityHiding.text)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray2)
						.flushedLeft
						.padding(.top, .medium3)

					VStack(alignment: .leading, spacing: .small3) {
						Text(viewStore.hiddenAccountsText)

						Text(viewStore.hiddenPersonasText)
					}
					.textStyle(.body1Header)
					.foregroundColor(.app.gray2)
					.centered

					Text(L10n.AppSettings.EntityHiding.unhideAllSection)
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.gray2)
						.flushedLeft

					Button(L10n.AppSettings.EntityHiding.unhideAllButton) {
						viewStore.send(.view(.unhideAllTapped))
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
					.controlState(viewStore.unhideAllButtonControlState)

					Spacer()
				}
				.padding(.horizontal, .medium3)
				.task { @MainActor in
					await viewStore.send(.view(.task)).finish()
				}
				.alert(store: store.scope(
					state: \.$destination.confirmUnhideAllAlert,
					action: \.destination.confirmUnhideAllAlert
				))
			}
			.navigationTitle(L10n.AppSettings.EntityHiding.title)
		}
	}
}
