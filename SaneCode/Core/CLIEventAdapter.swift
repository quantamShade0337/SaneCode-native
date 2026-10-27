import Foundation

final class CLIEventAdapter {
    private var bufferedText = ""

    func events(from chunk: String, roomID: UUID) -> [AgentMessage] {
        bufferedText += chunk
        let parts = bufferedText.components(separatedBy: .newlines)
        bufferedText = parts.last ?? ""

        return parts.dropLast().flatMap { rawLine -> [AgentMessage] in
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.count > 2 else { return [] }
            if let message = structuredEvent(from: line, roomID: roomID) {
                return [message]
            }
            return heuristicEvents(from: line, roomID: roomID)
        }
    }

    private func structuredEvent(from line: String, roomID: UUID) -> AgentMessage? {
        guard line.hasPrefix("{"), let data = line.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let normalized = normalize(object)
        let type = value(for: ["type", "event", "kind", "name"], in: normalized)?.lowercased() ?? "event"
        let kind = messageKind(for: type, object: normalized)
        let text = text(for: normalized, type: type)
        var metadata = flattenedMetadata(from: normalized)
        metadata["stream"] = "jsonl"
        metadata["eventType"] = type

        return AgentMessage(roomID: roomID, kind: kind, text: text, metadata: metadata)
    }

    private func heuristicEvents(from line: String, roomID: UUID) -> [AgentMessage] {
        if line.hasPrefix("$ ") {
            return [AgentMessage(roomID: roomID, kind: .commandStarted, text: line, metadata: ["stream": "text"])]
        }

        let lower = line.lowercased()
        if lower.contains("tool") || lower.contains("read file") || lower.contains("edit file") || lower.contains("apply_patch") {
            return [AgentMessage(roomID: roomID, kind: .toolCall, text: line, metadata: ["stream": "text"])]
        }

        if lower.contains("error") || lower.contains("failed") || lower.contains("exception") {
            return [AgentMessage(roomID: roomID, kind: .error, text: line, metadata: ["stream": "text"])]
        }

        if lower.hasPrefix("plan:") || lower.hasPrefix("summary:") || lower.hasPrefix("files changed:") || lower.hasPrefix("checks:") {
            return [AgentMessage(roomID: roomID, kind: .agentMessage, text: line, metadata: ["stream": "text"])]
        }

        if line.hasPrefix("•") || line.hasPrefix("- ") || line.hasPrefix("* ") {
            return [AgentMessage(roomID: roomID, kind: .agentMessage, text: line, metadata: ["stream": "text"])]
        }

        return []
    }

    private func normalize(_ object: [String: Any]) -> [String: Any] {
        if let msg = object["msg"] as? [String: Any] { return msg.merging(object) { current, _ in current } }
        if let event = object["event"] as? [String: Any] { return event.merging(object) { current, _ in current } }
        if let item = object["item"] as? [String: Any] { return item.merging(object) { current, _ in current } }
        return object
    }

    private func messageKind(for type: String, object: [String: Any]) -> MessageKind {
        let lower = type.lowercased()
        let joined = flattenedMetadata(from: object).values.joined(separator: " ").lowercased()

        if lower.contains("error") || lower.contains("failure") || joined.contains("error") { return .error }
        if lower.contains("approval") { return .approvalRequest }
        if lower.contains("command") || lower.contains("exec") || lower.contains("shell") {
            if lower.contains("output") || lower.contains("delta") { return .commandOutput }
            if lower.contains("finish") || lower.contains("complete") { return .commandFinished }
            return .commandStarted
        }
        if lower.contains("tool") || lower.contains("call") || lower.contains("function") {
            if lower.contains("result") || lower.contains("output") { return .toolResult }
            return .toolCall
        }
        if lower.contains("result") { return .toolResult }
        if lower.contains("agent") || lower.contains("message") || lower.contains("assistant") || lower.contains("response") { return .agentMessage }
        return .systemEvent
    }

    private func text(for object: [String: Any], type: String) -> String {
        if let direct = value(for: ["message", "text", "content", "delta", "output", "result", "summary"], in: object), !direct.isEmpty {
            return direct
        }

        let command = value(for: ["command", "cmd", "argv"], in: object)
        let path = value(for: ["path", "file", "file_path"], in: object)
        let status = value(for: ["status", "exit_code", "exitCode"], in: object)
        let pieces = [type, command, path, status].compactMap { $0 }.filter { !$0.isEmpty }
        if !pieces.isEmpty { return pieces.joined(separator: " · ") }
        return "Agent event: \(type)"
    }

    private func value(for keys: [String], in object: [String: Any]) -> String? {
        for key in keys {
            if let value = object[key] {
                return stringify(value)
            }
            if let match = object.first(where: { $0.key.lowercased() == key.lowercased() })?.value {
                return stringify(match)
            }
        }

        for (_, nested) in object {
            if let nestedObject = nested as? [String: Any], let found = value(for: keys, in: nestedObject) {
                return found
            }
        }
        return nil
    }

    private func flattenedMetadata(from object: [String: Any], prefix: String = "") -> [String: String] {
        var metadata: [String: String] = [:]
        for (key, value) in object {
            let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
            if let nested = value as? [String: Any] {
                metadata.merge(flattenedMetadata(from: nested, prefix: fullKey)) { current, _ in current }
            } else if let string = stringify(value), string.count < 300 {
                metadata[fullKey] = string
            }
        }
        return metadata
    }

    private func stringify(_ value: Any) -> String? {
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number.stringValue }
        if let array = value as? [Any] {
            return array.compactMap(stringify).joined(separator: " ")
        }
        if JSONSerialization.isValidJSONObject(value),
           let data = try? JSONSerialization.data(withJSONObject: value),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }
}
