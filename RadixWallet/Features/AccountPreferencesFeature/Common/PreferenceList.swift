import ComposableArchitecture
import SwiftUI

// MARK: - PreferenceSection
struct PreferenceSection<SectionId: Hashable, RowId: Hashable>: View {
	struct Row: Equatable {
		var id: RowId
		let rowCoreViewState: PlainListRowCore.ViewState
		let hint: String?
		let icon: AssetIcon.Content?

		init(
			id: RowId,
			title: String,
			subtitle: String? = nil,
			hint: String? = nil,
			icon: AssetIcon.Content? = nil
		) {
			self.id = id
			self.rowCoreViewState = .init(title: title, subtitle: subtitle)
			self.hint = hint
			self.icon = icon
		}
	}

	enum Mode: Equatable {
		typealias SelectedRow = RowId
		case selection(SelectedRow)
		case disclosure
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
				PlainListRow(viewState: .init(
					rowCoreViewState: row.rowCoreViewState,
					hints: hints(for: row),
					accessory: { accesory(for: row) },
					icon: {
						if let icon = row.icon {
							AssetIcon(icon)
						}
					}
				))
				.contentShape(Rectangle())
				.tappable {
					onRowSelected(viewState.id, row.id)
				}
				.listRowInsets(EdgeInsets())
			}
		} header: {
			if let title = viewState.title {
				Text(title)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray2)
					.listRowInsets(.init(top: .small1, leading: .medium3, bottom: .medium3, trailing: .medium3))
			}
		} footer: {
			Rectangle().fill().frame(height: 0)
				.listRowInsets(EdgeInsets())
		}
		.listSectionSeparator(.hidden)
		.textCase(nil)
	}

	private func accesory(for row: Row) -> some SwiftUI.View {
		Group {
			if case let .selection(selection) = viewState.mode {
				if row.id == selection {
					Image(asset: AssetResource.check)
				} else {
					/// Put a placeholder for unselected items.
					FixedSpacer(width: .medium1)
				}
			} else {
				Image(asset: AssetResource.chevronRight)
			}
		}
	}

	private func hints(for row: Row) -> [Hint.ViewState] {
		guard let hint = row.hint else {
			return []
		}
		return [.init(kind: .detail, text: hint)]
	}
}

// MARK: - PreferencesList
struct PreferencesList<SectionId: Hashable, RowId: Hashable, Header: View, Footer: View>: View {
	struct ViewState: Equatable {
		let sections: [PreferenceSection<SectionId, RowId>.ViewState]
	}

	let viewState: ViewState

	var onRowSelected: (SectionId, RowId) -> Void
	let header: Header
	let footer: Footer

	init(
		viewState: ViewState,
		onRowSelected: @escaping (SectionId, RowId) -> Void,
		@ViewBuilder header: () -> Header = { EmptyView() },
		@ViewBuilder footer: () -> Footer = { EmptyView() }
	) {
		self.viewState = viewState
		self.onRowSelected = onRowSelected
		self.header = header()
		self.footer = footer()
	}

	var body: some View {
		List {
			section(for: header)

			ForEach(viewState.sections, id: \.id) { section in
				PreferenceSection(viewState: section, onRowSelected: onRowSelected)
			}

			section(for: footer)
		}
		.scrollContentBackground(.hidden)
		.listStyle(.grouped)
		.environment(\.defaultMinListHeaderHeight, 0)
	}

	private func section(for content: some View) -> some View {
		Section {
			content
		} header: {
			Rectangle().frame(height: 0)
		} footer: {
			Rectangle().frame(height: 0)
		}
		.listRowSeparator(.hidden)
		.listRowBackground(Color.clear)
		.listRowInsets(EdgeInsets(top: .small2, leading: .medium3, bottom: .zero, trailing: .medium3))
	}
}
