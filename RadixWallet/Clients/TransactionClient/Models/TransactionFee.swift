// MARK: - TransactionFee
public struct TransactionFee: Hashable, Sendable {
	/// FeeSummary after transaction was analyzed
	public let feeSummary: FeeSummary

	/// FeeLocks after transaction was analyzed
	public let feeLocks: FeeLocks

	/// The calculation mode
	public var mode: Mode

	public init(feeSummary: FeeSummary, feeLocks: FeeLocks, mode: Mode) {
		self.feeSummary = feeSummary
		self.feeLocks = feeLocks
		self.mode = mode
	}

	public init(feeSummary: FeeSummary, feeLocks: FeeLocks) {
		self.init(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal(.init(feeSummary: feeSummary, feeLocks: feeLocks)))
	}

	public init(
		executionSummary: ExecutionSummary,
		signaturesCount: Int,
		notaryIsSignatory: Bool,
		includeLockFee: Bool
	) throws {
		let feeSummary: FeeSummary = try .init(
			executionCost: executionSummary.feeSummary.executionCost,
			finalizationCost: executionSummary.feeSummary.finalizationCost,
			storageExpansionCost: executionSummary.feeSummary.storageExpansionCost,
			royaltyCost: executionSummary.feeSummary.royaltyCost,
			guaranteesCost: executionSummary.guranteesCost(),
			signaturesCost: PredefinedFeeConstants.signaturesCost(signaturesCount),
			lockFeeCost: includeLockFee ? PredefinedFeeConstants.lockFeeInstructionCost : .zero,
			notarizingCost: PredefinedFeeConstants.notarizingCost(notaryIsSignatory)
		)

		let feeLocks: FeeLocks = .init(
			nonContingentLock: executionSummary.feeLocks.lock,
			contingentLock: executionSummary.feeLocks.contingentLock
		)

		self.init(
			feeSummary: feeSummary,
			feeLocks: feeLocks
		)
	}

	public mutating func update(with feeSummaryField: WritableKeyPath<FeeSummary, Decimal192>, amount: Decimal192) {
		var feeSummary = feeSummary
		feeSummary[keyPath: feeSummaryField] = amount
		let mode: Mode = switch self.mode {
		case .normal:
			.normal(.init(feeSummary: feeSummary, feeLocks: feeLocks))
		case .advanced:
			.advanced(.init(feeSummary: feeSummary, feeLocks: feeLocks))
		}
		self = .init(feeSummary: feeSummary, feeLocks: feeLocks, mode: mode)
	}

	public mutating func addLockFeeCost() {
		update(with: \.lockFeeCost, amount: PredefinedFeeConstants.lockFeeInstructionCost)
	}

	public mutating func updateNotarizingCost(notaryIsSignatory: Bool) {
		update(with: \.notarizingCost, amount: PredefinedFeeConstants.notarizingCost(notaryIsSignatory))
	}

	public mutating func updateSignaturesCost(_ count: Int) {
		update(with: \.signaturesCost, amount: PredefinedFeeConstants.signaturesCost(count))
	}
}

extension TransactionFee {
	/// Calculates the totalFee for the transaction based on the `mode`
	public var totalFee: TotalFee {
		switch mode {
		case let .normal(normalCustomization):
			let maxFee = normalCustomization.total
			let minFee = (maxFee - feeLocks.contingentLock).clamped
			return .init(min: minFee, max: maxFee)
		case let .advanced(advancedCustomization):
			return .init(min: advancedCustomization.total, max: advancedCustomization.total)
		}
	}

	public mutating func toggleMode() {
		switch mode {
		case .normal:
			mode = .advanced(.init(feeSummary: feeSummary, feeLocks: feeLocks))
		case .advanced:
			mode = .normal(.init(feeSummary: feeSummary, feeLocks: feeLocks))
		}
	}

	public var isNormalMode: Bool {
		if case .normal = mode {
			return true
		}
		return false
	}
}

extension TransactionFee {
	public enum PredefinedFeeConstants {
		/// 15% margin is added here to make up for the ambiguity of the transaction preview estimate)
		public static let networkFeeMultiplier = Decimal192(0.15)

		/// Network fees -> https://radixdlt.atlassian.net/wiki/spaces/S/pages/3134783512/Manifest+Mutation+Cost+Addition+Estimates
		// swiftformat:disable all
        public static let lockFeeInstructionCost =              try! Decimal192("0.08581566997")
        public static let fungibleGuaranteeInstructionCost =    try! Decimal192("0.00908532837")
        public static let nonFungibleGuranteeInstructionCost =  try! Decimal192("0.00954602837")
        public static let signatureCost =                       try! Decimal192("0.01109974758")
        public static let notarizingCost =                      try! Decimal192("0.0081393944")
        public static let notarizingCostWhenNotaryIsSignatory = try! Decimal192("0.0084273944")
        //    swiftformat:enable all

		public static func notarizingCost(_ notaryIsSignatory: Bool) -> Decimal192 {
			notaryIsSignatory ? notarizingCostWhenNotaryIsSignatory : notarizingCost
		}

		public static func signaturesCost(_ signaturesCount: Int) -> Decimal192 {
			Decimal192(Int64(signaturesCount)) * PredefinedFeeConstants.signatureCost
		}
	}

	public enum Mode: Hashable, Sendable {
		case normal(NormalFeeCustomization)
		case advanced(AdvancedFeeCustomization)
	}

