import SwiftUI

// MARK: - Separator
public struct Separator: View {
	public init() {}

	public var body: some View {
		Rectangle()
			.foregroundColor(.app.gray5)
			.frame(height: 1)
	}
}

// MARK: - Separator_Previews
struct Separator_Previews: PreviewProvider {
	static var previews: some View {
		Separator()
	}
}
