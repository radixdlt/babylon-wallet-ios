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
		Image(isChecked ? "checkmark-selected" : "checkmark-unselected")
			.padding(.leading, .small1)
	}
}

// MARK: - CheckmarkView_Previews
struct CheckmarkView_Previews: PreviewProvider {
	static var previews: some View {
		CheckmarkView(isChecked: true)
	}
}
