import EngineKit
import FactorSourcesClient
import FeaturePrelude
import TransactionClient

// MARK: - CustomizeFees
public struct CustomizeFees: FeatureReducer {
	public struct State: Hashable, Sendable {
		enum CustomizationModeState: Hashable, Sendable {
			case normal(NormalFeesCustomization.State)
			case advanced(AdvancedFeesCustomization.State)
		}

		var feePayerSelection: FeePayerSelectionAmongstCandidates {
			reviewedTransaction.feePayerSelection
		}

		let manifest: TransactionManifest
		let signingPurpose: SigningPurpose
		var reviewedTransaction: ReviewedTransaction
		var modeState: CustomizationModeState

		var feePayerAccount: Profile.Network.Account? {
			feePayerSelection.selected?.account
		}

		var transactionFee: TransactionFee {
			feePayerSelection.transactionFee
		}

		@PresentationState
		public var destination: Destinations.State? = nil

		init(
			reviewedTransaction: ReviewedTransaction,
			manifest: TransactionManifest,
			signingPurpose: SigningPurpose
		) {
			self.reviewedTransaction = reviewedTransaction
			self.manifest = manifest
			self.signingPurpose = signingPurpose
			self.modeState = reviewedTransaction.feePayerSelection.transactionFee.customizationModeState
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case changeFeePayerTapped
		case toggleMode
		case closeButtonTapped
	}

	public enum ChildAction: Equatable, Sendable {
		case destination(PresentationAction<Destinations.Action>)
		case normalFeesCustomization(NormalFeesCustomization.Action)
		case advancedFeesCustomization(AdvancedFeesCustomization.Action)
	}

	public enum DelegateAction: Equatable, Sendable {
		case updated(ReviewedTransaction)
	}

	public enum InternalAction: Equatable, Sendable {
		case updated(TaskResult<ReviewedTransaction>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case selectFeePayer(SelectFeePayer.State)
		}

		public enum Action: Sendable, Equatable {
			case selectFeePayer(SelectFeePayer.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.selectFeePayer, action: /Action.selectFeePayer) {
				SelectFeePayer()
			}
		}
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.modeState, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.CustomizationModeState.normal, action: /ChildAction.normalFeesCustomization) {
					NormalFeesCustomization()
				}
				.ifCaseLet(/State.CustomizationModeState.advanced, action: /ChildAction.advancedFeesCustomization) {
					AdvancedFeesCustomization()
				}
		}

		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .changeFeePayerTapped:
			state.destination = .selectFeePayer(.init(feePayerSelection: state.feePayerSelection))
			return .none
		case .toggleMode:
			state.reviewedTransaction.feePayerSelection.transactionFee.toggleMode()
			state.modeState = state.feePayerSelection.transactionFee.customizationModeState
			return .send(.delegate(.updated(state.reviewedTransaction)))
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.selectFeePayer(.delegate(.selected(selection))))):
			let previousFeePayer = state.reviewedTransaction.feePayerSelection.selected
			state.destination = nil
			let signingPurpose = state.signingPurpose

			@Sendable
			func replaceFeePayer(_ feePayer: FeePayerCandidate, _ reviewedTransaction: ReviewedTransaction, manifest: TransactionManifest) -> EffectTask<Action> {
				.run { send in
					var reviewedTransaction = reviewedTransaction
					var newSigners = OrderedSet(reviewedTransaction.transactionSigners.intentSignerEntitiesOrEmpty() + [.account(feePayer.account)])

					/// Remove the previous Fee Payer Signature if it is not required
					if let previousFeePayer, !manifest.accountsRequiringAuth().contains(where: { $0.addressString() == previousFeePayer.account.address.address }) {
						// removed, need to recalculate signing factors
						newSigners.remove(.account(previousFeePayer.account))

						let signers: TransactionSigners.IntentSigning = {
							guard let nonEmpty = NonEmpty(rawValue: OrderedSet(newSigners)) else {
								return .notaryIsSignatory
							}
							return TransactionSigners.IntentSigning.intentSigners(nonEmpty)
						}()

						reviewedTransaction.transactionSigners = .init(notaryPublicKey: reviewedTransaction.transactionSigners.notaryPublicKey, intentSigning: signers)
					}

					@Dependency(\.factorSourcesClient) var factorSourcesClient

					do {
						let factors = try await factorSourcesClient.getSigningFactors(.init(
							networkID: reviewedTransaction.networkId,
							signers: .init(rawValue: Set(newSigners))!,
							signingPurpose: signingPurpose
						))

						reviewedTransaction.signingFactors = factors
						reviewedTransaction.feePayerSelection.selected = selection
						if previousFeePayer == nil, reviewedTransaction.feePayerSelection.transactionFee.totalFee.max == .zero {
							/// The case when no FeePayer is required, but users chooses to add a FeePayer.
							reviewedTransaction.feePayerSelection.transactionFee.addLockFeeCost()
							reviewedTransaction.feePayerSelection.transactionFee.updateNotarizingCost(notaryIsSignatory: false)
						}
						reviewedTransaction.feePayerSelection.transactionFee.updateSignaturesCost(factors.expectedSignatureCount)
						await send(.internal(.updated(.success(reviewedTransaction))))
					} catch {
						await send(.internal(.updated(.failure(error))))
					}
				}
			}

			return replaceFeePayer(selection, state.reviewedTransaction, manifest: state.manifest)
		case let .advancedFeesCustomization(.delegate(.updated(advancedFees))):
			state.reviewedTransaction.feePayerSelection.transactionFee.mode = .advanced(advancedFees)
			return .send(.delegate(.updated(state.reviewedTransaction)))
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .updated(.success(reviewedTransaction)):
			state.reviewedTransaction = reviewedTransaction
			state.modeState = state.feePayerSelection.transactionFee.customizationModeState
			return .send(.delegate(.updated(state.reviewedTransaction)))
		case let .updated(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}
}

extension TransactionFee {
	var customizationModeState: CustomizeFees.State.CustomizationModeState {
		switch mode {
		case let .normal(normal):
			return .normal(.init(fees: normal))
		case let .advanced(advanced):
			return .advanced(.init(fees: advanced))
		}
	}
}
