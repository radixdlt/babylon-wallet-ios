import Resources
import SwiftUI

// MARK: - RadixButton
public struct RadixButton: View {
	private let text: String
	private let style: Style
	private let action: () -> Void

	/// The standard gray Radix button
	public init(_ text: String, action: @escaping () -> Void) {
		self.text = text
		self.style = .standard
		self.action = action
	}

	/// A destructive Radix button
	public init(destructive text: String, action: @escaping () -> Void) {
		self.text = text
		self.style = .destructive
		self.action = action
	}

	/// An account button with the given address and gradient
	public init(_ accountName: String, account: String, gradient: Gradient, action: @escaping () -> Void) {
		self.text = accountName
		self.style = .account(account, gradient)
		self.action = action
	}

	public var body: some View {
		Button(action: action) {
			content
				.frame(height: .standardButtonHeight)
				.frame(maxWidth: .infinity)
				.background(background)
				.clipShape(.radixButton)
		}
	}

	@ViewBuilder
	private var content: some View {
		switch style {
		case .standard, .destructive:
			mainText
		case let .account(account, _):
			HStack(spacing: 0) {
				mainText
				Spacer(minLength: 0)
				Text(account.formatted(.short))
					.textStyle(.body2HighImportance)
					.foregroundColor(foregroundColor.opacity(0.8))
			}
			.padding(.horizontal, .large2)
		}
	}

	private var mainText: some View {
		Text(text)
			.textStyle(.body1Header)
			.foregroundColor(foregroundColor)
	}

	private var foregroundColor: Color {
		switch style {
		case .standard:
			return .app.gray1
		case .destructive, .account:
			return .white
		}
	}

	@ViewBuilder
	private var background: some View {
		switch style {
		case .standard:
			Color.app.gray4
		case .destructive:
			Color.app.red1
		case let .account(_, gradient):
			LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
		}
	}

	private enum Style: Equatable {
		case standard
		case destructive
		case account(String, Gradient)
	}
}

extension Shape where Self == RoundedRectangle {
	static var radixButton: Self {
		RoundedRectangle(cornerRadius: .small1, style: .continuous)
	}
}
