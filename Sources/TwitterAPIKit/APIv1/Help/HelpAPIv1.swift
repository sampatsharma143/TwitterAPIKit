import Foundation

public protocol HelpAPIv1 {

    /// https://developer.twitter.com/en/docs/twitter-api/v1/developer-utilities/supported-languages/api-reference/get-help-languages
    @discardableResult
    func getSupportedLanguages(
        _ request: GetHelpLanguagesRequestV1,
        completionHandler: @escaping (Result<TwitterAPISuccessReponse, TwitterAPIKitError>) -> Void
    ) -> TwitterAPISessionTask
}

extension TwitterAPIKit.TwitterAPIImplV1: HelpAPIv1 {
    func getSupportedLanguages(
        _ request: GetHelpLanguagesRequestV1,
        completionHandler: @escaping (Result<TwitterAPISuccessReponse, TwitterAPIKitError>) -> Void
    ) -> TwitterAPISessionTask {
        return session.send(request, completionHandler: completionHandler)
    }
}