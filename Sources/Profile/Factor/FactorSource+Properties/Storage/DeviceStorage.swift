import Foundation

// MARK: - NextDerivationIndicies
public struct NextDerivationIndicies: Sendable, Hashable, Codable {
	public typealias Index = Int
	public var forAccount: Index
	public var forIdentity: Index
	public init(forAccount: UInt, forIdentity: UInt) {
		self.forAccount = Index(forAccount)
		self.forIdentity = Index(forIdentity)
	}
}

// MARK: - DeviceStorage
public struct DeviceStorage: Sendable, Hashable, Codable {
	public var nextDerivationIndicies: NextDerivationIndicies
}

extension NextDerivationIndicies {
	public func nextForEntity(kind entityKind: EntityKind) -> Index {
		switch entityKind {
		case .identity: return forIdentity
		case .account: return forAccount
		}
	}
}

extension DeviceStorage {
	public func nextForEntity(kind entityKind: EntityKind) -> NextDerivationIndicies.Index {
		nextDerivationIndicies.nextForEntity(kind: entityKind)
	}
}

extension FactorSource {
    public mutating func increaseNextDerivationIndex(for entityKind: EntityKind) throws {
        try storage?.increaseNextDerivationIndex(for: entityKind)
    }
}

extension FactorSource.Storage {
    public mutating func increaseNextDerivationIndex(for entityKind: EntityKind) throws {
        switch self {
        case .forSecurityQuestions: throw Discrepancy()
        case var .forDevice(deviceStorage):
            deviceStorage.increaseNextDerivationIndex(for: entityKind)
            self = .forDevice(deviceStorage)
        }
    }
}

extension DeviceStorage {
    public mutating func increaseNextDerivationIndex(for entityKind: EntityKind) {
        nextDerivationIndicies.increaseNextDerivationIndex(for: entityKind)
    }
}

extension NextDerivationIndicies {
    public mutating func increaseNextDerivationIndex(for entityKind: EntityKind) {
        switch entityKind {
        case .account: self.forAccount += 1
        case .identity: self.forIdentity += 1
        }
    }
}
