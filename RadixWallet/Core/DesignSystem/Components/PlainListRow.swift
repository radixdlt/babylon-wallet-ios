// MARK: - PlainListRow
public struct PlainListRow<Icon: View>: View {
	public struct ViewState {
		let accessory: ImageAsset?
		let rowCoreViewState: PlainListRowCore.ViewState
		let icon: Icon?

		public init(
			rowCoreViewState: PlainListRowCore.ViewState,
			accessory: ImageAsset? = AssetResource.chevronRight,
			@ViewBuilder icon: () -> Icon
		) {
			self.accessory = accessory
			self.rowCoreViewState = rowCoreViewState
			self.icon = icon()
		}

		public init(
			_ content: AssetIcon.Content?,
			rowCoreViewState: PlainListRowCore.ViewState,
			accessory: ImageAsset? = AssetResource.chevronRight
		) where Icon == AssetIcon {
			self.accessory = accessory
			self.rowCoreViewState = rowCoreViewState
			self.icon = content.map { AssetIcon($0) }
		}
	}

	public let viewState: ViewState

	public init(
		viewState: ViewState
	) {
		self.viewState = viewState
	}

	public init(
		title: String?,
		subtitle: String? = nil,
		accessory: ImageAsset? = AssetResource.chevronRight,
		@ViewBuilder icon: () -> Icon
	) {
		self.viewState = ViewState(rowCoreViewState: .init(title: title, subtitle: subtitle), accessory: accessory, icon: icon)
	}

	public init(
		_ content: AssetIcon.Content?,
		title: String?,
		subtitle: String? = nil,
		accessory: ImageAsset? = AssetResource.chevronRight
	) where Icon == AssetIcon {
		self.viewState = ViewState(content, rowCoreViewState: .init(title: title, subtitle: subtitle), accessory: accessory)
	}

	public var body: some View {
		HStack(spacing: .zero) {
			if let icon = viewState.icon {
				icon
					.padding(.trailing, .medium3)
			}

			PlainListRowCore(viewState: viewState.rowCoreViewState)

			Spacer(minLength: 0)

			if let accessory = viewState.accessory {
				Image(asset: accessory)
			}
		}
		.frame(minHeight: .settingsRowHeight)
		.padding(.horizontal, .medium3)
		.contentShape(Rectangle())
	}
}

// MARK: - PlainListRowCore
public struct PlainListRowCore: View {
	public struct ViewState {
		public let kind: Kind
		public let title: String?
		public let subtitle: String?
		public let detail: String?
		public let hint: Hint.ViewState?

		init(
			kind: Kind = .general,
			title: String?,
			subtitle: String? = nil,
			detail: String? = nil,
			hint: Hint.ViewState? = nil
		) {
			self.kind = kind
			self.title = title
			self.subtitle = subtitle
			self.detail = detail
			self.hint = hint
		}
	}

	public let viewState: ViewState

	public init(
		viewState: ViewState
	) {
		self.viewState = viewState
	}

	public init(title: String?, subtitle: String?) {
		self.viewState = ViewState(title: title, subtitle: subtitle)
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: .small3) {
			VStack(alignment: .leading, spacing: .zero) {
				if let title = viewState.title {
					Text(title)
						.lineSpacing(-6)
						.lineLimit(1)
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

			if let hint = viewState.hint {
				Hint(viewState: hint)
			}
		}
		.padding(.vertical, viewState.verticalPadding)
	}
}

private extension PlainListRowCore.ViewState {
	var titleTextStyle: TextStyle {
		switch kind {
		case .general:
			.secondaryHeader
		case .settings:
			.body1Header
		}
	}

	var subtitleTextStyle: TextStyle {
		switch kind {
		case .general:
			.body2Regular
		case .settings:
			detail == nil ? .body1Regular : .body2Regular
		}
	}

	var subtitleForegroundColor: Color {
		switch kind {
		case .general:
			.app.gray2
		case .settings:
			.app.gray1
		}
	}

	var subtitleLineLimit: Int {
		switch kind {
		case .general:
			2
		case .settings:
			3
		}
	}

	var verticalPadding: CGFloat {
		switch kind {
		case .general:
			.zero
		case .settings:
			.medium1
		}
	}
}

// MARK: - PlainListRowCore.ViewState.Kind
extension PlainListRowCore.ViewState {
	public enum Kind {
		case general
		case settings
	}
}

extension PlainListRow {
	public func tappable(_ action: @escaping () -> Void) -> some View {
		Button(action: action) {
			self
		}
		.buttonStyle(.tappableRowStyle)
	}
}

extension View {
	/// Adds a separator below the view, without padding. The separator has horizontal padding of default size.
	public var withSeparator: some View {
		withSeparator()
	}

	/// Adds a separator below the view, without padding. The separator has horizontal padding of of the provided size.
	public func withSeparator(horizontalPadding: CGFloat = .medium3) -> some View {
		VStack(spacing: .zero) {
			self
			Separator()
				.padding(.horizontal, horizontalPadding)
		}
	}

	public func tappable(_ action: @escaping () -> Void) -> some View {
		Button(action: action) {
			self
		}
	}
}

// MARK: - PlainListRow_Previews
struct PlainListRow_Previews: PreviewProvider {
	static var previews: some View {
		PlainListRow(
			viewState: .init(
				.asset(AssetResource.appSettings),
				rowCoreViewState: .init(title: "A title", subtitle: nil)
			)
		)
	}
}
