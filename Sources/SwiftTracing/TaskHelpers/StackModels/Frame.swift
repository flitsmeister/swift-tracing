//
//  Frame.swift
//
//
//  Created by Tomas Harkema on 21/08/2023.
//

import Foundation

#if DEBUG

#if canImport(SwiftDemangle)
import SwiftDemangle
#endif

struct Frame: CustomDebugStringConvertible, Hashable, Equatable {
    let index: Int
    let lib: String
    let stackPointer: String
    let mangledFunction: String
    let function: String

    init?(_ line: String) {
        if #available(iOS 16, macOS 13, *) {
            guard let match = line.firstMatch(of: FrameRegex.frameRegex) else {
                assertionFailure("STACKFRAME: line not matched: \(line)")
                return nil
            }

            index = match[FrameRegex.indexRef]
            lib = String(match[FrameRegex.libraryRef])
            stackPointer = String(match[FrameRegex.stackPointerRef])
            mangledFunction = String(match[FrameRegex.mangledFuncRef])
#if canImport(SwiftDemangle)
            function = mangledFunction.demangled
#else
            function = mangledFunction
#endif

        } else {
            return nil
        }
    }

    var debugDescription: String {
        "\(function) \(index) \(lib) \(stackPointer)"
    }

    var isSwiftConcurrency: Bool {
        lib.hasPrefix("libswift_Concurrency")
    }

    var isSwiftTask: Bool {
        isSwiftConcurrency && function.contains("Task") && !function.contains("TaskLocal")
    }

    var isFromUIKit: Bool {
        (lib.contains("UIKitCore") || lib.contains("libswiftUIKit")) && (function.contains("UIView") || function.contains("UIApplicationMain"))
    }

    var isAddObserverMain: Bool {
        isFromSwiftTracing && function.contains("addObserverMain") && isComingFromMainActor
    }

    var isComingFromMainActor: Bool {
        function.contains("using: @Swift.MainActor")
    }

    var isFromSwiftTracing: Bool {
        lib.contains("SwiftTracing") || function.contains("SwiftTracing.") || mangledFunction.contains("$s12SwiftTracing")
    }
}
#endif
