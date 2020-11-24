//
//  NetworkClient.swift
//  TFS Chat
//
//  Created by dmitry on 19.11.2020.
//  Copyright © 2020 dmitry. All rights reserved.
//

import Foundation

protocol NetworkClientProtocol {
    
    func sendRequest<Parser: ParserProtocol>(url: String, parser: Parser, completion: @escaping (Result<Parser.Model, Error>) -> Void)
}

class NetworkClient: NetworkClientProtocol {
    
    func sendRequest<Parser: ParserProtocol>(url: String, parser: Parser, completion: @escaping (Result<Parser.Model, Error>) -> Void) {
        
        guard let url = URL(string: url) else {
            completion(.failure(NetworkError.malformedURL))
            print("Malformed URL")
            return }
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                print("Error during request: ", error.localizedDescription)
            }
            
            guard let data = data,
                  let parsedModel: Parser.Model = parser.parse(data: data) else {
                completion(.failure(NetworkError.parsingError))
                print("Error during parsing")
                return
            }
            
            completion(.success(parsedModel))
        }
        dataTask.resume()
    }
}