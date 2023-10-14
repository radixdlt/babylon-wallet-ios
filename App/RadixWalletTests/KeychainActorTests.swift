import Foundation
import KeychainAccess
import XCTest
@_spi(KeychainInternal) import Prelude

let authRandomKey: KeychainActor.Key = "authRandomDataKey"
let noAuthRandomKey: KeychainActor.Key = "noAuthRandomDataKey"

// MARK: - KeychainActorTests
final class KeychainActorTests: XCTestCase {
	let sut = KeychainActor.shared

	func testNoAuth() async throws {
		try await onceNoAuthTest()
	}

	func testAuth() async throws {
		try await onceAuthTest()
	}

	func onceNoAuthTest() async throws {
		try await sut.removeAllItems()
		let startValue = try await sut.getDataWithoutAuth(forKey: noAuthRandomKey)
		XCTAssertNil(startValue)

		let values = try await valuesFromManyTasks {
			try await self.sut.noAuthGetSavedDataElseSaveNewRandom()
		}
		XCTAssertEqual(values.count, 1)
	}

	func onceAuthTest() async throws {
		try await sut.removeAllItems()
		let startValue = try await sut.getDataWithAuth(
			forKey: authRandomKey,
			authenticationPrompt: "onceAuthTest"
		)
		XCTAssertNil(startValue)

		let values = try await valuesFromManyTasks {
			try await self.sut.authGetSavedDataElseSaveNewRandom()
		}
		XCTAssertEqual(values.count, 1)
	}
}

extension KeychainActor {
	@MainActor
	@discardableResult
	func authGetSavedDataElseSaveNewRandom() async throws -> Data {
		try await self.getDataWithAuthForKeySetIfNil(
			forKey: authRandomKey,
			authenticationPrompt: "Keychain demo",
			ifNilSet: .init(
				to: .random(byteCount: 16),
				with: KeychainClient.AttributesWithAuth(
					accessibility: .whenUnlockedThisDeviceOnly,
					authenticationPolicy: .biometryAny
				)
			)
		).value
	}
}

extension KeychainActor {
	@MainActor
	@discardableResult
	func noAuthGetSavedDataElseSaveNewRandom() async throws -> Data {
		try await self.getDataWithoutAuthForKeySetIfNil(
			forKey: noAuthRandomKey,
			ifNilSet: .init(
				to: .random(byteCount: 16),
				with: KeychainClient.AttributesWithoutAuth(
					accessibility: .always
				)
			)
		).value
	}
}

public func valuesFromManyTasks<T: Hashable>(
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
