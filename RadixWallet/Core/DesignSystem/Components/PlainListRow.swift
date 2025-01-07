// MARK: - PlainListRow
struct PlainListRow<Icon: View, Accessory: View>: View {
	struct ViewState {
		let accessory: Accessory?
		let rowCoreViewState: PlainListRowCore.ViewState
		let icon: Icon?
		let hints: [Hint.ViewState]

		init(
			rowCoreViewState: PlainListRowCore.ViewState,
			hints: [Hint.ViewState] = [],
			@ViewBuilder accessory: () -> Accessory,
			@ViewBuilder icon: () -> Icon
		) {
			self.rowCoreViewState = rowCoreViewState
			self.hints = hints
			self.accessory = accessory()
			self.icon = icon()
		}

		init(
			rowCoreViewState: PlainListRowCore.ViewState,
			accessory: ImageResource? = .chevronRight,
			hints: [Hint.ViewState] = [],
			@ViewBuilder icon: () -> Icon
		) where Accessory == Image {
			self.accessory = accessory.map { Image($0) }
			self.rowCoreViewState = rowCoreViewState
			self.icon = icon()
			self.hints = hints
		}

		init(
			_ content: AssetIcon.Content?,
			rowCoreViewState: PlainListRowCore.ViewState,
			accessory: ImageResource? = .chevronRight,
			hints: [Hint.ViewState]
		) where Icon == AssetIcon, Accessory == Image {
			self.accessory = accessory.map { Image($0) }
			self.rowCoreViewState = rowCoreViewState
			self.icon = content.map { AssetIcon($0) }
			self.hints = hints
		}
	}

	let viewState: ViewState

	init(
		viewState: ViewState
	) {
		self.viewState = viewState
	}

	init(
		context: PlainListRowCore.ViewState.Context = .settings,
		title: String?,
		subtitle: String? = nil,
		accessory: ImageResource? = .chevronRight,
		@ViewBuilder icon: () -> Icon
	) where Accessory == Image {
		self.viewState = ViewState(rowCoreViewState: .init(context: context, title: title, subtitle: subtitle), accessory: accessory, icon: icon)
	}

	init(
		context: PlainListRowCore.ViewState.Context = .settings,
		title: String?,
		subtitle: String? = nil,
		@ViewBuilder accessory: () -> Accessory
	) where Icon == EmptyView {
		self.viewState = ViewState(rowCoreViewState: .init(context: context, title: title, subtitle: subtitle), accessory: accessory, icon: { EmptyView() })
	}

	var body: some View {
		VStack(alignment: .leading, spacing: .small1) {
			top
			hints
		}
		.applyIf(viewState.rowCoreViewState.shouldTintAsError) {
			$0.foregroundStyle(Color.app.error)
		}
		.padding(.vertical, viewState.rowCoreViewState.verticalPadding)
		.padding(.horizontal, viewState.rowCoreViewState.horizontalPadding)
		.frame(minHeight: .plainListRowMinHeight)
		.contentShape(Rectangle())
	}

	private var top: some View {
		HStack(spacing: .zero) {
			iconView
			PlainListRowCore(viewState: viewState.rowCoreViewState)
			Spacer(minLength: 0)
			accessoryView
		}
	}

	@ViewBuilder
	private var hints: some View {
		if !viewState.hints.isEmpty {
			HStack(spacing: .zero) {
				iconView
					.hidden() // to leave the same leading padding than on top view

				VStack(alignment: .leading, spacing: .small1) {
					ForEach(Array(viewState.hints.enumerated()), id: \.offset) { _, hint in
						Hint(viewState: hint)
					}
				}

				accessoryView
					.hidden() // to leave the same trailing padding than on top view
			}
		}
	}

	@ViewBuilder
	private var iconView: some View {
		if let icon = viewState.icon {
			icon
				.padding(.trailing, .medium3)
		}
	}

	@ViewBuilder
	private var accessoryView: some View {
		if let accessory = viewState.accessory {
			accessory
		}
	}
}

// MARK: - PlainListRowCore
struct PlainListRowCore: View {
	struct ViewState: Equatable {
		let context: Context
		let title: String?
		let subtitle: String?
		let detail: String?
		let markdown: String?

		init(
			context: Context = .settings,
			title: String?,
			subtitle: String? = nil,
			detail: String? = nil,
			markdown: String? = nil
		) {
			self.context = context
			self.title = title
			self.subtitle = subtitle
			self.detail = detail
			self.markdown = markdown
		}
	}

	let viewState: ViewState