	public struct FeeSummary: Hashable, Sendable {
		public let executionCost: Decimal192
		public let finalizationCost: Decimal192
		public let storageExpansionCost: Decimal192
		public let royaltyCost: Decimal192

		public let guaranteesCost: Decimal192

		public var lockFeeCost: Decimal192
		public var signaturesCost: Decimal192
		public var notarizingCost: Decimal192

		public var totalExecutionCost: Decimal192 {
			executionCost
				+ guaranteesCost
				+ signaturesCost
				+ lockFeeCost
				+ notarizingCost
		}

		public var total: Decimal192 {
			totalExecutionCost
				+ finalizationCost
				+ storageExpansionCost
				+ royaltyCost
		}

		public init(
			executionCost: Decimal192,
			finalizationCost: Decimal192,
			storageExpansionCost: Decimal192,
			royaltyCost: Decimal192,
			guaranteesCost: Decimal192,
			signaturesCost: Decimal192,
			lockFeeCost: Decimal192,
			notarizingCost: Decimal192
		) {
			self.executionCost = executionCost
			self.finalizationCost = finalizationCost
			self.storageExpansionCost = storageExpansionCost
			self.royaltyCost = royaltyCost
			self.guaranteesCost = guaranteesCost
			self.signaturesCost = signaturesCost
			self.lockFeeCost = lockFeeCost
			self.notarizingCost = notarizingCost
		}
	}

	public struct FeeLocks: Hashable, Sendable {
		public let nonContingentLock: Decimal192
		public let contingentLock: Decimal192

		public init(nonContingentLock: Decimal192, contingentLock: Decimal192) {
			self.nonContingentLock = nonContingentLock
			self.contingentLock = contingentLock
		}
	}

	public struct AdvancedFeeCustomization: Hashable, Sendable {
		public let feeSummary: FeeSummary
		public var paddingFee: Decimal192
		public var tipPercentage: UInt16
		public let paidByDapps: Decimal192

		public var tipAmount: Decimal192 {
			let lhsNominator = Decimal192(UInt64(tipPercentage))
			let lhsDenominator = Decimal192(100)
			let lhs: Decimal192 = lhsNominator / lhsDenominator
			let rhs: Decimal192 = feeSummary.totalExecutionCost + feeSummary.finalizationCost

			return lhs * rhs
		}

		public var total: Decimal192 {
			(feeSummary.total + paddingFee + tipAmount + paidByDapps).clamped
		}

		public init(feeSummary: FeeSummary, feeLocks: FeeLocks) {
			self.feeSummary = feeSummary
			self.paddingFee = (feeSummary.totalExecutionCost + feeSummary.finalizationCost + feeSummary.storageExpansionCost) * PredefinedFeeConstants.networkFeeMultiplier
			self.tipPercentage = .zero

			/// NonContingent lock will pay for some of the fee.
			self.paidByDapps = -feeLocks.nonContingentLock
		}
	}

	public struct NormalFeeCustomization: Hashable, Sendable {
		public let networkFee: Decimal192
		public let royaltyFee: Decimal192
		public let total: Decimal192

		public init(networkFee: Decimal192, royaltyFee: Decimal192) {
			self.networkFee = networkFee
			self.royaltyFee = royaltyFee
			self.total = networkFee + royaltyFee
		}

		public init(feeSummary: FeeSummary, feeLocks: FeeLocks) {
			let networkFee = (
				feeSummary.totalExecutionCost
					+ feeSummary.finalizationCost
					+ feeSummary.storageExpansionCost
			) * (1 + PredefinedFeeConstants.networkFeeMultiplier) // add network multiplier on top
			let remainingNonContingentLock = (feeLocks.nonContingentLock - networkFee).clamped

			self.init(
				networkFee: (networkFee - feeLocks.nonContingentLock).clamped,
				royaltyFee: (feeSummary.royaltyCost - remainingNonContingentLock).clamped
			)
		}
	}

	public struct TotalFee: Hashable, Sendable {
		public let min: Decimal192
		public let max: Decimal192

		public init(min: Decimal192, max: Decimal192) {
			self.min = min
			self.max = max
		}

		public var lockFee: Decimal192 {
			// We always lock the max amount
			max
		}

		public var displayedTotalFee: String {
			if max > min {
				return "\(min.formatted()) - \(max.formatted())"
			}
			return max.formatted()
		}
	}
}

extension TransactionFee {
	#if DEBUG
	public static var testValue: Self {
		let feeSummary = TransactionFee.FeeSummary(
			executionCost: 5,
			finalizationCost: 5,
			storageExpansionCost: 5,
			royaltyCost: 10,
			guaranteesCost: 5,
			signaturesCost: 5,
			lockFeeCost: 5,
			notarizingCost: 5
		)
		return .init(feeSummary: feeSummary, feeLocks: .init(nonContingentLock: 0, contingentLock: 0))
	}

	public static var nonContingentLockPaying: Self {
		let feeSummary = TransactionFee.FeeSummary(
			executionCost: 5,
			finalizationCost: 5,
			storageExpansionCost: 5,
			royaltyCost: 10,
			guaranteesCost: 5,
			signaturesCost: 5,
			lockFeeCost: 5,
			notarizingCost: 5
		)
		return .init(feeSummary: feeSummary, feeLocks: .init(nonContingentLock: 100, contingentLock: 0))
	}
	#endif
}
