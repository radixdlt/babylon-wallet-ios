import Resources
import SwiftUI

// MARK: - BackButton
public struct BackButton: View {
	let action: () -> Void

	public init(action: @escaping () -> Void) {
		self.action = action
	}
}

public extension BackButton {
	var body: some View {
		Button(
			action: action,
			label: { Image(asset: Asset.arrowBack) }
		)
		.frame(.small)
	}
}

// MARK: - BackButton_Previews
struct BackButton_Previews: PreviewProvider {
	static var previews: some View {
		BackButton {}
	}
}
