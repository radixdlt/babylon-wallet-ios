import Prelude
import SwiftUI

// MARK: - DAppPlaceholder

// TODO: • Determine large size values and make constant

public struct DAppPlaceholder: View {
	private let size: CGSize
	private let cornerRadius: CGFloat
	
	public init(large: Bool = false) {
		self.size = large ? .init(width: 120, height: 120) : HitTargetSize.small.frame
		self.cornerRadius = large ? .medium3 : .small2
	}
	
	public var body: some View {
		RoundedRectangle(cornerRadius: cornerRadius)
			.fill(.app.gray4)
			.frame(width: size.width, height: size.height)
	}
}

public struct NFTPlaceholder: View {
	public init() {
	}
	
	public var body: some View {
		Rectangle()
			.fill(.app.green2)
			.aspectRatio(1, contentMode: .fill)
	}
}

// MARK: - Previews

struct DAppPlaceholder_Previews: PreviewProvider {
	static var previews: some View {
		DAppPlaceholder()
	}
}
