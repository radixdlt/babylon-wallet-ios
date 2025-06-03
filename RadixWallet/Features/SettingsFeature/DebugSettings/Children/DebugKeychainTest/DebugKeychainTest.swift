import ComposableArchitecture
import SwiftUI

#if DEBUG

// MARK: - DebugKeychainTest
struct DebugKeychainTest: Sendable, FeatureReducer {
	enum Status: Sendable, Hashable {
		case new
		case initializing
		case initialized
		case failedToInitialize(String)

		case error(String)
		case finishedWithFailure(String)
		case finishedSuccessfully
	}

	struct State: Sendable, Hashable {
		var status: Status = .new
		var containsDataForAuth: Bool = false
		var containsDataForNoAuth: Bool = false
		var serviceAndAccessGroup: KeychainClient.KeychainServiceAndAccessGroup?
		init() {}
	}

	enum InternalAction: Sendable, Equatable {
		case statusChanged(Status)
		case containsResult(contains: Bool, key: KeychainClient.Key)
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case testAuth
		case testNoAuth
		case reset
	}

	@Dependency(\.keychainClient) var keychainClient

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			state.serviceAndAccessGroup = keychainClient.serviceAndAccessGroup()
			return .send(.view(.reset))
		case .testAuth:
			return doTest {
				try await keychainClient
					.authGetSavedDataElseSaveNewRandom()
			}.concatenate(with: checkContainsAuth())
		case .testNoAuth:
			return doTest {
				try await keychainClient
					.noAuthGetSavedDataElseSaveNewRandom()
			}.concatenate(with: checkContainsNoAuth())
		case .reset:
			state.status = .initializing
			return .run { send in
				let status: Status
				do {
					try await keychainClient.removeData(forKey: noAuthRandomKey)
					try await keychainClient.removeData(forKey: authRandomKey)
					let noAuth = try await keychainClient.contains(noAuthRandomKey)
					let auth = try await keychainClient.contains(authRandomKey)
					await send(.internal(.containsResult(contains: noAuth, key: noAuthRandomKey)))
					await send(.internal(.containsResult(contains: auth, key: authRandomKey)))
					if !auth, !noAuth {
						status = .initialized
					} else {
						status = .failedToInitialize("Unable to (re)-init.")
					}
				} catch {
					status = .failedToInitialize("Failed to remove all items in keychain \(error)")
				}
				await send(.internal(.statusChanged(status)))
			}
		}
	}

	private func checkContainsAuth() -> Effect<Action> {
		check(key: authRandomKey)
	}

	private func checkContainsNoAuth() -> Effect<Action> {
		check(key: noAuthRandomKey)
	}

	private func check(key: KeychainClient.Key) -> Effect<Action> {
		.run { send in
			let contains = try? await keychainClient.contains(key)
			await send(.internal(.containsResult(contains: contains ?? false, key: key)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .statusChanged(newStatus):
			state.status = newStatus
			return .none
		case let .containsResult(contains, key):
			if key == noAuthRandomKey {
				state.containsDataForNoAuth = contains
			} else if key == authRandomKey {
				state.containsDataForAuth = contains
			}
			return .none
		}
	}

	private func doTest(
		_ task: @escaping @Sendable () async throws -> some Hashable & Sendable
	) -> Effect<Action> {
		.run { send in
			let status: DebugKeychainTest.Status
			do {
				let values = try await valuesFromManyTasks {
					try await task()
				}
				if values.count == 0 {
					status = .finishedWithFailure("Zero elements")
				} else if values.count == 1 {
					status = .finishedSuccessfully
				} else {
					status = .finishedWithFailure("#\(values.count) elements")
				}
			} catch {
				status = .error("\(error)")
			}
			await send(.internal(.statusChanged(status)))
		}
	}
}

let authRandomKey: KeychainClient.Key = "authRandomDataKey"
let noAuthRandomKey: KeychainClient.Key = "noAuthRandomDataKey"

extension KeychainClient {
	@MainActor
	@discardableResult
	func authGetSavedDataElseSaveNewRandom() async throws -> Data {
		try await getDataWithAuth(
			forKey: authRandomKey,
			authenticationPrompt: "Keychain demo",
			ifNilSet: .init(
				to: .randomKeychainDemo(),
				with: .init(
					accessibility: .whenUnlockedThisDeviceOnly,
					authenticationPolicy: .biometryAny
				)
			)
		).value
	}

	@MainActor
	@discardableResult
	func noAuthGetSavedDataElseSaveNewRandom() async throws -> Data {
		try await getDataWithoutAuth(
			forKey: noAuthRandomKey,
			ifNilSet: .init(
				to: .randomKeychainDemo(),
				with: .init(
					accessibility: .whenUnlockedThisDeviceOnly
				)
			)
		).value
	}
}

func valuesFromManyTasks<T: Hashable & Sendable>(
	task: @Sendable @escaping () async throws -> T
) async throws -> Set<T> {
	let t0 = Task {
		try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t1 = Task { @MainActor in
		dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
		return try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t2 = Task { @MainActor in
		dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
		return try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t3 = Task {
		try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t4 = Task {
		try await task()
	}
	await Task.yield()
	await Task.yield()
	let t5 = Task {
		try await task()
	}
	await Task.yield()
	await Task.yield()
	let t6 = Task { @MainActor in
		dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
		return try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t7 = Task {
		try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t8 = Task { @MainActor in
		dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
		return try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t9 = Task {
		try await task()
	}
	await Task.yield()

	let tasks = [t0, t1, t2, t3, t4, t5, t6, t7, t8, t9]
	var values = Set<T>()
	for task in tasks {
		let value = try await task.value
		values.insert(value)
	}
	return values
}

extension Data {
	static func randomKeychainDemo() -> Self {
		try! .random(byteCount: 16)
	}
}

#endif // DEBUG
