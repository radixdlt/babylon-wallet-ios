import Foundation

// MARK: - HD.Path
public extension HD {
	/// A BIP32 derivation, either full or relative
	enum Path: HDPathConvertible, Hashable, Sendable {
		case full(Full)
		case relative(Relative)
	}
}

public extension HD.Path {
	func depth() throws -> Component.Child.Depth.Value {
		switch self {
		case let .relative(relativePath):
			return try relativePath.depth()
		case let .full(fullPath):
			return try fullPath.depth()
		}
	}

	var components: [Component] {
		switch self {
		case let .relative(relative): return relative.components
		case let .full(full): return full.components
		}
	}

	func toString() -> String {
		switch self {
		case let .relative(relative): return relative.toString()
		case let .full(full): return full.toString()
		}
	}

	init(components: [Component]) throws {
		do {
			let full = try Full(components: components)
			self = .full(full)
		} catch {
			let relative = try HD.Path.Relative(components: components)
			self = .relative(relative)
		}
	}

	init(string: String) throws {
		do {
			let full = try Full(string: string)
			self = .full(full)
		} catch {
			let relative = try HD.Path.Relative(string: string)
			self = .relative(relative)
		}
	}
}

// MARK: - HDPathConvertible
public protocol HDPathConvertible {
	var components: [HD.Path.Component] { get }
	func depth() throws -> HD.Path.Component.Child.Depth.Value
	init(components: [HD.Path.Component]) throws
	init(string: String) throws

	func toString() -> String
}

public extension HDPathConvertible {
	func appending(child: HD.Path.Component.Child) throws -> Self {
		var children = self.components
		children.append(HD.Path.Component.child(child))
		return try Self(components: children)
	}
}

public extension HD.Path {
	static func validate(components: [Component]) throws -> [Component] {
		guard components.count > 1 else { return components }
		let children = components.compactMap(\.asChild)

		var depthOfLast: Component.Child.Depth.Value = 0

		for child in children {
			switch child.depth {
			case let .explicit(explicitDepth):
				guard explicitDepth == depthOfLast + 1 else {
					throw Error.incorrectDepthOfComponentInPath
				}
				depthOfLast = explicitDepth
			case .inferred:
				depthOfLast += 1
			}
		}
		return components
	}

	struct Relative: Hashable, Sendable, HDPathConvertible {
		public let components: [Component]
		public init(components: [Component]) throws {
			guard !components.isEmpty else {
				throw Error.cannotBeEmpty
			}
			guard components.allSatisfy({ !$0.isRoot }) else {
				throw Error.relativePathCannotContainRoot
			}
			self.components = try HD.Path.validate(components: components)
		}

		public init(string: String) throws {
			let stringComponents = string.split(separator: HD.Path.delimitor).map {
				String($0)
			}

			let components = try stringComponents
				.map {
					try HD.Path.Component.inferredDepth(string: $0)
				}

			try self.init(components: components)
		}

		public func depth() throws -> HD.Path.Component.Child.Depth.Value {
			let last = self.components.last!.asChild! // `components` cannot be empty and does not contain `root`, only `child`, so force unwrap is safe
			switch last.depth {
			case .inferred:
				guard
					let indexOfFirstExplicit = self.components
					.firstIndex(where: { component in
						guard let child = component.asChild else {
							return false
						}
						return child.depth.asExplicit != nil
					})
				else {
//					return HD.Path.Component.Child.Depth.Value(self.components.count)
					throw Error.unableToInferDepth
				}

				let firstExplicit: Component = self.components[indexOfFirstExplicit]
				let depthOfFirstExplicit = firstExplicit.asChild!.depth.asExplicit! // safe to force unwrap, since we have search for it above
				let numberOfComponentsAfter = HD.Path.Component.Child.Depth.Value(self.components.count - 1 - indexOfFirstExplicit)
				let depth = depthOfFirstExplicit + numberOfComponentsAfter
				return depth
			case let .explicit(explicitDepth):
				return explicitDepth
			}
		}
	}

	enum Error: Swift.Error, Equatable {
		case cannotBeEmpty
		case pathMustStartWithRoot
		case relativePathCannotContainRoot
		case foundMultipleRootsInPath
		case incorrectDepthOfComponentInPath
		case unableToInferDepth
	}

	/// A full BIP32 derivation path
	struct Full: Hashable, Sendable, HDPathConvertible {
		public var onlyPublic: Bool {
			switch components[0] {
			case let .root(onlyPublic): return onlyPublic
			case .child: fatalError("A child component does not contain information about wether the root specifies only public or not.")
			}
		}

		public let components: [Component]

		var relativeRoot: Relative? {
			let remainingComponents = [Component](components.dropFirst())
			guard !remainingComponents.isEmpty else {
				return nil
			}
			return try! Relative(components: remainingComponents)
		}

		public init(children: [Component.Child], onlyPublic: Bool) throws {
			try self.init(components: [.root(onlyPublic: onlyPublic)] + children.map { Component.child($0) })
		}

		public init(components: [Component]) throws {
			guard let first = components.first else {
				throw Error.cannotBeEmpty
			}
			guard case .root = first else {
				throw Error.pathMustStartWithRoot
			}

			guard components.compactMap(\.asChild).count == components.count - 1 else {
				throw Error.foundMultipleRootsInPath
			}

			self.components = try HD.Path.validate(components: components)
		}

		public static func root(onlyPublic: Bool) -> Self { try! Self(components: [.root(onlyPublic: onlyPublic)]) }

		public init(string: String) throws {
			let stringComponents = string.split(separator: HD.Path.delimitor).map {
				String($0)
			}

			let components = try stringComponents
				.enumerated()
				.map(HD.Path.Component.init)

			try self.init(components: components)
		}

		public func depth() throws -> HD.Path.Component.Child.Depth.Value {
			let last = self.components.last!
			switch last {
			case let .child(childComponent):
				let depth = childComponent.depth
				switch depth {
				case let .explicit(explicitDepth):
					assert(explicitDepth == components.count - 1)
					return explicitDepth
				case .inferred:
					return HD.Path.Component.Child.Depth.Value(components.count) - 1
				}
			case .root:
				assert(components.count == 1)
				return 0
			}
		}
	}
}

public extension HD.Path {
	static let delimitor: Character = "/"
}

public extension HDPathConvertible {
	func toString() -> String {
		components.map { $0.toString() }.joined(separator: String(HD.Path.delimitor))
	}
}
