import FeaturePrelude

extension AccountPreferences.State {
	var viewState: AccountPreferences.ViewState {
		.init(sections: [
			.init(
				id: .personalize,
				title: "Personalize this account", // FIXME: strings
				rows: .init(uncheckedUniqueElements: [.accountLabel(account)])
			),
			.init(
				id: .development,
				title: "Set development preferences", // FIXME: strings
				rows: .init(uncheckedUniqueElements: [.devAccountPreferneces()])
			),
		])
	}
}

// MARK: - AccountPreferences.View
extension AccountPreferences {
	public struct ViewState: Equatable {
		public var sections: [Section]
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountPreferences>

		public init(store: StoreOf<AccountPreferences>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				List {
					ForEach(viewStore.sections) { section in
						SwiftUI.Section {
							ForEach(section.rows) { row in
								PlainListRow(
									row.icon,
									title: row.title,
									subtitle: row.subtitle
								)
								.alignmentGuide(.listRowSeparatorLeading) { $0[.leading] + 16 }
								.alignmentGuide(.listRowSeparatorTrailing) { $0[.trailing] - 16 }
								.listRowInsets(EdgeInsets())
								.onTapGesture {
									viewStore.send(.rowTapped(row.id))
								}
							}
						} header: {
							Text(section.title)
								.textStyle(.body1HighImportance)
								.foregroundColor(.app.gray2)
								.listRowInsets(.init(top: .small1, leading: .medium3, bottom: .medium3, trailing: .medium3))
						} footer: {
							Rectangle().fill().frame(height: 0)
								.listRowInsets(EdgeInsets())
						}
						.listSectionSeparator(.hidden)
						.textCase(nil)
					}
				}
				.task {
					viewStore.send(.task)
				}
				.destination(store: store)
				.listStyle(.grouped)
				.environment(\.defaultMinListHeaderHeight, 0)
				.background(.app.gray4)
				.navigationTitle(L10n.AccountSettings.title)
				#if os(iOS)
					.navigationBarTitleColor(.app.gray1)
					.navigationBarTitleDisplayMode(.inline)
					.navigationBarInlineTitleFont(.app.secondaryHeader)
					.toolbarBackground(.app.background, for: .navigationBar)
					.toolbarBackground(.visible, for: .navigationBar)
				#endif // os(iOS)
			}
		}
	}
}

extension View {
	@MainActor
	func destination(store: StoreOf<AccountPreferences>) -> some View {
		let destinationStore = store.scope(state: \.$destinations, action: { .child(.destinations($0)) })
		return updateAccountLabel(with: destinationStore)
			.devAccountPreferences(with: destinationStore)
	}

	@MainActor
	func updateAccountLabel(with destinationStore: PresentationStoreOf<AccountPreferences.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountPreferences.Destinations.State.updateAccountLabel,
			action: AccountPreferences.Destinations.Action.updateAccountLabel,
			destination: { UpdateAccountLabel.View(store: $0) }
		)
	}

	@MainActor
	func devAccountPreferences(with destinationStore: PresentationStoreOf<AccountPreferences.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountPreferences.Destinations.State.devPreferences,
			action: AccountPreferences.Destinations.Action.devPreferences,
			destination: { DevAccountPreferences.View(store: $0) }
		)
	}
}

// MARK: - AccountPreferences.Section
extension AccountPreferences {
	public struct Section: Identifiable, Equatable {
		public enum Kind: Equatable {
			case personalize
			case ledgerBehaviour
			case development
		}

		public struct Row: Identifiable, Equatable {
			public enum Kind: Equatable, Sendable {
				case accountLabel
				case accountColor
				case tags
				case accountSecurity
				case thirdPartyDeposits
				case devPreferences
			}

			public let id: Kind
			let title: String
			let subtitle: String?
			let icon: AssetIcon.Content
		}

		public let id: Kind
		let title: String
		let rows: IdentifiedArrayOf<Row>
	}
}

extension AccountPreferences.Section.Row {
	public static func accountLabel(_ account: Profile.Network.Account) -> Self {
		.init(
			id: .accountLabel,
			title: "Account Label", // FIXME: strings
			subtitle: account.displayName.rawValue,
			icon: .asset(AssetResource.create)
		)
	}

	static func devAccountPreferneces() -> Self {
		.init(
			id: .devPreferences,
			title: "Dev Preferences", // FIXME: strings
			subtitle: nil,
			icon: .asset(AssetResource.appSettings)
		)
	}

	// TODO: Pass the deposit mode
	static func thirdPartyDeposits() -> Self {
		.init(
			id: .thirdPartyDeposits,
			title: "Third-Party Deposits", // FIXME: strings
			subtitle: "Accept all deposits", // FIXME: strings
			icon: .asset(AssetResource.iconAcceptAirdrop)
		)
	}
}
