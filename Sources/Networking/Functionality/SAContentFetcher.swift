//
//  SContentFetcher.swift
//  SampleApp
//
//  Created by Kunal Kumar on 2020-10-07.
//

import Foundation

public protocol ContentFetcherProtocol: Sendable {
    func requestContent(request: URLRequest) async throws -> Data
}

public final class SAContentFetcher: ContentFetcherProtocol {

    private let session: URLSession

    // shared Instance of SAContentFetcher.
    public static let shared = SAContentFetcher()

    private init() {
        self.session = .shared
    }

    // Internal init for testing with a mock URLSession.
    init(session: URLSession) {
        self.session = session
    }

    /**
     Send out request to a URL and return the response data.

     - Parameters:
       - request: The URLRequest required to send out the request.

     - Returns: The raw `Data` from the response.

     - Throws: `SARequestError`
     */
    public func requestContent(request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SARequestError.otherError(errorCode: -1)
        }

        switch httpResponse.statusCode {
        case SANetworkConstant.successfulResponseLowerRange...SANetworkConstant.successfulResponseUpperRange:
            return data
        case SANetworkConstant.resourceNotFound:
            throw SARequestError.encountered404
        default:
            throw SARequestError.otherError(errorCode: httpResponse.statusCode)
        }
    }
}
