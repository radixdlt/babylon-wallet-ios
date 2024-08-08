// MARK: - CloseButtonBar
public struct CloseButtonBar: View {
	let action: () -> Void

	public init(action: @escaping () -> Void) {
		self.action = action
	}

	public var body: some View {
		HStack {
			Spacer()
			CloseButton(action: action)
				.padding(.small2)
		}
	}
}

// MARK: - CloseButton
public struct CloseButton: View {
	let kind: Kind
	let action: () -> Void

	public init(kind: Kind = .toolbar, action: @escaping () -> Void) {
		self.kind = kind
		self.action = action
	}

	public var body: some View {
		Button(action: action) {
			Image(.close)
				.resizable()
				.frame(kind.size)
				.foregroundColor(nil)
				.tint(kind.tint)
				.padding(kind.padding)
		}
		.frame(.small, alignment: kind.alignment)
	}
}

// MARK: CloseButton.Kind
extension CloseButton {
	public enum Kind {
		case toolbar
		case homeCard

		var size: CGFloat {
			switch self {
			case .toolbar: .medium1
			case .homeCard: .medium3
			}
		}

		var tint: Color {
			switch self {
			case .toolbar: .app.gray1
			case .homeCard: .app.gray2
			}
		}

		var padding: CGFloat {
			switch self {
			case .toolbar: .zero
			case .homeCard: .small2
			}
		}

		var alignment: Alignment {
			switch self {
			case .toolbar: .leading
			case .homeCard: .topTrailing
			}
		}
	}
}

// MARK: - CloseButton_Previews
struct CloseButton_Previews: PreviewProvider {
	static var previews: some View {
		CloseButton {}
			.previewLayout(.sizeThatFits)
	}
}
