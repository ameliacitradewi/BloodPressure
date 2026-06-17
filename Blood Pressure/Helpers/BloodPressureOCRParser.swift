//
//  BloodPressureOCRParser.swift
//  Blood Pressure
//

import Foundation

struct OCRParsedResult {
    var systolic: Int?
    var diastolic: Int?
    var pulse: Int?
    var rawLines: [String]

    var hasAnyValue: Bool {
        systolic != nil || diastolic != nil || pulse != nil
    }
}

enum BloodPressureOCRParser {

    private static let validSystolicRange = 50...300
    private static let validDiastolicRange = 30...200
    private static let validPulseRange = 30...220

    static func parse(lines: [String]) -> OCRParsedResult {
        let normalizedLines = lines.map(normalizedOCRText)
        let combined = normalizedLines.joined(separator: " ")
        var result = OCRParsedResult(systolic: nil, diastolic: nil, pulse: nil, rawLines: lines)

        result.systolic = extractLabeledValue(from: combined, labels: ["SYS", "SYST", "SYSTOLIC"])
        result.diastolic = extractLabeledValue(from: combined, labels: ["DIA", "DIAS", "DIASTOLIC"])
        result.pulse = extractLabeledValue(from: combined, labels: ["PUL", "PULSE", "BPM", "HR", "HEART"])

        if let slashMatch = extractSlashFormat(from: combined) {
            if result.systolic == nil { result.systolic = slashMatch.systolic }
            if result.diastolic == nil { result.diastolic = slashMatch.diastolic }
        }

        if result.systolic == nil || result.diastolic == nil {
            let triple = extractThreeNumberSequence(from: combined)
            if result.systolic == nil { result.systolic = triple?.systolic }
            if result.diastolic == nil { result.diastolic = triple?.diastolic }
            if result.pulse == nil { result.pulse = triple?.pulse }
        }

        if result.systolic == nil || result.diastolic == nil || result.pulse == nil {
            let lineTriple = extractFromThreeLineLayout(lines: normalizedLines)
            if result.systolic == nil { result.systolic = lineTriple?.systolic }
            if result.diastolic == nil { result.diastolic = lineTriple?.diastolic }
            if result.pulse == nil { result.pulse = lineTriple?.pulse }
        }

        result.systolic = validated(result.systolic, in: validSystolicRange)
        result.diastolic = validated(result.diastolic, in: validDiastolicRange)
        result.pulse = validated(result.pulse, in: validPulseRange)

        if let sys = result.systolic, let dia = result.diastolic, sys <= dia {
            result.systolic = nil
            result.diastolic = nil
        }

        return result
    }

    private static func extractLabeledValue(from text: String, labels: [String]) -> Int? {
        for label in labels {
            let pattern = #"(?i)\b"# + label + #"\s*[:.]?\s*(\d{2,3})\b"#
            if let value = firstMatch(in: text, pattern: pattern) {
                return Int(value)
            }
        }
        return nil
    }

    private static func extractSlashFormat(from text: String) -> (systolic: Int, diastolic: Int)? {
        let pattern = #"\b(\d{2,3})\s*[/\\]\s*(\d{2,3})\b"#
        guard let match = regexMatch(in: text, pattern: pattern),
              match.count >= 3,
              let sys = Int(match[1]),
              let dia = Int(match[2]),
              validSystolicRange.contains(sys),
              validDiastolicRange.contains(dia),
              sys > dia else {
            return nil
        }
        return (sys, dia)
    }

    private static func extractThreeNumberSequence(from text: String) -> (systolic: Int, diastolic: Int, pulse: Int?)? {
        let pattern = #"\b(\d{2,3})\s+(\d{2,3})(?:\s+(\d{2,3}))?\b"#
        guard let match = regexMatch(in: text, pattern: pattern),
              match.count >= 3,
              let first = Int(match[1]),
              let second = Int(match[2]) else {
            return nil
        }

        let third = match.count >= 4 ? Int(match[3]) : nil

        if validSystolicRange.contains(first),
           validDiastolicRange.contains(second),
           first > second {
            let pulse = third.flatMap { validPulseRange.contains($0) ? $0 : nil }
            return (first, second, pulse)
        }

        return nil
    }

    private static func validated(_ value: Int?, in range: ClosedRange<Int>) -> Int? {
        guard let value, range.contains(value) else { return nil }
        return value
    }

    private static func normalizedOCRText(_ text: String) -> String {
        let map: [Character: Character] = [
            "O": "0", "o": "0",
            "I": "1", "l": "1", "|": "1",
            "S": "5", "s": "5",
            "B": "8"
        ]
        return String(text.map { map[$0] ?? $0 })
    }

    private static func extractFromThreeLineLayout(lines: [String]) -> (systolic: Int, diastolic: Int, pulse: Int)? {
        guard lines.count >= 3 else { return nil }

        for start in 0...(lines.count - 3) {
            let chunk = Array(lines[start..<(start + 3)])
            guard let sys = firstNumber(in: chunk[0], digitCount: 3),
                  let dia = firstNumber(in: chunk[1], digitCount: 2),
                  let pulse = firstNumber(in: chunk[2], digitCount: 2) else {
                continue
            }

            guard validSystolicRange.contains(sys),
                  validDiastolicRange.contains(dia),
                  validPulseRange.contains(pulse),
                  sys > dia else {
                continue
            }

            return (sys, dia, pulse)
        }

        return nil
    }

    private static func firstNumber(in text: String, digitCount: Int) -> Int? {
        let pattern = #"\d{"# + String(digitCount) + #"}"#
        guard let value = firstMatch(in: text, pattern: pattern) else { return nil }
        return Int(value)
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let match = regexMatch(in: text, pattern: pattern), match.count >= 2 else {
            return nil
        }
        return match[1]
    }

    private static func regexMatch(in text: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }

        return (0..<match.numberOfRanges).compactMap { index in
            let matchRange = match.range(at: index)
            guard let swiftRange = Range(matchRange, in: text) else { return nil }
            return String(text[swiftRange])
        }
    }
}
