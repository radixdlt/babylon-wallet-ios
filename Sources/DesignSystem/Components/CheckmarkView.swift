import SwiftUI

import SwiftUI

// MARK: - CheckmarkView
public struct CheckmarkView: View {
	public var isChecked: Bool

	public init(isChecked: Bool) {
		self.isChecked = isChecked
	}
}

public extension CheckmarkView {
	var body: some View {
		// TODO: replace with checkmark images when given export permission from Figma
		RoundedRectangle(cornerRadius: 2)
			.fill(isChecked ? Color.green : Color.gray)
			.frame(width: 20, height: 20)
	}
}

// MARK: - CheckmarkView_Previews
struct CheckmarkView_Previews: PreviewProvider {
	static var previews: some View {
		CheckmarkView(isChecked: true)
	}
}
