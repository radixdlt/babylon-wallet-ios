import EngineToolkitClient
import FeaturePrelude
import GatewaysClient
import SecureStorageClient
import TransactionClient
import TransactionReviewFeature

// MARK: - TransactionSigningCoordinator
public struct TransactionSigningCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case prepare(TransactionSigningPrepare.State)
			case review(TransactionReview.State)
		}

		public let rawTransactionManifest: TransactionManifest
		public var step: Step

		public init(
			messageFromDapp: String?,
			rawTransactionManifest: TransactionManifest
		) {
			self.rawTransactionManifest = rawTransactionManifest
			self.step = .prepare(.init(
				messageFromDapp: messageFromDapp,
				rawTransactionManifest: rawTransactionManifest
			))
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		// TODO: replace with tuple when Apple makes them autoconform to Equatable
		public struct AddLockInstructionToManifestSuccessValues: Sendable, Equatable {
			let manifestWithLockFee: TransactionManifest
			let manifestWithLockFeeString: String
		}

		case addLockFeeInstructionToManifestResult(Result<AddLockInstructionToManifestSuccessValues, TransactionFailure>)
		case signTransactionResult(TransactionResult)
	}

	public enum DelegateAction: Sendable, Equatable {
		case failed(TransactionFailure)
		case signedTXAndSubmittedToGateway(TransactionIntent.TXID)
	}

	public enum ChildAction: Sendable, Equatable {
		case prepare(TransactionSigningPrepare.Action)
		case review(TransactionReview.Action)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.transactionClient) var transactionClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Step.prepare, action: /Action.child .. ChildAction.prepare) {
					TransactionSigningPrepare()
				}
				.ifCaseLet(/State.Step.review, action: /Action.child .. ChildAction.review) {
					TransactionReview()
				}
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
//			return .run { [manifest = state.transactionManifestWithoutLockFee] send in
//				do {
//					let networkID = await gatewaysClient.getCurrentNetworkID()
//					let manifestWithLockFee = try await transactionClient.addLockFeeInstructionToManifest(manifest)
//					let manifestWithLockFeeString = try manifestWithLockFee.toString(
//						preamble: "",
//						blobOutputFormat: .includeBlobsByByteCountOnly,
//						blobPreamble: "\n\nBLOBS:\n",
//						networkID: networkID
//					)
//					let result = InternalAction.AddLockInstructionToManifestSuccessValues(
//						manifestWithLockFee: manifestWithLockFee,
//						manifestWithLockFeeString: manifestWithLockFeeString
//					)
//					await send(.internal(.addLockFeeInstructionToManifestResult(.success(result))))
//				} catch let error as TransactionFailure {
//					await send(.internal(.addLockFeeInstructionToManifestResult(.failure(error))))
//				} catch TransactionManifest.ManifestConversionError.manifestGeneration {
//					await send(.internal(.addLockFeeInstructionToManifestResult(.failure(.failedToCompileOrSign(.failedToCompileTXIntent)))))
//				} catch {
//					errorQueue.schedule(error)
//					// this seems like jumping to conclusions, but we can't currently "send" general errors, only TransactionFailure as above
//					await send(.internal(.addLockFeeInstructionToManifestResult(.failure(.failedToPrepareForTXSigning(.failedToFindAccountWithEnoughFundsToLockFee)))))
//				}
//			}
			fatalError()
		case .closeButtonTapped:
			fatalError()
//		case .signTransactionButtonTapped:
//			guard
//				let transactionWithLockFee = state.transactionWithLockFee
//			else {
//				return .none
//			}
//
//			state.isSigningTX = true
//
//			let signRequest = SignManifestRequest(
//				manifestToSign: transactionWithLockFee,
//				makeTransactionHeaderInput: state.makeTransactionHeaderInput
//			)
//
//			return .run { send in
//				await send(.internal(.signTransactionResult(
//					transactionClient.signAndSubmitTransaction(signRequest)
//				)))
//			}
		}
	}

//	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
//		switch internalAction {
//		case let .addLockFeeInstructionToManifestResult(.success(values)):
//			state.transactionWithLockFee = values.manifestWithLockFee
//			state.transactionWithLockFeeString = values.manifestWithLockFeeString
//			return .none
//
//		case let .addLockFeeInstructionToManifestResult(.failure(transactionFailure)):
//			return .send(.delegate(.failed(transactionFailure)))
//
//		case let .signTransactionResult(.success(txID)):
//			state.isSigningTX = false
//			return .send(.delegate(.signedTXAndSubmittedToGateway(txID)))
//
//		case let .signTransactionResult(.failure(transactionFailure)):
//			state.isSigningTX = false
//			return .send(.delegate(.failed(transactionFailure)))
//		}
//	}
}