	init(viewState: ViewState) {
		self.viewState = viewState
	}

	init(context: ViewState.Context = .settings, title: String?, subtitle: String?) {
		self.viewState = ViewState(context: context, title: title, subtitle: subtitle)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: .zero) {
			if let title = viewState.title {
				Text(title)
					.lineSpacing(-6)
					.lineLimit(viewState.titleLineLimit)
					.textStyle(viewState.titleTextStyle)
					.foregroundColor(viewState.titleForegroundColor)
			}

			if let subtitle = viewState.subtitle {
				Text(subtitle)
					.lineSpacing(-4)
					.lineLimit(viewState.subtitleLineLimit)
					.minimumScaleFactor(0.8)
					.textStyle(viewState.subtitleTextStyle)
					.foregroundColor(viewState.subtitleForegroundColor)
			}

			if let detail = viewState.detail {
				Text(detail)
					.textStyle(.body2Regular)
					.lineLimit(1)
					.minimumScaleFactor(0.8)
					.foregroundColor(.app.gray2)
					.padding(.top, .small3)
			}

			if let markdown = viewState.markdown {
				Text(markdown: markdown, emphasizedColor: .app.gray2, emphasizedFont: .app.body1Header)
					.textStyle(.body1Regular)
					.lineLimit(1)
					.minimumScaleFactor(0.8)
					.foregroundStyle(.app.gray2)
					.padding(.top, .small3)
			}
		}
	}
}

private extension PlainListRowCore.ViewState {
	var titleTextStyle: TextStyle {
		switch context {
		case .toggle, .settings, .dappAndPersona, .compactPersona:
			.body1Header
		case .hiddenPersona:
			.body1HighImportance
		}
	}

	var subtitleTextStyle: TextStyle {
		switch context {
		case .toggle, .hiddenPersona:
			.body2Regular
		case .settings, .dappAndPersona, .compactPersona:
			detail == nil ? .body1Regular : .body2Regular
		}
	}

	var titleForegroundColor: Color {
		switch context {
		case .toggle, .hiddenPersona, .settings(isError: false), .dappAndPersona, .compactPersona:
			.app.gray1
		case .settings(isError: true):
			.app.error
		}
	}

	var subtitleForegroundColor: Color {
		switch context {
		case .toggle, .hiddenPersona:
			.app.gray2
		case .settings(isError: false), .dappAndPersona, .compactPersona:
			.app.gray1
		case .settings(isError: true):
			.app.error
		}
	}

	var titleLineLimit: Int? {
		switch context {
		case .settings, .dappAndPersona, .hiddenPersona, .compactPersona:
			1
		case .toggle:
			nil
		}
	}

	var subtitleLineLimit: Int {
		switch context {
		case .toggle, .hiddenPersona, .compactPersona:
			2
		case .settings, .dappAndPersona:
			3
		}
	}

	var verticalPadding: CGFloat {
		switch context {
		case .toggle:
			.zero
		case .settings:
			.medium1
		case .dappAndPersona, .hiddenPersona:
			.medium3
		case .compactPersona:
			.small1
		}
	}

	var horizontalPadding: CGFloat {
		switch context {
		case .toggle, .settings, .hiddenPersona, .compactPersona:
			.medium3
		case .dappAndPersona:
			.medium1
		}
	}

	var shouldTintAsError: Bool {
		switch context {
		case .settings(isError: true):
			true
		default:
			false
		}
	}
}

// MARK: - PlainListRowCore.ViewState.Context
extension PlainListRowCore.ViewState {
	enum Context: Equatable {
		case settings(isError: Bool)
		case toggle
		case dappAndPersona
		case hiddenPersona
		case compactPersona

		static var settings: Self {
			.settings(isError: false)
		}
	}
}

extension PlainListRow {
	func tappable(_ action: @escaping () -> Void) -> some View {
		Button(action: action) {
			self
		}
		.buttonStyle(.tappableRowStyle)
	}
}

extension View {
	/// Adds a separator below the view, without padding. The separator has horizontal padding of default size.
	var withSeparator: some View {
		withSeparator()
	}

	/// Adds a separator below the view, without padding. The separator has horizontal padding of of the provided size.
	func withSeparator(horizontalPadding: CGFloat = .medium3) -> some View {
		VStack(spacing: .zero) {
			self
			Separator()
				.padding(.horizontal, horizontalPadding)
		}
	}

	func tappable(_ action: @escaping () -> Void) -> some View {
		Button(action: action) {
			self
		}
	}
}
