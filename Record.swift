//
// Created by Felipe Lobo on 2018-10-28.
//


public struct Record<Base> {

	public let base: Base

	public init(_ base: Base) {
		self.base = base
	}

}

public protocol RecordCompatible {

	var record: Record<Self> { get }

}

extension RecordCompatible {

	public var record: Record<Self> {
		return Record(self)
	}

}

