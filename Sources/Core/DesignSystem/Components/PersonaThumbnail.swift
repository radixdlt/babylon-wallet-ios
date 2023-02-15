import SwiftUI

// MARK: - PersonaThumbnail
public struct PersonaThumbnail: View {
	let url: URL
	let size: HitTargetSize

	public init(_ url: URL, size: HitTargetSize = .small) {
		self.url = url
		self.size = size
	}

	public var body: some View {
		ZStack {
			Rectangle()
				.fill(.blue)
				.clipShape(Circle())
			Circle()
				.stroke(.app.gray3, lineWidth: 1)
		}
		.frame(size)
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
