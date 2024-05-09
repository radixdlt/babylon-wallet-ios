import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

// MARK: - SecurityCenterClient
public struct SecurityCenterClient: DependencyKey, Sendable {
	public let problems: Problems
}

// MARK: SecurityCenterClient.Problems
extension SecurityCenterClient {
	public typealias Problems = @Sendable (ProfileID) async -> AnyAsyncSequence<[SecurityProblem]>
}

// MARK: - SecurityProblem
public enum SecurityProblem: Hashable, Sendable, Identifiable {
	case problem3(accounts: Int, personas: Int)
	case problem5
	case problem6
	case problem7
	case problem9

	public var id: Int { number }

	public var number: Int {
		switch self {
		case .problem3: 3
		case .problem5: 5
		case .problem6: 6
		case .problem7: 7
		case .problem9: 9
		}
	}
}
