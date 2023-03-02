// From -> https://github.com/pointfreeco/swift-either/blob/main/Sources/Either/Either.swift

public enum Either<Left, Right> {
  case left(Left)
  case right(Right)

  public var left: Left? {
    return self.either(ifLeft: Optional.some, ifRight: { _ in Optional.none })
  }

  public var right: Right? {
    return self.either(ifLeft: { _ in Optional.none }, ifRight: Optional.some)
  }

  public func either<Value>(
    ifLeft: (Left) throws -> Value,
    ifRight: (Right) throws -> Value
    ) rethrows -> Value {
    switch self {
    case let .left(left):
      return try ifLeft(left)
    case let .right(right):
      return try ifRight(right)
    }
  }

  public func `do`(
    ifLeft: (Left) throws -> Void,
    ifRight: (Right) throws -> Void
    ) rethrows {
    switch self {
    case let .left(left):
      try ifLeft(left)
    case let .right(right):
      try ifRight(right)
    }
  }

  public func bimap<NewLeft, NewRight>(
    ifLeft transformLeft: (Left) throws -> NewLeft,
    ifRight transformRight: (Right) throws -> NewRight
    ) rethrows -> Either<NewLeft, NewRight> {
    return try self.either(
      ifLeft: { .left(try transformLeft($0)) },
      ifRight: { .right(try transformRight($0)) }
    )
  }

  public func mapLeft<NewLeft>(
    _ transform: (Left) throws -> NewLeft
    ) rethrows -> Either<NewLeft, Right> {
    return try self.bimap(ifLeft: transform, ifRight: { $0 })
  }

  public func mapRight<NewRight>(
    _ transform: (Right) throws -> NewRight
    ) rethrows -> Either<Left, NewRight> {
    return try self.bimap(ifLeft: { $0 }, ifRight: transform)
  }

  public func flatMapLeft<NewLeft>(
    _ transform: (Left) throws -> Either<NewLeft, Right>
    ) rethrows -> Either<NewLeft, Right> {
    return try self.either(ifLeft: transform, ifRight: { .right($0) })
  }

  public func flatMapRight<NewRight>(
    _ transform: (Right) throws -> Either<Left, NewRight>
    ) rethrows -> Either<Left, NewRight> {
    return try self.either(ifLeft: { .left($0) }, ifRight: transform)
  }

  public static func zipLeft<LeftLeft, RightLeft>(
    _ lhs: Either<LeftLeft, Right>, rhs: Either<RightLeft, Right>
    ) -> Either
    where Left == (LeftLeft, RightLeft) {
      switch (lhs, rhs) {
      case let (.left(left), .left(otherLeft)):
        return .left((left, otherLeft))
      case let (.right(right), _):
        return .right(right)
      case let (_, .right(right)):
        return .right(right)
      }
  }

  public static func zipRight<LeftRight, RightRight>(
    _ lhs: Either<Left, LeftRight>, rhs: Either<Left, RightRight>
    ) -> Either
    where Right == (LeftRight, RightRight) {
      switch (lhs, rhs) {
      case let (.right(right), .right(otherRight)):
        return .right((right, otherRight))
      case let (.left(left), _):
        return .left(left)
      case let (_, .left(left)):
        return .left(left)
      }
  }
}

extension Either: Equatable where Left: Equatable, Right: Equatable {
  public static func == (lhs: Either, rhs: Either) -> Bool {
    switch (lhs, rhs) {
    case let (.left(lhs), .left(rhs)):
      return lhs == rhs
    case let (.right(lhs), .right(rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}

extension Either: Comparable where Left: Comparable, Right: Comparable {
  public static func < (lhs: Either, rhs: Either) -> Bool {
    switch (lhs, rhs) {
    case let (.left(lhs), .left(rhs)):
      return lhs < rhs
    case let (.right(lhs), .right(rhs)):
      return lhs < rhs
    case (.left, .right):
      return true
    case (.right, .left):
      return false
    }
  }
}

extension Either: Sendable where Left: Sendable, Right: Sendable {}

private enum HashableTag: Hashable { case left, right }

extension Either: Hashable where Left: Hashable, Right: Hashable {
  public func hash(into hasher: inout Hasher) {
    self.do(
      ifLeft: {
        hasher.combine(HashableTag.left)
        hasher.combine($0)
    },
      ifRight: {
        hasher.combine(HashableTag.right)
        hasher.combine($0)
    }
    )
  }
}

public struct DecodingErrors: Error {
  let errors: [Error]
}

extension Either: Decodable where Left: Decodable, Right: Decodable {
  public init(from decoder: Decoder) throws {
    do {
      self = try .left(Left(from: decoder))
    } catch let leftError {
      do {
        self = try .right(Right(from: decoder))
      } catch let rightError {
        throw DecodingError.typeMismatch(
          Either.self,
          .init(
            codingPath: decoder.codingPath,
            debugDescription: "Could not decode \(Left.self) or \(Right.self)",
            underlyingError: DecodingErrors(errors: [leftError, rightError])
          )
        )
      }
    }
  }
}

extension Either: Encodable where Left: Encodable, Right: Encodable {
  public func encode(to encoder: Encoder) throws {
    return try self.either(
      ifLeft: { try $0.encode(to: encoder) },
      ifRight: { try $0.encode(to: encoder) }
    )
  }
}

extension Either where Left: Error {
  public var asRightResult: Result<Right, Left> {
    return self.either(ifLeft: Result.failure, ifRight: Result.success)
  }
}

extension Either where Right: Error {
  public var asLeftResult: Result<Left, Right> {
    return self.either(ifLeft: Result.success, ifRight: Result.failure)
  }
}

extension Optional {
  public func select<Left, Right>(
    _ perform: ((Left) -> Right)?
    ) -> Right?
    where Wrapped == Either<Left, Right> {
      return self.flatMap { e in
        e.either(
          ifLeft: { a in perform.map { f in f(a) } },
          ifRight: { b in .some(b) }
        )
      }
  }
}

extension Sequence {
  public func lefts<Left, Right>() -> [Left] where Element == Either<Left, Right> {
    return self.compactMap { $0.left }
  }

  public func rights<Left, Right>() -> [Right] where Element == Either<Left, Right> {
    return self.compactMap { $0.right }
  }

  public func partitionMap<Left, Right>(_ transform: (Element) -> Either<Left, Right>)
    -> ([Left], [Right]) {
      return self.reduce(into: ([], [])) { result, element in
        transform(element).do(
          ifLeft: { result.0.append($0) },
          ifRight: { result.1.append($0) }
        )
      }
  }

  public func partition(_ predicate: (Element) -> Bool) -> (pass: [Element], fail: [Element]) {
    return self.partitionMap { predicate($0) ? .left($0) : .right($0) }
  }

  public func partitioned<Left, Right>() -> ([Left], [Right])
    where Element == Either<Left, Right> {
      return self.partitionMap { $0 }
  }

  public func select<ConditionalEffects, Left, Right>(_ perform: ConditionalEffects) -> [Right]
    where Element == Either<Left, Right>,
    ConditionalEffects: Sequence,
    ConditionalEffects.Element == (Left) -> Right {
      return self.flatMap { either in
        either.either(
          ifLeft: { left in perform.map { f in f(left) } },
          ifRight: { right in [right] }
        )
      }
  }
}
