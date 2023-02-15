import SwiftUI

// MARK: - PersonaThumbnail
public struct PersonaThumbnail: View {
	let url: URL

	public init(_ url: URL) {
		self.url = url
	}

	public var body: some View {
		ZStack {
			Rectangle()
				.fill(.blue)
				.clipShape(Circle())
			Circle()
				.stroke(.app.gray3, lineWidth: 1)
		}
		.frame(.small)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct PersonaThumbnail_Previews: PreviewProvider {
	static var previews: some View {
		PersonaThumbnail(.trashDirectory)
	}
}
#endif
