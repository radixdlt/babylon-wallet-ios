import FeaturePrelude

extension ThirdPartyDeposits.State.ThirdPartyDepositMode {
	var toRowId: ThirdPartyDeposits.Section.Row.ID {
		switch self {
		case .acceptAll:
			return .acceptAll
		case .acceptKnown:
			return .acceptKnown
		case .denyAll:
			return .denyAll
		}
	}
}

extension ThirdPartyDeposits.State {
	var viewState: ThirdPartyDeposits.ViewState {
		.init(sections: [
			.init(
				id: .depositsMode,
				title: "Choose if you want to allow third-parties to directly deposit assets into your account. Deposits that you approve yourself in your Radix Wallet are always accepted.",
				rows: [
					.acceptAllMode(),
					.acceptKnownMode(),
					.denyAllMode(),
				],
				mode: .selection(.depositMode(depositMode))
			),
			.init(
				id: .allowDenyAssets,
				title: "",
				rows: [.allowDenyAssets()]
			),
		])
	}
}

extension ThirdPartyDeposits {
	public struct ViewState: Equatable {
		let sections: [PreferenceSection<ThirdPartyDeposits.Section.Kind, ThirdPartyDeposits.State.RowKind>.ViewState]
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<ThirdPartyDeposits>

		init(store: StoreOf<ThirdPartyDeposits>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				PreferencesList(viewState: .init(sections: viewStore.sections), onRowSelected: { _, row in
					viewStore.send(.rowTapped(row))
				})
				.background(.app.gray4)
				.navigationTitle("Third-party Deposits") // FIXME: strings
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
				.toolbarBackground(.app.background, for: .navigationBar)
				.toolbarBackground(.visible, for: .navigationBar)
				.footer {
					//                                        if let selection {
					//                                                Text("Result: \(String(describing: selection))")
					//                                        } else {
					//                                                Text("Result: nil")
					//                                        }
					//                                        WithControlRequirements(selection, forAction: { print($0) }) { action in
					Button("Update", action: {}).buttonStyle(.primaryRectangular)
					//                                        }
				}
			}
		}
	}
}

// MARK: - ThirdPartyDeposits.Section
extension ThirdPartyDeposits {
	public struct Section: Identifiable, Equatable {
		public enum Kind: Equatable {
			case depositsMode
			case allowDenyAssets
		}

		public struct Row: Identifiable, Equatable {
			public enum Kind: Equatable, Sendable {
				case acceptAll
				case acceptKnown
				case denyAll
				case allowDenyAssets
			}

			public let id: Kind
			let title: String
			let subtitle: String?
			let icon: AssetIcon.Content?
			let accessory: ImageAsset?
		}

		public let id: Kind
		let title: String?
		let rows: IdentifiedArrayOf<Row>
	}
}

// MARK: - ThirdPartyDeposits.State.RowKind
extension ThirdPartyDeposits.State {
	public enum RowKind: Hashable {
		case depositMode(ThirdPartyDepositMode)
		case allowDenyResources
	}
}

extension PreferenceSection.Row where SectionId == ThirdPartyDeposits.Section.ID, RowId == ThirdPartyDeposits.State.RowKind {
	static func acceptAllMode() -> Self {
		.init(
			id: .depositMode(.acceptAll),
			title: "Accept All", // FIXME: strings
			subtitle: "Allow third parties to deposit any asset",
			icon: .asset(AssetResource.iconAcceptAirdrop)
		)
	}

	static func acceptKnownMode() -> Self {
		.init(
			id: .depositMode(.acceptKnown),
			title: "Only accept known", // FIXME: strings
			subtitle: "Allow third parties to deposit only assets this account has held",
			icon: .asset(AssetResource.iconAcceptKnownAirdrop)
		)
	}

	static func denyAllMode() -> Self {
		.init(
			id: .depositMode(.denyAll),
			title: "Deny all", // FIXME: strings
			subtitle: "Deny all third parties deposits", // FIXME: strings
			icon: .asset(AssetResource.iconDeclineAirdrop)
		)
	}

	static func allowDenyAssets() -> Self {
		.init(
			id: .allowDenyResources,
			title: "Allow/Deny specific assets", // FIXME: strings
			subtitle: "Deny or allow third-party deposits of specific assets, ignoring the setting above", // FIXME: strings
			icon: nil
		)
	}
}

// MARK: - PreferenceSection
struct PreferenceSection<SectionId: Hashable, RowId: Hashable>: View {
	struct Row: Equatable {
		var id: RowId
		let title: String
		let subtitle: String?
		let icon: AssetIcon.Content?
	}

	enum Mode: Equatable {
		typealias SelectedRow = RowId
		case selection(SelectedRow)
		case disclosure

		func accessory(rowId: RowId) -> ImageAsset? {
			switch self {
			case let .selection(selection):
				return rowId == selection ? AssetResource.check : nil
			case .disclosure:
				return AssetResource.chevronRight
			}
		}
	}

	struct ViewState: Equatable {
		var id: SectionId
		let title: String?
		let rows: [Row]
		let mode: Mode

		init(id: SectionId, title: String?, rows: [Row], mode: Mode = .disclosure) {
			self.id = id
			self.title = title
			self.rows = rows
			self.mode = mode
		}
	}

	let viewState: ViewState

	var onRowSelected: (SectionId, RowId) -> Void

	var body: some View {
		SwiftUI.Section {
			ForEach(viewState.rows, id: \.id) { row in
				PlainListRow(
					row.icon,
					title: row.title,
					subtitle: row.subtitle,
					accessory: viewState.mode.accessory(rowId: row.id)
				)
				.onTapGesture {
					onRowSelected(viewState.id, row.id)
				}
			}
		} header: {
			if let title = viewState.title {
				Text(title)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray2)
			}
		}
		.textCase(nil)
	}
}

// MARK: - PreferencesList
struct PreferencesList<SectionId: Hashable, RowId: Hashable>: View {
	struct ViewState: Equatable {
		let sections: [PreferenceSection<SectionId, RowId>.ViewState]
	}

	let viewState: ViewState

	var onRowSelected: (SectionId, RowId) -> Void

	var body: some View {
		List {
			ForEach(viewState.sections, id: \.id) { section in
				PreferenceSection(viewState: section, onRowSelected: onRowSelected)
			}
		}
		.listStyle(.grouped)
	}
}
