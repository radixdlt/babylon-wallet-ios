import CasePaths
import Foundation

// MARK: - Bool + ValueProtocol
extension Bool: ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .bool
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.boolean
}

// MARK: - Int8 + ValueProtocol
extension Int8: ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .i8
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.i8
}

// MARK: - Int16 + ValueProtocol
extension Int16: ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .i16
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.i16
}

// MARK: - Int32 + ValueProtocol
extension Int32: ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .i32
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.i32
}

// MARK: - Int64 + ValueProtocol
extension Int64: ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .i64
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.i64
}

// MARK: - UInt8 + ValueProtocol
extension UInt8: ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .u8
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.u8
}

// MARK: - UInt16 + ValueProtocol
extension UInt16: ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .u16
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.u16
}

// MARK: - UInt32 + ValueProtocol
extension UInt32: ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .u32
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.u32
}

// MARK: - UInt64 + ValueProtocol
extension UInt64: ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .u64
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.u64
}

// MARK: - String + ValueProtocol
extension String: ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .string
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.string
}
