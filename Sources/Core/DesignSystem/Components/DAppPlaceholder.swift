import Prelude
import Resources
import SwiftUI

// MARK: - DappPlaceholder
public struct DappPlaceholder: View {
	private let size: HitTargetSize
	private let known: Bool

	public init(known: Bool = true, size hitTargetSize: HitTargetSize = .small) {
		self.known = known
		self.size = hitTargetSize
	}

	// TODO: Show different icon if known
	public var body: some View {
		Image(asset: AssetResource.iconUnknownComponent)
			.resizable()
			.cornerRadius(size.cornerRadius)
			.frame(size)
	}
}

// MARK: - TokenPlaceholder
public struct TokenPlaceholder: View {
	private let size: HitTargetSize
	private let known: Bool
	private let isXRD: Bool

	public init(known: Bool = true, isXRD: Bool = false, size hitTargetSize: HitTargetSize = .small) {
		self.known = known
		self.isXRD = isXRD
		self.size = hitTargetSize
	}

	// TODO: Show different icon if known
	public var body: some View {
		Image(asset: isXRD ? AssetResource.xrd : AssetResource.fungibleToken)
			.resizable()
			.clipShape(Circle())
			.frame(size)
	}
}

// MARK: - NFTPlaceholder
public struct NFTPlaceholder: View {
	private let size: HitTargetSize
	private let known: Bool

	public init(known: Bool = true, size hitTargetSize: HitTargetSize = .small) {
		self.known = known
		self.size = hitTargetSize
	}

	// TODO: Implement. Show different icon if known
	public var body: some View {
		DappPlaceholder(known: known, size: size)
	}
}

// MARK: - DappPlaceholder_Previews
struct DappPlaceholder_Previews: PreviewProvider {
	static var previews: some View {
		DappPlaceholder()
	}
}

// MARK: - PersonaPlaceholder
public struct PersonaPlaceholder: View {
	let size: HitTargetSize

	public init(size: HitTargetSize = .small) {
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
