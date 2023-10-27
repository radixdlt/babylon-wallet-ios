extension AccountAndPersonaHiding.State {
	var viewState: AccountAndPersonaHiding.ViewState {
		.init(
			hiddenAccountsCount: hiddenEntitiesStats?.hiddenAccountsCount ?? 0,
			hiddenPersonasCount: hiddenEntitiesStats?.hiddenPersonasCount ?? 0
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
				List {
					Section {
						VStack(alignment: .leading, spacing: .zero) {
							Text(viewStore.hiddenAccountsText)
							Text(viewStore.hiddenPersonasText)
						}
						.foregroundColor(.app.gray2)
						.textStyle(.body1Header)
						.listRowSeparator(.hidden)
						.listRowBackground(Color.clear)
						.centered
					} header: {
						Text(L10n.AppSettings.EntityHiding.info)
							.foregroundColor(.app.gray2)
							.textStyle(.body1Regular)
							.textCase(nil)
					}

					Section {
						Button(L10n.AppSettings.EntityHiding.unhideAllButton) {
							viewStore.send(.view(.unhideAllTapped))
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
						.controlState(viewStore.unhideAllButtonControlState)
					} header: {
						Text(L10n.AppSettings.EntityHiding.unhideAllSection)
							.foregroundColor(.app.gray2)
							.textStyle(.body1HighImportance)
							.textCase(nil)
					}
				}
				.listStyle(.grouped)
				.background(.app.background)
				.task { @MainActor in
					await viewStore.send(.view(.task)).finish()
				}
				.alert(
					store: store.scope(
						state: \.$confirmUnhideAllAlert,
						action: { .view(.confirmUnhideAllAlert($0)) }
					)
				)
			}
			.navigationTitle(L10n.AppSettings.EntityHiding.title)
			.toolbarBackground(.app.background, for: .navigationBar)
			.toolbarBackground(.visible, for: .navigationBar)
		}
	}
}
