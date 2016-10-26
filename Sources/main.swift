/*
 * Copyright 2016 Coodly LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import TalkToCloud
import SWLogger

public extension URLSession {
    func synchronousDataWithRequest(request: URLRequest, completionHandler: (Data?, URLResponse?, Error?) -> Void) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let sem = DispatchSemaphore(value: 0)
        
        let task = dataTask(with: request) {
            data = $0
            response = $1
            error = $2
            sem.signal()
        }
        
        task.resume()
        
        sem.wait()
        completionHandler(data, response, error)
    }
}

class Fetch: TalkToCloud.NetworkFetch {
    func fetch(request: URLRequest, completion: NetworkFetchClosure) {
        URLSession.shared.synchronousDataWithRequest(request: request, completionHandler: completion)
    }
}

class CloudLogDelegate: TalkToCloud.Logger {
    func log<T>(_ object: T, file: String, function: String, line: Int) {
        Log.debug(object, file: file, function: function, line: line)
    }
}

SWLogger.Log.add(output: ConsoleOutput())
SWLogger.Log.logLevel = .debug

Log.debug(CommandLine.arguments)
Log.debug("Usage: CloudCopy <container_id> <record>")

guard CommandLine.arguments.count >= 3 else {
    exit(1)
}

let containerID = CommandLine.arguments[1]
let record = CommandLine.arguments[2]

TalkToCloud.Logging.set(logger: CloudLogDelegate())

let fetch = Fetch()

let config = Configuration(containerId: containerID)

let devContainer = config.developmentContainer(with: fetch)
let prodContainer = config.productionContainer(with: fetch)

let copy = Copy(production: prodContainer, development: devContainer, record: record)
copy.execute()
