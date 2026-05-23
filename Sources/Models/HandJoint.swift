import Foundation
import CoreGraphics

enum HandJoint: String, CaseIterable {
    case wrist

    case thumbCMC
    case thumbMP
    case thumbIP
    case thumbTip

    case indexMCP
    case indexPIP
    case indexDIP
    case indexTip

    case middleMCP
    case middlePIP
    case middleDIP
    case middleTip

    case ringMCP
    case ringPIP
    case ringDIP
    case ringTip

    case littleMCP
    case littlePIP
    case littleDIP
    case littleTip

    var isTip: Bool {
        rawValue.hasSuffix("Tip")
    }

    var isMCP: Bool {
        rawValue.hasSuffix("MCP")
    }

    var fingerGroup: FingerGroup? {
        if rawValue.hasPrefix("thumb") { return .thumb }
        if rawValue.hasPrefix("index") { return .index }
        if rawValue.hasPrefix("middle") { return .middle }
        if rawValue.hasPrefix("ring") { return .ring }
        if rawValue.hasPrefix("little") { return .little }
        return nil
    }
}

enum FingerGroup: String, CaseIterable {
    case thumb
    case index
    case middle
    case ring
    case little
}
