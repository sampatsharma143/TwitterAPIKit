import Foundation

public enum TwitterAPIKitError: Error {

    case requestFailed(reason: RequestFailureReason)
    public enum RequestFailureReason {
        case invalidURL(url: String)
        case invalidParameter(parameter: [String: Any], cause: String)

        case cannotEncodeStringToData(string: String)
        case jsonSerializationFailed(error: Error)
    }

    case responseFailed(reason: ResponseFailureReason)
    public enum ResponseFailureReason {
        case responseError(error: Error, response: URLResponse?)
        case unacceptableStatusCode(statusCode: Int, error: TwitterAPIErrorResponse, rateLimit: TwitterRateLimit)
    }

    case responseSerializeFailed(reason: ResponseSerializationFailureReason)
    public enum ResponseSerializationFailureReason {
        case jsonSerializationFailed(error: Error, data: Data, rateLimit: TwitterRateLimit)
        case jsonDecodeFailed(error: Error, data: Data, rateLimit: TwitterRateLimit)
        case cannotConvert(data: Data, toTypeName: String)
    }
}

extension TwitterAPIKitError: LocalizedError {
    public var errorDescription: String? {

        switch self {
        case .requestFailed(let reason):
            return reason.localizedDescription
        case .responseFailed(let reason):
            return reason.localizedDescription
        case .responseSerializeFailed(let reason):
            return reason.localizedDescription
        }
    }
}

extension TwitterAPIKitError.RequestFailureReason {
    public var localizedDescription: String {
        switch self {
        case .invalidURL(let url):
            return "URL is not valid: \(url)"
        case .invalidParameter(let parameter, let cause):
            return "Parameter is not valid: \(parameter), cause: \(cause)"
        case .cannotEncodeStringToData(let string):
            return "Could not encode \"\(string)\""
        case .jsonSerializationFailed(let error):
            return "JSON could not be serialized because of error:\n\(error.localizedDescription)"
        }
    }
}

extension TwitterAPIKitError.ResponseFailureReason {
    public var localizedDescription: String {
        switch self {
        case .responseError(let error, response: _):
            return error.localizedDescription
        case let .unacceptableStatusCode(statusCode, error: error, rateLimit: _):
            return "Response status code was unacceptable: \(statusCode) with message: \(error.message)."
        }
    }
}

extension TwitterAPIKitError.ResponseSerializationFailureReason {
    public var localizedDescription: String {
        switch self {
        case .jsonSerializationFailed(let error, data: _, rateLimit: _):
            return "Response could not be serialized because of error:\n\(error.localizedDescription)"
        case .jsonDecodeFailed(let error, data: _, rateLimit: _):
            return "Response could not be decoded because of error:\n\(error.localizedDescription)"
        case .cannotConvert(data: _, let toTypeName):
            return "Response could not convert to \"\(toTypeName)\""
        }
    }
}

extension TwitterAPIKitError {

    public var requestFailureReason: RequestFailureReason? {
        guard case .requestFailed(reason: let reason) = self else { return nil }
        return reason
    }

    public var responseFailureReason: ResponseFailureReason? {
        guard case .responseFailed(let reason) = self else { return nil }
        return reason
    }

    public var responseSerializationFailureReason: ResponseSerializationFailureReason? {
        guard case .responseSerializeFailed(let reason) = self else { return nil }
        return reason
    }
}

/// https://developer.twitter.com/ja/docs/basics/response-codes
public struct TwitterAPIErrorResponse {

    public let message: String
    public let code: Int
    public let errors: [TwitterAPIErrorResponse]

    public init(message: String, code: Int, errors: [TwitterAPIErrorResponse]) {
        self.message = message
        self.code = code
        self.errors = errors
    }

    /// {"errors":[{"message":"Sorry, that page does not exist","code":34}]}
    public init(data: Data) {
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let errors = obj["errors"] as? [[String: Any]]
        else {
            self.message = String(data: data, encoding: .utf8) ?? "Unknown"
            self.code = 0
            self.errors = []
            return
        }

        let tErrors: [TwitterAPIErrorResponse] = errors.compactMap { error in
            guard let message = error["message"] as? String, let code = error["code"] as? Int else { return nil }
            return TwitterAPIErrorResponse(message: message, code: code, errors: [])
        }

        guard !tErrors.isEmpty else {
            self.message = String(data: data, encoding: .utf8) ?? "Unknown"
            self.code = 0
            self.errors = []
            return
        }

        self.message = tErrors[0].message
        self.code = tErrors[0].code
        self.errors = tErrors
    }

    var isValid: Bool {
        return !errors.isEmpty
    }

    public func contains(code: Int) -> Bool {
        return errors.contains(where: { $0.code == code })
    }
}