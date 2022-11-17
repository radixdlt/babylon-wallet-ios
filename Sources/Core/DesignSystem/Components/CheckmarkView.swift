import Resources
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
		Image(asset: isChecked ? AssetResource.checkmarkSelected : AssetResource.checkmarkUnselected)
			.padding(.leading, .small1)
	}
}

// MARK: - CheckmarkView_Previews
struct CheckmarkView_Previews: PreviewProvider {
	static var previews: some View {
		CheckmarkView(isChecked: true)
	}
}
