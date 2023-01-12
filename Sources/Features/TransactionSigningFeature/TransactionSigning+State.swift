import EngineToolkit
import FeaturePrelude
import Profile
import struct TransactionClient.MakeTransactionHeaderInput

// MARK: - TransactionSigning.State
public extension TransactionSigning {
	struct State: Equatable {
		public let request: P2P.SignTransactionRequestToHandle
		public var isSigningTX: Bool
		public var transactionManifestWithoutLockFee: TransactionManifest
		public var transactionWithLockFee: TransactionManifest?
		public var transactionWithLockFeeString: String?
		public var makeTransactionHeaderInput: MakeTransactionHeaderInput

		public init(
			makeTransactionHeaderInput: MakeTransactionHeaderInput = .default,
			request: P2P.SignTransactionRequestToHandle,
			isSigningTX: Bool = false,
			transactionWithLockFee: TransactionManifest? = nil,
			transactionWithLockFeeString: String? = nil
		) {
			self.makeTransactionHeaderInput = makeTransactionHeaderInput
			self.request = request
			self.isSigningTX = isSigningTX
			transactionManifestWithoutLockFee = request.requestItem.transactionManifest
			self.transactionWithLockFee = transactionWithLockFee
			self.transactionWithLockFeeString = transactionWithLockFeeString
		}
	}
}

#if DEBUG
public extension TransactionManifest {
	static var mock: Self {
		.init(instructions: .string(
			"""
			# Withdraw XRD from account
			CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "withdraw_by_amount" Decimal("5.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");

			# Buy GUM with XRD
			TAKE_FROM_WORKTOP_BY_AMOUNT Decimal("2.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("xrd");
			CALL_METHOD ComponentAddress("component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum") "buy_gumball" Bucket("xrd");
			ASSERT_WORKTOP_CONTAINS_BY_AMOUNT Decimal("3.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");
			ASSERT_WORKTOP_CONTAINS ResourceAddress("resource_sim1qzhdk7tq68u8msj38r6v6yqa5myc64ejx3ud20zlh9gseqtux6");

			# Create a proof from bucket, clone it and drop both
			TAKE_FROM_WORKTOP ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("some_xrd");
			CREATE_PROOF_FROM_BUCKET Bucket("some_xrd") Proof("proof1");
			CLONE_PROOF Proof("proof1") Proof("proof2");
			DROP_PROOF Proof("proof1");
			DROP_PROOF Proof("proof2");

			# Create a proof from account and drop it
			CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "create_proof_by_amount" Decimal("5.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");
			POP_FROM_AUTH_ZONE Proof("proof3");
			DROP_PROOF Proof("proof3");

			# Return a bucket to worktop
			RETURN_TO_WORKTOP Bucket("some_xrd");
			TAKE_FROM_WORKTOP_BY_IDS Set<NonFungibleId>(NonFungibleId("0905000000"), NonFungibleId("0907000000")) ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("nfts");

			# Create a new fungible resource
			CREATE_RESOURCE Enum("Fungible", 0u8) Map<String, String>() Map<Enum, Tuple>() Some(Enum("Fungible", Decimal("1.0")));

			# Cancel all buckets and move resources to account
			CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "deposit_batch" Expression("ENTIRE_WORKTOP");

			# Drop all proofs
			DROP_ALL_PROOFS;

			# Complicated method that takes all of the number types
			CALL_METHOD ComponentAddress("component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum") "complicated_method" Decimal("1") PreciseDecimal("2");
			"""
		))
	}
}

public extension TransactionSigning.State {
	static var previewValue: Self {
		.init(request: .init(requestItem: .previewValue, parentRequest: .previewValue))
	}
}
#endif
