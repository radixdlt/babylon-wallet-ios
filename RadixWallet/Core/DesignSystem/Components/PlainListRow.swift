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
		_ content: AssetIcon.Content?,
		title: String?,
		subtitle: String? = nil,
		accessory: ImageResource? = .chevronRight
	) where Icon == AssetIcon, Accessory == Image {
		self.viewState = ViewState(content, rowCoreViewState: .init(title: title, subtitle: subtitle), accessory: accessory, hints: [])
	}

	var body: some View {
		VStack(alignment: .leading, spacing: .small1) {
			top
			hints
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

		init(
			context: Context = .settings,
			title: String?,
			subtitle: String? = nil,
			detail: String? = nil
		) {
			self.context = context
			self.title = title
			self.subtitle = subtitle
			self.detail = detail
		}
	}

	let viewState: ViewState

	init(
		viewState: ViewState
	) {
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
					.foregroundColor(.app.gray1)
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
		}
	}
}

private extension PlainListRowCore.ViewState {
	var titleTextStyle: TextStyle {
		switch context {
		case .toggle:
			.secondaryHeader
		case .settings, .dappAndPersona:
			.body1Header
		}
	}

	var subtitleTextStyle: TextStyle {
		switch context {
		case .toggle:
			.body2Regular
		case .settings, .dappAndPersona:
			detail == nil ? .body1Regular : .body2Regular
		}
	}

	var subtitleForegroundColor: Color {
		switch context {
		case .toggle:
			.app.gray2
		case .settings, .dappAndPersona:
			.app.gray1
		}
	}

	var titleLineLimit: Int? {
		switch context {
		case .settings, .dappAndPersona:
			1
		case .toggle:
			nil
		}
	}

	var subtitleLineLimit: Int {
		switch context {
		case .toggle:
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
		case .dappAndPersona:
			.medium3
		}
	}

	var horizontalPadding: CGFloat {
		switch context {
		case .toggle, .settings:
			.medium3
		case .dappAndPersona:
			.medium1
		}
	}
}

// MARK: - PlainListRowCore.ViewState.Context
extension PlainListRowCore.ViewState {
	enum Context {
		case settings
		case toggle
		case dappAndPersona
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
