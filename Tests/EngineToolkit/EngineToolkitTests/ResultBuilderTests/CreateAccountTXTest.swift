// import Cryptography
// @testable import EngineToolkit
// import TestingPrelude
//
//// MARK: - HammunetAddresses
// public enum HammunetAddresses {}
// public extension HammunetAddresses {
//	static let faucet: ComponentAddress = "component_tdx_22_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7ql6v973"
//
//	/// For non-virtual accounts
//	static let createAccountComponent: PackageAddress = "package_tdx_22_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlsk0emdf"
//
//	static let xrd: ResourceAddress = "resource_tdx_22_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqfpm3gw"
// }
//
//// MARK: - CreateAccountTXTest
// final class CreateAccountTXTest: TestCase {
//	override func setUp() {
//		debugPrint = false
//		super.setUp()
//		continueAfterFailure = false
//	}
//
//	func test_create_account_tx() throws {
//		let networkID: NetworkID = .hammunet
//
//		let privateKeyData = try Data(hex: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")
//		let privateKey = try Engine.PrivateKey.curve25519(.init(rawRepresentation: privateKeyData))
//
//		let nonFungibleGlobalId = try sut.deriveNonFungibleGlobalIdFromPublicKeyRequest(
//			request: DeriveNonFungibleGlobalIdFromPublicKeyRequest(
//				publicKey: privateKey.publicKey(),
//				networkId: networkID
//			))
//			.get()
//			.nonFungibleGlobalId
//
//		let transactionManifest = TransactionManifest {
//			CallMethod(
//				receiver: HammunetAddresses.faucet,
//				methodName: "lock_fee"
//			) {
//				Decimal_(value: "10.0")
//			}
//
//			CallMethod(
//				receiver: HammunetAddresses.faucet,
//				methodName: "free"
//			)
//
//			let xrdBucket: Bucket = "xrd"
//
//			TakeFromWorktop(resourceAddress: HammunetAddresses.xrd, bucket: xrdBucket)
//
//			CallFunction(
//				packageAddress: HammunetAddresses.createAccountComponent,
//				blueprintName: "Account",
//				functionName: "new_with_resource"
//			) {
//				Enum("Protected") {
//					Enum("ProofRule") {
//						Enum("Require") {
//							Enum("StaticNonFungible") {
//								nonFungibleGlobalId
//							}
//						}
//					}
//				}
//				xrdBucket
//			}
//		}
//
//		let startEpoch: Epoch = 8000
//		let endEpochExclusive = startEpoch + 2
//		let header = TransactionHeader(
//			version: .default,
//			networkId: networkID,
//			startEpochInclusive: startEpoch,
//			endEpochExclusive: endEpochExclusive,
//			nonce: 12345,
//			publicKey: try privateKey.publicKey(),
//			notaryAsSignatory: true,
//			costUnitLimit: 10_000_000,
//			tipPercentage: 0
//		)
//
//		let jsonManifest = try sut.convertManifest(
//			request: .init(
//				transactionVersion: header.version,
//				manifest: transactionManifest,
//				outputFormat: .parsed,
//				networkId: networkID
//			)
//		).get()
//
//		let manifestString = jsonManifest.toString(
//			preamble: "",
//			instructionsSeparator: "",
//			instructionsArgumentSeparator: " ",
//			networkID: networkID
//		)
//		let expected = """
//		CALL_METHOD ComponentAddress("component_tdx_22_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7ql6v973") "lock_fee" Decimal("10");CALL_METHOD ComponentAddress("component_tdx_22_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7ql6v973") "free";TAKE_FROM_WORKTOP ResourceAddress("resource_tdx_22_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqfpm3gw") Bucket("bucket1");CALL_FUNCTION PackageAddress("package_tdx_22_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlsk0emdf") "Account" "new_with_resource" Enum("Protected", Enum("ProofRule", Enum("Require", Enum("StaticNonFungible", NonFungibleGlobalId("resource_tdx_22_1qq8cays25704xdyap2vhgmshkkfyr023uxdtk59ddd4qq3t577", Bytes("71cf1c6fc032e971de8fd8349a2b05dcb6d57ff15bef8bfbe98e")))))) Bucket("bucket1");
//		"""
//		XCTAssertNoDifference(expected, manifestString)
//
//		let signTxContext = try transactionManifest
//			.header(header)
//			.notarize(privateKey)
//
//		XCTAssertNoThrow(try sut.compileSignedTransactionIntentRequest(request: signTxContext.signedTransactionIntent).get())
//	}
// }
