# EB Tools - Callout Utilities

## Overview

The EB Tools - Callout Utilities package provides helpful contructs to streamline development and testing of Salesforce callouts.

These utilities utilize method chaining as a way to increase the readability of code.

## Installation

A managed package version is available to install [here](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5G000004PzVwQAK).

To install via Salesforce DX, run the following command

```Command Line
sfdx force:package:install -i 04t5G000004PzVwQAK -u <alias or username>
```

## Usage

### Http Request Builder

There are several factory methods on the HttpRequestBuilder used to initialize the request specification with one of two required pieces of information: the method. Methods include `get()`, `post()`, `patch()`, `put()`, and `del()` (delete is a reserved word in Apex). `HttpRequestBuilder.init(String method)` can also be used.

Methods on the builder assign values to the method, headers, and body of the request, as well as other request parameters such as the timeout, compression, and client certificate name to use for encryption.

Invoking `build()` will return the constructed HttpRequest.

Invoking `send()` will execute the request against the remote server or mock and return the response.

#### Multi-part Post Body

Invoking `multipartBody()` configures the request to send the body as Form-Data. The appropriate Content-Type header is set with the calculated boundary value. The format of the boundary is `-----xUNIX_TIMESTAMPx-----`. The returned value is a MultipartBodyBuilder instance on which you can call methods to add fields or files.

The `addField()` method takes a name, value (String) and (optionally) a content type.

The `addFile()` method takes a name, filename, value (Blob), and (optionally) content type. If no content type is provided, the default is `application/octet-stream`.

Set the body back to the request by invoking `setMultipartBody()`. This will return the related HttpRequestBuilder instance.

#### Request Logging

The `RequestLoggingInterface` provides a programmatic hook to access the HttpRequest and HttpResponse objects. A default implementation of this interface is available in the `DefaultRequestLogger` class. In order to enable this functionality, invoke `enableLogging()` method with a `RequestLoggingInterface` instance.

### Mock Server

The MockServer class is a universal implementation of HttpCalloutMock interface that allows the test to determine the behavior exhibited by the endpoint at runtime. It allows for more responsive testing as the test functionality is determined within the test definition instead of a separate class. Additionally, it captures the requests such that we can validate the construction and composition of the web request being sent out from Salesforce.

#### Initialization

Use the static `MockServer.initQueued()` or `MockServer.initMatched()` to initialized the Mock Server. Initialization creates the singleton instance of the MockServer and sets it as the active mock in the test context (`Test.setMock()`).

Once initialized, you can retarget the active mock server using `MockServer.getInstance()`.

#### Queue Mode

When in `QUEUE` mode, the MockServer will return the staged responses in a predefined sequence. Add a response to the queue using the instance method `enqueue(HttpResponse resp)`. These will be returned in a FIFO (first in - first out) sequence as reqeusts are made to the mock.

If no mock responses are available, a `MockServerException` will be thrown.

>This mode is useful in unit tests where the number of potential requests is limited (usually one, sometimes two) and responses vary greatly to accomodate the needs of the test.

#### Match Mode

When in `MATCH` mode, the MockServer will return the correct staged response based on criteria evaluated against the request. In this way, the number of requests does not need to be predetermined, only the total potential responses that can be returned.

Request specs are created using the `whenRequest()` function chain to define request criteria such as method, endpoint, headers, and body content. After request criteria has been defined, invoking `thenReturn` registers the spec and returns an instance of ResponseSpec.

If a request doesn't meet the criteria of any of the RequestSpecs, a `MockServerException` is thrown. If a request meets the criteria of more than one RequestSpec, a `MockServerException` is thrown.

>This mode is useful in larger unit or regression testing scenarios. The MockServer can be initialized in the `@testSetup` method and persist across all tests in the test class without the need to set the response for each individual request.

##### RequestSpec

The RequestSpec object has for properties that can be used to define criteria:

 * `method(String method)` - This method sets the appropriate method, always using an 'equal' operator.
 * `endpoint()` - Allows multiple conditions evaluated against the request endpoint.
 * `header(String headerName)` - Allows multiple conditions evaluated against the header defined as a parameter.
 * `body()` - Allows multiple conditions evaluated against the body of the request.

Each of these specifications use string-based values, performing literal comparisons (no wildcards). Operations include:

 * Is Null/Not Null
 * Equal/Not Equal
 * Contains/Does Not Contain
 * Starts With/Does Not Start With
 * Ends With/Does Not End With

##### ResponseSpec

Upon invoked `thenReturn()` you are provided an instance of ResponseSpec. Invoking the methods inherited from the HttpResponseBuilder define the response. Methods include the following and function similar to those found on the [HttpResponse](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httpresponse.htm):

 * status(String status)
 * statusCode(Integer statusCode)
 * header(String headerName, String headerValue)
 * body(String body)
 * body(Blob body)

>There is no need for any further calls after the response is defined, the `thenReturn()` function registers the specifications with the MockSever.

#### Take Request

To allow better testing of HttpRequests, the MockServer stores all requests made to a list that can be retrieve the requests in sequence using `takeRequest()`. Utilize the `clear()` function to reset this list.

#### Clear and Reset Functions

Because the MockServer acts as a singleton within the execution context, it is shared across all tests in a specific class. In order to prevent one test configuration from bleeding into another, it is best practice to either clear (empty the request list only) or reset (clears all staged configuration for both queue and match mode).

## What are the EB Tools packages?

The EB Tools packages are a collection of helpful components, utilities, and frameworks to promote use of best practices in Salesforce.com development and configuration.

 * [EDHU Trigger Framework](https://bitbucket.org/eidebailly/edhu)
 * [Dynamic Lookup Component](https://bitbucket.org/eidebailly/dynamiclookup2)
