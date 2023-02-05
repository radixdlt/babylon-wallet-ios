import Resources
import SwiftUI

// MARK: - CloseButton
public struct CloseButton: View {
	let action: () -> Void

	public init(action: @escaping () -> Void) {
		self.action = action
	}
}

public extension CloseButton {
	var body: some View {
		Button(action: action) {
			Image(asset: AssetResource.close).renderingMode(.original)
		}
		.frame(.small)
	}
}

// MARK: - CloseButton_Previews
struct CloseButton_Previews: PreviewProvider {
	static var previews: some View {
		CloseButton {}
	}
}
