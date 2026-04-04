//
//  SAImageFetcher.swift
//  SampleApp
//
//  Created by Kunal Kumar on 2020-10-07.
//

import Foundation
@preconcurrency import UIKit.UIImage

/// Error to be displayed when image downloading fails
public enum ImageFetcherError: Error, Sendable, Equatable {
    case imageURLNil
    case unableToFetchImage
}

@MainActor
public final class SAImageFetcher {

    private let urlRequestBuilder: NetworkRequestBuilder
    private let session: URLSession

    /// NSCache object used to cache images by URL key.
    /// NSCache is internally thread-safe; nonisolated(unsafe) lets callers
    /// read/clear it from any context.
    nonisolated(unsafe) public static let cache = NSCache<NSString, UIImage>()

    public init() {
        self.urlRequestBuilder = NetworkRequestBuilder()
        self.session = .shared
    }

    // Internal init for testing with a mock URLSession.
    init(session: URLSession) {
        self.urlRequestBuilder = NetworkRequestBuilder()
        self.session = session
    }

    /**
     Fetches an image from the given URL, returning a cached copy if available.

     - Parameters:
       - url: The URL of the image to fetch.

     - Returns: The fetched `UIImage`.

     - Throws: `ImageFetcherError`
     */
    public func fetchImage(url: URL?) async throws -> UIImage {
        guard let url = url else {
            throw ImageFetcherError.imageURLNil
        }

        if let cachedImage = SAImageFetcher.cache.object(forKey: url.absoluteString as NSString) {
            return cachedImage
        }

        let urlRequest = urlRequestBuilder.buildURLRequest(withURL: url)
        let (data, _) = try await session.data(for: urlRequest)

        guard let image = UIImage(data: data) else {
            throw ImageFetcherError.unableToFetchImage
        }

        SAImageFetcher.cache.setObject(image, forKey: url.absoluteString as NSString)
        return image
    }
}
