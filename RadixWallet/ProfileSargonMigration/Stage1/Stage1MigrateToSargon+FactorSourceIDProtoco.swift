import Foundation
import Sargon

// MARK: - BaseFactorSourceIDProtocol
public protocol BaseFactorSourceIDProtocol {
	var kind: FactorSourceKind { get }
	func embed() -> FactorSourceID
}

// MARK: - FactorSourceIDProtocol
public protocol FactorSourceIDProtocol: BaseFactorSourceIDProtocol, Sendable, Hashable, CustomStringConvertible, Codable {
	associatedtype Body: Sendable & Hashable & CustomStringConvertible
	var body: Body { get }
	static var casePath: CasePath<FactorSourceID, Self> { get }
	func embed() -> FactorSourceID
}

extension FactorSourceIDProtocol {
	public var casePath: CasePath<FactorSourceID, Self> { Self.casePath }
	public func embed() -> FactorSourceID {
		casePath.embed(self)
	}

	public static func extract(from factorSourceID: FactorSourceID) -> Self? {
		casePath.extract(from: factorSourceID)
	}
}

extension FactorSourceIDProtocol {
	public var description: String {
		"\(kind):\(String(describing: body))"
	}
}

// MARK: - FactorSourceIDFromHash + FactorSourceIDProtocol
extension FactorSourceIDFromHash: FactorSourceIDProtocol {
	public static let casePath: CasePath<FactorSourceID, Self> = /FactorSourceID.hash
}

// MARK: - FactorSourceIdFromAddress + FactorSourceIDProtocol
extension FactorSourceIdFromAddress: FactorSourceIDProtocol {
	public static let casePath: CasePath<FactorSourceID, Self> = /FactorSourceID.address
}
