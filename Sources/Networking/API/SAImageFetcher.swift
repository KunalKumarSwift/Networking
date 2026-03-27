//
//  SAImageFetcher.swift
//  SampleApp
//
//  Created by Kunal Kumar on 2020-10-07.
//

import Foundation
import UIKit.UIImage

/// Error to be displayed when image downloading fails
public enum ImageFetcherError: Error, Sendable {
    case imageURLNil
    case unableToFetchImage
}

@MainActor
public final class SAImageFetcher {

    private let urlRequestBuilder: NetworkRequestBuilder

    /// NSCache object used to cache images by URL key
    public static let cache = NSCache<NSString, UIImage>()

    public init() {
        self.urlRequestBuilder = NetworkRequestBuilder()
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
        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        guard let image = UIImage(data: data) else {
            throw ImageFetcherError.unableToFetchImage
        }

        SAImageFetcher.cache.setObject(image, forKey: url.absoluteString as NSString)
        return image
    }
}
