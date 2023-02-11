import Foundation

// MARK: - HD.Path.Component
extension HD.Path {
	public enum Component: Hashable, Sendable {
		case root(onlyPublic: Bool)
		case child(Child)
	}
}

extension HD.Path.Component {
	public static let rootPrivateKey = "m"
	public static let rootOnlyPublicKey = "M"

	public enum Error: Swift.Error {
		case expectedRootToBeAtDepthZero
	}

	public static func inferredDepth(string: String) throws -> Self {
		switch string {
		case Self.rootPrivateKey:
			return .root(onlyPublic: false)
		case Self.rootOnlyPublicKey:
			return .root(onlyPublic: true)
		default:
			return .child(try HD.Path.Component.Child(
				depth: HD.Path.Component.Child.Depth.inferred,
				string: string
			))
		}
	}

	public init(depth explicitDepth: Int, string: String) throws {
		switch string {
		case Self.rootPrivateKey:
			guard explicitDepth == 0 else { throw Error.expectedRootToBeAtDepthZero }
			self = .root(onlyPublic: false)
		case Self.rootOnlyPublicKey:
			guard explicitDepth == 0 else { throw Error.expectedRootToBeAtDepthZero }
			self = .root(onlyPublic: true)
		default:
			self = .child(try HD.Path.Component.Child(
				depth: HD.Path.Component.Child.Depth.explicit(Child.Depth.Value(explicitDepth)),
				string: string
			))
		}
	}

	public func toString() -> String {
		switch self {
		case let .child(childComponent): return childComponent.toString()
		case let .root(onlyPublic): return onlyPublic ? Self.rootOnlyPublicKey : Self.rootPrivateKey
		}
	}

	public var isRoot: Bool {
		switch self {
		case .child: return false
		case .root: return true
		}
	}

	public var asChild: Child? {
		switch self {
		case let .child(childComponent): return childComponent
		case .root: return nil
		}
	}
}

// MARK: - HD.Path.Component.Child
extension HD.Path.Component {
	/// One component in an HD Derivation path
	public struct Child: Hashable, Sendable {
		public let depth: Depth
		public let nonHardenedValue: Value
		public let isHardened: Bool

		public init(
			depth: Depth = .inferred,
			nonHardenedValue: Value,
			isHardened: Bool
		) {
			self.depth = depth
			self.nonHardenedValue = nonHardenedValue
			self.isHardened = isHardened
		}

		public init(depth explicitDepth: Child.Depth.Value, value: Child.Value) {
			let isHardened = value > Self.hardenedIncrement
			let nonHardenedValue = isHardened ? value - Self.hardenedIncrement : value
			self.init(depth: .explicit(explicitDepth), nonHardenedValue: nonHardenedValue, isHardened: isHardened)
		}

		public static func harden(_ nonHardenedValue: Value, depth: Depth = .inferred) -> Self {
			.init(depth: depth, nonHardenedValue: nonHardenedValue, isHardened: true)
		}
	}
}

extension HD.Path.Component.Child {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		guard
			lhs.isHardened == rhs.isHardened,
			lhs.nonHardenedValue == rhs.nonHardenedValue
		else { return false }

		switch (lhs.depth, rhs.depth) {
		case (.inferred, .inferred): return true
		case (.inferred, .explicit(_)): return true
		case (.explicit(_), .inferred): return true
		case let (.explicit(lhsDepth), .explicit(rhsDepth)): return lhsDepth == rhsDepth
		}
	}

	public func toString() -> String {
		let intString = nonHardenedValue.description
		guard isHardened else {
			return intString
		}
		return [
			intString,
			Self.canonicalDelimitor,
		].joined(separator: "")
	}

	public enum Depth: Hashable, Sendable {
		public typealias Value = UInt8
		case inferred
		case explicit(Value)

		var asExplicit: Value? {
			switch self {
			case let .explicit(explicit):
				return explicit
			case .inferred:
				return nil
			}
		}
	}

	public typealias Value = UInt32

	public static let hardenedIncrement = Value(1) << 31

	public var value: Value {
		guard isHardened else {
			return nonHardenedValue
		}
		return nonHardenedValue + Self.hardenedIncrement
	}

	public static let canonicalDelimitor = "H"
	public static let acceptedDelimitors = [canonicalDelimitor, "h", "'", "\""]

	public enum Error: Swift.Error {
		case notAnInteger(String)
	}

	public init(depth: Depth, string: String) throws {
		var string = string
		Self.acceptedDelimitors.forEach {
			string = string.replacingOccurrences(of: $0, with: Self.canonicalDelimitor)
		}
		let isHardened = string.hasSuffix(Self.canonicalDelimitor)

		if isHardened {
			string = String(string.dropLast())
		}

		guard let nonHardenedValue = Value(string) else {
			throw Error.notAnInteger(string)
		}

		self.init(depth: depth, nonHardenedValue: nonHardenedValue, isHardened: isHardened)
	}
}
