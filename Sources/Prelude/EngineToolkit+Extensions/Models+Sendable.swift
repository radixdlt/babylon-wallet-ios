import EngineToolkitUniFFI
import Foundation

// MARK: - TransactionManifest + Sendable
extension TransactionManifest: @unchecked Sendable {}

// MARK: - NonFungibleGlobalId + Sendable
extension NonFungibleGlobalId: @unchecked Sendable {}

// MARK: - Instructions + Sendable
extension Instructions: @unchecked Sendable {}

// MARK: - Instruction + Sendable
extension Instruction: @unchecked Sendable {}

// MARK: - EngineToolkitUniFFI.Address + Sendable
extension EngineToolkitUniFFI.Address: @unchecked Sendable {}

// MARK: - ManifestValue + Sendable
extension ManifestValue: @unchecked Sendable {}

// MARK: - MapEntry + Sendable
extension MapEntry: @unchecked Sendable {}

// MARK: - EngineToolkitUniFFI.Decimal + Sendable
extension EngineToolkitUniFFI.Decimal: @unchecked Sendable {}

// MARK: - PreciseDecimal + Sendable
extension PreciseDecimal: @unchecked Sendable {}

// MARK: - ManifestBlobRef + Sendable
extension ManifestBlobRef: @unchecked Sendable {}

// MARK: - Hash + Sendable
extension Hash: @unchecked Sendable {}

// MARK: - TransactionIntent + Sendable
extension TransactionIntent: @unchecked Sendable {}

// MARK: - ExecutionAnalysis + Sendable
extension ExecutionAnalysis: @unchecked Sendable {}

// MARK: - FeeLocks + Sendable
extension FeeLocks: @unchecked Sendable {}

// MARK: - FeeSummary + Sendable
extension FeeSummary: @unchecked Sendable {}

// MARK: - TransactionType + Sendable
extension TransactionType: @unchecked Sendable {}

// MARK: - ResourceSpecifier + Sendable
extension ResourceSpecifier: @unchecked Sendable {}

// MARK: - Resources + Sendable
extension Resources: @unchecked Sendable {}

// MARK: - Source + Sendable
extension Source: @unchecked Sendable {}

// MARK: - MetadataValue + Sendable
extension MetadataValue: @unchecked Sendable {}
