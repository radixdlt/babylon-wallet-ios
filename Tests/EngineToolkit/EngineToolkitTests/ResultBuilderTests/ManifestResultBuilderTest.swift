@testable import EngineToolkit
import Prelude

final class ManifestResultBuilderTest: TestCase {
	func test__complex_resultBuilder() throws {
		let expected = try sut.convertManifest(request: makeRequest(outputFormat: .json, manifest: .complex)).get()

		let built: TransactionManifest = try TransactionManifest {
			// Withdraw XRD from account
			let account: ComponentAddress = "account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064"
			let resource: ResourceAddress = "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag"
			CallMethod(
				receiver: account,
				methodName: "withdraw_by_amount"
			) {
				Decimal_(value: "5")
				resource
			}
			// Buy GUM with XRD
			let xrdBucket0: Bucket = "xrd"
			TakeFromWorktopByAmount(
				amount: Decimal_(value: "2"),
				resourceAddress: resource,
				bucket: xrdBucket0
			)
			let gumballComponent: ComponentAddress = "component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum"
			CallMethod(
				receiver: gumballComponent,
				methodName: "buy_gumball"
			) { xrdBucket0 }

			AssertWorktopContainsByAmount(
				amount: Decimal_(value: "3"),
				resourceAddress: resource
			)
			AssertWorktopContains(resourceAddress: "resource_sim1qzhdk7tq68u8msj38r6v6yqa5myc64ejx3ud20zlh9gseqtux6")

			// Create a proof from bucket, clone it and drop both
			let xrdBucket1: Bucket = "some_xrd"
			TakeFromWorktop(
				resourceAddress: resource,
				bucket: xrdBucket1
			)
			// We can even make use of temporary variables, which are ignored by the @resultBuilder, like so:
			let proof1: Proof = "proof1"
			let proof2: Proof = "proof2"

			CreateProofFromBucket(bucket: xrdBucket1, proof: proof1)
			CloneProof(from: proof1, to: proof2)
			DropProof(proof1)
			DropProof(proof2)

			// Create a proof from account and drop it
			CallMethod(
				receiver: account,
				methodName: "create_proof_by_amount"
			) {
				Decimal_(value: "5")
				resource
			}
			let proof3: Proof = "proof3"
			PopFromAuthZone(proof: proof3)
			DropProof(proof3)

			// Return a bucket to worktop
			ReturnToWorktop(bucket: xrdBucket1)
			TakeFromWorktopByIds(
				[
					try .bytes(.init(hex: "031b84c5567b126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5dd078f")),
				],
				resourceAddress: resource,
				bucket: "nfts"
			)

			// Create a new fungible resource
			//			CreateResource(
			//				resourceType: .enum(Enum("Fungible") { UInt8(0) }),
			//				metadata: try Array_(elementType: .tuple, elements: []),
			//				accessRules: try Array_(elementType: .tuple, elements: []),
			//				mintParams: .option(.some(Enum("Fungible") { Decimal_(value: "1") }))
			//			)

			// Cancel all buckets and move resources to account
			CallMethod(
				receiver: account,
				methodName: "deposit_batch"
			) {
				Expression("ENTIRE_WORKTOP")
			}

			// Drop all proofs
			DropAllProofs()

			// Complicated method that takes all of the number types
			CallMethod(
				receiver: gumballComponent,
				methodName: "complicated_method"
			) {
				Decimal_(value: "1")
				PreciseDecimal(2)
			}
		}

		XCTAssertNoDifference(built, expected)
	}
}
