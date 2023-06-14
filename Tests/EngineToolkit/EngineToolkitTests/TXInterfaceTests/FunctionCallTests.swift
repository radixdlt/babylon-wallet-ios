@testable import EngineToolkit
import Prelude

final class FunctionCallsTest: TestCase {
	func test_analyzeTransactionExecution() throws {
		//                try RadixEngine.instance.analyzeTransactionExecution(request: .init(
		//                        networkId: .simulator,
		//                        manifest: .init(instructions: .string("""
		//                        CALL_METHOD
		//                                Address("account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q")
		//                                "lock_fee"
		//                                Decimal("10");
		//                        CALL_METHOD
		//                                Address("account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q")
		//                                "withdraw"
		//                                Address("resource_sim1ngktvyeenvvqetnqwysevcx5fyvl6hqe36y3rkhdfdn6uzvt5366ha")
		//                                Decimal("2000");
		//                        TAKE_ALL_FROM_WORKTOP
		//                                Address("resource_sim1ngktvyeenvvqetnqwysevcx5fyvl6hqe36y3rkhdfdn6uzvt5366ha")
		//                                Bucket("bucket1");
		//                        CALL_METHOD
		//                                Address("component_sim1cqvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cvemygpmu")
		//                                "swap"
		//                                Bucket("bucket1");
		//                        CALL_METHOD
		//                                Address("account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q")
		//                                "deposit_batch"
		//                                Expression("ENTIRE_WORKTOP");
		//                        """)),
		//                        transactionReceipt: [UInt8](resource(named: "file", extension: "blob"))
		//                )).get()
	}

	func test_compileNotarizedTransaction() throws {
		//                try RadixEngine.instance.compileNotarizedTransactionIntentRequest(request: .init(signedIntent: <#T##SignedTransactionIntent#>, notarySignature: <#T##Engine.Signature#>))
	}
}
