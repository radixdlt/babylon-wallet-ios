import Resources
import SwiftUI

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
	let action: () -> Void

	public init(action: @escaping () -> Void) {
		self.action = action
	}
}

extension CloseButton {
	public var body: some View {
		Button(action: action) {
			Image(asset: AssetResource.close).tint(.app.gray1)
		}
		.frame(.small)
	}
}

// MARK: - CloseButton_Previews
struct CloseButton_Previews: PreviewProvider {
	static var previews: some View {
		CloseButton {}
			.previewLayout(.sizeThatFits)
	}
}
