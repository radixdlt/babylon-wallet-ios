import FeaturePrelude

// MARK: - PreferenceSection
struct PreferenceSection<SectionId: Hashable, RowId: Hashable>: View {
	struct Row: Equatable {
		var id: RowId
		let title: String
		let subtitle: String?
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
			self.title = title
			self.subtitle = subtitle
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
				HStack {
					VStack(alignment: .leading) {
						HStack(spacing: .medium3) {
							if let icon = row.icon {
								AssetIcon(icon)
							}
							PlainListRowCore(title: row.title, subtitle: row.subtitle)
						}

						if let hint = row.hint {
							// Align hint with the PlainListRowCore
							Text(hint)
								.textStyle(.body2Regular)
								.foregroundColor(.app.alert)
								.lineSpacing(-4)
								.padding(.leading, HitTargetSize.verySmall.frame.width + .medium3)
								.padding(.top, .medium3)
						}
					}
					.padding(.vertical, .small1)
					.frame(minHeight: .settingsRowHeight)

					Spacer(minLength: 0)

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
				.padding(.horizontal, .medium3)
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
		.scrollContentBackground(.hidden)
		.listStyle(.grouped)
		.environment(\.defaultMinListHeaderHeight, 0)
	}
}
