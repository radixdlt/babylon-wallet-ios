import Prelude
import SwiftUI

// MARK: - DAppPlaceholder
// TODO: • Determine large size values and make constant

public struct DAppPlaceholder: View {
	private let size: HitTargetSize

	public init(size hitTargetSize: HitTargetSize = .small) {
		self.size = hitTargetSize
	}

	public var body: some View {
		RoundedRectangle(cornerRadius: size.cornerRadius)
			.fill(.app.gray4)
			.frame(size)
	}
}

// MARK: - TokenPlaceholder
public struct TokenPlaceholder: View {
	private let size: HitTargetSize

	public init(size hitTargetSize: HitTargetSize = .small) {
		self.size = hitTargetSize
	}

	public var body: some View {
		Circle()
			.fill(.app.gray4)
			.frame(size)
	}
}

// MARK: - NFTPlaceholder
public struct NFTPlaceholder: View {
	private let size: HitTargetSize

	public init(size hitTargetSize: HitTargetSize = .small) {
		self.size = hitTargetSize
	}

	public var body: some View {
		Rectangle()
			.fill(.app.green2)
			.frame(size)
	}
}

// MARK: - DAppPlaceholder_Previews
struct DAppPlaceholder_Previews: PreviewProvider {
	static var previews: some View {
		DAppPlaceholder()
	}
}
