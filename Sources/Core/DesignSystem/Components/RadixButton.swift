import Resources
import SwiftUI

// MARK: - RadixButton
public struct RadixButton<Background: View>: View {
	private let text: String
	private let secondaryText: String?
	private let textColor: Color
	private let background: Background
	private let action: () -> Void

	/// The standard gray Radix button
	public init(_ text: String, action: @escaping () -> Void) where Background == Color {
		self.text = text
		self.secondaryText = nil
		self.textColor = .app.gray1
		self.background = Color.app.gray4
		self.action = action
	}

	/// A destructive Radix button
	public init(destructive text: String, action: @escaping () -> Void) where Background == Color {
		self.text = text
		self.secondaryText = nil
		self.textColor = .white
		self.background = Color.app.red1
		self.action = action
	}

	/// An account button with the given address and gradient
	public init(_ accountName: String, account: String, gradient: Gradient, action: @escaping () -> Void) where Background == LinearGradient {
		self.text = accountName
		self.secondaryText = account
		self.textColor = .white
		self.background = LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
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
		if let secondaryText {
			HStack(spacing: 0) {
				mainText
				Spacer(minLength: 0)
				Text(secondaryText.formatted(.short))
					.textStyle(.body2HighImportance)
					.foregroundColor(textColor.opacity(0.8))
			}
			.padding(.horizontal, .large2)
		} else {
			mainText
		}
	}

	private var mainText: some View {
		Text(text)
			.textStyle(.body1Header)
			.foregroundColor(textColor)
	}
}

extension Shape where Self == RoundedRectangle {
	static var radixButton: Self {
		RoundedRectangle(cornerRadius: .small1, style: .continuous)
	}
}
