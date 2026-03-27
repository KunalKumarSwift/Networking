//
//  SAServiceRequest.swift
//  SampleApp
//
//  Created by Kunal Kumar on 2020-10-07.
//

import Foundation

public protocol SAServiceRequest: SAURLBuilder {

    var contentFetcher: ContentFetcherProtocol { get }

    func requestData<Model: Decodable & Sendable>(model: Model.Type) async throws -> Model

    func requestData<Model: Decodable & Sendable>(
        withParameters parameters: [String: String],
        model: Model.Type
    ) async throws -> Model
}

public extension SAServiceRequest {

    func requestData<Model: Decodable & Sendable>(model: Model.Type) async throws -> Model {
        try await requestData(withParameters: [:], model: model)
    }

    func requestData<Model: Decodable & Sendable>(
        withParameters parameters: [String: String],
        model: Model.Type
    ) async throws -> Model {
        let requestBuilder = NetworkRequestBuilder()
        let urlRequest = try requestBuilder.buildURLRequest(withURLBuilder: self, andParameters: parameters)
        let data = try await contentFetcher.requestContent(request: urlRequest)
        return try JSONDecoder().decode(model, from: data)
    }
}
