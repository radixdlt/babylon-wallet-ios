import FeaturePrelude

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
				.listRowInsets(EdgeInsets())
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
