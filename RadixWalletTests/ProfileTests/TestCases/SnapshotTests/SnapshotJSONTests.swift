import Foundation
import JSONTesting
@testable import Radix_Wallet_Dev
import XCTest

// MARK: - SnapshotJSONTests
final class SnapshotJSONTests: TestCase {
	func test_generate() throws {
		let plaintextSnapshot: ProfileSnapshot = try readTestFixture(
			bundle: Bundle(for: Self.self),
			// This Profile has been built using the PROD version of app, version `1.0.0 (5)`
			// and exported as file and put here.
			jsonName: "only_plaintext_profile_snapshot_version_100",
			jsonDecoder: jsonDecoder
		)

		let vector = try SnapshotTestVector.encrypting(
			plaintext: plaintextSnapshot,
			mnemonics: [
				MnemonicWithPassphrase(
					mnemonic: .init(
						phrase: "alley urge tag valid execute hat little funny armed salute orient hurt balcony urban found clip tennis wrong turtle canoe castle exist pledge test",
						language: .english
					)
				),
				.init(
					mnemonic: .init(
						phrase: "gentle hawk winner rain embrace erosion call update photo frost fatal wrestle",
						language: .english
					)
				),
				.init(
					mnemonic: .init(
						phrase: "smile entry satisfy shed margin rubber disorder hungry foot error ribbon cradle aim round october blind lab spend",
						language: .english
					)
				),
			].map {
				try SnapshotTestVector.IdentifiableMnemonic(
					mnemonicWithPassphrase: $0
				)
			},
			passwords: [
				"",
				"Radix... just imagine!", // ref: https://github.com/radixdlt/radixdlt-swift-archive/blob/c289fa5bb8996fc427d2df064d9ae433665cac88/Tests/TestCases/UnitTests/RadixStack/3_Chemistry/AtomToExecutedActionMapper/DefaultAtomToTransactionMapperCreateTokenFromGenesisAtomTests.swift#L55
				"babylon",
			]
		)

		try XCTAssertJSONCoding(vector)

		try print(XCTUnwrap(String(data: jsonEncoder.encode(vector), encoding: .utf8)))
	}

	func test_profile_snapshot_version_100() throws {
		try testFixture(
			bundle: Bundle(for: Self.self),
			jsonName: "multi_profile_snapshots_test_version_100"
		) { (vector: SnapshotTestVector) in
			let decryptedSnapshots = try vector.validate()
			XCTAssertAllEqual(
				decryptedSnapshots.map(\.header.snapshotVersion),
				vector.plaintext.header.snapshotVersion,
				100
			)
			try XCTAssertJSONCoding(vector, encoder: jsonEncoder, decoder: jsonDecoder)
		}
	}

	lazy var jsonEncoder: JSONEncoder = {
		let jsonEncoder = JSONEncoder.iso8601
		jsonEncoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
		return jsonEncoder
	}()

	lazy var jsonDecoder: JSONDecoder = .iso8601
}
