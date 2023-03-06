import Prelude
import SwiftUI

// MARK: - DappPlaceholder
public struct DappPlaceholder: View {
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
		RoundedRectangle(cornerRadius: size.cornerRadius)
			.fill(.app.green2)
			.frame(size)
	}
}

// MARK: - DappPlaceholder_Previews
struct DappPlaceholder_Previews: PreviewProvider {
	static var previews: some View {
		DappPlaceholder()
	}
}
