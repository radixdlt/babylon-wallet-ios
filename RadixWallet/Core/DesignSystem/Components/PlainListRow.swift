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
		title: String,
		subtitle: String? = nil,
		accessory: ImageAsset? = AssetResource.chevronRight,
		@ViewBuilder icon: () -> Icon
	) {
		self.viewState = ViewState(rowCoreViewState: .init(title: title, subtitle: subtitle), accessory: accessory, icon: icon)
	}

	public init(
		_ content: AssetIcon.Content?,
		title: String,
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
		public let title: String
		public let subtitle: String?
		public let hint: Hint.ViewState?

		init(
			title: String,
			subtitle: String? = nil,
			hint: Hint.ViewState? = nil
		) {
			self.title = title
			self.subtitle = subtitle
			self.hint = hint
		}
	}

	public let viewState: ViewState

	public init(
		viewState: ViewState
	) {
		self.viewState = viewState
	}

	public init(title: String, subtitle: String?) {
		self.viewState = ViewState(title: title, subtitle: subtitle)
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: .zero) {
			Text(viewState.title)
				.lineSpacing(-6)
				.lineLimit(1)
				.textStyle(.secondaryHeader)
				.foregroundColor(.app.gray1)

			if let subtitle = viewState.subtitle {
				Text(subtitle)
					.lineSpacing(-4)
					.lineLimit(2)
					.minimumScaleFactor(0.8)
					.textStyle(.body2Regular)
					.foregroundColor(.app.gray2)
			}

			if let hint = viewState.hint {
				Hint(viewState: hint)
					.padding(.top, .small3)
			}
		}
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
